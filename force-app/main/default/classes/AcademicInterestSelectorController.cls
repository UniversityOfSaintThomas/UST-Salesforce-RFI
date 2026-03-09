/**
 * Dedicated controller for the Academic Interest Selector admin tool.
 * Kept separate from rfiFormController to avoid cross-purpose conflicts.
 *
 * Key design decisions:
 * - Programs are scoped to only those whose Program_Major_Concentration__c value
 *   exists as an active entry in the Academic_Interests_To_Display__c picklist.
 *   This ensures the selector can only save valid picklist values back to the field.
 * - Save is done via Apex (not LDS updateRecord) because MultiselectPicklist fields
 *   cannot be written through the LDS updateRecord API.
 */
public with sharing class AcademicInterestSelectorController {

    public class ProgramOption {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public Boolean is_group { get; set; }
        @AuraEnabled public Integer group_level { get; set; }
    }

    /**
     * Returns the list of valid picklist values from Academic_Interests_To_Display__c.
     * These are the only codes the selector is allowed to save back.
     */
    private static Set<String> getValidPicklistValues() {
        Schema.DescribeFieldResult d = Schema.SObjectType.RFI_Controller__c
            .fields.getMap().get('Academic_Interests_To_Display__c').getDescribe();
        Set<String> valid = new Set<String>();
        for (Schema.PicklistEntry e : d.getPicklistValues()) {
            if (e.isActive()) {
                valid.add(e.getValue());
            }
        }
        return valid;
    }

    /**
     * Get all programs eligible for the Academic Interest Selector.
     * Only returns programs whose Program_Major_Concentration__c is a valid
     * entry in the Academic_Interests_To_Display__c picklist.
     * Grouped by school and degree for the dual-listbox UI.
     *
     * @param academic_level  'U'/'Undergraduate' or 'G'/'Graduate'
     * @param school_college  Optional school/college filter
     */
    @AuraEnabled(Cacheable=true)
    public static List<ProgramOption> getSelectablePrograms(String academic_level, String school_college) {
        // Get valid codes from the picklist definition
        Set<String> validCodes = getValidPicklistValues();

        if (validCodes.isEmpty()) {
            return new List<ProgramOption>();
        }

        // Build query scoped to valid picklist codes only
        String query_string =
            'SELECT Id, Program_Name_on_Application__c, Program_Major_Concentration__c, ' +
            'Degree__c, Primary_School_College_for_Assignment__c ' +
            'FROM Program__c ' +
            'WHERE RecordType.DeveloperName = \'Recruitment_Program\' ' +
            'AND Program_Display__c INCLUDES (\'RFI\') ' +
            'AND Active__c = true ' +
            'AND Program_Major_Concentration__c IN :validCodes ';

        if (academic_level == 'U' || academic_level == 'Undergraduate') {
            query_string += 'AND (Academic_Level__c = \'Undergraduate\' OR Academic_Level__c = \'U\') ';
            query_string += 'AND (Program_Type__c INCLUDES (\'Major\') OR Program_Type__c INCLUDES (\'Pre-Professional\') ' +
                            'OR Program_Type__c INCLUDES (\'Major Concentration\') OR Program_Type__c INCLUDES (\'Co-Major\')) ';
        } else {
            query_string += 'AND (Academic_Level__c = \'Graduate\' OR Academic_Level__c = \'G\') ';
            if (String.isNotBlank(school_college)) {
                String safeSchool = String.escapeSingleQuotes(school_college);
                query_string += 'AND Associated_Schools__c INCLUDES (\'' + safeSchool + '\') ';
                if (school_college == 'School of Law') {
                    query_string += 'AND Banner_Program_Code__c LIKE \'LW_%\' ';
                }
            }
        }

        query_string += 'WITH USER_MODE ORDER BY Primary_School_College_for_Assignment__c, Degree__c, Program_Name_on_Application__c';

        List<Program__c> programs = Database.query(query_string);

        // Build nested map: School -> Degree -> Programs
        Map<String, Map<String, List<ProgramOption>>> schoolDegreeMap = new Map<String, Map<String, List<ProgramOption>>>();

        for (Program__c p : programs) {
            String schoolKey = String.isNotBlank(p.Primary_School_College_for_Assignment__c)
                ? p.Primary_School_College_for_Assignment__c : 'Other Programs';
            String degreeKey = String.isNotBlank(p.Degree__c) ? p.Degree__c : 'Other';

            ProgramOption pv = new ProgramOption();
            pv.label = p.Program_Name_on_Application__c;
            pv.value = p.Program_Major_Concentration__c;
            pv.description = schoolKey + ' - ' + degreeKey;
            pv.is_group = false;
            pv.group_level = 0;

            if (!schoolDegreeMap.containsKey(schoolKey)) {
                schoolDegreeMap.put(schoolKey, new Map<String, List<ProgramOption>>());
            }
            if (!schoolDegreeMap.get(schoolKey).containsKey(degreeKey)) {
                schoolDegreeMap.get(schoolKey).put(degreeKey, new List<ProgramOption>());
            }
            schoolDegreeMap.get(schoolKey).get(degreeKey).add(pv);
        }

        // Flatten to list with school/degree headers
        List<ProgramOption> results = new List<ProgramOption>();
        List<String> sortedSchools = new List<String>(schoolDegreeMap.keySet());
        sortedSchools.sort();

        for (String school : sortedSchools) {
            ProgramOption schoolHeader = new ProgramOption();
            schoolHeader.label = school;
            schoolHeader.value = school;
            schoolHeader.is_group = true;
            schoolHeader.group_level = 1;
            results.add(schoolHeader);

            Map<String, List<ProgramOption>> degreeMap = schoolDegreeMap.get(school);
            List<String> sortedDegrees = new List<String>(degreeMap.keySet());
            sortedDegrees.sort();

            for (String degree : sortedDegrees) {
                ProgramOption degreeHeader = new ProgramOption();
                degreeHeader.label = degree;
                degreeHeader.value = school + '::' + degree;
                degreeHeader.description = school + ' - ' + degree;
                degreeHeader.is_group = true;
                degreeHeader.group_level = 2;
                results.add(degreeHeader);

                results.addAll(degreeMap.get(degree));
            }
        }

        return results;
    }

    /**
     * Save selected academic interest codes back to the RFI Controller record.
     * Validates that all supplied codes are valid picklist entries before saving.
     *
     * @param recordId  The RFI_Controller__c record Id
     * @param codes     Semicolon-delimited list of program short codes
     */
    @AuraEnabled
    public static void saveAcademicInterests(Id recordId, String codes) {
        if (!Schema.sObjectType.RFI_Controller__c.isUpdateable()) {
            throw new AuraHandledException('Insufficient permissions to update RFI Controller records.');
        }

        if (String.isBlank(codes)) {
            RFI_Controller__c ctrl = new RFI_Controller__c(
                Id = recordId,
                Academic_Interests_To_Display__c = null
            );
            update ctrl;
            return;
        }

        // Validate all codes against the picklist before saving
        Set<String> validCodes = getValidPicklistValues();
        List<String> incoming = codes.split(';');
        List<String> safeToSave = new List<String>();
        List<String> rejected = new List<String>();

        for (String code : incoming) {
            if (String.isNotBlank(code)) {
                if (validCodes.contains(code.trim())) {
                    safeToSave.add(code.trim());
                } else {
                    rejected.add(code.trim());
                }
            }
        }

        if (!rejected.isEmpty()) {
            System.debug('⚠️ Rejected non-picklist program codes: ' + String.join(rejected, ', '));
        }

        RFI_Controller__c ctrl = new RFI_Controller__c(
            Id = recordId,
            Academic_Interests_To_Display__c = safeToSave.isEmpty() ? null : String.join(safeToSave, ';')
        );
        update ctrl;
    }
}

