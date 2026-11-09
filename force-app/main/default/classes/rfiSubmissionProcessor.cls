/**
 * Fills in the values that the old RFI path set for every inquiry: the old form (requestForInformationForm
 * and its Apex) and the "Lead: Convert to Interaction" flow. The new form saves the Interaction directly,
 * so none of that happens unless it happens here.
 *
 * Rules this class follows:
 *  - An RFI is never blocked. Every step is isolated, a failed step is reported as a warning, and the
 *    record is still saved.
 *  - Values set here come from the server, so they win over anything the browser sent.
 *  - Picklist values are checked against the field before they are set, because restricted picklists
 *    reject unknown values and would make the whole insert fail.
 *  - Lookups that only resolve an Id (programs, terms, record type, presets) run in a small
 *    without-sharing reader. Accounts stay under sharing, so admins decide which schools the guest can see.
 */
public with sharing class rfiSubmissionProcessor {

    private static final String inquirySource = 'Webform';
    private static final String inquiryStage = 'Inquiry';
    private static final String inquiryRecordTypeName = 'Inquiry_Opportunity';
    private static final String undergraduateProgramCode = 'AS_UN_BA';
    private static final String doughertyProgramCode = 'DC_UG_AA|LIBA';
    private static final String doughertySchoolName = 'Dougherty Family College';
    @TestVisible
    private static Set<Id> hiddenLookupIdsForTest = new Set<Id>();
    private static final Set<String> lookupTargetsToSkip = new Set<String>{ 'RecordType', 'User', 'Group' };

    /** Old Lead field names mapped to the Interaction field that replaces them (from the old flow). */
    @TestVisible
    private static final Map<String, String> interactionFieldByLeadField = new Map<String, String>{
            'LeadSource' => 'Lead_Source__c',
            'Company' => 'Employer__c',
            'Title' => 'Contact_Title__c',
            'Description' => 'Description__c',
            'Phone' => 'Home_Phone__c',
            'MobilePhone' => 'Mobile_Phone__c',
            'Citizenship_Type__c' => 'Citizenship__c',
            'Major_Program__c' => 'Major_Program_1__c',
            'Mail_Information_Requested__c' => 'Mailed_Program_Information_Requested__c',
            'Expected_Graduate_Date__c' => 'High_School_Graduation_Year__c',
            'Inquiry_Date__c' => 'Date_Inquiry__c'
    };

    private static Map<String, Schema.SObjectField> cachedInteractionFields;

    /** A preset answer an admin set up for one RFI Controller. */
    public class PresetValue {
        public String fieldApiName { get; private set; }
        public String value { get; private set; }

        /**
         * Builds a preset answer.
         *
         * @param fieldApiName The field the preset applies to
         * @param value The preset value as text
         */
        public PresetValue(String fieldApiName, String value) {
            this.fieldApiName = fieldApiName;
            this.value = value;
        }
    }

    /** The program the old form chose for an undergraduate inquiry. */
    public class ProgramRule {
        public String programName { get; private set; }
        public String programCode { get; private set; }

        /**
         * Builds a program rule result.
         *
         * @param programName The name of the Academic Program
         * @param programCode The Program Major Concentration code of the Academic Program
         */
        public ProgramRule(String programName, String programCode) {
            this.programName = programName;
            this.programCode = programCode;
        }
    }

    /**
     * Applies presets, defaults, State and Country, programs, school and term to an Interaction that is
     * about to be inserted.
     *
     * @param record The Interaction to complete (changed in place)
     * @param controller The RFI Controller the form was loaded from, or null when unknown
     * @return Warnings for steps that could not finish; empty when everything worked
     */
    public static List<String> apply(Interaction__c record, RFI_Controller__c controller) {
        List<String> warnings = new List<String>();
        if (record == null) {
            return warnings;
        }
        ProcessorReader reader = new ProcessorReader();

        try {
            if (controller != null) {
                applyPresetValues(record, reader.getPresetValues(controller.Name), warnings);
            }
        } catch (Exception presetError) {
            warnings.add('Presets: ' + presetError.getMessage());
        }
        try {
            applyDefaults(record, reader);
        } catch (Exception defaultsError) {
            warnings.add('Defaults: ' + defaultsError.getMessage());
        }
        try {
            applyStateAndCountry(record);
        } catch (Exception geographyError) {
            warnings.add('State and Country: ' + geographyError.getMessage());
        }
        try {
            applyPrograms(record, controller, reader);
        } catch (Exception programError) {
            warnings.add('Programs: ' + programError.getMessage());
        }
        try {
            applySchool(record, controller, reader);
        } catch (Exception schoolError) {
            warnings.add('School: ' + schoolError.getMessage());
        }
        try {
            applyTerm(record, reader);
        } catch (Exception termError) {
            warnings.add('Term: ' + termError.getMessage());
        }
        try {
            dropLookupsTheUserCannotSee(record, warnings);
        } catch (Exception visibilityError) {
            warnings.add('Lookup visibility: ' + visibilityError.getMessage());
        }
        return warnings;
    }

    /**
     * Clears every lookup on the record that points to a record the running user cannot see. The reader finds
     * Ids in system mode, but Salesforce refuses the insert when the user cannot see the record a lookup points
     * to. An RFI must always be accepted, so the lookup is dropped (and reported) instead of losing the RFI.
     * Visibility follows the org's sharing rules, so an admin decides what the public form can point to.
     *
     * @param record The Interaction about to be inserted
     * @param warnings Collects a message for every lookup that was cleared
     */
    @TestVisible
    private static void dropLookupsTheUserCannotSee(Interaction__c record, List<String> warnings) {
        for (String fieldName : new List<String>(record.getPopulatedFieldsAsMap().keySet())) {
            Schema.SObjectField field = interactionFields().get(fieldName);
            if (field == null) {
                continue;
            }
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            Object currentValue = record.get(fieldName);
            if (fieldDescribe.getType() != Schema.DisplayType.REFERENCE || String.isBlank(String.valueOf(currentValue))
                    || !(currentValue instanceof Id)) {
                continue;
            }
            List<Schema.SObjectType> targets = fieldDescribe.getReferenceTo();
            if (targets.size() != 1 || lookupTargetsToSkip.contains(targets[0].getDescribe().getName())) {
                continue;
            }
            Id lookupId = (Id) currentValue;
            String targetName = targets[0].getDescribe().getName();
            Boolean visible = !hiddenLookupIdsForTest.contains(lookupId)
                    && !Database.query('SELECT Id FROM ' + String.escapeSingleQuotes(targetName)
                            + ' WHERE Id = :lookupId LIMIT 1').isEmpty();
            if (!visible) {
                record.put(fieldName, null);
                warnings.add('Cleared ' + fieldName + ' because the user cannot see the ' + targetName + ' record ' + lookupId);
            }
        }
    }

    /**
     * Sets the values the old flow set on every inquiry. These win over anything the browser sent.
     *
     * @param record The Interaction to complete
     * @param reader The reader used to find the Inquiry Opportunity record type
     */
    private static void applyDefaults(Interaction__c record, ProcessorReader reader) {
        String sourceValue = resolvePicklistValue('Interaction_Source__c', inquirySource);
        if (sourceValue != null) {
            record.Interaction_Source__c = sourceValue;
        }
        record.Date_Inquiry__c = Date.today();
        String stageValue = resolvePicklistValue('Opportunity_Stage__c', inquiryStage);
        if (stageValue != null) {
            record.Opportunity_Stage__c = stageValue;
        }
        String recordTypeId = reader.getInquiryRecordTypeId();
        if (recordTypeId != null) {
            record.Opportunity_Record_Type__c = recordTypeId;
        }
    }

    /**
     * Copies the address State and Country into the State and Country fields the Opportunity reads. The
     * values are matched against the org's own lists, so they follow the org's State and Country settings.
     *
     * @param record The Interaction to complete
     */
    private static void applyStateAndCountry(Interaction__c record) {
        if (String.isNotBlank(record.Mailing_Country__c)) {
            String countryValue = findPicklistValue('Country__c', record.Mailing_Country__c);
            if (countryValue != null) {
                record.Country__c = countryValue;
            }
        }
        // The form sends the state code (the old flow stored StateCode here). A code that is not in the
        // org's own list is dropped, because a restricted picklist would otherwise reject the whole RFI.
        if (String.isNotBlank(record.State__c)) {
            record.State__c = findPicklistValue('State__c', record.State__c);
        }
        if (String.isBlank(record.State__c) && String.isNotBlank(record.Mailing_State__c)) {
            String stateValue = findPicklistValue('State__c', record.Mailing_State__c);
            if (stateValue != null) {
                record.State__c = stateValue;
            }
        }
    }

    /**
     * Chooses the Academic and Recruitment Program. Undergraduate forms use the old form's rules; other
     * forms (and undergraduate forms where no rule program exists) use the program that matches the major.
     *
     * @param record The Interaction to complete
     * @param controller The RFI Controller, or null when unknown
     * @param reader The reader used to find programs
     */
    private static void applyPrograms(Interaction__c record, RFI_Controller__c controller, ProcessorReader reader) {
        String academicLevel = controller == null ? null : controller.Academic_Level__c;
        Boolean isUndergraduate = academicLevel == 'U' || academicLevel == 'Undergraduate';
        Program__c chosenProgram = null;
        if (isUndergraduate) {
            String schoolName = controller.School_College__c;
            if (String.isBlank(schoolName) && record.Major_Program_1__c != null) {
                schoolName = reader.getPrimarySchoolName(record.Major_Program_1__c);
            }
            ProgramRule rule = chooseUndergraduateProgramRule(record.Admit_Type__c, record.Citizenship__c, schoolName);
            chosenProgram = reader.getAcademicProgramByNameAndCode(rule.programName, rule.programCode);
        }
        if (chosenProgram == null && record.Major_Program_1__c != null) {
            chosenProgram = reader.getAcademicProgramForMajor(record.Major_Program_1__c);
        }
        if (chosenProgram == null) {
            return;
        }
        record.Recruitment_Program__c = chosenProgram.Id;
        record.Academic_Program__c = chosenProgram.Id;
        String associatedSchools = filterMultiPicklist('Recruitment_Program_Associated_Schools__c', chosenProgram.Associated_Schools__c);
        if (String.isNotBlank(associatedSchools)) {
            record.put('Recruitment_Program_Associated_Schools__c', associatedSchools);
        }
    }

    /**
     * Picks the undergraduate Academic Program with the rules the old form used.
     *
     * @param admitType The applicant type the visitor chose (for example Transfer)
     * @param citizenship The citizenship the visitor chose (International changes the transfer program)
     * @param schoolName The school or college of the form or of the chosen major
     * @return The program name and code to look up
     */
    @TestVisible
    private static ProgramRule chooseUndergraduateProgramRule(String admitType, String citizenship, String schoolName) {
        if (admitType == 'Transfer') {
            if (citizenship == 'International') {
                return new ProgramRule('Undergraduate Transfer (INTL)', undergraduateProgramCode);
            }
            return new ProgramRule('Undergraduate Transfer', undergraduateProgramCode);
        }
        if (String.isNotBlank(schoolName) && schoolName.equalsIgnoreCase(doughertySchoolName)) {
            return new ProgramRule(doughertySchoolName, doughertyProgramCode);
        }
        return new ProgramRule('Undergraduate First-Year', undergraduateProgramCode);
    }

    /**
     * Fills the school or college when the form did not set one, from the controller or from the chosen major.
     * Accounts are read under sharing on purpose; if the guest cannot see the school, nothing is set.
     *
     * @param record The Interaction to complete
     * @param controller The RFI Controller, or null when unknown
     * @param reader The reader used to find the major's school name
     */
    private static void applySchool(Interaction__c record, RFI_Controller__c controller, ProcessorReader reader) {
        if (record.St_Thomas_College_School__c != null) {
            return;
        }
        String schoolName = controller == null ? null : controller.School_College__c;
        if (String.isBlank(schoolName) && record.Major_Program_1__c != null) {
            schoolName = reader.getPrimarySchoolName(record.Major_Program_1__c);
        }
        if (String.isBlank(schoolName)) {
            return;
        }
        List<Account> schools = [
                SELECT Id
                FROM Account
                WHERE School_College_Name__c = :schoolName
                AND RecordType.DeveloperName = 'University_Department'
                AND Banner_Key__c LIKE 'STVCOLL-%'
                AND Name != 'other'
                WITH USER_MODE
                LIMIT 1
        ];
        if (!schools.isEmpty()) {
            record.St_Thomas_College_School__c = schools[0].Id;
        }
    }

    /**
     * Finds the Term that matches the start term the visitor chose, as the old flow did.
     *
     * @param record The Interaction to complete
     * @param reader The reader used to find the Term
     */
    private static void applyTerm(Interaction__c record, ProcessorReader reader) {
        if (record.Intended_Start_Term__c == null) {
            return;
        }
        Id termId = reader.getTermIdForAcademicTerm(record.Intended_Start_Term__c);
        if (termId != null) {
            record.Term__c = termId;
        }
    }

    /**
     * Applies an RFI Controller's preset answers. A preset is used only when the visitor left the field blank.
     *
     * @param record The Interaction to complete
     * @param presets The presets set up for the controller
     * @param warnings Collects a message for every preset that could not be applied
     */
    @TestVisible
    private static void applyPresetValues(Interaction__c record, List<PresetValue> presets, List<String> warnings) {
        for (PresetValue preset : presets) {
            if (preset == null || String.isBlank(preset.fieldApiName)) {
                continue;
            }
            String interactionFieldName = toInteractionFieldName(preset.fieldApiName);
            Schema.SObjectField field = interactionFields().get(interactionFieldName.toLowerCase());
            if (field == null) {
                warnings.add('Preset field is not on Interaction: ' + preset.fieldApiName);
                continue;
            }
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            if (fieldDescribe.isCalculated() || fieldDescribe.isAutoNumber()) {
                warnings.add('Preset field cannot be set: ' + interactionFieldName);
                continue;
            }
            if (!isBlankValue(record.get(interactionFieldName))) {
                continue;
            }
            try {
                Object converted = convertPresetValue(fieldDescribe, interactionFieldName, preset.value);
                if (converted == null) {
                    warnings.add('Preset value is not valid for ' + interactionFieldName + ': ' + preset.value);
                    continue;
                }
                record.put(interactionFieldName, converted);
            } catch (Exception conversionError) {
                warnings.add('Preset for ' + interactionFieldName + ': ' + conversionError.getMessage());
            }
        }
    }

    /**
     * Turns a preset's text value into a value of the field's type.
     *
     * @param fieldDescribe The describe of the target field
     * @param interactionFieldName The API name of the target field
     * @param rawValue The preset value as text
     * @return The converted value, or null when the value is not valid for the field
     */
    private static Object convertPresetValue(Schema.DescribeFieldResult fieldDescribe, String interactionFieldName, String rawValue) {
        if (rawValue == null) {
            return null;
        }
        Schema.DisplayType fieldType = fieldDescribe.getType();
        if (fieldType == Schema.DisplayType.BOOLEAN) {
            return Boolean.valueOf(rawValue);
        }
        if (fieldType == Schema.DisplayType.DATE) {
            return Date.valueOf(rawValue);
        }
        if (fieldType == Schema.DisplayType.INTEGER) {
            return Integer.valueOf(rawValue);
        }
        if (fieldType == Schema.DisplayType.DOUBLE || fieldType == Schema.DisplayType.CURRENCY || fieldType == Schema.DisplayType.PERCENT) {
            return Decimal.valueOf(rawValue);
        }
        if (fieldType == Schema.DisplayType.REFERENCE) {
            return Id.valueOf(rawValue);
        }
        if (fieldType == Schema.DisplayType.PICKLIST) {
            return resolvePicklistValue(interactionFieldName, rawValue);
        }
        if (fieldType == Schema.DisplayType.MULTIPICKLIST) {
            return filterMultiPicklist(interactionFieldName, rawValue);
        }
        Integer maximumLength = fieldDescribe.getLength();
        if (maximumLength > 0 && rawValue.length() > maximumLength) {
            return rawValue.substring(0, maximumLength);
        }
        return rawValue;
    }

    /**
     * Translates an old Lead field name into the Interaction field name; names that match pass through.
     *
     * @param leadFieldName The field name stored in the preset
     * @return The Interaction field name
     */
    private static String toInteractionFieldName(String leadFieldName) {
        for (String knownName : interactionFieldByLeadField.keySet()) {
            if (knownName.equalsIgnoreCase(leadFieldName)) {
                return interactionFieldByLeadField.get(knownName);
            }
        }
        return leadFieldName;
    }

    private static Boolean isBlankValue(Object currentValue) {
        if (currentValue == null) {
            return true;
        }
        if (currentValue instanceof String) {
            return String.isBlank((String) currentValue);
        }
        if (currentValue instanceof Boolean) {
            return (Boolean) currentValue == false;
        }
        return false;
    }

    /**
     * Finds the active picklist entry that matches a value or a label, ignoring case.
     *
     * @param fieldApiName The Interaction picklist field
     * @param candidate The value or label to look for
     * @return The entry's API value, or null when nothing matches
     */
    @TestVisible
    private static String findPicklistValue(String fieldApiName, String candidate) {
        if (String.isBlank(candidate)) {
            return null;
        }
        Schema.SObjectField field = interactionFields().get(fieldApiName.toLowerCase());
        if (field == null) {
            return null;
        }
        String wanted = candidate.trim();
        for (Schema.PicklistEntry entry : field.getDescribe().getPicklistValues()) {
            if (entry.isActive() && (wanted.equalsIgnoreCase(entry.getValue()) || wanted.equalsIgnoreCase(entry.getLabel()))) {
                return entry.getValue();
            }
        }
        return null;
    }

    /**
     * Resolves a value for a picklist field. A restricted picklist accepts only its active entries, so an
     * unknown value gives null. An unrestricted picklist accepts any value, so an unknown value is kept.
     *
     * @param fieldApiName The Interaction picklist field
     * @param candidate The value or label to set
     * @return The value to set, or null when it must not be set
     */
    @TestVisible
    private static String resolvePicklistValue(String fieldApiName, String candidate) {
        String matched = findPicklistValue(fieldApiName, candidate);
        if (matched != null) {
            return matched;
        }
        Schema.SObjectField field = interactionFields().get(fieldApiName.toLowerCase());
        if (field != null && String.isNotBlank(candidate) && !field.getDescribe().isRestrictedPicklist()) {
            return candidate.trim();
        }
        return null;
    }

    /**
     * Keeps only the parts of a semicolon-separated value that are active entries of a multi-select picklist.
     *
     * @param fieldApiName The Interaction multi-select picklist field
     * @param rawValue The semicolon-separated value
     * @return The cleaned semicolon-separated value, or null when nothing is valid
     */
    @TestVisible
    private static String filterMultiPicklist(String fieldApiName, String rawValue) {
        if (String.isBlank(rawValue)) {
            return null;
        }
        List<String> keptValues = new List<String>();
        for (String part : rawValue.split(';')) {
            String matched = findPicklistValue(fieldApiName, part);
            if (matched != null && !keptValues.contains(matched)) {
                keptValues.add(matched);
            }
        }
        return keptValues.isEmpty() ? null : String.join(keptValues, ';');
    }

    private static Map<String, Schema.SObjectField> interactionFields() {
        if (cachedInteractionFields == null) {
            cachedInteractionFields = Schema.SObjectType.Interaction__c.fields.getMap();
        }
        return cachedInteractionFields;
    }

    /**
     * Reads the few records the processor needs to resolve Ids and presets. It runs without sharing and in
     * system mode on purpose, because the guest user cannot see these records and the processor only stores
     * the resolved Ids and names on the Interaction the guest is creating. It never returns record lists to
     * the browser.
     */
    private without sharing class ProcessorReader {

        /**
         * Finds the active preset answers for one RFI Controller.
         *
         * @param controllerName The Name of the RFI Controller
         * @return The active presets, or an empty list when there are none
         */
        public List<PresetValue> getPresetValues(String controllerName) {
            List<PresetValue> presetValues = new List<PresetValue>();
            Map<String, Object> binds = new Map<String, Object>{ 'controllerName' => controllerName };
            List<SObject> rows = Database.queryWithBinds(
                    'SELECT Field_API_Name__c, Value__c FROM Lead_Preset_Value__mdt'
                            + ' WHERE RFI_Controller_Name__c = :controllerName AND Active__c = TRUE',
                    binds, AccessLevel.SYSTEM_MODE);
            for (SObject row : rows) {
                presetValues.add(new PresetValue((String) row.get('Field_API_Name__c'), (String) row.get('Value__c')));
            }
            return presetValues;
        }

        /**
         * Finds the Id of the Opportunity record type for inquiries.
         *
         * @return The record type Id as text, or null when the record type does not exist
         */
        public String getInquiryRecordTypeId() {
            List<RecordType> recordTypes = [
                    SELECT Id
                    FROM RecordType
                    WHERE SobjectType = 'Opportunity' AND DeveloperName = :inquiryRecordTypeName
                    LIMIT 1
            ];
            return recordTypes.isEmpty() ? null : String.valueOf(recordTypes[0].Id);
        }

        /**
         * Finds the Term record that matches an Academic Term. Terms come in pairs; the old flow used the one
         * whose key contains the letter a.
         *
         * @param academicTermId The Academic Term the visitor chose
         * @return The Term Id, or null when there is no match
         */
        public Id getTermIdForAcademicTerm(Id academicTermId) {
            List<Academic_Term__c> academicTerms = [
                    SELECT Name
                    FROM Academic_Term__c
                    WHERE Id = :academicTermId
                    WITH SYSTEM_MODE
                    LIMIT 1
            ];
            if (academicTerms.isEmpty()) {
                return null;
            }
            Map<String, Object> binds = new Map<String, Object>{ 'termName' => academicTerms[0].Name };
            List<SObject> terms = Database.queryWithBinds(
                    'SELECT Id FROM hed__Term__c WHERE Name = :termName AND Term_Key__c LIKE \'%a%\' ORDER BY Id LIMIT 1',
                    binds, AccessLevel.SYSTEM_MODE);
            return terms.isEmpty() ? null : terms[0].Id;
        }

        /**
         * Finds the Academic Program that belongs to a Recruitment Program (the major the visitor chose).
         *
         * @param majorId The Recruitment Program the visitor chose
         * @return The Academic Program, or null when there is none
         */
        public Program__c getAcademicProgramForMajor(Id majorId) {
            List<Program__c> programs = [
                    SELECT Id, Associated_Schools__c
                    FROM Program__c
                    WHERE Recruitment_Program__c = :majorId
                    AND RecordType.DeveloperName = 'Academic_Program'
                    AND Active__c = TRUE
                    WITH SYSTEM_MODE
                    LIMIT 1
            ];
            return programs.isEmpty() ? null : programs[0];
        }

        /**
         * Finds an active Academic Program by name and code.
         *
         * @param programName The program name
         * @param programCode The Program Major Concentration code
         * @return The Academic Program, or null when there is none
         */
        public Program__c getAcademicProgramByNameAndCode(String programName, String programCode) {
            List<Program__c> programs = [
                    SELECT Id, Associated_Schools__c
                    FROM Program__c
                    WHERE Name = :programName
                    AND Program_Major_Concentration__c = :programCode
                    AND RecordType.DeveloperName = 'Academic_Program'
                    AND Active__c = TRUE
                    WITH SYSTEM_MODE
                    LIMIT 1
            ];
            return programs.isEmpty() ? null : programs[0];
        }

        /**
         * Finds the school or college a major is assigned to.
         *
         * @param majorId The Recruitment Program the visitor chose
         * @return The school or college name, or null when it is not set
         */
        public String getPrimarySchoolName(Id majorId) {
            List<Program__c> programs = [
                    SELECT Primary_School_College_for_Assignment__c
                    FROM Program__c
                    WHERE Id = :majorId
                    WITH SYSTEM_MODE
                    LIMIT 1
            ];
            return programs.isEmpty() ? null : programs[0].Primary_School_College_for_Assignment__c;
        }
    }
}
