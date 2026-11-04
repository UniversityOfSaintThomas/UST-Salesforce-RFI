/**
 * Tests for rfiQuestionReader, the one tolerant reader of the saved question list, and for how the form behaves
 * when a saved question is broken.
 *
 * The three fixtures are real lists copied from eda-staging on 2026-11-02 (configuration only, no personal data).
 * Every future change to the saved format must keep loading them: they are the old shapes that exist in the org.
 */
@IsTest
private class rfiQuestionReader_TEST {

    // ---------- real saved lists (older shapes: derived display flags saved, no key, no schemaVersion) ----------

    private static final String stagingWithFilterAndCustomPicklist = '[{"id":0,"type":"preconfigured","fieldName":"First Name","questionLabel":"First Name","fieldInteractionAPIName":"First_Name__c","isRequired":true,"typePreconfigured":true,"typeCustom":false,"typeFilter":false,"isPicklist":false,"isTextBox":false,"isTextarea":false,"isEmail":false,"isStaticContent":false,"isFirst":true,"isLast":false},{"id":1,"type":"preconfigured","fieldName":"Last Name","questionLabel":"Last Name","fieldInteractionAPIName":"Last_Name__c","isRequired":true,"typePreconfigured":true,"typeCustom":false,"typeFilter":false,"isPicklist":false,"isTextBox":false,"isTextarea":false,"isEmail":false,"isStaticContent":false,"isFirst":false,"isLast":false},{"id":2,"type":"preconfigured","fieldName":"Email","questionLabel":"Email","fieldInteractionAPIName":"Email__c","isRequired":true,"typePreconfigured":true,"typeCustom":false,"typeFilter":false,"isPicklist":false,"isTextBox":false,"isTextarea":false,"isEmail":false,"isStaticContent":false,"isFirst":false,"isLast":false},{"id":3,"type":"preconfigured","fieldName":"Academic Interest","questionLabel":"Academic Interest","fieldInteractionAPIName":"Major_Program_1__c","isRequired":false,"typePreconfigured":true,"typeCustom":false,"typeFilter":false,"isPicklist":false,"isTextBox":false,"isTextarea":false,"isEmail":false,"isStaticContent":false,"isFirst":false,"isLast":false},{"type":"custom","questionLabel":"What Type of Athlete are you?","questionType":"Picklist","fieldToApplyTo":"Athlete_Type_1__c","isRequired":true,"picklistValues":[{"label":"Blue Chip/Coach Priority","value":"Blue Chip/Coach Priority"},{"label":"Athlete Commit","value":"Athlete Commit"},{"label":"Stacked Athletic Scholar","value":"Stacked Athletic Scholar"},{"label":"Full Athletic Scholar","value":"Full Athletic Scholar"},{"label":"Athletic Revision","value":"Athletic Revision"},{"label":"Regular","value":"Regular"}],"valuesFlat":"Blue Chip/Coach Priority;Athlete Commit;Stacked Athletic Scholar;Full Athletic Scholar;Athletic Revision;Regular","assistiveText":"Help text for athlete","isMappedPicklist":true,"id":4,"typePreconfigured":false,"typeCustom":true,"typeFilter":false,"isPicklist":true,"isTextBox":false,"isTextarea":false,"isEmail":false,"isStaticContent":false,"isFirst":false,"isLast":false},{"type":"filter","questionLabel":"School / College","filterControllerField":"School_College_To_Display__c","filterInteractionAPIName":"St_Thomas_College_School__c","isFilterSchoolList":true,"filterSelectedValues":["School of Nursing","College of Arts and Sciences"],"isRequired":true,"id":5,"typePreconfigured":false,"typeCustom":false,"typeFilter":true,"isPicklist":false,"isTextBox":false,"isTextarea":false,"isEmail":false,"isStaticContent":false,"isFirst":false,"isLast":true}]';
    private static final String stagingWithFilters = '[{"id":0,"type":"preconfigured","fieldName":"First Name","questionLabel":"First Name","fieldInteractionAPIName":"First_Name__c","isRequired":true,"typePreconfigured":true,"typeCustom":false,"typeFilter":false,"isPicklist":false,"isTextBox":false,"isTextarea":false,"isEmail":false,"isStaticContent":false,"isFirst":true,"isLast":false},{"id":1,"type":"preconfigured","fieldName":"Last Name","questionLabel":"Last Name","fieldInteractionAPIName":"Last_Name__c","isRequired":true,"typePreconfigured":true,"typeCustom":false,"typeFilter":false,"isPicklist":false,"isTextBox":false,"isTextarea":false,"isEmail":false,"isStaticContent":false,"isFirst":false,"isLast":false},{"id":2,"type":"preconfigured","fieldName":"Academic Interest","questionLabel":"Academic Interest","fieldInteractionAPIName":"Major_Program_1__c","isRequired":true,"typePreconfigured":true,"typeCustom":false,"typeFilter":false,"isPicklist":false,"isTextBox":false,"isTextarea":false,"isEmail":false,"isStaticContent":false,"isFirst":false,"isLast":false},{"id":3,"type":"preconfigured","fieldName":"Email","questionLabel":"Email","fieldInteractionAPIName":"Email__c","isRequired":true,"typePreconfigured":true,"typeCustom":false,"typeFilter":false,"isPicklist":false,"isTextBox":false,"isTextarea":false,"isEmail":false,"isStaticContent":false,"isFirst":false,"isLast":false},{"id":4,"type":"preconfigured","fieldName":"Phone","questionLabel":"Phone","fieldInteractionAPIName":"Home_Phone__c","isRequired":false,"typePreconfigured":true,"typeCustom":false,"typeFilter":false,"isPicklist":false,"isTextBox":false,"isTextarea":false,"isEmail":false,"isStaticContent":false,"isFirst":false,"isLast":false},{"id":5,"type":"preconfigured","fieldName":"I would like to receive text messages","questionLabel":"I would like to receive text messages","fieldInteractionAPIName":"Receive_Texts__c","isRequired":false,"typePreconfigured":true,"typeCustom":false,"typeFilter":false,"isPicklist":false,"isTextBox":false,"isTextarea":false,"isEmail":false,"isStaticContent":false,"isFirst":false,"isLast":false},{"type":"filter","questionLabel":"Citizenship Type?","filterControllerField":"Citizen_Types_To_Display__c","filterInteractionAPIName":"Citizenship__c","isFilterSchoolList":false,"filterSelectedValues":["U.S. Citizen","U.S. Dual Citizen","U.S. Permanent Resident (green card holder)","International","U.S. Resident"],"isRequired":true,"id":6,"typePreconfigured":false,"typeCustom":false,"typeFilter":true,"isPicklist":false,"isTextBox":false,"isTextarea":false,"isEmail":false,"isStaticContent":false,"isFirst":false,"isLast":false},{"type":"filter","questionLabel":"Delivery Type","filterControllerField":"Delivery_Types_To_Display__c","filterInteractionAPIName":"Delivery_Type__c","isFilterSchoolList":false,"filterSelectedValues":["On-Campus","Online","Evenings and Weekends"],"isRequired":true,"id":7,"typePreconfigured":false,"typeCustom":false,"typeFilter":true,"isPicklist":false,"isTextBox":false,"isTextarea":false,"isEmail":false,"isStaticContent":false,"isFirst":false,"isLast":false},{"type":"filter","questionLabel":"School Type?","filterControllerField":"School_College_To_Display__c","filterInteractionAPIName":"St_Thomas_College_School__c","isFilterSchoolList":true,"filterSelectedValues":["College of Arts and Sciences","Dougherty Family College","Graduate"],"isRequired":true,"id":8,"typePreconfigured":false,"typeCustom":false,"typeFilter":true,"isPicklist":false,"isTextBox":false,"isTextarea":false,"isEmail":false,"isStaticContent":false,"isFirst":false,"isLast":true}]';
    private static final String stagingWithEmailStaticContentAndTextBoxes = '[{"id":0,"type":"preconfigured","fieldName":"First Name","questionLabel":"First Name","fieldInteractionAPIName":"First_Name__c","isRequired":true,"typePreconfigured":true,"typeCustom":false,"typeFilter":false,"isPicklist":false,"isTextBox":false,"isTextarea":false,"isEmail":false,"isStaticContent":false,"isFirst":true,"isLast":false},{"id":1,"type":"preconfigured","fieldName":"Last Name","questionLabel":"Last Name","fieldInteractionAPIName":"Last_Name__c","isRequired":true,"typePreconfigured":true,"typeCustom":false,"typeFilter":false,"isPicklist":false,"isTextBox":false,"isTextarea":false,"isEmail":false,"isStaticContent":false,"isFirst":false,"isLast":false},{"id":2,"type":"preconfigured","fieldName":"Address","questionLabel":"Address","fieldInteractionAPIName":"Mailing_Street__c","isRequired":false,"typePreconfigured":true,"typeCustom":false,"typeFilter":false,"isPicklist":false,"isTextBox":false,"isTextarea":false,"isEmail":false,"isStaticContent":false,"isFirst":false,"isLast":false},{"id":3,"type":"preconfigured","fieldName":"Birthdate","questionLabel":"Birthdate","fieldInteractionAPIName":"Birthdate__c","isRequired":true,"typePreconfigured":true,"typeCustom":false,"typeFilter":false,"isPicklist":false,"isTextBox":false,"isTextarea":false,"isEmail":false,"isStaticContent":false,"isFirst":false,"isLast":false},{"id":4,"type":"preconfigured","fieldName":"Email","questionLabel":"Email","fieldInteractionAPIName":"Email__c","isRequired":true,"typePreconfigured":true,"typeCustom":false,"typeFilter":false,"isPicklist":false,"isTextBox":false,"isTextarea":false,"isEmail":false,"isStaticContent":false,"isFirst":false,"isLast":false},{"id":5,"type":"preconfigured","fieldName":"High School Attended","questionLabel":"High School Attended","fieldInteractionAPIName":"High_School_or_College__c","isRequired":false,"typePreconfigured":true,"typeCustom":false,"typeFilter":false,"isPicklist":false,"isTextBox":false,"isTextarea":false,"isEmail":false,"isStaticContent":false,"isFirst":false,"isLast":false},{"id":6,"type":"preconfigured","fieldName":"High School Graduation Year","questionLabel":"High School Graduation Year","fieldInteractionAPIName":"High_School_Graduation_Year__c","isRequired":true,"typePreconfigured":true,"typeCustom":false,"typeFilter":false,"isPicklist":false,"isTextBox":false,"isTextarea":false,"isEmail":false,"isStaticContent":false,"isFirst":false,"isLast":false},{"type":"custom","questionLabel":"Referring Alum Information","questionType":"Static content","fieldToApplyTo":"","isRequired":false,"picklistValues":[],"valuesFlat":"<p><strong>Referring Alum Information</strong></p>","assistiveText":"","isMappedPicklist":false,"id":7,"typePreconfigured":false,"typeCustom":true,"typeFilter":false,"isPicklist":false,"isTextBox":false,"isTextarea":false,"isEmail":false,"isStaticContent":true,"isFirst":false,"isLast":false},{"type":"custom","questionLabel":"Alum First Name","questionType":"Text box required","fieldToApplyTo":"Nominator_First_Name__c","isRequired":true,"picklistValues":[],"valuesFlat":"","assistiveText":"","isMappedPicklist":false,"id":8,"typePreconfigured":false,"typeCustom":true,"typeFilter":false,"isPicklist":false,"isTextBox":true,"isTextarea":false,"isEmail":false,"isStaticContent":false,"isFirst":false,"isLast":false},{"type":"custom","questionLabel":"Alum Last Name","questionType":"Text box required","fieldToApplyTo":"Nominator_Last_Name__c","isRequired":true,"picklistValues":[],"valuesFlat":"","assistiveText":"","isMappedPicklist":false,"id":9,"typePreconfigured":false,"typeCustom":true,"typeFilter":false,"isPicklist":false,"isTextBox":true,"isTextarea":false,"isEmail":false,"isStaticContent":false,"isFirst":false,"isLast":false},{"type":"custom","questionLabel":"Alum Last Name as a Student at St. Thomas","questionType":"Text box","fieldToApplyTo":"Nominator_Previous_Last_Name__c","isRequired":false,"picklistValues":[],"valuesFlat":"","assistiveText":"","isMappedPicklist":false,"id":10,"typePreconfigured":false,"typeCustom":true,"typeFilter":false,"isPicklist":false,"isTextBox":true,"isTextarea":false,"isEmail":false,"isStaticContent":false,"isFirst":false,"isLast":false},{"type":"custom","questionLabel":"Alum Preferred Email Address","questionType":"Email required","fieldToApplyTo":"Nominator_Email__c","isRequired":true,"picklistValues":[],"valuesFlat":"","assistiveText":"","isMappedPicklist":false,"id":11,"typePreconfigured":false,"typeCustom":true,"typeFilter":false,"isPicklist":false,"isTextBox":false,"isTextarea":false,"isEmail":true,"isStaticContent":false,"isFirst":false,"isLast":false},{"type":"custom","questionLabel":"Alum Class Year - Year Graduate (YYYY)","questionType":"Text box required","fieldToApplyTo":"St_Thomas_Alumni_Class_Year__c","isRequired":true,"picklistValues":[],"valuesFlat":"","assistiveText":"","isMappedPicklist":false,"id":12,"typePreconfigured":false,"typeCustom":true,"typeFilter":false,"isPicklist":false,"isTextBox":true,"isTextarea":false,"isEmail":false,"isStaticContent":false,"isFirst":false,"isLast":true}]';

