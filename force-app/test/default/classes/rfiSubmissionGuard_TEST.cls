@IsTest
private class rfiSubmissionGuard_TEST {

    private static rfiFormController.rfiField question(String apiName) {
        rfiFormController.rfiField field = new rfiFormController.rfiField();
        field.fieldInteractionAPIName = apiName;
        return field;
    }

    // ---------- allowedFieldsFor ----------

    @IsTest
    static void allowedFieldsFor_includesQuestionFieldsTrackingAndControllerDefaults_TEST() {
        Set<String> allowed = rfiSubmissionGuard.allowedFieldsFor(
                new List<rfiFormController.rfiField>{ question('First_Name__c'), question('Timeline__c') },
                new Interaction__c(Employer__c = 'No Company'));
        System.assert(allowed.contains('first_name__c'));
        System.assert(allowed.contains('timeline__c'));
        System.assert(allowed.contains('employer__c'), 'A default the controller gave the form');
        System.assert(allowed.contains('utm_campaign__c'), 'Tracking field');
        System.assert(allowed.contains('description__c'), 'The composed answers');
        System.assertEquals(false, allowed.contains('admit_type__c'), 'Not asked on this form');
    }

    @IsTest
    static void allowedFieldsFor_neverAllowsAFieldTheServerControls_evenIfAQuestionMapsToIt_TEST() {
        Set<String> allowed = rfiSubmissionGuard.allowedFieldsFor(
                new List<rfiFormController.rfiField>{ question('Term__c'), question('OwnerId') },
                new Interaction__c(OwnerId = UserInfo.getUserId(), Lead_Source__c = 'Webform'));
        System.assertEquals(false, allowed.contains('term__c'));
        System.assertEquals(false, allowed.contains('ownerid'));
        System.assertEquals(false, allowed.contains('lead_source__c'), 'The controller sets this itself');
    }

    @IsTest
    static void allowedFieldsFor_addsTheCompanionFieldsOfSpecialQuestions_TEST() {
        rfiFormController.rfiField address = question('Mailing_Street__c');
        address.isAddress = true;
        rfiFormController.rfiField school = question('High_School_or_College__c');
        school.isSchoolLookup = true;
        rfiFormController.rfiField program = question('Major_Program_1__c');
        program.isProgramLookup = true;
        rfiFormController.rfiField hasQuestion = question('Has_Question__c');
        hasQuestion.showDependentField = true;
        Set<String> allowed = rfiSubmissionGuard.allowedFieldsFor(
                new List<rfiFormController.rfiField>{ address, school, program, hasQuestion }, null);
        for (String expected : new List<String>{ 'mailing_city__c', 'mailing_state__c', 'mailing_country__c', 'mailing_postal_code__c',
                'state__c', 'school_name_text__c', 'major_program_2__c', 'major_program_3__c', 'major_program_4__c', 'has_question__c' }) {
            System.assert(allowed.contains(expected), expected + ' should be allowed');
        }
    }

    @IsTest
    static void allowedFieldsFor_skipsStaticContentAndHandlesNothing_TEST() {
        rfiFormController.rfiField staticContent = question('Admit_Type__c');
        staticContent.isStaticContent = true;
        Set<String> allowed = rfiSubmissionGuard.allowedFieldsFor(new List<rfiFormController.rfiField>{ staticContent, null }, null);
        System.assertEquals(false, allowed.contains('admit_type__c'), 'Static content takes no answer');
        System.assert(rfiSubmissionGuard.allowedFieldsFor(null, null).contains('utm_source__c'));
    }

    // ---------- filterIncoming ----------

    @IsTest
    static void filterIncoming_keepsAllowedFieldsAndIgnoresTheRest_TEST() {
        Set<String> allowed = new Set<String>{ 'first_name__c', 'email__c' };
        rfiSubmissionGuard.FilterResult result = rfiSubmissionGuard.filterIncoming(new Map<String, Object>{
            'First_Name__c' => 'Ada', 'Email__c' => 'ada@example.invalid',
            'OwnerId' => UserInfo.getUserId(), 'Opportunity_Stage__c' => 'Enrolled', 'Admit_Type__c' => 'Transfer', 'Not_A_Field__c' => 'x'
        }, allowed);
        System.assertEquals(2, result.accepted.size());
        System.assertEquals('Ada', result.accepted.get('First_Name__c'));
        System.assertEquals(new List<String>{ 'Admit_Type__c', 'Not_A_Field__c', 'Opportunity_Stage__c', 'OwnerId' }, result.ignored);
    }

    @IsTest
    static void filterIncoming_withoutAnAllowList_stillBlocksTheServerControlledFields_TEST() {
        rfiSubmissionGuard.FilterResult result = rfiSubmissionGuard.filterIncoming(new Map<String, Object>{
            'First_Name__c' => 'Ada', 'OwnerId' => UserInfo.getUserId(), 'Opportunity_Record_Type__c' => 'x', 'Pardot_Sync_OCB__c' => true
        }, null);
        System.assertEquals(1, result.accepted.size(), 'Only the answer is kept');
        System.assert(result.accepted.containsKey('First_Name__c'));
        System.assertEquals(3, result.ignored.size());
    }

