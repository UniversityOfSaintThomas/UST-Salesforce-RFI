/**
 * The one list that says which Interaction field each RFI question saves to.
 *
 * Before this class the same mapping was written three times: in the Question Manager (JavaScript), in the
 * older form definition (a switch in rfiFormController) and in the newer one (a remap table). They drifted
 * apart, which is how questions ended up pointing at fields that do not exist or at the wrong field.
 * Now the older form, the newer form and the Question Manager all read this class, and the tests in
 * rfiQuestionCatalog_TEST check every entry against the real Interaction__c fields.
 *
 * To add a question: add it to the Fields_to_Display__c picklist, add one entry here, and run the tests.
 */
public with sharing class rfiQuestionCatalog {

    /**
     * One pre-configured question.
     */
    public class Question {
        /** The question's identity: the Fields_to_Display__c value saved in the controller */
        @AuraEnabled public String name { get; set; }
        /** The label the Question Manager shows until an admin changes it */
        @AuraEnabled public String defaultLabel { get; set; }
        /** The Interaction__c field the answer is saved to */
        @AuraEnabled public String targetField { get; set; }
        /** True for a short name older saved forms may hold; the picklist does not offer it */
        @AuraEnabled public Boolean isAlias { get; set; }
        /** True when the question draws more than one input (Home and Mobile Phone) */
        @AuraEnabled public Boolean isComposite { get; set; }
    }

    /**
     * One program filter question.
     */
    public class Filter {
        /** The RFI_Controller__c field that holds the filter's choices */
        @AuraEnabled public String controllerField { get; set; }
        /** The Interaction__c field named for the filter */
        @AuraEnabled public String targetField { get; set; }
        /** False when that field does not exist: the answer only filters the program list and is not saved */
        @AuraEnabled public Boolean storesAnswer { get; set; }
    }

    /**
     * Everything the Question Manager needs, in one response.
     */
    public class Catalog {
        @AuraEnabled public List<Question> questions { get; set; }
        @AuraEnabled public List<Filter> filters { get; set; }
        // Names the Fields_to_Display__c picklist still holds that the Question Manager must not offer for adding:
        // the old split address questions (the single Address question replaces them) and retired questions
        @AuraEnabled public List<String> notOffered { get; set; }
    }

    /** Names the picklist offers that are folded into the single Address question */
    public static final Set<String> splitAddressQuestions = new Set<String>{
        'Address 1', 'Address 2', 'Address 3', 'City', 'State', 'Zipcode', 'Country'
    };

    /** Questions the picklist may still hold, that are no longer offered and save nowhere */
    public static final Set<String> retiredQuestions = new Set<String>{
        'When do you plan to start school'
    };

    private static List<Question> cachedQuestions;
    private static List<Filter> cachedFilters;

    /**
     * Older saved forms hold Interaction field names that were never right. This turns each of them into the
     * right one. Keys are lower case.
     */
    @TestVisible
    private static final Map<String, String> correctedLegacyApiNames = new Map<String, String>{
        'citizenship_type__c' => 'Citizenship__c',
        'degree_type__c' => 'Admit_Type__c',
        'how_did_you_hear__c' => 'Heard_About_Us__c',
        'timeline_to_enrollment__c' => 'Timeline__c',
        'address_1__c' => 'Mailing_Street__c',
        'birth_date__c' => 'Birthdate__c',
        'company__c' => 'Employer__c',
        'expected_start_term__c' => 'Intended_Start_Term__c',
        'high_school_attended__c' => 'High_School_or_College__c',
        'high_school_grad_year__c' => 'High_School_Graduation_Year__c',
        'phone__c' => 'Mobile_Phone__c',
        'comments__c' => 'Has_Question__c',
        'mail_me__c' => 'Mailed_Program_Information_Requested__c',
        'ok_to_text__c' => 'Receive_Texts__c',
        'school_college__c' => 'St_Thomas_College_School__c',
        'tell_us_about_yourself__c' => 'Description__c',
        'title__c' => 'Contact_Title__c'
    };

    /**
     * Returns the catalog for the Question Manager. Readable by anyone who can run the form; it holds no
     * applicant data.
     *
     * @return All pre-configured questions and all program filters
     */
    public static Catalog getCatalog() {
        Catalog catalog = new Catalog();
        catalog.questions = questions();
        catalog.filters = filters();
        Set<String> hidden = new Set<String>(splitAddressQuestions);
        hidden.addAll(retiredQuestions);
        catalog.notOffered = new List<String>(hidden);
        catalog.notOffered.sort();
        return catalog;
    }

    /**
     * Finds the Interaction field a pre-configured question saves to.
     *
     * @param questionName The question's name (a Fields_to_Display__c value)
     * @return The Interaction__c field API name, or null when the question is not in the catalog
     */
    public static String targetFieldFor(String questionName) {
        if (questionName == null) {
            return null;
        }
        for (Question question : questions()) {
            if (question.name == questionName) {
                return question.targetField;
            }
        }
        return null;
    }

    /**
     * Finds the Interaction field named for a program filter.
     *
     * @param controllerField The RFI_Controller__c field that holds the filter's choices
     * @return The Interaction__c field API name, or null when the filter is not in the catalog
     */
    public static String filterTargetFor(String controllerField) {
        if (controllerField == null) {
            return null;
        }
        for (Filter filter : filters()) {
            if (filter.controllerField == controllerField) {
                return filter.targetField;
            }
        }
        return null;
    }

    /**
     * Replaces an Interaction field name that older saved forms held and that was never right.
     *
     * @param storedApiName The name saved in the form, or null
     * @return The right name, or the same name when it needed no correction
     */
    public static String correctStoredApiName(String storedApiName) {
        if (String.isBlank(storedApiName)) {
            return storedApiName;
        }
        String corrected = correctedLegacyApiNames.get(storedApiName.toLowerCase());
        return corrected == null ? storedApiName : corrected;
    }

    /**
     * @return Every pre-configured question
     */
    public static List<Question> questions() {
        if (cachedQuestions == null) {
            cachedQuestions = new List<Question>{
                question('Academic Interest', 'Major_Program_1__c'),
                question('Address', 'Mailing_Street__c'),
                question('Birthdate', 'Birthdate__c'),
                question('Citizenship', 'Citizenship__c'),
                question('Company', 'Employer__c'),
                question('Email', 'Email__c'),
                question('Employer', 'Employer__c'),
                question('Expected Start Term at St Thomas', 'Intended_Start_Term__c'),
                question('First Name', 'First_Name__c'),
                question('High School Attended', 'High_School_or_College__c'),
                question('High School Graduation Year', 'High_School_Graduation_Year__c'),
                question('Phone', 'Mobile_Phone__c'),
                question('Home Phone', 'Home_Phone__c'),
                composite('Home and Mobile Phone', 'Home_Phone__c'),
                question('How did you hear about us', 'Heard_About_Us__c'),
                question('I have a question', 'Has_Question__c'),
                question('I will apply to St Thomas as a', 'Admit_Type__c'),
                question('I will apply to St Thomas Law as a', 'Admit_Type__c'),
                question('Last Name', 'Last_Name__c'),
                question('I would like program information to be mailed to me', 'Mailed_Program_Information_Requested__c'),
                question('I would like to receive text messages', 'Receive_Texts__c'),
                alias('Mail Information', 'Mailed_Program_Information_Requested__c'),
                alias('Receive Text Messages', 'Receive_Texts__c'),
                question('Scholarship of Interest', 'Scholarship_of_Interest__c'),
                labelled('St Thomas Colleges', 'College\\School', 'St_Thomas_College_School__c'),
                question('Tell us about yourself', 'Description__c'),
                question('Timeline to Enrollment', 'Timeline__c'),
                question('Title', 'Contact_Title__c')
            };
        }
        return cachedQuestions;
    }

    /**
     * @return Every program filter. Most name an Interaction field that does not exist, so their answer only
     *         filters the program list. If one of those fields is ever created, the catalog test says so and
     *         the entry should be switched to store the answer.
     */
    public static List<Filter> filters() {
        if (cachedFilters == null) {
            cachedFilters = new List<Filter>{
                filter('School_College_To_Display__c', 'St_Thomas_College_School__c', true),
                filter('Citizen_Types_To_Display__c', 'Citizenship__c', true),
                filter('Degree_Types_To_Display__c', 'Degree_Type__c', false),
                filter('Student_Types_To_Display__c', 'Student_Type__c', false),
                filter('Delivery_Types_To_Display__c', 'Delivery_Type__c', false),
                filter('Program_Types_To_Display__c', 'Generic_Filter_5__c', false),
                filter('Generic_Filter_2_To_Display__c', 'Generic_Filter_2__c', false),
                filter('Generic_Filter_3_To_Display__c', 'Generic_Filter_3__c', true),
                filter('Generic_Filter_4_To_Display__c', 'Generic_Filter_4__c', false),
                filter('Generic_Filter_6_To_Display__c', 'Generic_Filter_6__c', false),
                filter('Generic_Filter_7_To_Display__c', 'Generic_Filter_7__c', false),
                filter('Generic_Filter_8_To_Display__c', 'Generic_Filter_8__c', false)
            };
        }
        return cachedFilters;
    }

    private static Question question(String name, String targetField) {
        return labelled(name, name, targetField);
    }

    private static Question labelled(String name, String defaultLabel, String targetField) {
        Question entry = new Question();
        entry.name = name;
        entry.defaultLabel = defaultLabel;
        entry.targetField = targetField;
        entry.isAlias = false;
        entry.isComposite = false;
        return entry;
    }

    private static Question alias(String name, String targetField) {
        Question entry = question(name, targetField);
        entry.isAlias = true;
        return entry;
    }

    private static Question composite(String name, String targetField) {
        Question entry = question(name, targetField);
        entry.isComposite = true;
        return entry;
    }

    private static Filter filter(String controllerField, String targetField, Boolean storesAnswer) {
        Filter entry = new Filter();
        entry.controllerField = controllerField;
        entry.targetField = targetField;
        entry.storesAnswer = storesAnswer;
        return entry;
    }
}