    @IsTest
    static void realStagingLists_allLoadWithoutWarnings_andKeepEveryQuestion_TEST() {
        Map<String, Integer> expectedCounts = new Map<String, Integer>{
            stagingWithFilterAndCustomPicklist => 6, stagingWithFilters => 9, stagingWithEmailStaticContentAndTextBoxes => 13
        };
        for (String saved : expectedCounts.keySet()) {
            rfiQuestionReader.ReadResult result = rfiQuestionReader.read(saved);
            System.assertEquals(new List<String>(), result.warnings, 'A real saved list must load cleanly');
            System.assertEquals(expectedCounts.get(saved), result.questions.size(), 'No question may be lost');
            for (Map<String, Object> question : result.questions) {
                System.assertEquals(1, question.get('schemaVersion'), 'Lists saved before versions existed count as version 1');
                System.assert(question.get('isRequired') instanceof Boolean);
            }
        }
    }

    @IsTest
    static void realStagingLists_stillBuildAForm_andTheDerivedFlagsAreIgnored_TEST() {
        for (String saved : new List<String>{ stagingWithFilterAndCustomPicklist, stagingWithFilters, stagingWithEmailStaticContentAndTextBoxes }) {
            rfiFormController.interactionRFIFields form = formFor(saved);
            System.assertEquals(0, form.warnings.size(), 'Warnings: ' + form.warnings);
            System.assert(form.rfiFieldList.size() >= 2);
        }
    }

