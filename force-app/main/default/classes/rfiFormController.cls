/**
 * Created by Thad-PC-2019 on 9/23/2025.
 */

public with sharing class rfiFormController {

    public class leadAndRfiFields {
        @AuraEnabled public Lead leadRecord { get; set; }
        @AuraEnabled public List<rfiField> rfiFieldList { get; set; }
        @AuraEnabled public List<String> countries { get; set; }
        @AuraEnabled public List<String> states { get; set; }
    }

    public class rfiField {
        @AuraEnabled public String fieldLabel { get; set; }
        @AuraEnabled public String fieldLeadAPIName { get; set; }
        @AuraEnabled public String fieldType { get; set; }
        @AuraEnabled public List<String> picklistValues { get; set; }
        @AuraEnabled public Boolean isVisible { get; set; }
        @AuraEnabled public Boolean isRequired { get; set; }
        @AuraEnabled public Boolean isSelected { get; set; }
        @AuraEnabled public Integer max { get; set; }
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
        // Prefill sensible defaults
        if (String.isBlank(leadAndRfi.leadRecord.Country)) {
            leadAndRfi.leadRecord.Country = 'United States';
        }
        leadAndRfi.rfiFieldList = new List<rfiField>();

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
            // sensible default type
            newField.fieldType = 'text';
            switch on fieldName {
                when 'Academic Interest' {
                    newField.fieldLabel = 'Academic Interest (Max 4)';
                    newField.fieldLeadAPIName = 'Academic_Interests__c';
                    newField.fieldType = 'multi-select';
                    newField.picklistValues = rfiController.Academic_Interests_To_Display__c != null
                            ? rfiController.Academic_Interests_To_Display__c.split(';')
                            : new List<String>();
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
                        newField.fieldType = 'address';
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
                    newField.fieldType = 'date';
                }
                when 'Citizenship' {
                    newField.fieldLabel = 'Citizenship';
                    newField.fieldLeadAPIName = 'Citizenship_Type__c';
                }
                when 'Email' {
                    newField.fieldLabel = 'Email';
                    newField.fieldLeadAPIName = 'Email';
                    newField.fieldType = 'email';
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
                    newField.fieldType = 'checkbox';
                }
                when 'I will apply to St Thomas as a' {
                    newField.fieldLabel = 'I will apply to St. Thomas as a';
                    newField.fieldLeadAPIName = 'Admit_Type__c';
                }
                when 'I would like program information to be mailed to me' {
                    newField.fieldLabel = 'I would like program information to be mailed to me';
                    newField.fieldLeadAPIName = 'Mail_Information__c';
                    newField.fieldType = 'checkbox';
                }
                when 'I would like to receive text messages' {
                    newField.fieldLabel = 'I would like to receive text messages';
                    newField.fieldType = 'checkbox';
                }
                when 'Phone', 'Home and Mobile Phone', 'Mobile Phone' {
                    newField.fieldLabel = 'Phone';
                    newField.fieldLeadAPIName = 'Phone';
                    newField.fieldType = 'tel';
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
                    newField.fieldType = 'textarea';
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
                }
            }


            // If this maps to a real Lead field, detect picklist/multipicklist and populate options
            if (!String.isBlank(newField.fieldLeadAPIName) && newField.fieldLeadAPIName != 'Address' && leadFieldMap.containsKey(newField.fieldLeadAPIName)) {
                Schema.DescribeFieldResult d = leadFieldMap.get(newField.fieldLeadAPIName).getDescribe();
                if (d.getType() == Schema.DisplayType.MULTIPICKLIST) {
                    newField.fieldType = 'multi-select';
                    List<String> opts = new List<String>();
                    for (Schema.PicklistEntry e : d.getPicklistValues()) {
                        if (e.isActive()) opts.add(String.valueOf(e.getValue()));
                    }
                    newField.picklistValues = opts;
                } else if (d.getType() == Schema.DisplayType.PICKLIST) {
                    newField.fieldType = 'picklist';
                    List<String> opts = new List<String>();
                    for (Schema.PicklistEntry e : d.getPicklistValues()) {
                        if (e.isActive()) opts.add(String.valueOf(e.getValue()));
                    }
                    newField.picklistValues = opts;
                }
            }

            //Get states and countries for picklist values from lead
            leadAndRfi.countries = new List<String>();
            for (Schema.PicklistEntry e : leadFieldMap.get('Country').getDescribe().getPicklistValues()) {
                if (e.isActive()) leadAndRfi.countries.add(String.valueOf(e.getValue()));
            }

            leadAndRfi.states = new List<String>();
            for (Schema.PicklistEntry e : leadFieldMap.get('State').getDescribe().getPicklistValues()) {
                if (e.isActive()) leadAndRfi.states.add(String.valueOf(e.getValue()));
            }


            // mark required if present in Required_Fields__c
            if (newField.fieldLeadAPIName != 'Address') {
                Boolean forceRequired = (newField.fieldLeadAPIName == 'FirstName' || newField.fieldLeadAPIName == 'LastName');
                newField.isRequired = forceRequired || requiredFields.contains(fieldName);
                leadAndRfi.rfiFieldList.add(newField);
            }
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
                        newField.fieldType = 'picklist';
                        newField.picklistValues = qMap.get('valuesFlat').toString().split(';');
                        System.debug('Picklist values: ' + newField.picklistValues);
                    } else if (qMap.containsKey('isTextarea') && (Boolean) qMap.get('isTextarea')) {
                        newField.fieldType = 'textarea';
                    } else if (qMap.containsKey('isRichText') && (Boolean) qMap.get('isRichText')) {
                        newField.fieldType = 'richtext';
                    } else if (qMap.containsKey('isEmail') && (Boolean) qMap.get('isEmail')) {
                        newField.fieldType = 'email';
                    } else if (qMap.containsKey('isTextBox') && (Boolean) qMap.get('isTextBox')) {
                        newField.fieldType = 'text';
                    } else {
                        // default to text
                        newField.fieldType = 'text';
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

    @AuraEnabled
    public static Id submitRFI(String rfiControllerName, Map<String, Object> fieldValues) {
        // touch parameter to avoid unused warnings
        Boolean unusedParam = String.isBlank(rfiControllerName);
        // create a lead and set fields dynamically; only set fields that exist on Lead
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
}