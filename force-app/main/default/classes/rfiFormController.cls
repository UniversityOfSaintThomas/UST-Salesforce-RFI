/**
 * Created by Thad-PC-2019 on 9/23/2025.
 */

public with sharing class rfiFormController {

    public class leadAndRfiFields {
        @AuraEnabled public Lead leadRecord { get; set; }
        @AuraEnabled public List<rfiField> rfiFieldList { get; set; }
        @AuraEnabled public List<picklistOption> countryOptions { get; set; }
        @AuraEnabled public List<String> states { get; set; }
    }

    public class rfiField {
        @AuraEnabled public String fieldLabel { get; set; }
        @AuraEnabled public String fieldLeadAPIName { get; set; }
        @AuraEnabled public List<picklistOption> picklistValues { get; set; }
        @AuraEnabled public List<programValues> programValues { get; set; }
        @AuraEnabled public String inputType { get; set; }
        @AuraEnabled public Boolean isVisible { get; set; }
        @AuraEnabled public Boolean isRequired { get; set; }
        @AuraEnabled public Boolean isSelected { get; set; }
        @AuraEnabled public Integer max { get; set; }
        @AuraEnabled public Boolean isCheckbox { get; set; }
        @AuraEnabled public Boolean isEmail { get; set; }
        @AuraEnabled public Boolean isTel { get; set; }
        @AuraEnabled public Boolean isDate { get; set; }
        @AuraEnabled public Boolean isTextarea { get; set; }
        @AuraEnabled public Boolean isMultiSelect { get; set; }
        @AuraEnabled public Boolean isPicklist { get; set; }
        @AuraEnabled public Boolean isAddress { get; set; }
        @AuraEnabled public Boolean isStaticContent { get; set; }
        @AuraEnabled public Boolean isSchoolLookup { get; set; }
        @AuraEnabled public Boolean isProgramLookup { get; set; }
        @AuraEnabled public Boolean isProgramFilter { get; set; }
    }

    public class programValues {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public Boolean is_group { get; set; }
    }

    public class picklistOption {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }
    }

    @AuraEnabled(Cacheable=true)
    public static leadAndRfiFields getRFIForm(String rfiControllerName) {
        RFI_Controller__c rfiController = [
                SELECT
                        Academic_Level__c,
                        School_College__c,
                        Citizenship_Type__c,
                        Fields_to_Display__c,
                        Required_Fields__c,
                        Academic_Interests_To_Display__c,
                        Lead_Owner__c,
                        Redirect_URL__c,
                        Hide_Form_Title__c,
                        Lead_Source__c,
                        Redirect_After_Form_Submission__c,
                        Multi_Select_Display_Type__c,
                        Additional_Questions__c,
                        Academic_Interest_Max_Selection__c,
                        Disable_fields_to_display__c,
                        School_College_Question__c,
                        School_College_To_Display__c,
                        Citizen_Type_Question__c,
                        Citizen_Types_To_Display__c,
                        Degree_Type_Question__c,
                        Degree_Types_To_Display__c,
                        Generic_Filter_2_Question__c,
                        Generic_Filter_2_To_Display__c,
                        Generic_Filter_3_Question__c,
                        Generic_Filter_3_To_Display__c,
                        Generic_Filter_4_Question__c,
                        Generic_Filter_4_To_Display__c,
                        Generic_Filter_6_Question__c,
                        Generic_Filter_6_To_Display__c,
                        Generic_Filter_7_Question__c,
                        Generic_Filter_7_To_Display__c,
                        Generic_Filter_8_Question__c,
                        Generic_Filter_8_To_Display__c,
                        Student_Type_Question__c,
                        Student_Types_To_Display__c,
                        Delivery_Type_Question__c,
                        Delivery_Types_To_Display__c,
                        Program_Type_Question__c,
                        Program_Types_To_Display__c
                FROM RFI_Controller__c
                WHERE Name = :rfiControllerName
                LIMIT 1
        ];


        leadAndRfiFields leadAndRfi = new leadAndRfiFields();
        leadAndRfi.leadRecord = new Lead();

        List<picklistOption> countries = new List<picklistOption>();
        List<Schema.PicklistEntry> countryValues = Lead.CountryCode.getDescribe().getPicklistValues();
        for (Schema.PicklistEntry v : countryValues) {
            if (v.isActive()) {
                picklistOption option = new picklistOption();
                option.label = v.getLabel();
                option.value = v.getValue();
                countries.add(option);
            }
        }
        leadAndRfi.countryOptions = countries;

        // Prefill sensible defaults
        if (String.isBlank(leadAndRfi.leadRecord.Country)) {
            leadAndRfi.leadRecord.Country = 'United States';
        }
        leadAndRfi.rfiFieldList = new List<rfiField>();

        //Get field information for all pre-filters for programs
        Map<String, String> mapFilterFields = new Map<String, String>{
                'School_College_To_Display__c' => 'School_College_Question__c',
                'Citizen_Types_To_Display__c' => 'Citizen_Type_Question__c',
                'Degree_Types_To_Display__c' => 'Degree_Type_Question__c',
                'Generic_Filter_2_To_Display__c' => 'Generic_Filter_2_Question__c',
                'Generic_Filter_3_To_Display__c' => 'Generic_Filter_3_Question__c',
                'Generic_Filter_4_To_Display__c' => 'Generic_Filter_4_Question__c',
                'Generic_Filter_6_To_Display__c' => 'Generic_Filter_6_Question__c',
                'Generic_Filter_7_To_Display__c' => 'Generic_Filter_7_Question__c',
                'Generic_Filter_8_To_Display__c' => 'Generic_Filter_8_Question__c',
                'Student_Types_To_Display__c' => 'Student_Type_Question__c',
                'Delivery_Types_To_Display__c' => 'Delivery_Type_Question__c',
                'Program_Types_To_Display__c' => 'Program_Type_Question__c'
        };

        //Create rfiField entries for each valid filter field configured on the controller
        for (String key : mapFilterFields.keySet()) {
            if (String.isNotBlank((String) rfiController.get(key))) {
                // valid filter field
                String questionField = mapFilterFields.get(key);
                String questionText = (String) rfiController.get(questionField);
                if (!String.isBlank(questionText)) {
                    rfiField newField = new rfiField();
                    newField.fieldLabel = questionText;
                    //newField.fieldLeadAPIName = key.replace('_To_Display__c', '__c');
                    newField.isPicklist = true;
                    newField.isVisible = true;
                    newField.isSelected = false;
                    newField.isRequired = false;
                    newField.isProgramFilter = true;
                    newField.picklistValues = getOptionsFromDelineatedString((String) rfiController.get(key));
                    leadAndRfi.rfiFieldList.add(newField);
                }

            }
        }


        List<String> fieldsToDisplay = rfiController.Fields_to_Display__c != null
                ? rfiController.Fields_to_Display__c.split(';')
                : new List<String>();
        // If no fields configured on the controller record, use a sensible internal default
        if (fieldsToDisplay.isEmpty()) {
            fieldsToDisplay.addAll(new List<String>{
                    'First Name', 'Last Name', 'Email'
            });
        }
        // Always include First/Last Name even if not configured
        if (!fieldsToDisplay.contains('Last Name')) {
            fieldsToDisplay.add(0, 'Last Name');
        }
        if (!fieldsToDisplay.contains('First Name')) {
            fieldsToDisplay.add(0, 'First Name');
        }
        List<String> requiredFields = rfiController.Required_Fields__c != null ? rfiController.Required_Fields__c.split(';') : new List<String>();


        Boolean addressAdded = false;
        // Lead field describes for dynamic picklist detection
        Map<String, Schema.SObjectField> leadFieldMap = Schema.SObjectType.Lead.fields.getMap();


        for (String fieldName : fieldsToDisplay) {
            rfiField newField = new rfiField();
            // default visibility/selection
            newField.isVisible = true;
            newField.isSelected = false;
            newField.max = 4;
            switch on fieldName {
                when 'Academic Interest' {
                    newField.fieldLabel = 'Academic Interest (Max 4)';
                    newField.fieldLeadAPIName = 'Academic_Interests__c';
                    newField.isProgramLookup = true;
                    newField.programValues = getPrograms(rfiController.Academic_Level__c, rfiController.School_College__c, rfiController.Academic_Interests_To_Display__c, rfiController.Multi_Select_Display_Type__c == 'Standard Multi-Select', '');
                    if (rfiController.Academic_Interest_Max_Selection__c != null) {
                        try {
                            newField.max = Integer.valueOf(rfiController.Academic_Interest_Max_Selection__c);
                        } catch (Exception ex) {
                            // ignore if not numeric
                        }
                    }
                }
                when 'Address 1', 'Address 2', 'Address 3', 'City', 'Country', 'State', 'Zipcode' {
                    if (!addressAdded) {
                        newField.fieldLabel = 'Address';
                        newField.fieldLeadAPIName = 'Address';
                        newField.isAddress = true;
                        addressAdded = true;
                        // mark required if present in Required_Fields__c using any of the address tokens
                        newField.isRequired = requiredFields.contains('Address 1') || requiredFields.contains('City') ||
                                requiredFields.contains('Country') || requiredFields.contains('State') || requiredFields.contains('Zipcode');
                        leadAndRfi.rfiFieldList.add(newField);
                    }
                    continue; // skip adding duplicates for address tokens
                }
                when 'Birthdate' {
                    newField.fieldLabel = 'Birthday (MM/DD/YYYY)';
                    newField.fieldLeadAPIName = 'Birthdate';
                    newField.inputType = 'date';
                    newField.isDate = true;
                }
                when 'Citizenship' {
                    newField.fieldLabel = 'Citizenship';
                    newField.fieldLeadAPIName = 'Citizenship_Type__c';
                }
                when 'Email' {
                    newField.fieldLabel = 'Email';
                    newField.fieldLeadAPIName = 'Email';
                    newField.isEmail = true;
                    newField.inputType = 'email';
                }
                when 'Employer' {
                    newField.fieldLabel = 'Employer';
                    newField.fieldLeadAPIName = 'Company';
                }
                when 'Expected Start Term at St Thomas' {
                    newField.fieldLabel = 'Expected Start Term at St. Thomas';
                    newField.fieldLeadAPIName = 'Intended_Start_Term__c';
                }
                when 'High School Attended' {
                    newField.fieldLabel = 'High School Attended';
                    newField.fieldLeadAPIName = 'High_School_or_College__c';
                    newField.isSchoolLookup = true;
                }
                when 'High School Graduation Year' {
                    newField.fieldLabel = 'High School Graduation (YYYY)';
                    newField.fieldLeadAPIName = 'Expected_Graduate_Date__c';
                }
                when 'How did you hear about us' {
                    newField.fieldLabel = 'How did you hear about us?';
                    newField.fieldLeadAPIName = 'Heard_About_Us__c';
                }
                when 'I have a question' {
                    newField.fieldLabel = 'I have a question';
                    newField.fieldLeadAPIName = 'Has_Question__c';
                    newField.isCheckbox = true;
                }
                when 'I will apply to St Thomas as a' {
                    newField.fieldLabel = 'I will apply to St. Thomas as a';
                    newField.fieldLeadAPIName = 'Admit_Type__c';
                }
                when 'I would like program information to be mailed to me' {
                    newField.fieldLabel = 'I would like program information to be mailed to me';
                    newField.fieldLeadAPIName = 'Mail_Information__c';
                    newField.isCheckbox = true;
                }
                when 'I would like to receive text messages' {
                    newField.fieldLabel = 'I would like to receive text messages';
                    newField.isCheckbox = true;
                }
                when 'Phone', 'Home and Mobile Phone', 'Mobile Phone' {
                    newField.fieldLabel = 'Phone';
                    newField.fieldLeadAPIName = 'Phone';
                    newField.isTel = true;
                    newField.inputType = 'tel';
                }
                when 'First Name' {
                    newField.fieldLabel = 'First Name';
                    newField.fieldLeadAPIName = 'FirstName';
                }
                when 'Last Name' {
                    newField.fieldLabel = 'Last Name';
                    newField.fieldLeadAPIName = 'LastName';
                }
                when 'Company' {
                    newField.fieldLabel = 'Company';
                    newField.fieldLeadAPIName = 'Company';
                }
                when 'Scholarship of Interest' {
                    newField.fieldLabel = 'Scholarship of Interest';
                    newField.fieldLeadAPIName = 'Scholarship_of_Interest__c';
                }
                when 'St Thomas Colleges' {
                    newField.fieldLabel = 'College\\School';
                    newField.fieldLeadAPIName = 'High_School_or_College__c';
                }
                when 'Tell us about yourself' {
                    newField.fieldLabel = 'Tell us about yourself and why you are interested in this program. (150 words or less)';
                    newField.fieldLeadAPIName = 'Description';
                    newField.isTextarea = true;
                }
                when 'Timeline to Enrollment' {
                    newField.fieldLabel = 'Timeline to Enrollment';
                    newField.fieldLeadAPIName = 'Timeline__c';
                }
                when 'Title' {
                    newField.fieldLabel = 'Title';
                    newField.fieldLeadAPIName = 'Title';
                }
                when 'When do you plan to start school' {
                    newField.fieldLabel = 'When do you plan to start school';
                    newField.fieldLeadAPIName = 'Expected_Graduate_Date__c';
                }
                when else {
                    newField.fieldLabel = 'Field Label Not Found';
                    newField.fieldLeadAPIName = 'Description';
                    newField.isTextarea = true;
                }
            }


            // If this maps to a real Lead field, detect picklist/multipicklist and populate options
            if (!String.isBlank(newField.fieldLeadAPIName) && newField.fieldLeadAPIName != 'Address' && leadFieldMap.containsKey(newField.fieldLeadAPIName)) {
                Schema.DescribeFieldResult d = leadFieldMap.get(newField.fieldLeadAPIName).getDescribe();
                if (d.getType() == Schema.DisplayType.MULTIPICKLIST || d.getType() == Schema.DisplayType.PICKLIST) {
                    System.debug('Picklist detected: ' + newField.fieldLeadAPIName);
                    newField.picklistValues = getPicklistOptions(d);
                    if (d.getType() == Schema.DisplayType.MULTIPICKLIST) {
                        newField.isMultiSelect = true;
                        newField.max = 4;
                    } else {
                        newField.isPicklist = true;
                    }
                }
            }

            Boolean forceRequired = (newField.fieldLeadAPIName == 'FirstName' || newField.fieldLeadAPIName == 'LastName');
            newField.isRequired = forceRequired || requiredFields.contains(fieldName);
            leadAndRfi.rfiFieldList.add(newField);

        }

        // Additional Questions
        /* Data example stored in Additional_Questions__c field:
        [{"id":0,"questionLabel":"TEST","questionType":"Picklist","fieldToApplyTo":"Description","assistiveText":"","position":"bottom","isPicklist":true,"isRequired":false,"isTextBox":false,"isTextarea":false,"isRichText":false,"isStaticContent":false,"isEmail":false,"picklistValues":[{"label":"Test1","value":"Test1"},{"label":"Test2","value":"Test2"},{"label":"Test3","value":"Test3"},{"label":"Test4","value":"Test4"},{"label":"Test5","value":"Test5"}],"valuesFlat":"Test1;Test2;Test3;Test4;Test5"}]
         */
        List<rfiField> additionalFieldsTop = new List<rfiField>();
        List<rfiField> additionalFieldsBottom = new List<rfiField>();
        if (!String.isBlank(rfiController.Additional_Questions__c)) {
            try {
                List<Object> additionalQuestions = (List<Object>) JSON.deserializeUntyped(rfiController.Additional_Questions__c);
                for (Object qObj : additionalQuestions) {
                    if (!(qObj instanceof Map<String, Object>)) continue;
                    Map<String, Object> qMap = (Map<String, Object>) qObj;
                    rfiField newField = new rfiField();
                    newField.fieldLabel = qMap.containsKey('questionLabel') ? String.valueOf(qMap.get('questionLabel')) : 'Question';
                    newField.fieldLeadAPIName = qMap.containsKey('fieldToApplyTo') ? String.valueOf(qMap.get('fieldToApplyTo')) : 'Description';
                    newField.isRequired = qMap.containsKey('isRequired') ? (Boolean) qMap.get('isRequired') : false;
                    // Determine field type
                    if (qMap.containsKey('isPicklist') && (Boolean) qMap.get('isPicklist')) {
                        newField.isPicklist = true;
                        newField.picklistValues = getOptionsFromDelineatedString((String) qMap.get('valuesFlat'));
                    } else if (qMap.containsKey('isTextarea') && (Boolean) qMap.get('isTextarea')) {
                        newField.isTextarea = true;
                    } else if (qMap.containsKey('isRichText') && (Boolean) qMap.get('isRichText')) {
                        newField.isStaticContent = true;
                    } else if (qMap.containsKey('isEmail') && (Boolean) qMap.get('isEmail')) {
                        newField.isEmail = true;
                        newField.inputType = 'email';
                    } else if (qMap.containsKey('isTextBox') && (Boolean) qMap.get('isTextBox')) {
                        newField.isTextarea = true;
                    }
                    //if position is top add to the start of leadAndRfi.rfiFieldList
                    if (qMap.containsKey('position') && String.valueOf(qMap.get('position')).toLowerCase() == 'top') {
                        additionalFieldsTop.add(newField);
                    } else {
                        additionalFieldsBottom.add(newField);
                    }
                }
            } catch (Exception ex) {
                // ignore JSON parse errors
            }

            // Add additional fields to the main list in the correct position
            if (!additionalFieldsTop.isEmpty()) {
                List<rfiField> merged = new List<rfiField>();
                merged.addAll(additionalFieldsTop);
                merged.addAll(leadAndRfi.rfiFieldList);
                leadAndRfi.rfiFieldList = merged;
            }
            if (!additionalFieldsBottom.isEmpty()) {
                leadAndRfi.rfiFieldList.addAll(additionalFieldsBottom);
            }

        }

        return leadAndRfi;
    }

    @AuraEnabled(Cacheable=true)
    public static List<picklistOption> getStateProvince(String countryCode) {
        List<PicklistOption> stateOptions = new List<PicklistOption>();
/*        Schema.DescribeFieldResult fieldResult = Account.MailingStateCode.getDescribe();
        List<Schema.PicklistEntry> stateEntries = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry entry : stateEntries) {
            if (entry.getValidFor() != null && entry.getValidFor().contains(countryCode)) { // Simplified check
                stateOptions.add(new PicklistOption(entry.getLabel(), entry.getValue()));
            }
        }*/
        return stateOptions;
    }

    @AuraEnabled
    public static Id submitRFI(String rfiControllerName, Map<String, Object> fieldValues) {
        // intentionally do not use rfiControllerName here; parameter kept for compatibility
        Lead l = new Lead();
        Map<String, Schema.SObjectField> leadFields = Schema.SObjectType.Lead.fields.getMap();
        for (String apiName : fieldValues.keySet()) {
            if (String.isBlank(apiName)) continue;
            if (!leadFields.containsKey(apiName)) continue;
            Object val = fieldValues.get(apiName);
            // Handle boolean strings
            if (val instanceof String && ((String) val).equalsIgnoreCase('true') || ((String) val).equalsIgnoreCase('false')) {
                // coerce to boolean for checkbox fields
                try {
                    val = ((String) val).equalsIgnoreCase('true');
                } catch (Exception ex) {
                }
            }
            l.put(apiName, val);
        }
        insert l;
        return l.Id;
    }

    @AuraEnabled
    public static Id submitRFILead(Lead leadRecord) {
        // Sanitize: copy only valid Lead fields from the incoming record
        Lead toInsert = new Lead();
        Map<String, Schema.SObjectField> leadFields = Schema.SObjectType.Lead.fields.getMap();
        Map<String, Object> incoming = leadRecord != null ? leadRecord.getPopulatedFieldsAsMap() : new Map<String, Object>();
        for (String apiName : incoming.keySet()) {
            if (leadFields.containsKey(apiName)) {
                toInsert.put(apiName, incoming.get(apiName));
            }
        }
        insert toInsert;
        return toInsert.Id;
    }

    public static List<picklistOption> getPicklistOptions(Schema.DescribeFieldResult d) {
        List<picklistOption> opts = new List<picklistOption>();
        for (Schema.PicklistEntry e : d.getPicklistValues()) {
            if (e.isActive()) {
                System.debug('Adding picklist option: ' + e.getLabel() + ' / ' + e.getValue());
                picklistOption po = new picklistOption();
                po.label = String.valueOf(e.getLabel());
                po.value = String.valueOf(e.getValue());
                opts.add(po);
            }
        }
        return opts;
    }

    public static List<picklistOption> getOptionsFromDelineatedString(String delimited) {
        List<picklistOption> opts = new List<picklistOption>();
        for (String val : delimited.split(';')) {
            picklistOption po = new picklistOption();
            po.label = val;
            po.value = val;
            opts.add(po);
        }
        return opts;
    }

    @AuraEnabled(Cacheable=true)
    public static List<programValues> getPrograms(String academic_level, String school_college, String academic_interest_codes, Boolean multi_select_standard, String filters) {
        // reference filters to avoid compiler unused-parameter warning
        Boolean unusedFilters = String.isBlank(filters);

        String query_string =
                //Student type buckets
                'SELECT ' +
                        'Id, ' +
                        'Name, ' +
                        'Program_Name_on_Application__c, ' +
                        'Student_Type__c, ' +
                        'Degree__c, ' +
                        'Program_Major_Concentration__c ' +
                        'FROM Program__c ' +
                        'WHERE RecordType.DeveloperName = \'Recruitment_Program\' ' +
                        'AND Program_Display__c INCLUDES (\'RFI\') ' +
                        'AND Active__c = true ';
        if (academic_level == 'U' || academic_level == 'Undergraduate') {
            query_string += ' AND (Academic_Level__c = \'Undergraduate\' OR Academic_Level__c = \'U\') ';
            query_string += ' AND (Program_Type__c INCLUDES (\'Major\') OR Program_Type__c INCLUDES (\'Pre-Professional\') OR Program_Type__c INCLUDES (\'Major Concentration\') OR Program_Type__c INCLUDES (\'Co-Major\')) ';
        } else {
            query_string += ' AND (Academic_Level__c = \'Graduate\' OR Academic_Level__c = \'G\')  ';
            if (!String.isBlank(school_college)) {
                query_string += ' AND Associated_Schools__c INCLUDES (\'' + school_college + '\')';
                if (school_college == 'School of Law') {
                    query_string += ' AND Banner_Program_Code__c LIKE \'LW_%\'';
                }
            }
        }

        if (String.isNotBlank(academic_interest_codes)) {
            academic_interest_codes = academic_interest_codes.escapeHtml4();
            List<String> academicCodes = academic_interest_codes.split(';');
            query_string += ' AND Program_Major_Concentration__c IN :academicCodes ';
        }
        if (multi_select_standard) {
            query_string += ' ORDER BY Program_Name_on_Application__c ';
        } else {
            query_string += ' ORDER BY Degree__c, Program_Name_on_Application__c ';
        }

        List<Program__c> programs = Database.query(query_string);

        List<programValues> results = new List<programValues>();
        if (!programs.isEmpty()) {
            Map<String, List<programValues>> degreeMap = new Map<String, List<programValues>>();
            for (Program__c p : programs) {
                programValues pv = new programValues();
                pv.label = p.Program_Name_on_Application__c;
                pv.value = String.valueOf(p.Id);
                pv.description = (p.Degree__c != null ? p.Degree__c + ' - ' : '') + (p.Program_Major_Concentration__c != null ? p.Program_Major_Concentration__c : '');
                pv.is_group = false;
                if (multi_select_standard) {
                    results.add(pv);
                } else {
                    // Group by Degree
                    String degreeKey = p.Degree__c != null ? p.Degree__c : 'Other Programs';
                    if (!degreeMap.containsKey(degreeKey)) {
                        degreeMap.put(degreeKey, new List<programValues>());
                    }
                    degreeMap.get(degreeKey).add(pv);
                }
            }
            if (!multi_select_standard) {
                // Flatten the map into results with group headers
                List<String> sortedDegrees = new List<String>(degreeMap.keySet());
                sortedDegrees.sort();
                for (String degree : sortedDegrees) {
                    programValues header = new programValues();
                    header.label = degree;
                    header.value = degree;
                    header.is_group = true;
                    results.add(header);
                    results.addAll(degreeMap.get(degree));
                }
            }

        }
        return results;
    }
}