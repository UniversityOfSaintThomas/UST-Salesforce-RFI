/**
 * Created by Thad-PC-2019 on 9/23/2025.
 */

public with sharing class rfiFormController {

    public class interactionRFIFields {
        @AuraEnabled public Interaction__c interaction { get; set; }
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
        @AuraEnabled public String fieldInteractionAPIName { get; set; }
        @AuraEnabled public List<picklistOption> picklistValues { get; set; }
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
        @AuraEnabled public String staticContentHtml { get; set; } // HTML content for static content fields
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
    public static interactionRFIFields getRFIForm(String rfiControllerName) {
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
                        Interaction_Questions__c,
                        Unified_Questions__c,
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


        interactionRFIFields interactionAndRfi = new interactionRFIFields();
        interactionAndRfi.academicLevel = rfiController.Academic_Level__c;
        interactionAndRfi.schoolCollege = rfiController.School_College__c;
        interactionAndRfi.academicInterestCodes = rfiController.Academic_Interests_To_Display__c;
        interactionAndRfi.cantFindSchool = false;
        interactionAndRfi.iHaveAQuestion = false;
        interactionAndRfi.redirectUrl = rfiController.Redirect_URL__c;
        interactionAndRfi.redirectAfterSubmission = rfiController.Redirect_After_Form_Submission__c;

        //Populate Interaction record with rfi_controller defined values and defaults
        interactionAndRfi.interaction = new Interaction__c();
        interactionAndRfi.interaction.Employer__c = 'No Company';
        if (String.isNotBlank(rfiController.Lead_Source__c)) {
            interactionAndRfi.interaction.Lead_Source__c = rfiController.Lead_Source__c;
        }
        if (rfiController.Lead_Owner__c != null) {
            interactionAndRfi.interaction.OwnerId = rfiController.Lead_Owner__c;
        }
        if (rfiController.Citizenship_Type__c != null) {
            interactionAndRfi.interaction.Citizenship__c = rfiController.Citizenship_Type__c;
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
                interactionAndRfi.interaction.St_Thomas_College_School__c = school_college_accounts[0].Id;
            }
        }

        // Populate Major/Program lookup if configured
        if (String.isNotBlank(rfiController.Academic_Interests_To_Display__c)) {
            System.debug('Populating Academic Interest lookup for codes: ' + rfiController.Academic_Interests_To_Display__c);
            //Query for the id of the Program record to populate the lookup properly
            List<Program__c> programRecords = [
                    SELECT Id
                    FROM Program__c
                    WHERE Program_Major_Concentration__c IN :rfiController.Academic_Interests_To_Display__c.split(';')
                    AND RecordType.DeveloperName = 'Recruitment_Program'
                    AND Active__c = TRUE
            ];
            System.debug('Found ' + programRecords.size() + ' matching Program records for Academic Interest codes.');
            if (programRecords.size() > 0) {
                interactionAndRfi.interaction.Major_Program_1__c = programRecords[0].Id;
            }
        }

        System.debug(JSON.serializePretty(interactionAndRfi.interaction));

        //Get country picklist options from Lead
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
        interactionAndRfi.countryOptions = countries;
        interactionAndRfi.stateOptions = getStateProvince('US');

        interactionAndRfi.programValues = getPrograms(
                rfiController.Academic_Level__c,
                rfiController.School_College__c,
                rfiController.Academic_Interests_To_Display__c,
                null
        );

        // Prefill sensible defaults
        interactionAndRfi.rfiFieldList = new List<rfiField>();

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

        //Map the filter questions to the correct Interaction field API names
        Map<String, String> mapFilterToInteractionField = new Map<String, String>{
                'School_College_To_Display__c' => 'St_Thomas_College_School__c',
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
        interactionAndRfi.filterValues = new Map<String, String>();
        for (String key : mapFilterFields.keySet()) {
            if (String.isNotBlank((String) rfiController.get(key))) {
                // valid filter field
                String questionField = mapFilterFields.get(key);
                String questionText = (String) rfiController.get(questionField);
                if (String.isNotBlank(questionText)) {
                    rfiField newField = new rfiField();
                    newField.fieldLabel = questionText;
                    newField.isVisible = true;
                    newField.isRequired = true;
                    newField.isProgramFilter = true;

                    // Special handling for School_College filter - return Account IDs instead of text values
                    if (key == 'School_College_To_Display__c') {
                        newField.picklistValues = getUSTSchoolList((String) rfiController.get(key));
                    } else {
                        newField.picklistValues = getOptionsFromDelineatedString((String) rfiController.get(key));
                    }

                    newField.fieldInteractionAPIName = mapFilterToInteractionField.get(key);
                    interactionAndRfi.rfiFieldList.add(newField);
                    interactionAndRfi.filterValues.put(newField.fieldInteractionAPIName, '');
                }

            }
        }

        List<String> fieldsToDisplay = rfiController.Fields_to_Display__c != null
                ? rfiController.Fields_to_Display__c.split(';')
                : new List<String>();

        // Check if using Unified Questions (new structure)
        if (String.isNotBlank(rfiController.Unified_Questions__c)) {
            System.debug('📦 Using Unified Questions structure');
            // Process unified questions - they contain all questions in one ordered list
            processUnifiedQuestions(rfiController, interactionAndRfi);
            // Skip the legacy field processing below
        } else {
            System.debug('📦 Using legacy field structure (Fields_to_Display__c + Interaction_Questions__c)');
            // LEGACY PATH: Continue with existing logic

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
        // Interaction field describes to validate field existence
        Map<String, Schema.SObjectField> interactionFieldMap = Schema.SObjectType.Interaction__c.fields.getMap();

        //Reorder fieldsToDisplay based on Fields_to_Display_Order__c
        List<String> orderedFields = new List<String>();
        if (String.isNotBlank(rfiController.Fields_to_Display_Order__c)) {
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
                    newField.fieldInteractionAPIName = 'Major_Program_1__c';
                    newField.isProgramLookup = true;
                    if (rfiController.Academic_Interest_Max_Selection__c != null) {
                        newField.max = Integer.valueOf(String.valueOf(rfiController.Academic_Interest_Max_Selection__c));
                    } else {
                        newField.max = 4;
                    }

                    // Use custom label if provided, otherwise use default
                    if (String.isNotBlank(rfiController.Academic_Interest_Label__c)) {
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
                        newField.fieldInteractionAPIName = 'Address';
                        newField.isAddress = true;
                        addressAdded = true;
                        // mark required if present in Required_Fields__c using any of the address tokens
                        newField.isRequired = requiredFields.contains('Address 1') || requiredFields.contains('City') ||
                                requiredFields.contains('Country') || requiredFields.contains('State') || requiredFields.contains('Zipcode');
                        interactionAndRfi.rfiFieldList.add(newField);
                    }
                    continue; // skip adding duplicates for address tokens
                }
                when 'Birthdate' {
                    newField.fieldLabel = String.isNotBlank(rfiController.Birthdate_Label__c) ? rfiController.Birthdate_Label__c : 'Birthday (MM/DD/YYYY)';
                    newField.fieldInteractionAPIName = 'Birthdate__c';
                    newField.isDate = true;
                }
                when 'Citizenship' {
                    newField.fieldLabel = String.isNotBlank(rfiController.Citizenship_Label__c) ? rfiController.Citizenship_Label__c : 'Citizenship';
                    newField.fieldInteractionAPIName = 'Citizenship__c';
                }
                when 'Email' {
                    newField.fieldLabel = String.isNotBlank(rfiController.Email_Label__c) ? rfiController.Email_Label__c : 'Email';
                    newField.fieldInteractionAPIName = 'Email__c';
                    newField.isEmail = true;
                }
                when 'Employer' {
                    newField.fieldLabel = String.isNotBlank(rfiController.Employer_Label__c) ? rfiController.Employer_Label__c : 'Employer';
                    newField.fieldInteractionAPIName = 'Employer__c';
                }
                when 'Expected Start Term at St Thomas' {
                    newField.fieldLabel = String.isNotBlank(rfiController.Expected_Start_Term_Label__c) ? rfiController.Expected_Start_Term_Label__c : 'Expected Start Term at St. Thomas';
                    newField.isPicklist = true;
                    newField.picklistValues = getTerms();
                    newField.fieldInteractionAPIName = 'Intended_Start_Term__c';
                }
                when 'High School Attended' {
                    newField.fieldLabel = String.isNotBlank(rfiController.High_School_Attended_Label__c) ? rfiController.High_School_Attended_Label__c : 'High School Attended';
                    newField.fieldInteractionAPIName = 'High_School_or_College__c';
                    newField.isSchoolLookup = true;
                }
                when 'High School Graduation Year' {
                    newField.fieldLabel = String.isNotBlank(rfiController.High_School_Graduation_Year_Label__c) ? rfiController.High_School_Graduation_Year_Label__c : 'High School Graduation (YYYY)';
                    newField.fieldInteractionAPIName = 'High_School_Graduation_Year__c';
                }
                when 'How did you hear about us' {
                    newField.fieldLabel = String.isNotBlank(rfiController.How_Did_You_Hear_About_Us_Label__c) ? rfiController.How_Did_You_Hear_About_Us_Label__c : 'How did you hear about us?';
                    newField.fieldInteractionAPIName = 'Heard_About_Us__c';
                }
                when 'I have a question' {
                    newField.fieldLabel = String.isNotBlank(rfiController.I_Have_A_Question_Label__c) ? rfiController.I_Have_A_Question_Label__c : 'I have a question';
                    newField.fieldInteractionAPIName = 'Has_Question__c';
                    newField.isCheckbox = true;
                    newField.showDependentField = true; // Show Questions/Comments textarea when checked
                }
                when 'I will apply to St Thomas as a' {
                    newField.fieldLabel = String.isNotBlank(rfiController.Apply_To_St_Thomas_As_Label__c) ? rfiController.Apply_To_St_Thomas_As_Label__c : 'I will apply to St. Thomas as a';
                    newField.fieldInteractionAPIName = 'Admit_Type__c';
                }
                when 'I would like program information to be mailed to me' {
                    newField.fieldLabel = String.isNotBlank(rfiController.Mail_Information_Label__c) ? rfiController.Mail_Information_Label__c : 'I would like program information to be mailed to me';
                    newField.fieldInteractionAPIName = 'Mail_Information__c';
                    newField.isCheckbox = true;
                }
                when 'I would like to receive text messages' {
                    newField.fieldLabel = String.isNotBlank(rfiController.Receive_Text_Messages_Label__c) ? rfiController.Receive_Text_Messages_Label__c : 'I would like to receive text messages';
                    newField.fieldInteractionAPIName = 'Receive_Texts__c';
                    newField.isCheckbox = true;
                }
                when 'Phone' {
                    newField.fieldLabel = String.isNotBlank(rfiController.Phone_Label__c) ? rfiController.Phone_Label__c : 'Phone';
                    newField.fieldInteractionAPIName = 'Home_Phone__c';
                    newField.isTel = true;
                }
                when 'Home Phone' {
                    newField.fieldLabel = String.isNotBlank(rfiController.Home_Phone_Label__c) ? rfiController.Home_Phone_Label__c : 'Home Phone';
                    newField.fieldInteractionAPIName = 'Home_Phone__c';
                    newField.isTel = true;
                }
                when 'First Name' {
                    newField.fieldLabel = String.isNotBlank(rfiController.First_Name_Label__c) ? rfiController.First_Name_Label__c : 'First Name';
                    newField.fieldInteractionAPIName = 'First_Name__c';
                }
                when 'Last Name' {
                    newField.fieldLabel = String.isNotBlank(rfiController.Last_Name_Label__c) ? rfiController.Last_Name_Label__c : 'Last Name';
                    newField.fieldInteractionAPIName = 'Last_Name__c';
                }
                when 'Company' {
                    newField.fieldLabel = String.isNotBlank(rfiController.Company_Label__c) ? rfiController.Company_Label__c : 'Company';
                    newField.fieldInteractionAPIName = 'Employer__c';
                }
                when 'Scholarship of Interest' {
                    newField.fieldLabel = String.isNotBlank(rfiController.Scholarship_Of_Interest_Label__c) ? rfiController.Scholarship_Of_Interest_Label__c : 'Scholarship of Interest';
                    newField.fieldInteractionAPIName = 'Scholarship_of_Interest__c';
                }
                when 'St Thomas Colleges' {
                    newField.fieldLabel = String.isNotBlank(rfiController.St_Thomas_Colleges_Label__c) ? rfiController.St_Thomas_Colleges_Label__c : 'College\\School';
                    newField.isPicklist = true;
                    newField.picklistValues = getUSTSchoolList();
                    newField.fieldInteractionAPIName = 'St_Thomas_College_School__c';
                }
                when 'Tell us about yourself' {
                    newField.fieldLabel = String.isNotBlank(rfiController.Tell_Us_About_Yourself_Label__c) ? rfiController.Tell_Us_About_Yourself_Label__c : 'Tell us about yourself and why you are interested in this program. (150 words or less)';
                    newField.fieldInteractionAPIName = 'Description__c';
                    newField.isTextarea = true;
                }
                when 'Timeline to Enrollment' {
                    newField.fieldLabel = String.isNotBlank(rfiController.Timeline_To_Enrollment_Label__c) ? rfiController.Timeline_To_Enrollment_Label__c : 'Timeline to Enrollment';
                    newField.fieldInteractionAPIName = 'Timeline__c';
                }
                when 'Title' {
                    newField.fieldLabel = String.isNotBlank(rfiController.Title_Label__c) ? rfiController.Title_Label__c : 'Title';
                    newField.fieldInteractionAPIName = 'Contact_Title__c';
                }
                when 'When do you plan to start school' {
                    newField.fieldLabel = String.isNotBlank(rfiController.When_Start_School_Label__c) ? rfiController.When_Start_School_Label__c : 'When do you plan to start school';
                    newField.fieldInteractionAPIName = 'High_School_Graduation_Year__c';
                }
                when else {
                    newField.fieldLabel = 'Field Label Not Found';
                    newField.fieldInteractionAPIName = 'Description__c';
                    newField.isTextarea = true;
                }
            }


            // If this maps to an Interaction field, detect picklist/multipicklist and populate options dynamically
            if (String.isNotBlank(newField.fieldInteractionAPIName) && newField.fieldInteractionAPIName != 'Address' && newField.isPicklist != true && newField.isMultiSelect != true) {
                String apiNameLower = newField.fieldInteractionAPIName.toLowerCase();
                if (interactionFieldMap.containsKey(apiNameLower)) {
                    Schema.DescribeFieldResult d = interactionFieldMap.get(apiNameLower).getDescribe();
                    if (d.getType() == Schema.DisplayType.MULTIPICKLIST) {
                        newField.picklistValues = getPicklistOptions(d);
                        newField.isMultiSelect = true;
                        newField.max = 4;
                    } else if (d.getType() == Schema.DisplayType.PICKLIST) {
                        newField.picklistValues = getPicklistOptions(d);
                        newField.isPicklist = true;
                    }
                }
            }

            Boolean forceRequired = (newField.fieldInteractionAPIName == 'First_Name__c' || newField.fieldInteractionAPIName == 'Last_Name__c');
            newField.isRequired = forceRequired || requiredFields.contains(fieldName);
            interactionAndRfi.rfiFieldList.add(newField);

        }

        // Additional Questions - Read from Interaction_Questions__c for Interaction forms
        /* Data example stored in Interaction_Questions__c field:
        [{"id":0,"questionLabel":"TEST","questionType":"Picklist","fieldToApplyTo":"Description","assistiveText":"","position":"bottom","isPicklist":true,"isRequired":false,"isTextBox":false,"isTextarea":false,"isRichText":false,"isStaticContent":false,"isEmail":false,"picklistValues":[{"label":"Test1","value":"Test1"},{"label":"Test2","value":"Test2"},{"label":"Test3","value":"Test3"},{"label":"Test4","value":"Test4"},{"label":"Test5","value":"Test5"}],"valuesFlat":"Test1;Test2;Test3;Test4;Test5"}]
         */
        List<rfiField> additionalFieldsTop = new List<rfiField>();
        List<rfiField> additionalFieldsBottom = new List<rfiField>();
        if (String.isNotBlank(rfiController.Interaction_Questions__c)) {
            try {
                List<Object> additionalQuestions = (List<Object>) JSON.deserializeUntyped(rfiController.Interaction_Questions__c);
                for (Object qObj : additionalQuestions) {
                    if (!(qObj instanceof Map<String, Object>)) continue;
                    Map<String, Object> qMap = (Map<String, Object>) qObj;
                    rfiField newField = new rfiField();
                    newField.fieldLabel = qMap.containsKey('questionLabel') ? String.valueOf(qMap.get('questionLabel')) : 'Question';
                    newField.fieldInteractionAPIName = qMap.containsKey('fieldToApplyTo') ? String.valueOf(qMap.get('fieldToApplyTo')) : 'Description';
                    newField.isRequired = qMap.containsKey('isRequired') ? (Boolean) qMap.get('isRequired') : false;
                    // Determine field type
                    if (qMap.containsKey('isPicklist') && (Boolean) qMap.get('isPicklist')) {
                        newField.isPicklist = true;
                        newField.picklistValues = getOptionsFromDelineatedString((String) qMap.get('valuesFlat'));
                    } else if (qMap.containsKey('isTextarea') && (Boolean) qMap.get('isTextarea')) {
                        newField.isTextarea = true;
                    } else if (qMap.containsKey('isStaticContent') && (Boolean) qMap.get('isStaticContent')) {
                        newField.isStaticContent = true;
                        newField.staticContentHtml = qMap.containsKey('valuesFlat') ? String.valueOf(qMap.get('valuesFlat')) : '';
                    } else if (qMap.containsKey('isRichText') && (Boolean) qMap.get('isRichText')) {
                        // Legacy support for isRichText (older data structure)
                        newField.isStaticContent = true;
                        newField.staticContentHtml = qMap.containsKey('valuesFlat') ? String.valueOf(qMap.get('valuesFlat')) : '';
                    } else if (qMap.containsKey('isEmail') && (Boolean) qMap.get('isEmail')) {
                        newField.isEmail = true;
                    } else if (qMap.containsKey('isTextBox') && (Boolean) qMap.get('isTextBox')) {
                        newField.isTextarea = true;
                    }
                    //if position is top add to the start of interactionAndRfi.rfiFieldList
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
                merged.addAll(interactionAndRfi.rfiFieldList);
                interactionAndRfi.rfiFieldList = merged;
            }
            if (!additionalFieldsBottom.isEmpty()) {
                interactionAndRfi.rfiFieldList.addAll(additionalFieldsBottom);
            }

        }
        } // End of else block for legacy field processing

        return interactionAndRfi;
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

    /**
     * Get school list with Account IDs for use in picklists
     * If schoolNames parameter is provided, returns only those schools (filtered list)
     * If schoolNames is blank, returns all schools from School_College__c picklist (full list)
     * @param schoolNames Optional semicolon-delimited list of school names to filter by
     * @return List of picklistOption with Account IDs as values and school names as labels
     */
    public static List<picklistOption> getUSTSchoolList(String schoolNames) {
        List<String> schoolNameList = new List<String>();

        if (String.isBlank(schoolNames)) {
            // No filter provided - get all schools from School_College__c picklist
            Schema.DescribeFieldResult d = Schema.SObjectType.RFI_Controller__c.fields.getMap().get('School_College__c').getDescribe();
            for (Schema.PicklistEntry e : d.getPicklistValues()) {
                if (e.isActive()) {
                    schoolNameList.add(String.valueOf(e.getValue()));
                }
            }
        } else {
            // Filter provided - use only specified schools
            schoolNameList = schoolNames.split(';');
        }

        // Return empty list if no schools to query
        if (schoolNameList.isEmpty()) {
            return new List<picklistOption>();
        }

        // Query for Account records matching the school names
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

    /**
     * Overloaded method for backward compatibility - returns full school list
     * @return List of picklistOption with all schools from School_College__c picklist
     */
    public static List<picklistOption> getUSTSchoolList() {
        return getUSTSchoolList(null);
    }

    @AuraEnabled(Cacheable=true)
    public static List<programValues> getPrograms(String academic_level, String school_college, String academic_interest_codes, Map<String, String> filters) {
        // Debug logging
        System.debug('=== getPrograms called ===');
        System.debug('academic_level: ' + academic_level);
        System.debug('school_college: ' + school_college);
        System.debug('academic_interest_codes: ' + academic_interest_codes);
        System.debug('filters: ' + JSON.serialize(filters));

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
            // Only apply school_college parameter if it's not in the filters map
            // This prevents duplicate/conflicting WHERE clauses
            if (String.isNotBlank(school_college) && (filters == null || !filters.containsKey('School_College__c'))) {
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

        System.debug('Final query: ' + query_string);
        List<Program__c> programs = Database.query(query_string);
        System.debug('Programs found: ' + programs.size());

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
        System.debug('=== filterQuery called ===');
        System.debug('Input filters: ' + JSON.serialize(filters));

        // Map Lead field names to Program field names
        Map<String, String> leadToProgramFieldMap = new Map<String, String>{
            'Citizenship__c' => 'Citizenship__c',
            'Student_Type__c' => 'Student_Type__c',
            'Degree_Type__c' => 'Degree_Type__c',
            'Delivery_Type__c' => 'Delivery_Type__c',
            'Generic_Filter_2__c' => 'Generic_Filter_2__c',
            'Generic_Filter_3__c' => 'Generic_Filter_3__c',
            'Generic_Filter_4__c' => 'Generic_Filter_4__c',
            'Generic_Filter_5__c' => 'Program_Type__c',  // Program_Type maps to Generic_Filter_5 on Lead
            'Generic_Filter_6__c' => 'Generic_Filter_6__c',
            'Generic_Filter_7__c' => 'Generic_Filter_7__c',
            'Generic_Filter_8__c' => 'Generic_Filter_8__c',
            'School_College__c' => 'Associated_Schools__c',
            'St_Thomas_College_School__c' => 'Associated_Schools__c'  // Filter question uses this field name
        };

        String query_string = '';
        if (filters != null) {
            for (String filterKey : filters.keySet()) {
                String filterValue = filters.get(filterKey);
                System.debug('Processing filter - Key: ' + filterKey + ', Value: ' + filterValue);

                if (String.isNotBlank(filterValue)) {
                    // Map Lead field to Program field
                    String programField = leadToProgramFieldMap.get(filterKey);
                    System.debug('Mapped to Program field: ' + programField);

                    if (String.isBlank(programField)) {
                        System.debug('No mapping found, skipping');
                        continue;
                    }

                    // Special handling for St_Thomas_College_School__c - convert Account ID to School Name
                    if (filterKey == 'St_Thomas_College_School__c') {
                        // filterValue is an Account ID, we need to get the School_College_Name__c
                        try {
                            List<Account> accounts = [
                                SELECT School_College_Name__c
                                FROM Account
                                WHERE Id = :filterValue
                                LIMIT 1
                            ];
                            if (!accounts.isEmpty() && String.isNotBlank(accounts[0].School_College_Name__c)) {
                                filterValue = accounts[0].School_College_Name__c;
                                System.debug('Converted Account ID to School Name: ' + filterValue);
                            } else {
                                System.debug('Could not find School_College_Name__c for Account ID: ' + filterValue);
                                continue;
                            }
                        } catch (Exception e) {
                            System.debug('Error looking up School Name for ID ' + filterValue + ': ' + e.getMessage());
                            continue;
                        }
                    }

                    filterValue = filterValue.escapeHtml4();

                    // Get field describe for the Program field
                    Map<String, Schema.SObjectField> programFieldMap = Schema.SObjectType.Program__c.fields.getMap();
                    if (!programFieldMap.containsKey(programField)) {
                        System.debug('Program field does not exist: ' + programField + ', skipping');
                        continue;
                    }

                    Schema.DescribeFieldResult d = programFieldMap.get(programField).getDescribe();
                    String fieldType = String.valueOf(d.getType());
                    System.debug('Field type: ' + fieldType);

                    if (d.getType() == Schema.DisplayType.MULTIPICKLIST) {
                        // For multipicklist, check if any of the selected values match
                        String clause = ' AND ' + programField + ' INCLUDES (\'' + filterValue + '\') ';
                        System.debug('Adding multipicklist clause: ' + clause);
                        query_string += clause;
                    } else {
                        // For regular picklist or text fields
                        String clause = ' AND ' + programField + ' = \'' + filterValue + '\' ';
                        System.debug('Adding regular clause: ' + clause);
                        query_string += clause;
                    }
                }
            }
        }
        System.debug('Final filter query string: ' + query_string);
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
            if (String.isNotBlank(school_college)) {
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
    public static Id submitRfiInteraction(Interaction__c interaction) {
        // Sanitize: copy only valid Interaction fields from the incoming record
        System.debug('Received Interaction Record: ' + JSON.serializePretty(interaction));
        if (interaction == null) {
            throw new AuraHandledException('No Interaction record provided.');
        }
        if (String.isNotBlank(interaction.Major_Program_1__c)) {
            //using major_program__c id find program with the same name that is of the record type academic program
            List<Program__c> programs = [
                    SELECT Name, Id
                    FROM Program__c
                    WHERE Recruitment_Program__c = :interaction.Major_Program_1__c
                    AND RecordType.DeveloperName = 'Academic_Program'
                    AND Active__c = TRUE
                    LIMIT 1
            ];
            if (!programs.isEmpty()) {
                interaction.Recruitment_Program__c = programs[0].Id;
                interaction.Academic_Program__c = programs[0].Id;
            }
        }

        //Loop through the interaction fields and only copy those that exist and are insertable on the Interaction__c object
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Interaction__c.fields.getMap();
        Interaction__c cleanInteraction = new Interaction__c();

        Map<String, Object> interactionFields = interaction.getPopulatedFieldsAsMap();
        for (String fieldName : interactionFields.keySet()) {
            if (fieldMap.containsKey(fieldName)) {
                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
                if (fieldDescribe.isCreateable()) {
                    cleanInteraction.put(fieldName, interactionFields.get(fieldName));
                } else {
                    System.debug('Field ' + fieldName + ' is not creatable on Interaction__c.');
                }
            } else {
                System.debug('Field ' + fieldName + ' does not exist on Interaction__c or is not creatable.');
            }
        }

        Database.DMLOptions dml = new Database.DMLOptions();
        //Will create duplicate records if not allowed
        dml.duplicateRuleHeader.allowSave = true;
        Database.SaveResult result = Database.insert(cleanInteraction, dml);
        if (!result.isSuccess()) {
            String errorMessage = '';
            for (Database.Error err : result.getErrors()) {
                System.debug(JSON.serializePretty(err));
                errorMessage += err.getMessage() + ' ';
            }
            throw new AuraHandledException(errorMessage.trim());
        }

        return result.getId();
    }

    /**
     * Process Unified Questions structure (new approach)
     * All questions (pre-configured and custom) are in one ordered JSON array
     * @param rfiController The RFI Controller record with unified questions
     * @param interactionAndRfi The wrapper object to populate with field data
     */
    private static void processUnifiedQuestions(RFI_Controller__c rfiController, interactionRFIFields interactionAndRfi) {
        try {
            List<Object> unifiedQuestions = (List<Object>) JSON.deserializeUntyped(rfiController.Unified_Questions__c);

            // Cache field map outside loop — describe calls are expensive
            Map<String, Schema.SObjectField> interactionFieldMap = Schema.SObjectType.Interaction__c.fields.getMap();

            // Remap legacy/incorrect fieldInteractionAPIName values saved before the corrected map
            Map<String, String> legacyApiNameRemap = new Map<String, String>{
                'citizenship_type__c'       => 'Citizenship__c',
                'degree_type__c'            => 'Admit_Type__c',
                'how_did_you_hear__c'       => 'Heard_About_Us__c',
                'timeline_to_enrollment__c' => 'Timeline__c',
                'address_1__c'              => 'Mailing_Street__c',
                'birth_date__c'             => 'Birthdate__c',
                'company__c'               => 'Employer__c',
                'expected_start_term__c'    => 'Intended_Start_Term__c',
                'high_school_attended__c'   => 'High_School_or_College__c',
                'high_school_grad_year__c'  => 'High_School_Graduation_Year__c',
                'phone__c'                  => 'Home_Phone__c',
                'comments__c'               => 'Has_Question__c',
                'mail_me__c'                => 'Mail_Information__c',
                'ok_to_text__c'             => 'Receive_Texts__c',
                'school_college__c'         => 'St_Thomas_College_School__c',
                'tell_us_about_yourself__c' => 'Description__c',
                'title__c'                  => 'Salutation__c'
            };

            for (Object qObj : unifiedQuestions) {
                Map<String, Object> q = (Map<String, Object>) qObj;
                String questionType = (String) q.get('type');

                rfiField newField = new rfiField();
                newField.fieldLabel = (String) q.get('questionLabel');
                newField.isRequired = q.get('isRequired') == true;
                newField.isVisible = true;
                newField.isSelected = false;

                if (questionType == 'preconfigured') {
                    String rawApiName = (String) q.get('fieldInteractionAPIName');
                    // Remap any legacy incorrect API names saved before the corrected map
                    if (String.isNotBlank(rawApiName) && legacyApiNameRemap.containsKey(rawApiName.toLowerCase())) {
                        rawApiName = legacyApiNameRemap.get(rawApiName.toLowerCase());
                    }
                    newField.fieldInteractionAPIName = rawApiName;
                    String fieldName = String.valueOf(q.get('fieldName') != null ? q.get('fieldName') : '');

                    // Special handling for known field types
                    if (fieldName == 'Academic Interest') {
                        newField.isProgramLookup = true;
                        newField.max = 4;
                    } else if (fieldName == 'Address') {
                        newField.isAddress = true;
                    } else if (fieldName == 'Email') {
                        newField.isEmail = true;
                    } else if (fieldName.contains('Phone')) {
                        newField.isTel = true;
                    } else if (fieldName == 'I have a question' || fieldName == 'Tell us about yourself') {
                        newField.isTextarea = true;
                    } else if (fieldName == 'Receive Text Messages' || fieldName == 'Mail Information') {
                        newField.isCheckbox = true;
                    }

                    // For remaining fields, check if the Interaction field is a picklist
                    if (newField.isProgramLookup != true && newField.isAddress != true && newField.isEmail != true
                            && newField.isTel != true && newField.isTextarea != true && newField.isCheckbox != true
                            && String.isNotBlank(newField.fieldInteractionAPIName)) {
                        Schema.SObjectField sField = interactionFieldMap.get(newField.fieldInteractionAPIName.toLowerCase());
                        if (sField != null) {
                            Schema.DescribeFieldResult d = sField.getDescribe();
                            if (d.getType() == Schema.DisplayType.MULTIPICKLIST) {
                                newField.picklistValues = getPicklistOptions(d);
                                newField.isMultiSelect = true;
                                newField.max = 4;
                            } else if (d.getType() == Schema.DisplayType.PICKLIST) {
                                newField.picklistValues = getPicklistOptions(d);
                                newField.isPicklist = true;
                            }
                        }
                    }

                } else if (questionType == 'custom') {
                    newField.fieldInteractionAPIName = (String) q.get('fieldToApplyTo');
                    String qType = String.valueOf(q.get('questionType') != null ? q.get('questionType') : '');

                    if (qType == 'Static content') {
                        newField.isStaticContent = true;
                        newField.staticContentHtml = (String) q.get('valuesFlat');
                    } else if (qType.toLowerCase().contains('picklist') || qType.toLowerCase().contains('combobox')) {
                        newField.isPicklist = true;
                        List<picklistOption> opts = new List<picklistOption>();
                        Object picklistValuesObj = q.get('picklistValues');
                        if (picklistValuesObj != null) {
                            for (Object pvObj : (List<Object>) picklistValuesObj) {
                                Map<String, Object> pv = (Map<String, Object>) pvObj;
                                picklistOption po = new picklistOption();
                                po.label = (String) pv.get('label');
                                po.value = (String) pv.get('value');
                                opts.add(po);
                            }
                        }
                        // Fall back to Interaction field schema if no stored values
                        if (opts.isEmpty() && String.isNotBlank(newField.fieldInteractionAPIName)) {
                            Schema.SObjectField sField = interactionFieldMap.get(newField.fieldInteractionAPIName.toLowerCase());
                            if (sField != null) {
                                for (Schema.PicklistEntry entry : sField.getDescribe().getPicklistValues()) {
                                    if (entry.isActive()) {
                                        picklistOption po = new picklistOption();
                                        po.label = entry.getLabel();
                                        po.value = entry.getValue();
                                        opts.add(po);
                                    }
                                }
                            }
                        }
                        newField.picklistValues = opts;
                    } else if (qType.toLowerCase().contains('textarea')) {
                        newField.isTextarea = true;
                    } else if (qType.toLowerCase().contains('email')) {
                        newField.isEmail = true;
                    }
                    // Default (text box) falls through to lightning-input in the template
                }

                interactionAndRfi.rfiFieldList.add(newField);
            }

            System.debug('✅ Processed ' + unifiedQuestions.size() + ' unified questions');

        } catch (Exception e) {
            System.debug('❌ Error processing unified questions: ' + e.getMessage());
            System.debug(e.getStackTraceString());
        }
    }
}