    @IsTest
    static void filterIncoming_handlesNull_TEST() {
        rfiSubmissionGuard.FilterResult result = rfiSubmissionGuard.filterIncoming(null, new Set<String>());
        System.assertEquals(0, result.accepted.size());
        System.assertEquals(0, result.ignored.size());
    }

    // ---------- buildRecord ----------

    @IsTest
    static void buildRecord_storesAcceptedValues_andIgnoresOnesItCannotStore_TEST() {
        rfiSubmissionGuard.FilterResult filtered = new rfiSubmissionGuard.FilterResult();
        filtered.accepted.put('First_Name__c', 'Ada');
        // Academic_Level__c is a formula field, so it cannot be stored
        filtered.accepted.put('Academic_Level__c', 'Undergraduate');
        Interaction__c record = rfiSubmissionGuard.buildRecord(filtered);
        System.assertEquals('Ada', record.First_Name__c);
        System.assertEquals(new List<String>{ 'Academic_Level__c' }, filtered.ignored, 'The formula field is reported, not fatal');
    }

    // ---------- program filters that have no Interaction field ----------

    @IsTest
    static void filterIncoming_aProgramFilterWithNoInteractionField_isDroppedWithoutBeingReported_TEST() {
        // Degree_Type__c is a program filter whose Interaction field does not exist: it only narrows the program list
        System.assertEquals(false, Schema.SObjectType.Interaction__c.fields.getMap().containsKey('degree_type__c'),
                'This test assumes Degree_Type__c does not exist on Interaction__c');
        Set<String> allowed = new Set<String>{ 'first_name__c', 'degree_type__c' };
        rfiSubmissionGuard.FilterResult result = rfiSubmissionGuard.filterIncoming(
                new Map<String, Object>{ 'First_Name__c' => 'Ada', 'Degree_Type__c' => 'Graduate' }, allowed);
        System.assertEquals(1, result.accepted.size());
        System.assertEquals(0, result.ignored.size(), 'A filter answer is expected and must not be reported: ' + result.ignored);
    }

    @IsTest
    static void filterIncoming_aQuestionWhoseFieldIsMissing_isStillReported_TEST() {
        // Not a program filter, so a missing field is a mistake that must show up
        rfiSubmissionGuard.FilterResult result = rfiSubmissionGuard.filterIncoming(
                new Map<String, Object>{ 'Field_That_Is_Missing__c' => 'x' }, new Set<String>{ 'field_that_is_missing__c' });
        System.assertEquals(new List<String>{ 'Field_That_Is_Missing__c' }, result.ignored);
    }

    @IsTest
    static void filterOnlyFieldNames_matchTheFiltersThatDoNotStoreTheirAnswer_TEST() {
        Set<String> expected = new Set<String>();
        for (rfiQuestionCatalog.Filter filter : rfiQuestionCatalog.filters()) {
            if (filter.storesAnswer != true) {
                expected.add(filter.targetField.toLowerCase());
            }
        }
        System.assertEquals(expected, rfiSubmissionGuard.filterOnlyFieldNames());
        System.assert(!expected.isEmpty());
    }


    // ---------- answers to questions hidden by a "show only when" rule ----------

    private static rfiFormController.rfiField dependent(String field, String parentField, String kind, List<String> answers) {
        rfiFormController.rfiField question = question(field);
        question.visibleWhenField = parentField;
        question.visibleWhenKind = kind;
        question.visibleWhenValues = answers;
        return question;
    }

    @IsTest
    static void dropAnswersToHiddenQuestions_clearsOnlyTheHiddenOne_andNamesIt_TEST() {
        Interaction__c record = new Interaction__c(Citizenship__c = 'US Citizen', Employer__c = 'typed', Email__c = 'keep@example.invalid');
        List<String> cleared = rfiSubmissionGuard.dropAnswersToHiddenQuestions(new List<rfiFormController.rfiField>{
            question('Citizenship__c'), question('Email__c'), dependent('Employer__c', 'Citizenship__c', 'picklist', new List<String>{ 'International' })
        }, record);
        System.assertEquals(new List<String>{ 'Employer__c' }, cleared);
        System.assertEquals(null, record.Employer__c);
        System.assertEquals('keep@example.invalid', record.Email__c);
        System.assertEquals('US Citizen', record.Citizenship__c);
    }

    @IsTest
    static void dropAnswersToHiddenQuestions_keepsTheAnswerWhenTheRuleIsMet_TEST() {
        Interaction__c record = new Interaction__c(Citizenship__c = 'International', Employer__c = 'typed');
        List<String> cleared = rfiSubmissionGuard.dropAnswersToHiddenQuestions(new List<rfiFormController.rfiField>{
            question('Citizenship__c'), dependent('Employer__c', 'Citizenship__c', 'picklist', new List<String>{ 'Other', 'International' })
        }, record);
        System.assertEquals(0, cleared.size());
        System.assertEquals('typed', record.Employer__c);
    }