    // ---------- helpers ----------

    private static String baseline() {
        return '{"id":0,"type":"preconfigured","fieldName":"First Name","questionLabel":"First Name","fieldInteractionAPIName":"First_Name__c","isRequired":true}';
    }

    private static rfiQuestionReader.ReadResult read(String json) {
        return rfiQuestionReader.read(json);
    }

    private static rfiFormController.interactionRFIFields formFor(String savedJson) {
        RFI_Controller__c controller = new RFI_Controller__c(Academic_Level__c = 'U', Fields_to_Display__c = 'Email',
                Redirect_URL__c = 'https://reader.example.com', Unified_Questions__c = savedJson);
        insert controller;
        String name = [SELECT Name FROM RFI_Controller__c WHERE Id = :controller.Id].Name;
        delete [SELECT Id FROM RFI_Controller__c WHERE Name = :name AND Id != :controller.Id];
        return rfiFormController.getRFIForm(name);
    }

    private static Boolean anyWarningContains(List<String> warnings, String text) {
        for (String warning : warnings) {
            if (warning.contains(text)) {
                return true;
            }
        }
        return false;
    }

    // ---------- shapes the saved list can take ----------

    @IsTest
    static void aPlainList_andAListInsideAnObject_readTheSame_TEST() {
        System.assertEquals(1, read('[' + baseline() + ']').questions.size());
        rfiQuestionReader.ReadResult wrapped = read('{"version":2,"questions":[' + baseline() + ']}');
        System.assertEquals(1, wrapped.questions.size(), 'Room for a future wrapper');
        System.assertEquals(0, wrapped.warnings.size());
    }

