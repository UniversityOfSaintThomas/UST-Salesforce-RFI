/**
 * Guardrails for the question to field mapping. These run with every deploy, so a question that points at a
 * field that does not exist, at the wrong field, or at a field of the wrong type fails the build instead of
 * being found by hand months later.
 */
@IsTest
private class rfiQuestionCatalog_TEST {

    // ---------- helpers ----------

    private static Map<String, Schema.SObjectField> interactionFields() {
        return Schema.SObjectType.Interaction__c.fields.getMap();
    }

    private static List<String> offeredQuestionNames() {
        List<String> names = new List<String>();
        for (Schema.PicklistEntry entry : RFI_Controller__c.Fields_to_Display__c.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                names.add(entry.getValue());
            }
        }
        return names;
    }

    /** The questions the form can show: offered, not folded into Address, not retired. */
    private static List<String> usableOfferedQuestionNames() {
        List<String> names = new List<String>();
        Boolean addressAdded = false;
        for (String name : offeredQuestionNames()) {
            if (rfiQuestionCatalog.retiredQuestions.contains(name)) {
                continue;
            }
            if (rfiQuestionCatalog.splitAddressQuestions.contains(name)) {
                if (!addressAdded && !offeredQuestionNames().contains('Address')) {
                    names.add('Address');
                    addressAdded = true;
                }
                continue;
            }
            names.add(name);
        }
        return names;
    }

    /** What an admin's older form actually holds: every offered name, split address names included. */
    private static List<String> offeredNamesAsSaved() {
        List<String> names = new List<String>();
        for (String name : offeredQuestionNames()) {
            if (!rfiQuestionCatalog.retiredQuestions.contains(name)) {
                names.add(name);
            }
        }
        return names;
    }

    private static String insertControllerAndGetName(RFI_Controller__c controller) {
        insert controller;
        String name = [SELECT Name FROM RFI_Controller__c WHERE Id = :controller.Id].Name;
        // The Name is an auto-number that can repeat inside a test; keep only this controller under it
        delete [SELECT Id FROM RFI_Controller__c WHERE Name = :name AND Id != :controller.Id];
        return name;
    }

    private static String firstOffered() {
        return offeredQuestionNames()[0];
    }

    private static rfiFormController.interactionRFIFields unifiedForm(List<String> questionNames) {
        List<Map<String, Object>> questions = new List<Map<String, Object>>();
        Integer position = 0;
        for (String questionName : questionNames) {
            // The stored field name is left blank on purpose: the catalog must supply it
            questions.add(new Map<String, Object>{
                'id' => position, 'type' => 'preconfigured', 'fieldName' => questionName,
                'questionLabel' => questionName, 'fieldInteractionAPIName' => '', 'isRequired' => false
            });
            position++;
        }
        String name = insertControllerAndGetName(new RFI_Controller__c(
                Academic_Level__c = 'U', Fields_to_Display__c = firstOffered(),
                Unified_Questions__c = JSON.serialize(questions), Redirect_URL__c = 'https://catalog-unified.example.com'));
        return rfiFormController.buildForm(rfiFormController.loadControllerByName(name));
    }

    private static rfiFormController.interactionRFIFields legacyForm(List<String> questionNames) {
        String name = insertControllerAndGetName(new RFI_Controller__c(
                Academic_Level__c = 'U', Fields_to_Display__c = String.join(questionNames, ';'),
                Redirect_URL__c = 'https://catalog-legacy.example.com'));
        return rfiFormController.buildForm(rfiFormController.loadControllerByName(name));
    }

    /** Whether the field on the form can sensibly save into a field of this type. */
    private static Boolean isCompatible(rfiFormController.rfiField question, Schema.DisplayType fieldType) {
        if (question.isEmail == true) {
            return fieldType == Schema.DisplayType.EMAIL;
        }
        if (question.isDate == true) {
            return fieldType == Schema.DisplayType.DATE;
        }
        if (question.isCheckbox == true) {
            return fieldType == Schema.DisplayType.BOOLEAN;
        }
        if (question.isMultiSelect == true) {
            return fieldType == Schema.DisplayType.MULTIPICKLIST;
        }
        if (question.isProgramLookup == true || question.isSchoolLookup == true) {
            return fieldType == Schema.DisplayType.REFERENCE;
        }
        if (question.isPicklist == true) {
            return fieldType == Schema.DisplayType.PICKLIST || fieldType == Schema.DisplayType.REFERENCE;
        }
        if (question.isTel == true) {
            return fieldType == Schema.DisplayType.PHONE || fieldType == Schema.DisplayType.STRING;
        }
        // A plain text box or text area
        return fieldType == Schema.DisplayType.STRING || fieldType == Schema.DisplayType.TEXTAREA
                || fieldType == Schema.DisplayType.PHONE || fieldType == Schema.DisplayType.EMAIL;
    }

    private static void assertQuestionsSaveToUsableFields(rfiFormController.interactionRFIFields form, String formName) {
        Map<String, Schema.SObjectField> fields = interactionFields();
        Integer checked = 0;
        for (rfiFormController.rfiField question : form.rfiFieldList) {
            if (question.isStaticContent == true || String.isBlank(question.fieldInteractionAPIName)) {
                continue;
            }
            Schema.SObjectField field = fields.get(question.fieldInteractionAPIName.toLowerCase());
            System.assertNotEquals(null, field, formName + ': "' + question.fieldLabel + '" saves to '
                    + question.fieldInteractionAPIName + ', which is not a field on Interaction__c');
            Schema.DescribeFieldResult describe = field.getDescribe();
            System.assertEquals(false, describe.isCalculated(), formName + ': ' + question.fieldInteractionAPIName + ' is a formula and cannot be written');
            System.assertEquals(false, describe.isAutoNumber(), formName + ': ' + question.fieldInteractionAPIName + ' is an auto number and cannot be written');
            System.assert(isCompatible(question, describe.getType()), formName + ': "' + question.fieldLabel + '" is drawn as '
                    + describeControl(question) + ' but saves to ' + question.fieldInteractionAPIName + ', which is a ' + describe.getType() + ' field');
            checked++;
        }
        System.assert(checked > 0, formName + ': the form had no questions to check');
    }

    private static String describeControl(rfiFormController.rfiField question) {
        List<String> flags = new List<String>();
        for (String flag : new List<String>{ 'isEmail', 'isDate', 'isCheckbox', 'isMultiSelect', 'isProgramLookup', 'isSchoolLookup', 'isPicklist', 'isTel', 'isTextarea', 'isAddress' }) {
            if (JSON.serialize(question).contains('"' + flag + '":true')) {
                flags.add(flag);
            }
        }
        return flags.isEmpty() ? 'a text box' : String.join(flags, '+');
    }

    // ---------- the catalog itself ----------

    @IsTest
    static void everyQuestionTheManagerOffers_hasACatalogEntry_TEST() {
        Set<String> known = new Set<String>();
        for (rfiQuestionCatalog.Question question : rfiQuestionCatalog.questions()) {
            known.add(question.name);
        }
        for (String offered : offeredQuestionNames()) {
            Boolean accountedFor = known.contains(offered)
                    || rfiQuestionCatalog.splitAddressQuestions.contains(offered)
                    || rfiQuestionCatalog.retiredQuestions.contains(offered);
            System.assert(accountedFor, '"' + offered + '" is offered in Fields_to_Display__c but has no entry in rfiQuestionCatalog');
        }
    }

    @IsTest
    static void catalog_hasNoDuplicateNamesAndNoBlankTargets_TEST() {
        Set<String> seen = new Set<String>();
        for (rfiQuestionCatalog.Question question : rfiQuestionCatalog.questions()) {
            System.assert(seen.add(question.name), 'Listed twice: ' + question.name);
            System.assert(String.isNotBlank(question.targetField), question.name + ' has no target field');
            System.assert(String.isNotBlank(question.defaultLabel), question.name + ' has no label');
        }
    }

    @IsTest
    static void catalog_anAliasSavesWhereItsFullNameSaves_TEST() {
        Map<String, String> fullNameFor = new Map<String, String>{
            'Mail Information' => 'I would like program information to be mailed to me',
            'Receive Text Messages' => 'I would like to receive text messages'
        };
        for (rfiQuestionCatalog.Question question : rfiQuestionCatalog.questions()) {
            if (question.isAlias == true) {
                System.assert(fullNameFor.containsKey(question.name), 'Tell this test what ' + question.name + ' is short for');
                System.assertEquals(rfiQuestionCatalog.targetFieldFor(fullNameFor.get(question.name)), question.targetField,
                        question.name + ' must save where ' + fullNameFor.get(question.name) + ' saves');
            }
        }
    }

    @IsTest
    static void catalog_everyTargetIsARealWritableFieldOnInteraction_TEST() {
        Map<String, Schema.SObjectField> fields = interactionFields();
        Set<Schema.DisplayType> writableTypes = new Set<Schema.DisplayType>{
            Schema.DisplayType.STRING, Schema.DisplayType.TEXTAREA, Schema.DisplayType.EMAIL, Schema.DisplayType.PHONE,
            Schema.DisplayType.DATE, Schema.DisplayType.BOOLEAN, Schema.DisplayType.PICKLIST,
            Schema.DisplayType.MULTIPICKLIST, Schema.DisplayType.REFERENCE
        };
        for (rfiQuestionCatalog.Question question : rfiQuestionCatalog.questions()) {
            Schema.SObjectField field = fields.get(question.targetField.toLowerCase());
            System.assertNotEquals(null, field, '"' + question.name + '" points at ' + question.targetField + ', which is not a field on Interaction__c');
            Schema.DescribeFieldResult describe = field.getDescribe();
            System.assertEquals(false, describe.isCalculated(), question.targetField + ' is a formula field');
            System.assertEquals(false, describe.isAutoNumber(), question.targetField + ' is an auto number field');
            System.assert(writableTypes.contains(describe.getType()), question.targetField + ' has type ' + describe.getType() + ', which the form cannot write');
        }
    }

    @IsTest
    static void catalog_everyFilterNamesARealControllerFieldAndSaysTruthfullyWhetherItSaves_TEST() {
        Map<String, Schema.SObjectField> controllerFields = Schema.SObjectType.RFI_Controller__c.fields.getMap();
        Map<String, Schema.SObjectField> fields = interactionFields();
        for (rfiQuestionCatalog.Filter filter : rfiQuestionCatalog.filters()) {
            System.assert(controllerFields.containsKey(filter.controllerField.toLowerCase()),
                    filter.controllerField + ' is not a field on RFI_Controller__c');
            Boolean exists = fields.containsKey(filter.targetField.toLowerCase());
            System.assertEquals(exists, filter.storesAnswer == true, filter.targetField + (exists
                    ? ' exists on Interaction__c, so the catalog must say the filter stores its answer'
                    : ' does not exist on Interaction__c, so the catalog must say the filter only narrows the program list'));
            if (exists) {
                Schema.DescribeFieldResult describe = fields.get(filter.targetField.toLowerCase()).getDescribe();
                System.assertEquals(false, describe.isCalculated(), filter.targetField + ' is a formula field');
                System.assert(describe.getType() == Schema.DisplayType.PICKLIST || describe.getType() == Schema.DisplayType.REFERENCE
                        || describe.getType() == Schema.DisplayType.STRING, filter.targetField + ' has type ' + describe.getType());
            }
        }
    }

    @IsTest
    static void catalog_correctedLegacyNamesAllPointAtRealFields_TEST() {
        Map<String, Schema.SObjectField> fields = interactionFields();
        for (String oldName : rfiQuestionCatalog.correctedLegacyApiNames.keySet()) {
            String corrected = rfiQuestionCatalog.correctedLegacyApiNames.get(oldName);
            System.assert(fields.containsKey(corrected.toLowerCase()), oldName + ' is corrected to ' + corrected + ', which is not a field on Interaction__c');
        }
        System.assertEquals('Contact_Title__c', rfiQuestionCatalog.correctStoredApiName('Title__c'));
        System.assertEquals('Some_Other__c', rfiQuestionCatalog.correctStoredApiName('Some_Other__c'));
        System.assertEquals(null, rfiQuestionCatalog.correctStoredApiName(null));
    }

    // ---------- the forms built from the catalog ----------

    @IsTest
    static void unifiedForm_everyCatalogQuestionSavesToItsCatalogFieldWithACompatibleType_TEST() {
        List<String> allNames = new List<String>();
        for (rfiQuestionCatalog.Question question : rfiQuestionCatalog.questions()) {
            allNames.add(question.name);
        }
        rfiFormController.interactionRFIFields form = unifiedForm(allNames);
        assertQuestionsSaveToUsableFields(form, 'Newer form');
        Set<String> savedTo = new Set<String>();
        for (rfiFormController.rfiField question : form.rfiFieldList) {
            if (String.isNotBlank(question.fieldInteractionAPIName)) {
                savedTo.add(question.fieldInteractionAPIName);
            }
        }
        for (rfiQuestionCatalog.Question question : rfiQuestionCatalog.questions()) {
            System.assert(savedTo.contains(question.targetField), '"' + question.name + '" should save to ' + question.targetField
                    + ' on the newer form but the form saves to ' + savedTo);
        }
    }

    @IsTest
    static void legacyForm_everyOfferedQuestionSavesToItsCatalogFieldWithACompatibleType_TEST() {
        List<String> names = usableOfferedQuestionNames();
        rfiFormController.interactionRFIFields form = legacyForm(offeredNamesAsSaved());
        assertQuestionsSaveToUsableFields(form, 'Older form');
        Set<String> savedTo = new Set<String>();
        for (rfiFormController.rfiField question : form.rfiFieldList) {
            if (String.isNotBlank(question.fieldInteractionAPIName)) {
                savedTo.add(question.fieldInteractionAPIName);
            }
        }
        for (String name : names) {
            String target = rfiQuestionCatalog.targetFieldFor(name);
            System.assert(savedTo.contains(target), '"' + name + '" should save to ' + target + ' on the older form but the form saves to ' + savedTo);
        }
    }

    @IsTest
    static void olderAndNewerForms_giveTheSameFieldsAndControlsForTheSameQuestions_TEST() {
        List<String> names = usableOfferedQuestionNames();
        List<String> older = signatures(legacyForm(offeredNamesAsSaved()));
        List<String> newer = signatures(unifiedForm(names));
        List<String> onlyOlder = differenceBetween(older, newer);
        List<String> onlyNewer = differenceBetween(newer, older);
        System.assertEquals(0, onlyOlder.size() + onlyNewer.size(),
                'The older and newer forms must agree. Only on the older form: ' + onlyOlder + '. Only on the newer form: ' + onlyNewer);
    }

    /** The lines in first that are not matched by a line in second (each line matches once). */
    private static List<String> differenceBetween(List<String> first, List<String> second) {
        List<String> remaining = new List<String>(second);
        List<String> unmatched = new List<String>();
        for (String line : first) {
            Integer position = remaining.indexOf(line);
            if (position >= 0) {
                remaining.remove(position);
            } else {
                unmatched.add(line);
            }
        }
        return unmatched;
    }

    /** One line per field the form draws: where it saves and how it is drawn. Labels are allowed to differ. */
    private static List<String> signatures(rfiFormController.interactionRFIFields form) {
        List<String> lines = new List<String>();
        for (rfiFormController.rfiField question : form.rfiFieldList) {
            lines.add(question.fieldInteractionAPIName + ' | ' + describeControl(question)
                    + (question.showDependentField == true ? ' +dependent' : ''));
        }
        lines.sort();
        return lines;
    }

    // ---------- dates ----------

    @IsTest
    static void everyQuestionThatSavesToADateField_isDrawnAsADatePicker_onBothForms_TEST() {
        rfiFormController.interactionRFIFields older = legacyForm(offeredNamesAsSaved());
        rfiFormController.interactionRFIFields newer = unifiedForm(usableOfferedQuestionNames());
        Integer dateQuestions = 0;
        for (rfiFormController.interactionRFIFields form : new List<rfiFormController.interactionRFIFields>{ older, newer }) {
            for (rfiFormController.rfiField question : form.rfiFieldList) {
                if (String.isBlank(question.fieldInteractionAPIName)) {
                    continue;
                }
                Schema.SObjectField field = interactionFields().get(question.fieldInteractionAPIName.toLowerCase());
                if (field != null && field.getDescribe().getType() == Schema.DisplayType.DATE) {
                    System.assertEquals('date', question.inputType, '"' + question.fieldLabel + '" saves to a Date field and must be a date picker; typed text such as 01/15/2000 makes the server reject the whole submission');
                    dateQuestions++;
                }
            }
        }
        System.assertEquals(2, dateQuestions, 'Birthdate is on both forms');
    }

    @IsTest
    static void useDatePickerForDateFields_leavesOtherQuestionsAsTextBoxes_TEST() {
        rfiFormController.rfiField name = new rfiFormController.rfiField();
        name.fieldInteractionAPIName = 'First_Name__c';
        rfiFormController.rfiField noTarget = new rfiFormController.rfiField();
        rfiFormController.useDatePickerForDateFields(new List<rfiFormController.rfiField>{ name, noTarget, null });
        System.assertEquals(null, name.inputType);
        System.assertEquals(null, noTarget.inputType);
    }

    // ---------- the fields the object requires ----------

    @IsTest
    static void newerForm_alwaysAsksForFirstAndLastName_evenWhenTheSavedListLacksThem_TEST() {
        rfiFormController.interactionRFIFields form = unifiedForm(new List<String>{ 'Email' });
        System.assertEquals('First_Name__c', form.rfiFieldList[0].fieldInteractionAPIName);
        System.assertEquals('Last_Name__c', form.rfiFieldList[1].fieldInteractionAPIName);
        System.assertEquals(true, form.rfiFieldList[0].isRequired);
        System.assertEquals(true, form.rfiFieldList[1].isRequired);
        System.assertEquals('Email__c', form.rfiFieldList[2].fieldInteractionAPIName, 'The admin\'s questions follow');
    }

    @IsTest
    static void newerForm_withAnEmptySavedList_stillLoadsWithFirstAndLastName_TEST() {
        rfiFormController.interactionRFIFields form = unifiedForm(new List<String>());
        System.assertEquals(2, form.rfiFieldList.size());
        System.assertEquals('First_Name__c', form.rfiFieldList[0].fieldInteractionAPIName);
        System.assertEquals('Last_Name__c', form.rfiFieldList[1].fieldInteractionAPIName);
    }

    @IsTest
    static void newerForm_doesNotAddNamesThatAreAlreadyThere_TEST() {
        rfiFormController.interactionRFIFields form = unifiedForm(new List<String>{ 'Last Name', 'First Name', 'Email' });
        Integer firstNames = 0;
        Integer lastNames = 0;
        for (rfiFormController.rfiField question : form.rfiFieldList) {
            firstNames += question.fieldInteractionAPIName == 'First_Name__c' ? 1 : 0;
            lastNames += question.fieldInteractionAPIName == 'Last_Name__c' ? 1 : 0;
        }
        System.assertEquals(1, firstNames);
        System.assertEquals(1, lastNames);
        System.assertEquals('Last_Name__c', form.rfiFieldList[0].fieldInteractionAPIName, 'The admin\'s order is kept');
    }

    // ---------- fill in every question and read back what was saved ----------

    /** A valid answer for a field, chosen from the field's own type so it never drifts from the schema. */
    private static Object sampleAnswerFor(Schema.DescribeFieldResult describe, Map<Schema.SObjectType, Id> referenceTargets) {
        Schema.DisplayType fieldType = describe.getType();
        if (fieldType == Schema.DisplayType.EMAIL) {
            return 'catalog.sample@example.invalid';
        }
        if (fieldType == Schema.DisplayType.PHONE) {
            return '6515550100';
        }
        if (fieldType == Schema.DisplayType.DATE) {
            return Date.newInstance(2000, 1, 15);
        }
        if (fieldType == Schema.DisplayType.BOOLEAN) {
            return true;
        }
        if (fieldType == Schema.DisplayType.PICKLIST || fieldType == Schema.DisplayType.MULTIPICKLIST) {
            for (Schema.PicklistEntry entry : describe.getPicklistValues()) {
                if (entry.isActive()) {
                    return entry.getValue();
                }
            }
            return null;
        }
        if (fieldType == Schema.DisplayType.REFERENCE) {
            return referenceTargets.get(describe.getReferenceTo()[0]);
        }
        String text = 'Sample_for_' + describe.getName();
        return text.left(describe.getLength() > 0 ? Math.min(describe.getLength(), 40) : 40);
    }

    @IsTest
    static void fillingInEveryQuestion_savesEveryAnswerToItsCatalogField_TEST() {
        // Real records for the lookups the questions point at
        Account school = new Account(Name = 'Catalog Sample School');
        insert school;
        Academic_Term__c term = new Academic_Term__c(Name = 'Catalog Term', Term_Start_Date__c = Date.today().addMonths(8));
        insert term;
        Program__c major = new Program__c(Name = 'Catalog Major', Active__c = true,
                RecordTypeId = Schema.SObjectType.Program__c.getRecordTypeInfosByDeveloperName().get('Recruitment_Program').getRecordTypeId());
        insert major;
        Map<Schema.SObjectType, Id> referenceTargets = new Map<Schema.SObjectType, Id>{
            Schema.SObjectType.Account.getSObjectType() => school.Id,
            Schema.SObjectType.Academic_Term__c.getSObjectType() => term.Id,
            Schema.SObjectType.Program__c.getSObjectType() => major.Id
        };

        // Every question the form can show, on the newer form, with the stored field name left blank
        List<String> questionNames = new List<String>();
        for (rfiQuestionCatalog.Question question : rfiQuestionCatalog.questions()) {
            if (question.isAlias != true && question.isComposite != true) {
                questionNames.add(question.name);
            }
        }
        List<Map<String, Object>> questions = new List<Map<String, Object>>();
        Integer position = 0;
        for (String questionName : questionNames) {
            questions.add(new Map<String, Object>{ 'id' => position, 'type' => 'preconfigured', 'fieldName' => questionName,
                'questionLabel' => questionName, 'fieldInteractionAPIName' => '', 'isRequired' => false });
            position++;
        }
        String controllerName = insertControllerAndGetName(new RFI_Controller__c(
                Academic_Level__c = 'U', Fields_to_Display__c = firstOffered(),
                Unified_Questions__c = JSON.serialize(questions), Redirect_URL__c = 'https://catalog-fill.example.com'));

        // What a visitor would send: one answer per distinct target field
        Map<String, Schema.SObjectField> fields = interactionFields();
        Interaction__c answers = new Interaction__c();
        Map<String, Object> sent = new Map<String, Object>();
        for (String questionName : questionNames) {
            String target = rfiQuestionCatalog.targetFieldFor(questionName);
            if (sent.containsKey(target)) {
                continue;
            }
            Object answer = sampleAnswerFor(fields.get(target.toLowerCase()).getDescribe(), referenceTargets);
            System.assertNotEquals(null, answer, 'No sample answer could be made for ' + target + ' (' + questionName + ')');
            answers.put(target, answer);
            sent.put(target, answer);
        }
        answers.First_Name__c = 'Catalog';
        answers.Last_Name__c = 'Roundtrip';
        sent.put('First_Name__c', 'Catalog');
        sent.put('Last_Name__c', 'Roundtrip');

        Test.startTest();
        Id savedId = rfiFormController.submitRfiForm(answers, controllerName);
        Test.stopTest();

        System.assertNotEquals(null, savedId, 'The submission was not saved: ' + [SELECT hed__Full_Message__c FROM hed__Error__c]);
        List<String> targets = new List<String>(sent.keySet());
        targets.sort();
        Interaction__c saved = Database.query('SELECT ' + String.join(targets, ', ') + ' FROM Interaction__c WHERE Id = :savedId');
        for (String target : targets) {
            System.assertEquals(String.valueOf(sent.get(target)), String.valueOf(saved.get(target)),
                    target + ' was sent as ' + sent.get(target) + ' but saved as ' + saved.get(target));
        }
        System.assertEquals(0, [SELECT COUNT() FROM hed__Error__c], 'A form filled in correctly must not log a problem: ' + [SELECT hed__Full_Message__c FROM hed__Error__c]);
    }
}
