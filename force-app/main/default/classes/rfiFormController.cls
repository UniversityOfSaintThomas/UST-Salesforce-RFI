/**
 * Created by Thad-PC-2019 on 9/23/2025.
 */

public with sharing class rfiFormController {

    public class leadAndRfiFields {
        @AuraEnabled public Lead leadRecord { get; set; }
        @AuraEnabled public List<rfiField> rfiFieldList { get; set; }
        @AuraEnabled public List<picklistOption> countryOptions { get; set; }
        @AuraEnabled public List<picklistOption> stateOptions { get; set; }
        @AuraEnabled public Map<String, String> filterValues { get; set; }
        @AuraEnabled public List<programValues> programValues { get; set; }
        @AuraEnabled public String academicLevel { get; set; }
        @AuraEnabled public String schoolCollege { get; set; }
        @AuraEnabled public String academicInterestCodes { get; set; }
        @AuraEnabled public Boolean cantFindSchool { get; set; }
        @AuraEnabled public Boolean iHaveAQuestion { get; set; }
        @AuraEnabled public String redirectUrl { get; set; }
        @AuraEnabled public Boolean redirectAfterSubmission { get; set; }
    }

    public class rfiField {
        @AuraEnabled public String fieldLabel { get; set; }
        @AuraEnabled public String fieldLeadAPIName { get; set; }
        @AuraEnabled public List<picklistOption> picklistValues { get; set; }
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
        @AuraEnabled public Boolean showDependentField { get; set; }
    }

    public class programValues {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public Boolean is_group { get; set; }
        @AuraEnabled public Integer group_level { get; set; } // 1 for school, 2 for degree
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
                        Fields_to_Display_Order__c,
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
                        Program_Types_To_Display__c,
                        Academic_Interest_Label__c,
                        Address_Label__c,
                        Birthdate_Label__c,
                        Citizenship_Label__c,
                        Email_Label__c,
                        Employer_Label__c,
                        Expected_Start_Term_Label__c,
                        High_School_Attended_Label__c,
                        High_School_Graduation_Year_Label__c,
                        How_Did_You_Hear_About_Us_Label__c,
                        I_Have_A_Question_Label__c,
                        Apply_To_St_Thomas_As_Label__c,
                        Mail_Information_Label__c,
                        Receive_Text_Messages_Label__c,
                        Phone_Label__c,
                        Home_Phone_Label__c,
                        First_Name_Label__c,
                        Last_Name_Label__c,
                        Company_Label__c,
                        Scholarship_Of_Interest_Label__c,
                        St_Thomas_Colleges_Label__c,
                        Tell_Us_About_Yourself_Label__c,
                        Timeline_To_Enrollment_Label__c,
                        Title_Label__c,
                        When_Start_School_Label__c
                FROM RFI_Controller__c
                WHERE Name = :rfiControllerName
                LIMIT 1
        ];


        leadAndRfiFields leadAndRfi = new leadAndRfiFields();
        leadAndRfi.academicLevel = rfiController.Academic_Level__c;
        leadAndRfi.schoolCollege = rfiController.School_College__c;
        leadAndRfi.academicInterestCodes = rfiController.Academic_Interests_To_Display__c;
        leadAndRfi.cantFindSchool = false;
        leadAndRfi.iHaveAQuestion = false;
        leadAndRfi.redirectUrl = rfiController.Redirect_URL__c;
        leadAndRfi.redirectAfterSubmission = rfiController.Redirect_After_Form_Submission__c;

        //Populate Lead record with rfi_controller defined values and defaults
        leadAndRfi.leadRecord = new Lead();
        leadAndRfi.leadRecord.Company = 'No Company';
        if (!String.isBlank(rfiController.Lead_Source__c)) {
            leadAndRfi.leadRecord.LeadSource = rfiController.Lead_Source__c;
        }
        if (rfiController.Lead_Owner__c != null) {
            leadAndRfi.leadRecord.OwnerId = rfiController.Lead_Owner__c;
        }
        if (rfiController.Citizenship_Type__c != null) {
            leadAndRfi.leadRecord.Citizenship_Type__c = rfiController.Citizenship_Type__c;
        }

        //Populate School/College lookup if configured
        if (rfiController.School_College__c != null) {
            //Query for the id of the School/College record to populate the lookup properly
            List<Account> school_college_accounts = [
                    SELECT Id
                    FROM Account
                    WHERE School_College_Name__c = :rfiController.School_College__c
                    AND RecordType.DeveloperName = 'University_Department'
                    AND Banner_Key__c LIKE 'STVCOLL-%'
                    AND Name != 'other'
            ];
            if (school_college_accounts.size() > 0) {
                leadAndRfi.leadRecord.St_Thomas_College_School__c = school_college_accounts[0].Id;
            }
        }

        //Get country picklist options
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
        leadAndRfi.stateOptions = getStateProvince('US');

        leadAndRfi.programValues = getPrograms(
                rfiController.Academic_Level__c,
                rfiController.School_College__c,
                rfiController.Academic_Interests_To_Display__c,
                null
        );

        // Prefill sensible defaults
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

        //Map the filter questions to the correct Lead field API names
        Map<String, String> mapFilterToLeadField = new Map<String, String>{
                'School_College_To_Display__c' => 'School_College__c',
                'Citizen_Types_To_Display__c' => 'Citizenship__c',
                'Degree_Types_To_Display__c' => 'Degree_Type__c',
                'Generic_Filter_2_To_Display__c' => 'Generic_Filter_2__c',
                'Generic_Filter_3_To_Display__c' => 'Generic_Filter_3__c',
                'Generic_Filter_4_To_Display__c' => 'Generic_Filter_4__c',
                'Generic_Filter_6_To_Display__c' => 'Generic_Filter_6__c',
                'Generic_Filter_7_To_Display__c' => 'Generic_Filter_7__c',
                'Generic_Filter_8_To_Display__c' => 'Generic_Filter_8__c',
                'Student_Types_To_Display__c' => 'Student_Type__c',
                'Delivery_Types_To_Display__c' => 'Delivery_Type__c',
                'Program_Types_To_Display__c' => 'Generic_Filter_5__c'
        };

        //Create rfiField entries for each valid filter field configured on the controller
        leadAndRfi.filterValues = new Map<String, String>();
        for (String key : mapFilterFields.keySet()) {
            if (String.isNotBlank((String) rfiController.get(key))) {
                // valid filter field
                String questionField = mapFilterFields.get(key);
                String questionText = (String) rfiController.get(questionField);
                if (!String.isBlank(questionText)) {
                    rfiField newField = new rfiField();
                    newField.fieldLabel = questionText;
                    newField.isVisible = true;
                    newField.isRequired = true;
                    newField.isProgramFilter = true;
                    newField.picklistValues = getOptionsFromDelineatedString((String) rfiController.get(key));
                    newField.fieldLeadAPIName = mapFilterToLeadField.get(key);
                    leadAndRfi.rfiFieldList.add(newField);
                    leadAndRfi.filterValues.put(newField.fieldLeadAPIName, '');
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

        //Reorder fieldsToDisplay based on Fields_to_Display_Order__c
        List<String> orderedFields = new List<String>();
        if (!String.isBlank(rfiController.Fields_to_Display_Order__c)) {
            // Use the explicit order from Fields_to_Display_Order__c
            List<String> orderList = rfiController.Fields_to_Display_Order__c.split(';');
            for (String orderedField : orderList) {
                if (fieldsToDisplay.contains(orderedField) && !orderedFields.contains(orderedField)) {
                    orderedFields.add(orderedField);
                }
            }
            // Add any remaining fields that were not in the order list
            for (String fieldName : fieldsToDisplay) {
                if (!orderedFields.contains(fieldName)) {
                    orderedFields.add(fieldName);
                }
            }
            fieldsToDisplay = orderedFields;
        } else {
            // LEGACY SUPPORT: Apply hard-coded order from old requestForInformationForm component
            // This ensures backward compatibility with existing RFI Controller records created
            // before Fields_to_Display_Order__c was implemented
            List<String> legacyOrder = new List<String>{
                'I will apply to St Thomas as a',
                'I will apply to St Thomas Law as a',
                'St Thomas Colleges',
                'Citizenship',
                'Academic Interest',
                'Title',
                'First Name',
                'Last Name',
                'Email',
                'Home and Mobile Phone',
                'Home Phone',
                'Phone',
                'I would like to receive text messages',
                'Birthdate',
                'Employer',
                'Company',
                'Expected Start Term at St Thomas',
                'Timeline to Enrollment',
                'When do you want to start school',
                'High School Attended',
                'High School Graduation Year',
                'Address 1',
                'Address 2',
                'Address 3',
                'City',
                'State',
                'Country',
                'Zipcode',
                'Mail me information',
                'How did you hear about us',
                'Scholarship of Interest',
                'Tell us about yourself',
                'I have a question'
            };

            // Apply legacy order
            for (String legacyField : legacyOrder) {
                if (fieldsToDisplay.contains(legacyField) && !orderedFields.contains(legacyField)) {
                    orderedFields.add(legacyField);
                }
            }
            // Add any remaining fields not in legacy order (in case new fields were added)
            for (String fieldName : fieldsToDisplay) {
                if (!orderedFields.contains(fieldName)) {
                    orderedFields.add(fieldName);
                }
            }
            fieldsToDisplay = orderedFields;

            System.debug('Applied legacy field order for backward compatibility');
        }

        for (String fieldName : fieldsToDisplay) {
            rfiField newField = new rfiField();
            // default visibility/selection
            newField.isVisible = true;
            newField.isSelected = false;
            newField.max = 4;
            switch on fieldName {
                when 'Academic Interest' {
                    newField.fieldLeadAPIName = 'Major_Program__c';
                    newField.isProgramLookup = true;
                    if (rfiController.Academic_Interest_Max_Selection__c != null) {
                        newField.max = Integer.valueOf(String.valueOf(rfiController.Academic_Interest_Max_Selection__c));
                    } else {
                        newField.max = 4;
                    }

                    // Use custom label if provided, otherwise use default
                    if (!String.isBlank(rfiController.Academic_Interest_Label__c)) {
                        if (newField.max == 1) {
                            newField.fieldLabel = rfiController.Academic_Interest_Label__c;
                        } else if (newField.max > 1) {
                            newField.fieldLabel = rfiController.Academic_Interest_Label__c + ' (Max ' + newField.max + ' selections)';
                        }
                    } else {
                        if (newField.max == 1) {
                            newField.fieldLabel = 'Academic Interest';
                        } else if (newField.max > 1) {
                            newField.fieldLabel = 'Academic Interest (Max ' + newField.max + ' selections)';
                        }
                    }
                }
                when 'Address 1', 'Address 2', 'Address 3', 'City', 'Country', 'State', 'Zipcode' {
                    if (!addressAdded) {
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
                    newField.fieldLabel = !String.isBlank(rfiController.Birthdate_Label__c) ? rfiController.Birthdate_Label__c : 'Birthday (MM/DD/YYYY)';
                    newField.fieldLeadAPIName = 'Birthdate';
                    newField.inputType = 'date';
                    newField.isDate = true;
                }
                when 'Citizenship' {
                    newField.fieldLabel = !String.isBlank(rfiController.Citizenship_Label__c) ? rfiController.Citizenship_Label__c : 'Citizenship';
                    newField.fieldLeadAPIName = 'Citizenship_Type__c';
                }
                when 'Email' {
                    newField.fieldLabel = !String.isBlank(rfiController.Email_Label__c) ? rfiController.Email_Label__c : 'Email';
                    newField.fieldLeadAPIName = 'Email';
                    newField.isEmail = true;
                    newField.inputType = 'email';
                }
                when 'Employer' {
                    newField.fieldLabel = !String.isBlank(rfiController.Employer_Label__c) ? rfiController.Employer_Label__c : 'Employer';
                    newField.fieldLeadAPIName = 'Company';
                }
                when 'Expected Start Term at St Thomas' {
                    newField.fieldLabel = !String.isBlank(rfiController.Expected_Start_Term_Label__c) ? rfiController.Expected_Start_Term_Label__c : 'Expected Start Term at St. Thomas';
                    newField.isPicklist = true;
                    newField.picklistValues = getTerms();
                    newField.fieldLeadAPIName = 'Intended_Start_Term__c';
                }
                when 'High School Attended' {
                    newField.fieldLabel = !String.isBlank(rfiController.High_School_Attended_Label__c) ? rfiController.High_School_Attended_Label__c : 'High School Attended';
                    newField.fieldLeadAPIName = 'High_School_or_College__c';
                    newField.isSchoolLookup = true;
                }
                when 'High School Graduation Year' {
                    newField.fieldLabel = !String.isBlank(rfiController.High_School_Graduation_Year_Label__c) ? rfiController.High_School_Graduation_Year_Label__c : 'High School Graduation (YYYY)';
                    newField.fieldLeadAPIName = 'Expected_Graduate_Date__c';
                }
                when 'How did you hear about us' {
                    newField.fieldLabel = !String.isBlank(rfiController.How_Did_You_Hear_About_Us_Label__c) ? rfiController.How_Did_You_Hear_About_Us_Label__c : 'How did you hear about us?';
                    newField.fieldLeadAPIName = 'Heard_About_Us__c';
                }
                when 'I have a question' {
                    newField.fieldLabel = !String.isBlank(rfiController.I_Have_A_Question_Label__c) ? rfiController.I_Have_A_Question_Label__c : 'I have a question';
                    newField.fieldLeadAPIName = 'Has_Question__c';
                    newField.isCheckbox = true;
                    newField.showDependentField = true; // Show Questions/Comments textarea when checked
                }
                when 'I will apply to St Thomas as a' {
                    newField.fieldLabel = !String.isBlank(rfiController.Apply_To_St_Thomas_As_Label__c) ? rfiController.Apply_To_St_Thomas_As_Label__c : 'I will apply to St. Thomas as a';
                    newField.fieldLeadAPIName = 'Admit_Type__c';
                }
                when 'I would like program information to be mailed to me' {
                    newField.fieldLabel = !String.isBlank(rfiController.Mail_Information_Label__c) ? rfiController.Mail_Information_Label__c : 'I would like program information to be mailed to me';
                    newField.fieldLeadAPIName = 'Mail_Information__c';
                    newField.isCheckbox = true;
                }
                when 'I would like to receive text messages' {
                    newField.fieldLabel = !String.isBlank(rfiController.Receive_Text_Messages_Label__c) ? rfiController.Receive_Text_Messages_Label__c : 'I would like to receive text messages';
                    newField.fieldLeadAPIName = 'Text_Message_Opt_In__c';
                    newField.isCheckbox = true;
                }
                when 'Phone' {
                    newField.fieldLabel = !String.isBlank(rfiController.Phone_Label__c) ? rfiController.Phone_Label__c : 'Phone';
                    newField.fieldLeadAPIName = 'Phone';
                    newField.isTel = true;
                    newField.inputType = 'tel';
                }
                when 'Home Phone' {
                    newField.fieldLabel = !String.isBlank(rfiController.Home_Phone_Label__c) ? rfiController.Home_Phone_Label__c : 'Home Phone';
                    newField.fieldLeadAPIName = 'Home_Phone__c';
                    newField.isTel = true;
                    newField.inputType = 'tel';
                }
                when 'First Name' {
                    newField.fieldLabel = !String.isBlank(rfiController.First_Name_Label__c) ? rfiController.First_Name_Label__c : 'First Name';
                    newField.fieldLeadAPIName = 'FirstName';
                }
                when 'Last Name' {
                    newField.fieldLabel = !String.isBlank(rfiController.Last_Name_Label__c) ? rfiController.Last_Name_Label__c : 'Last Name';
                    newField.fieldLeadAPIName = 'LastName';
                }
                when 'Company' {
                    newField.fieldLabel = !String.isBlank(rfiController.Company_Label__c) ? rfiController.Company_Label__c : 'Company';
                    newField.fieldLeadAPIName = 'Company';
                }
                when 'Scholarship of Interest' {
                    newField.fieldLabel = !String.isBlank(rfiController.Scholarship_Of_Interest_Label__c) ? rfiController.Scholarship_Of_Interest_Label__c : 'Scholarship of Interest';
                    newField.fieldLeadAPIName = 'Scholarship_of_Interest__c';
                }
                when 'St Thomas Colleges' {
                    newField.fieldLabel = !String.isBlank(rfiController.St_Thomas_Colleges_Label__c) ? rfiController.St_Thomas_Colleges_Label__c : 'College\\School';
                    newField.isPicklist = true;
                    newField.picklistValues = getUSTSchoolList();
                    newField.fieldLeadAPIName = 'St_Thomas_College_School__c';
                }
                when 'Tell us about yourself' {
                    newField.fieldLabel = !String.isBlank(rfiController.Tell_Us_About_Yourself_Label__c) ? rfiController.Tell_Us_About_Yourself_Label__c : 'Tell us about yourself and why you are interested in this program. (150 words or less)';
                    newField.fieldLeadAPIName = 'Description';
                    newField.isTextarea = true;
                }
                when 'Timeline to Enrollment' {
                    newField.fieldLabel = !String.isBlank(rfiController.Timeline_To_Enrollment_Label__c) ? rfiController.Timeline_To_Enrollment_Label__c : 'Timeline to Enrollment';
                    newField.fieldLeadAPIName = 'Timeline__c';
                }
                when 'Title' {
                    newField.fieldLabel = !String.isBlank(rfiController.Title_Label__c) ? rfiController.Title_Label__c : 'Title';
                    newField.fieldLeadAPIName = 'Title';
                }
                when 'When do you plan to start school' {
                    newField.fieldLabel = !String.isBlank(rfiController.When_Start_School_Label__c) ? rfiController.When_Start_School_Label__c : 'When do you plan to start school';
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
                leadAndRfi.leadRecord.put(newField.fieldLeadAPIName, null);
                if (d.getType() == Schema.DisplayType.MULTIPICKLIST || d.getType() == Schema.DisplayType.PICKLIST) {
                    newField.picklistValues = getPicklistOptions(d);
                    if (d.getType() == Schema.DisplayType.MULTIPICKLIST) {
                        newField.isMultiSelect = true;
                        newField.max = 4;
                    } else {
                        newField.isPicklist = true;
                    }
                }
            } else {

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

    private static final Map<String, Integer> countryIndexCache = new Map<String, Integer>();

    @AuraEnabled(Cacheable=true)
    public static List<picklistOption> getStateProvince(String countryCode) {
        List<picklistOption> stateOptions = new List<picklistOption>();

        if (String.isBlank(countryCode)) {
            return null;
        }

        Integer countryIndex = getCountryIndex(countryCode);
        if (countryIndex == -1) {
            return null;
        }

        Schema.DescribeFieldResult stateField = Lead.StateCode.getDescribe();
        List<Schema.PicklistEntry> stateEntries = stateField.getPicklistValues();

        for (Schema.PicklistEntry entry : stateEntries) {
            if (isValidForCountry(entry, countryIndex)) {
                picklistOption option = new picklistOption();
                option.label = entry.getLabel();
                option.value = entry.getValue();
                stateOptions.add(option);
            }
        }
        return stateOptions;
    }

    private static Integer getCountryIndex(String countryCode) {
        if (countryIndexCache.containsKey(countryCode)) {
            return countryIndexCache.get(countryCode);
        }

        Schema.DescribeFieldResult countryField = Lead.CountryCode.getDescribe();
        List<Schema.PicklistEntry> countryEntries = countryField.getPicklistValues();

        for (Integer i = 0; i < countryEntries.size(); i++) {
            if (countryEntries[i].getValue().equals(countryCode)) {
                countryIndexCache.put(countryCode, i);
                return i;
            }
        }

        countryIndexCache.put(countryCode, -1);
        return -1;
    }

    private static Boolean isValidForCountry(Schema.PicklistEntry entry, Integer countryIndex) {
        String validFor = String.valueOf(((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor'));

        if (String.isBlank(validFor)) {
            return false;
        }

        String base64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        Integer byteIndex = countryIndex / 6;
        Integer bitIndex = 5 - Math.mod(countryIndex, 6);

        if (byteIndex >= validFor.length()) {
            return false;
        }

        Integer charValue = base64.indexOf(validFor.substring(byteIndex, byteIndex + 1));

        return (charValue & (1 << bitIndex)) != 0;
    }

    public static List<picklistOption> getPicklistOptions(Schema.DescribeFieldResult d) {
        List<picklistOption> opts = new List<picklistOption>();
        for (Schema.PicklistEntry e : d.getPicklistValues()) {
            if (e.isActive()) {
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

    public static List<picklistOption> getUSTSchoolList() {
        //Using the list of school names on School_College_To_Display__c field on RFI_Controller__c get the ids of the account ids with matching titles
        Schema.DescribeFieldResult d = Schema.SObjectType.RFI_Controller__c.fields.getMap().get('School_College__c').getDescribe();
        List<String> schoolNameList = new List<String>();
        for (Schema.PicklistEntry e : d.getPicklistValues()) {
            if (e.isActive()) {
                schoolNameList.add(String.valueOf(e.getValue()));
            }
        }
        //Query for Account records matching the school names
        List<Account> schoolAccounts = [
                SELECT Id, School_College_Name__c
                FROM Account
                WHERE School_College_Name__c IN :schoolNameList
                AND RecordType.DeveloperName = 'University_Department'
                AND Banner_Key__c LIKE 'STVCOLL-%'
                AND Name != 'other'
        ];
        List<picklistOption> opts = new List<picklistOption>();
        for (Account acc : schoolAccounts) {
            picklistOption po = new picklistOption();
            po.label = acc.School_College_Name__c;
            po.value = acc.Id;
            opts.add(po);
        }
        return opts;
    }

    @AuraEnabled(Cacheable=true)
    public static List<programValues> getPrograms(String academic_level, String school_college, String academic_interest_codes, Map<String, String> filters) {
        // reference filters to avoid compiler unused-parameter warning

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

        query_string += filterQuery(filters);
        query_string += ' ORDER BY Degree__c, Program_Name_on_Application__c ';
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
                // Group by Degree
                String degreeKey = p.Degree__c != null ? p.Degree__c : 'Other Programs';
                if (!degreeMap.containsKey(degreeKey)) {
                    degreeMap.put(degreeKey, new List<programValues>());
                }
                degreeMap.get(degreeKey).add(pv);
            }

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
        return results;
    }

    private static String filterQuery(Map<String, String> filters) {
        String query_string = '';
        if (filters != null) {
            for (String filterKey : filters.keySet()) {
                String filterValue = filters.get(filterKey);
                if (!String.isBlank(filterValue)) {
                    filterValue = filterValue.escapeHtml4();
                    //Check filter key which is a Lead field to see if it is a picklist or a multipicklist
                    Schema.DescribeFieldResult d = Schema.SObjectType.Program__c.fields.getMap().get(filterKey).getDescribe();
                    if (d.getType() == Schema.DisplayType.MULTIPICKLIST) {
                        List<String> filterValues = filterValue.split(';');
                        query_string += ' AND ' + filterKey + ' INCLUDES ( :filterValues) ';
                    } else {
                        query_string += ' AND ' + filterKey + ' = :filterValue ';
                    }
                }
            }
        }
        return query_string;
    }

    private static List<picklistOption> getTerms() {
        List<picklistOption> termOptions = new List<picklistOption>();
        Date today = System.today();
        Date today_plus_four_years = today.addYears(4);
        // Academic Term -> intended start term
        // limit by 4 years, show Fall and Spring
        Map<Id, Academic_Term__c> terms = new Map<Id, Academic_Term__c>([
                SELECT
                        Id,
                        Name,
                        Term_Start_Date__c
                FROM Academic_Term__c
                WHERE Term_Start_Date__c >= :today
                AND Term_Start_Date__c <= :today_plus_four_years
                AND (Name LIKE 'Fall%' OR Name LIKE 'Spring%')
                ORDER BY Term_Start_Date__c
        ]);
        for (Academic_Term__c term : terms.values()) {
            picklistOption po = new picklistOption();
            po.label = term.Name;
            po.value = String.valueOf(term.Id);
            termOptions.add(po);
        }
        return termOptions;
    }

    /**
     * Get programs for academic interest selector - returns short codes as values
     * @param academic_level - The academic level (U/Undergraduate or G/Graduate)
     * @param school_college - The school/college name
     * @param academic_interest_codes - Semicolon-delimited list of program codes to filter
     * @param filters - Optional filters to apply
     * @return List of programValues with short codes as values, grouped by Primary_School_College_for_Assignment__c
     */
    @AuraEnabled(Cacheable=true)
    public static List<programValues> getProgramsWithShortCodes(String academic_level, String school_college, String academic_interest_codes, Map<String, String> filters) {
        String query_string =
                'SELECT ' +
                        'Id, ' +
                        'Name, ' +
                        'Program_Name_on_Application__c, ' +
                        'Student_Type__c, ' +
                        'Degree__c, ' +
                        'Program_Major_Concentration__c, ' +
                        'Primary_School_College_for_Assignment__c ' +
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

        if (String.isBlank(school_college) && String.isBlank(academic_interest_codes)) {
            //Scope programs to only those with Program_Major_Concentration__c that ar in the available values of the Academic_Interests_To_Display__c field on active RFI_Controller__c
            //Get the values from Academic_Interests_To_Display__c field
            Schema.DescribeFieldResult d = Schema.SObjectType.RFI_Controller__c.fields.getMap().get('Academic_Interests_To_Display__c').getDescribe();
            List<String> academicInterestValues = new List<String>();
            for (Schema.PicklistEntry e : d.getPicklistValues()) {
                if (e.isActive()) {
                    academicInterestValues.add(String.valueOf(e.getValue()));
                }
            }
            query_string += ' AND Program_Major_Concentration__c IN :academicInterestValues ';
        }

        query_string += filterQuery(filters);
        query_string += ' ORDER BY Primary_School_College_for_Assignment__c, Degree__c, Program_Name_on_Application__c ';
        List<Program__c> programs = Database.query(query_string);

        List<programValues> results = new List<programValues>();
        if (!programs.isEmpty()) {
            // Create nested map: School -> Degree -> Programs
            Map<String, Map<String, List<programValues>>> schoolDegreeMap = new Map<String, Map<String, List<programValues>>>();

            for (Program__c p : programs) {
                programValues pv = new programValues();
                pv.label = p.Program_Name_on_Application__c;
                // Use short code as value instead of ID
                pv.value = p.Program_Major_Concentration__c != null ? p.Program_Major_Concentration__c : String.valueOf(p.Id);
                String schoolKey = p.Primary_School_College_for_Assignment__c != null ? p.Primary_School_College_for_Assignment__c : 'Other Programs';
                String degreeKey = p.Degree__c != null ? p.Degree__c : 'Other';
                pv.description = schoolKey + ' - ' + degreeKey + ' - ' + (p.Program_Major_Concentration__c != null ? p.Program_Major_Concentration__c : '');
                pv.is_group = false;
                pv.group_level = 0;

                // Build nested structure
                if (!schoolDegreeMap.containsKey(schoolKey)) {
                    schoolDegreeMap.put(schoolKey, new Map<String, List<programValues>>());
                }
                if (!schoolDegreeMap.get(schoolKey).containsKey(degreeKey)) {
                    schoolDegreeMap.get(schoolKey).put(degreeKey, new List<programValues>());
                }
                schoolDegreeMap.get(schoolKey).get(degreeKey).add(pv);
            }

            // Flatten the nested map into results with school and degree headers
            List<String> sortedSchools = new List<String>(schoolDegreeMap.keySet());
            sortedSchools.sort();

            for (String school : sortedSchools) {
                // Add school header (level 1)
                programValues schoolHeader = new programValues();
                schoolHeader.label = school;
                schoolHeader.value = school;
                schoolHeader.is_group = true;
                schoolHeader.group_level = 1;
                results.add(schoolHeader);

                // Get degrees for this school
                Map<String, List<programValues>> degreeMap = schoolDegreeMap.get(school);
                List<String> sortedDegrees = new List<String>(degreeMap.keySet());
                sortedDegrees.sort();

                for (String degree : sortedDegrees) {
                    // Add degree header (level 2)
                    programValues degreeHeader = new programValues();
                    degreeHeader.label = degree;
                    degreeHeader.value = school + '::' + degree; // Unique value for degree headers
                    degreeHeader.description = school + ' - ' + degree;
                    degreeHeader.is_group = true;
                    degreeHeader.group_level = 2;
                    results.add(degreeHeader);

                    // Add programs for this degree
                    results.addAll(degreeMap.get(degree));
                }
            }
        }
        return results;
    }

//Submit the RFI Lead record
    @AuraEnabled
    public static Id submitRFILead(Lead leadRecord) {
        // Sanitize: copy only valid Lead fields from the incoming record
        System.debug('Received Lead Record: ' + JSON.serializePretty(leadRecord));
        if (leadRecord == null) {
            throw new AuraHandledException('No Lead record provided.');
        }
        if (String.isNotBlank(leadRecord.Major_Program__c)) {
            //using major_program__c id find program with the same name that is of the record type academic program
            List<Program__c> programs = [
                    SELECT Name, Id
                    FROM Program__c
                    WHERE Recruitment_Program__c = :leadRecord.Major_Program__c
                    AND RecordType.DeveloperName = 'Academic_Program'
                    LIMIT 1
            ];
            if (!programs.isEmpty()) {
                leadRecord.Recruitment_Program__c = programs[0].Id;
            }
        }
        Database.DMLOptions dml = new Database.DMLOptions();
        //Will create duplicate records if not allowed
        dml.duplicateRuleHeader.allowSave = true;
        Database.SaveResult result = Database.insert(leadRecord, dml);
        return result.id;
    }
}