    @IsTest
    static void anEmptyList_isFine_TEST() {
        rfiQuestionReader.ReadResult result = read('[]');
        System.assertEquals(0, result.questions.size());
        System.assertEquals(0, result.warnings.size());
    }

    @IsTest
    static void somethingThatIsNotAListOfQuestions_cannotBeRead_TEST() {
        for (String unreadable : new List<String>{ '{broken', '42', '"text"', '{"questions":"nope"}', '{"other":[]}', 'null' }) {
            Boolean threw = false;
            try {
                read(unreadable);
            } catch (rfiQuestionReader.UnreadableException expected) {
                threw = true;
            }
            System.assert(threw, unreadable + ' has no questions to build a form from, so it must be reported as unreadable');
        }
    }

    @IsTest
    static void keysThisVersionDoesNotKnow_arePassedThrough_TEST() {
        rfiQuestionReader.ReadResult result = read('[{"id":0,"type":"preconfigured","fieldName":"Email","questionLabel":"Email","fieldInteractionAPIName":"Email__c","futureFeature":{"a":1},"anotherNewKey":"x"}]');
        System.assertEquals(0, result.warnings.size());
        System.assertEquals(true, result.questions[0].containsKey('futureFeature'), 'Newer data is not damaged');
        System.assertEquals('x', result.questions[0].get('anotherNewKey'));
    }

    @IsTest
    static void aStableKey_isKept_andABlankOneIsLeftOut_TEST() {
        rfiQuestionReader.ReadResult result = read('[' + baseline().replace('"id":0,', '"id":0,"key":"q-abc123",')
                + ',{"id":1,"type":"preconfigured","fieldName":"Email","questionLabel":"Email","key":""}]');
        System.assertEquals('q-abc123', result.questions[0].get('key'));
        System.assertEquals(false, result.questions[1].containsKey('key'));
    }

    @IsTest
    static void twoQuestionsWithTheSameKey_areBothKept_butReported_TEST() {
        rfiQuestionReader.ReadResult result = read('[' + baseline().replace('"id":0,', '"id":0,"key":"same",')
                + ',{"id":1,"type":"preconfigured","fieldName":"Email","questionLabel":"Email","key":"same"}]');
        System.assertEquals(2, result.questions.size());
        System.assert(anyWarningContains(result.warnings, 'same key'), String.valueOf(result.warnings));
    }

    @IsTest
    static void aNewerFormatVersion_isKept_butReported_TEST() {
        rfiQuestionReader.ReadResult result = read('[' + baseline().replace('"id":0,', '"id":0,"schemaVersion":99,') + ']');
        System.assertEquals(1, result.questions.size());
        System.assert(anyWarningContains(result.warnings, 'newer version'), String.valueOf(result.warnings));
    }

    @IsTest
    static void theVersionIsReadFromTextOrANumber_andDefaultsToOne_TEST() {
        System.assertEquals(2, read('[' + baseline().replace('"id":0,', '"id":0,"schemaVersion":"2",') + ']').questions[0].get('schemaVersion'));
        System.assertEquals(1, read('[' + baseline().replace('"id":0,', '"id":0,"schemaVersion":"abc",') + ']').questions[0].get('schemaVersion'));
        System.assertEquals(1, read('[' + baseline() + ']').questions[0].get('schemaVersion'));
    }

    // ---------- values of the wrong type ----------