    @IsTest
    static void dropAnswersToHiddenQuestions_aMissingEarlierAnswer_hidesTheQuestion_TEST() {
        Interaction__c record = new Interaction__c(Employer__c = 'typed');
        List<String> cleared = rfiSubmissionGuard.dropAnswersToHiddenQuestions(new List<rfiFormController.rfiField>{
            question('Citizenship__c'), dependent('Employer__c', 'Citizenship__c', 'picklist', new List<String>{ 'International' })
        }, record);
        System.assertEquals(new List<String>{ 'Employer__c' }, cleared);
    }

    @IsTest
    static void dropAnswersToHiddenQuestions_aTickBox_unticked_orNotSentAtAll_meansNotChecked_TEST() {
        List<rfiFormController.rfiField> form = new List<rfiFormController.rfiField>{
            question('Has_Question__c'), dependent('Employer__c', 'Has_Question__c', 'checkbox', new List<String>{ 'false' })
        };
        Interaction__c notSent = new Interaction__c(Employer__c = 'typed');
        System.assertEquals(0, rfiSubmissionGuard.dropAnswersToHiddenQuestions(form, notSent).size(), 'Not sent counts as not checked, so a rule for "false" is met');
        Interaction__c unticked = new Interaction__c(Has_Question__c = false, Employer__c = 'typed');
        System.assertEquals(0, rfiSubmissionGuard.dropAnswersToHiddenQuestions(form, unticked).size());
        Interaction__c ticked = new Interaction__c(Has_Question__c = true, Employer__c = 'typed');
        System.assertEquals(new List<String>{ 'Employer__c' }, rfiSubmissionGuard.dropAnswersToHiddenQuestions(form, ticked));
        System.assertEquals(null, ticked.Employer__c);
    }

    @IsTest
    static void dropAnswersToHiddenQuestions_aFieldAVisibleQuestionAlsoWrites_isNotCleared_TEST() {
        // Employer and Company are two questions that both save to Employer__c; hiding one must not delete the other's answer
        Interaction__c record = new Interaction__c(Citizenship__c = 'US Citizen', Employer__c = 'typed in the visible one');
        List<String> cleared = rfiSubmissionGuard.dropAnswersToHiddenQuestions(new List<rfiFormController.rfiField>{
            question('Citizenship__c'), question('Employer__c'), dependent('Employer__c', 'Citizenship__c', 'picklist', new List<String>{ 'International' })
        }, record);
        System.assertEquals(0, cleared.size());
        System.assertEquals('typed in the visible one', record.Employer__c);
    }

    @IsTest
    static void dropAnswersToHiddenQuestions_aHiddenAddress_clearsEveryAddressField_TEST() {
        rfiFormController.rfiField address = dependent('Mailing_Street__c', 'Citizenship__c', 'picklist', new List<String>{ 'International' });
        address.isAddress = true;
        Interaction__c record = new Interaction__c(Citizenship__c = 'US Citizen', Mailing_Street__c = '1 Main', Mailing_City__c = 'Saint Paul', Mailing_Postal_Code__c = '55105');
        List<String> cleared = rfiSubmissionGuard.dropAnswersToHiddenQuestions(new List<rfiFormController.rfiField>{ question('Citizenship__c'), address }, record);
        System.assertEquals(new List<String>{ 'Mailing_City__c', 'Mailing_Postal_Code__c', 'Mailing_Street__c' }, cleared);
        System.assertEquals(null, record.Mailing_City__c);
    }

    @IsTest
    static void dropAnswersToHiddenQuestions_aBlankAnswerIsNotReported_andNothingBreaksOnNulls_TEST() {
        Interaction__c record = new Interaction__c(Citizenship__c = 'US Citizen', Employer__c = '');
        System.assertEquals(0, rfiSubmissionGuard.dropAnswersToHiddenQuestions(new List<rfiFormController.rfiField>{
            question('Citizenship__c'), dependent('Employer__c', 'Citizenship__c', 'picklist', new List<String>{ 'International' })
        }, record).size());
        System.assertEquals(0, rfiSubmissionGuard.dropAnswersToHiddenQuestions(null, record).size());
        System.assertEquals(0, rfiSubmissionGuard.dropAnswersToHiddenQuestions(new List<rfiFormController.rfiField>{ null }, null).size());
    }

    @IsTest
    static void dropAnswersToHiddenQuestions_staticContentTakesNoAnswer_TEST() {
        rfiFormController.rfiField note = dependent('Employer__c', 'Citizenship__c', 'picklist', new List<String>{ 'International' });
        note.isStaticContent = true;
        Interaction__c record = new Interaction__c(Citizenship__c = 'US Citizen', Employer__c = 'typed');
        System.assertEquals(0, rfiSubmissionGuard.dropAnswersToHiddenQuestions(new List<rfiFormController.rfiField>{ question('Citizenship__c'), note }, record).size());
    }
}