    @IsTest
    static void isRequiredSavedAsText_isUnderstood_withoutAWarning_TEST() {
        rfiQuestionReader.ReadResult result = read('[{"id":0,"type":"preconfigured","fieldName":"Email","questionLabel":"Email","isRequired":"true"},'
                + '{"id":1,"type":"preconfigured","fieldName":"Title","questionLabel":"Title","isRequired":"FALSE"}]');
        System.assertEquals(true, result.questions[0].get('isRequired'));
        System.assertEquals(false, result.questions[1].get('isRequired'));
        System.assertEquals(0, result.warnings.size());
    }

    @IsTest
    static void isRequiredSavedAsSomethingElse_countsAsFalse_andIsReported_TEST() {
        rfiQuestionReader.ReadResult result = read('[{"id":0,"type":"preconfigured","fieldName":"Email","questionLabel":"Email","isRequired":"maybe"}]');
        System.assertEquals(false, result.questions[0].get('isRequired'));
        System.assert(anyWarningContains(result.warnings, 'isRequired'), String.valueOf(result.warnings));
    }

    @IsTest
    static void aLabelSavedAsANumber_becomesText_TEST() {
        rfiQuestionReader.ReadResult result = read('[{"id":0,"type":"preconfigured","fieldName":"Email","questionLabel":42}]');
        System.assertEquals('42', result.questions[0].get('questionLabel'));
        System.assertEquals(0, result.warnings.size());
    }

    @IsTest
    static void aPreconfiguredQuestionWithoutALabel_usesItsName_TEST() {
        System.assertEquals('Email', read('[{"id":0,"type":"preconfigured","fieldName":"Email"}]').questions[0].get('questionLabel'));
    }

    // ---------- questions that have to be skipped ----------

    @IsTest
    static void anUnknownQuestionType_isSkippedAndNamed_otherQuestionsLoad_TEST() {
        rfiQuestionReader.ReadResult result = read('[' + baseline() + ',{"id":1,"type":"matrix","questionLabel":"Future thing"},'
                + '{"id":2,"type":"preconfigured","fieldName":"Email","questionLabel":"Email"}]');
        System.assertEquals(2, result.questions.size(), 'The two good questions load');
        System.assertEquals(1, result.warnings.size());
        System.assert(result.warnings[0].contains('Question 2'), result.warnings[0]);
        System.assert(result.warnings[0].contains('Future thing'), result.warnings[0]);
        System.assert(result.warnings[0].contains('matrix'), result.warnings[0]);
    }

    @IsTest
    static void aPreconfiguredQuestionWithNoName_isSkipped_TEST() {
        rfiQuestionReader.ReadResult result = read('[' + baseline() + ',{"id":1,"type":"preconfigured","questionLabel":"No name"}]');
        System.assertEquals(1, result.questions.size());
        System.assert(anyWarningContains(result.warnings, 'No name'), String.valueOf(result.warnings));
    }

    @IsTest
    static void anEntryThatIsNotAQuestion_isSkipped_TEST() {
        rfiQuestionReader.ReadResult result = read('[' + baseline() + ',"oops",null,7]');
        System.assertEquals(1, result.questions.size());
        System.assertEquals(3, result.warnings.size());
        System.assert(result.warnings[0].contains('Question 2'));
    }

    @IsTest
    static void aCustomQuestionThatSavesNowhere_isSkipped_butStaticContentNeedsNoField_TEST() {
        rfiQuestionReader.ReadResult result = read('[{"id":0,"type":"custom","questionLabel":"Orphan","questionType":"Text box"},'
                + '{"id":1,"type":"custom","questionLabel":"Intro","questionType":"Static content","valuesFlat":"<p>Hi</p>"},'
                + '{"id":2,"type":"custom","questionLabel":"No type","fieldToApplyTo":"Employer__c"}]');
        System.assertEquals(1, result.questions.size());
        System.assertEquals('Intro', result.questions[0].get('questionLabel'));
        System.assertEquals(2, result.warnings.size());
    }

    @IsTest
    static void aFilterThatNamesNoControllerField_isSkipped_TEST() {
        rfiQuestionReader.ReadResult result = read('[{"id":0,"type":"filter","questionLabel":"Broken filter"}]');
        System.assertEquals(0, result.questions.size());
        System.assert(anyWarningContains(result.warnings, 'Broken filter'), String.valueOf(result.warnings));
    }

    // ---------- lists inside a question ----------

    @IsTest
    static void picklistChoicesSavedAsText_areIgnoredAndReported_TEST() {
        rfiQuestionReader.ReadResult result = read('[{"id":0,"type":"custom","questionLabel":"Pick","questionType":"Picklist","fieldToApplyTo":"Employer__c","picklistValues":"A;B"}]');
        System.assertEquals(1, result.questions.size(), 'The question itself still loads');
        System.assertEquals(0, ((List<Object>) result.questions[0].get('picklistValues')).size());
        System.assert(anyWarningContains(result.warnings, 'picklistValues'), String.valueOf(result.warnings));
    }

    @IsTest
    static void picklistChoices_acceptPairsAndPlainText_andDropJunk_TEST() {
        rfiQuestionReader.ReadResult result = read('[{"id":0,"type":"custom","questionLabel":"Pick","questionType":"Picklist","fieldToApplyTo":"Employer__c",'
                + '"picklistValues":[{"label":"Main","value":"Main"},{"value":"Online"},"Hybrid",{"label":"x"},5,null]}]');
        List<Object> choices = (List<Object>) result.questions[0].get('picklistValues');
        System.assertEquals(3, choices.size());
        System.assertEquals('Online', ((Map<String, Object>) choices[1]).get('label'), 'A missing label falls back to the value');
        System.assertEquals('Hybrid', ((Map<String, Object>) choices[2]).get('value'));
    }

    @IsTest
    static void filterChoices_numbersBecomeText_andTextInsteadOfAListIsReported_TEST() {
        rfiQuestionReader.ReadResult result = read('[{"id":0,"type":"filter","questionLabel":"F","filterControllerField":"Citizen_Types_To_Display__c","filterSelectedValues":["US",2,null]},'
                + '{"id":1,"type":"filter","questionLabel":"G","filterControllerField":"Degree_Types_To_Display__c","filterSelectedValues":"US;Intl"}]');
        List<Object> first = (List<Object>) result.questions[0].get('filterSelectedValues');
        System.assertEquals(2, first.size());
        System.assertEquals('2', first[1]);
        System.assertEquals(0, ((List<Object>) result.questions[1].get('filterSelectedValues')).size());
        System.assertEquals(1, result.warnings.size());
    }

    // ---------- what the form does ----------

    @IsTest
    static void aBrokenQuestion_isLeftOutOfTheForm_theOthersLoad_andTheFormSaysWhy_TEST() {
        rfiFormController.interactionRFIFields form = formFor('[' + baseline() + ',{"id":1,"type":"matrix","questionLabel":"Future thing"},'
                + '{"id":2,"type":"preconfigured","fieldName":"Email","questionLabel":"Email","fieldInteractionAPIName":"Email__c"}]');
        List<String> targets = new List<String>();
        for (rfiFormController.rfiField question : form.rfiFieldList) {
            targets.add(question.fieldInteractionAPIName);
        }
        System.assert(targets.contains('First_Name__c'));
        System.assert(targets.contains('Email__c'), 'The question after the broken one still loads: ' + targets);
        System.assertEquals(1, form.warnings.size());
        System.assert(form.warnings[0].contains('Future thing'), form.warnings[0]);
    }

    @IsTest
    static void aQuestionThatFailsWhileBeingBuilt_isUndone_andReported_TEST() {
        rfiFormController.questionFailureForTest = 'Explodes';
        rfiFormController.interactionRFIFields form = formFor('[' + baseline() + ',{"id":1,"type":"custom","questionLabel":"Explodes","questionType":"Text box","fieldToApplyTo":"Employer__c"},'
                + '{"id":2,"type":"preconfigured","fieldName":"Email","questionLabel":"Email","fieldInteractionAPIName":"Email__c"}]');
        for (rfiFormController.rfiField question : form.rfiFieldList) {
            System.assertNotEquals('Employer__c', question.fieldInteractionAPIName, 'The failed question leaves nothing behind');
        }
        System.assertEquals(1, form.warnings.size());
        System.assert(form.warnings[0].contains('Explodes'), form.warnings[0]);
        System.assertEquals(true, hasField(form, 'Email__c'), 'The next question still loads');
    }

    @IsTest
    static void aQuestionThatFailsAfterItWasAdded_leavesNoFieldAndNoFilterBehind_TEST() {
        rfiFormController.questionFailureAfterAddForTest = 'Half built filter';
        rfiFormController.interactionRFIFields form = formFor('[' + baseline()
                + ',{"id":1,"type":"filter","questionLabel":"Half built filter","filterControllerField":"Citizen_Types_To_Display__c","filterInteractionAPIName":"Citizenship__c","filterSelectedValues":["International"]},'
                + '{"id":2,"type":"preconfigured","fieldName":"Email","questionLabel":"Email","fieldInteractionAPIName":"Email__c"}]');
        System.assertEquals(false, hasField(form, 'Citizenship__c'), 'The half-added question is removed');
        System.assertEquals(false, form.filterValues.containsKey('Citizenship__c'), 'Its filter registration is removed, so the page does not wait for an answer that will never come');
        System.assertEquals(true, hasField(form, 'Email__c'), 'The next question still loads');
        System.assertEquals(1, form.warnings.size());
    }

    @IsTest
    static void aListThatCannotBeReadAtAll_stillStopsTheForm_TEST() {
        String message;
        try {
            formFor('{broken');
        } catch (AuraHandledException formError) {
            message = formError.getMessage();
        }
        System.assertNotEquals(null, message);
        System.assert(message.contains('could not be loaded'), message);
    }

    @IsTest
    static void aSubmitOnAFormWithABrokenQuestion_savesTheRfi_andRecordsTheProblem_TEST() {
        RFI_Controller__c controller = new RFI_Controller__c(Academic_Level__c = 'U', Fields_to_Display__c = 'Email', Redirect_URL__c = 'https://reader.example.com',
                Unified_Questions__c = '[' + baseline() + ',{"id":1,"type":"preconfigured","fieldName":"Last Name","questionLabel":"Last Name","fieldInteractionAPIName":"Last_Name__c","isRequired":true},'
                + '{"id":2,"type":"matrix","questionLabel":"Future thing"}]');
        insert controller;
        String name = [SELECT Name FROM RFI_Controller__c WHERE Id = :controller.Id].Name;
        delete [SELECT Id FROM RFI_Controller__c WHERE Name = :name AND Id != :controller.Id];
        Test.startTest();
        Id savedId = rfiFormController.submitRfiForm(new Interaction__c(First_Name__c = 'Ada', Last_Name__c = 'Reader'), name);
        Test.stopTest();
        System.assertNotEquals(null, savedId, 'A broken question never blocks an RFI');
        List<hed__Error__c> errors = [SELECT hed__Error_Type__c, hed__Full_Message__c FROM hed__Error__c];
        System.assertEquals(1, errors.size());
        System.assertEquals(rfiErrorLogger.gapsType, errors[0].hed__Error_Type__c);
        System.assert(errors[0].hed__Full_Message__c.contains('Saved question list'), errors[0].hed__Full_Message__c);
        System.assert(errors[0].hed__Full_Message__c.contains('Future thing'), errors[0].hed__Full_Message__c);
    }

    private static Boolean hasField(rfiFormController.interactionRFIFields form, String apiName) {
        for (rfiFormController.rfiField question : form.rfiFieldList) {
            if (question.fieldInteractionAPIName == apiName) {
                return true;
            }
        }
        return false;
    }


    // ---------- "show only when" rules ----------

    private static String parentQuestion() {
        return '{"id":1,"type":"preconfigured","fieldName":"Citizenship","questionLabel":"Citizenship","fieldInteractionAPIName":"Citizenship__c","key":"qcitizen"}';
    }

    private static String childQuestion(String rule) {
        return '{"id":2,"type":"custom","questionLabel":"Visa status","questionType":"Text box","fieldToApplyTo":"Employer__c","key":"qvisa","visibleWhen":' + rule + '}';
    }

    @IsTest
    static void aCompleteRule_isKeptWithItsAnswersAsText_TEST() {
        rfiQuestionReader.ReadResult result = read('[' + baseline() + ',' + parentQuestion() + ',' + childQuestion('{"key":"qcitizen","equals":["International","Other"]}') + ']');
        System.assertEquals(0, result.warnings.size(), String.valueOf(result.warnings));
        Map<String, Object> rule = (Map<String, Object>) result.questions[2].get('visibleWhen');
        System.assertEquals('qcitizen', rule.get('key'));
        System.assertEquals(new List<String>{ 'International', 'Other' }, (List<String>) rule.get('equals'));
    }

    @IsTest
    static void aSingleAnswer_aNumber_andATrueOrFalse_areAllReadAsText_TEST() {
        System.assertEquals(new List<String>{ 'International' }, rfiQuestionReader.answerList('International'));
        System.assertEquals(new List<String>{ '2' }, rfiQuestionReader.answerList(2));
        System.assertEquals(new List<String>{ 'true', 'false' }, rfiQuestionReader.answerList(new List<Object>{ true, false }));
        System.assertEquals(new List<String>(), rfiQuestionReader.answerList(null));
        System.assertEquals(new List<String>{ 'A' }, rfiQuestionReader.answerList(new List<Object>{ 'A', '', null, '  ' }), 'Blanks are left out');
        System.assertEquals(new List<String>{ 'International' }, rfiQuestionReader.answerList(new List<Object>{ '  International ' }), 'Stray spaces from hand-edited data do not stop a match');
    }

    @IsTest
    static void aRuleWithNoAnswersOrNoEarlierQuestion_isRemoved_andReported_TEST() {
        for (String incomplete : new List<String>{ '{"key":"qcitizen","equals":[]}', '{"key":"qcitizen"}', '{"equals":["International"]}', '{"key":"","equals":["x"]}' }) {
            rfiQuestionReader.ReadResult result = read('[' + baseline() + ',' + parentQuestion() + ',' + childQuestion(incomplete) + ']');
            System.assertEquals(3, result.questions.size(), 'The question itself still loads: ' + incomplete);
            System.assertEquals(false, result.questions[2].containsKey('visibleWhen'), incomplete);
            System.assert(anyWarningContains(result.warnings, 'Visa status'), incomplete + ' ' + result.warnings);
            System.assert(anyWarningContains(result.warnings, 'incomplete'), incomplete + ' ' + result.warnings);
        }
    }

    @IsTest
    static void aRuleThatIsNotAnObject_isRemoved_andReported_TEST() {
        for (String broken : new List<String>{ '"International"', '[1,2]', '7' }) {
            rfiQuestionReader.ReadResult result = read('[' + baseline() + ',' + parentQuestion() + ',' + childQuestion(broken) + ']');
            System.assertEquals(false, result.questions[2].containsKey('visibleWhen'), broken);
            System.assert(anyWarningContains(result.warnings, 'cannot be read'), broken + ' ' + result.warnings);
        }
    }

    @IsTest
    static void aRuleKeepsPartsThisVersionDoesNotKnow_TEST() {
        rfiQuestionReader.ReadResult result = read('[' + baseline() + ',' + parentQuestion() + ',' + childQuestion('{"key":"qcitizen","equals":["International"],"operator":"in","futurePart":{"a":1}}') + ']');
        Map<String, Object> rule = (Map<String, Object>) result.questions[2].get('visibleWhen');
        System.assertEquals(true, rule.containsKey('futurePart'), 'Newer data is not damaged');
        System.assertEquals('in', rule.get('operator'));
    }

    @IsTest
    static void aRuleThatPointsAtAMissingQuestion_isRemoved_andReported_TEST() {
        rfiQuestionReader.ReadResult result = read('[' + baseline() + ',' + childQuestion('{"key":"qgone","equals":["International"]}') + ']');
        System.assertEquals(false, result.questions[1].containsKey('visibleWhen'));
        System.assert(anyWarningContains(result.warnings, 'Visa status'), String.valueOf(result.warnings));
        System.assert(anyWarningContains(result.warnings, 'not available'), String.valueOf(result.warnings));
    }

    @IsTest
    static void aRuleThatPointsAtALaterQuestion_isRemoved_andReported_TEST() {
        rfiQuestionReader.ReadResult result = read('[' + baseline() + ',' + childQuestion('{"key":"qcitizen","equals":["International"]}') + ',' + parentQuestion() + ']');
        System.assertEquals(false, result.questions[1].containsKey('visibleWhen'));
        System.assert(anyWarningContains(result.warnings, 'does not come before'), String.valueOf(result.warnings));
    }

    @IsTest
    static void aRuleThatPointsAtItself_isRemoved_TEST() {
        rfiQuestionReader.ReadResult result = read('[' + baseline() + ',' + childQuestion('{"key":"qvisa","equals":["x"]}') + ']');
        System.assertEquals(false, result.questions[1].containsKey('visibleWhen'));
        System.assert(anyWarningContains(result.warnings, 'does not come before'), String.valueOf(result.warnings));
    }

    @IsTest
    static void aChainOfRules_isNotSupported_theSecondLinkIsRemoved_TEST() {
        String middle = '{"id":2,"type":"custom","questionLabel":"Middle","questionType":"Picklist","fieldToApplyTo":"Citizenship__c","key":"qmiddle","visibleWhen":{"key":"qcitizen","equals":["International"]}}';
        String last = '{"id":3,"type":"custom","questionLabel":"Last link","questionType":"Text box","fieldToApplyTo":"Employer__c","key":"qlast","visibleWhen":{"key":"qmiddle","equals":["x"]}}';
        rfiQuestionReader.ReadResult result = read('[' + baseline() + ',' + parentQuestion() + ',' + middle + ',' + last + ']');
        System.assertEquals(true, result.questions[2].containsKey('visibleWhen'), 'The first link is fine');
        System.assertEquals(false, result.questions[3].containsKey('visibleWhen'), 'Only one level is supported');
        System.assert(anyWarningContains(result.warnings, 'Only one level'), String.valueOf(result.warnings));
    }

    @IsTest
    static void aProgramFilter_cannotBeHidden_TEST() {
        String filter = '{"id":2,"type":"filter","questionLabel":"Degree","filterControllerField":"Degree_Types_To_Display__c","key":"qfilter","visibleWhen":{"key":"qcitizen","equals":["International"]}}';
        rfiQuestionReader.ReadResult result = read('[' + baseline() + ',' + parentQuestion() + ',' + filter + ']');
        System.assertEquals(3, result.questions.size());
        System.assertEquals(false, result.questions[2].containsKey('visibleWhen'));
        System.assert(anyWarningContains(result.warnings, 'program filter'), String.valueOf(result.warnings));
    }

    @IsTest
    static void aRuleOnAQuestionWithNoKeyOfItsOwn_stillWorks_TEST() {
        // The child needs no key; only the parent does
        String child = '{"id":2,"type":"custom","questionLabel":"Visa status","questionType":"Text box","fieldToApplyTo":"Employer__c","visibleWhen":{"key":"qcitizen","equals":["International"]}}';
        rfiQuestionReader.ReadResult result = read('[' + baseline() + ',' + parentQuestion() + ',' + child + ']');
        System.assertEquals(true, result.questions[2].containsKey('visibleWhen'));
        System.assertEquals(0, result.warnings.size());
    }

    @IsTest
    static void aRuleOnASkippedQuestion_isNotChecked_andDoesNotBreakTheOthers_TEST() {
        String skipped = '{"id":2,"type":"matrix","questionLabel":"Future","key":"qfuture","visibleWhen":{"key":"qnone","equals":["x"]}}';
        rfiQuestionReader.ReadResult result = read('[' + baseline() + ',' + skipped + ']');
        System.assertEquals(1, result.questions.size());
        System.assertEquals(1, result.warnings.size(), 'Only the unknown type is reported: ' + result.warnings);
    }
}
