@IsTest
private class rfiSubmissionProcessor_TEST {

    // ---------- helpers ----------

    private static Id academicProgramRecordType() {
        return Schema.SObjectType.Program__c.getRecordTypeInfosByDeveloperName().get('Academic_Program').getRecordTypeId();
    }

    private static Id recruitmentProgramRecordType() {
        return Schema.SObjectType.Program__c.getRecordTypeInfosByDeveloperName().get('Recruitment_Program').getRecordTypeId();
    }

    /**
     * Program_Major_Concentration__c is a formula: Banner_Program_Code__c, then "|" and Major_Code__c,
     * then "|" and Concentration_Code__c. The code is split into those three fields so the formula
     * produces it.
     */
    private static Program__c insertAcademicProgram(String name, String code, String associatedSchools, Id recruitmentProgramId) {
        List<String> parts = code.split('\\|');
        Program__c program = new Program__c(
                Name = name,
                RecordTypeId = academicProgramRecordType(),
                Banner_Program_Code__c = parts[0],
                Major_Code__c = parts.size() > 1 ? parts[1] : null,
                Concentration_Code__c = parts.size() > 2 ? parts[2] : null,
                Active__c = true,
                Associated_Schools__c = associatedSchools,
                Recruitment_Program__c = recruitmentProgramId
        );
        insert program;
        return program;
    }

    private static Program__c insertMajor(String name) {
        Program__c major = new Program__c(
                Name = name,
                RecordTypeId = recruitmentProgramRecordType(),
                Program_Name_on_Application__c = name,
                Active__c = true
        );
        insert major;
        return major;
    }

    private static RFI_Controller__c undergraduateController(String schoolCollege) {
        return new RFI_Controller__c(Academic_Level__c = 'U', School_College__c = schoolCollege);
    }

    /** A school value that both the Program and the Interaction multi-select accept, or null if none. */
    private static String sharedSchoolValue() {
        Set<String> interactionValues = new Set<String>();
        for (Schema.PicklistEntry entry : Interaction__c.Recruitment_Program_Associated_Schools__c.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                interactionValues.add(entry.getValue());
            }
        }
        for (Schema.PicklistEntry entry : Program__c.Associated_Schools__c.getDescribe().getPicklistValues()) {
            if (entry.isActive() && interactionValues.contains(entry.getValue())) {
                return entry.getValue();
            }
        }
        return null;
    }

    private static String firstActivePicklistValue(Schema.DescribeFieldResult fieldDescribe) {
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            if (entry.isActive()) {
                return entry.getValue();
            }
        }
        return null;
    }

    // ---------- defaults (ECRMSF-6044) ----------

    @IsTest
    static void defaults_setSourceStageDateAndRecordType_andOverrideTheBrowser_TEST() {
        Interaction__c record = new Interaction__c(
                Last_Name__c = 'Defaults',
                Interaction_Source__c = 'Application',
                Opportunity_Stage__c = 'Enrolled',
                Date_Inquiry__c = Date.today().addDays(-30));
        List<String> warnings = rfiSubmissionProcessor.apply(record, null);
        System.assertEquals('Webform', record.Interaction_Source__c, 'Source must be Webform, not what the browser sent');
        System.assertEquals('Inquiry', record.Opportunity_Stage__c);
        System.assertEquals(Date.today(), record.Date_Inquiry__c);
        List<RecordType> inquiryTypes = [SELECT Id FROM RecordType WHERE SobjectType = 'Opportunity' AND DeveloperName = 'Inquiry_Opportunity'];
        System.assertEquals(1, inquiryTypes.size(), 'The Inquiry Opportunity record type is part of the org');
        System.assertEquals(String.valueOf(inquiryTypes[0].Id), record.Opportunity_Record_Type__c);
        System.assertEquals(0, warnings.size(), 'No warnings expected: ' + String.join(warnings, ' | '));
    }

    @IsTest
    static void apply_withNullRecord_doesNothing_TEST() {
        System.assertEquals(0, rfiSubmissionProcessor.apply(null, null).size());
    }

    // ---------- term ----------

    @IsTest
    static void term_choosesTheTermWhoseKeyContainsA_TEST() {
        Account holder = new Account(Name = 'Term holder');
        insert holder;
        // The wrong Term is inserted first, so a lookup that ignores the key would pick it.
        hed__Term__c wrongTerm = new hed__Term__c(Name = 'Fall 2031', hed__Account__c = holder.Id, Term_Key__c = '203140');
        insert wrongTerm;
        hed__Term__c rightTerm = new hed__Term__c(Name = 'Fall 2031', hed__Account__c = holder.Id, Term_Key__c = '203140a');
        insert rightTerm;
        Academic_Term__c academicTerm = new Academic_Term__c(Name = 'Fall 2031', Term_Start_Date__c = Date.today().addYears(5));
        insert academicTerm;

        Interaction__c record = new Interaction__c(Last_Name__c = 'Term', Intended_Start_Term__c = academicTerm.Id);
        rfiSubmissionProcessor.apply(record, null);
        System.assertEquals(rightTerm.Id, record.Term__c, 'Term must be the one whose key contains the letter a');
    }

    @IsTest
    static void term_isLeftBlankWhenNoStartTermWasChosen_TEST() {
        Interaction__c record = new Interaction__c(Last_Name__c = 'NoTerm');
        rfiSubmissionProcessor.apply(record, null);
        System.assertEquals(null, record.Term__c);
    }

    // ---------- programs (ECRMSF-6045) ----------

    @IsTest
    static void undergraduatePrograms_followTheOldFormRules_TEST() {
        Program__c firstYear = insertAcademicProgram('Undergraduate First-Year', 'AS_UN_BA', null, null);
        Program__c transfer = insertAcademicProgram('Undergraduate Transfer', 'AS_UN_BA', null, null);
        Program__c transferInternational = insertAcademicProgram('Undergraduate Transfer (INTL)', 'AS_UN_BA', null, null);
        Program__c dougherty = insertAcademicProgram('Dougherty Family College', 'DC_UG_AA|LIBA', null, null);

        Interaction__c firstYearRecord = new Interaction__c(Last_Name__c = 'A', Admit_Type__c = 'First-Year', Citizenship__c = 'U.S. Citizen');
        rfiSubmissionProcessor.apply(firstYearRecord, undergraduateController('Undergraduate'));
        System.assertEquals(firstYear.Id, firstYearRecord.Academic_Program__c, 'First-year');
        System.assertEquals(firstYear.Id, firstYearRecord.Recruitment_Program__c);

        Interaction__c transferRecord = new Interaction__c(Last_Name__c = 'B', Admit_Type__c = 'Transfer', Citizenship__c = 'U.S. Citizen');
        rfiSubmissionProcessor.apply(transferRecord, undergraduateController('Undergraduate'));
        System.assertEquals(transfer.Id, transferRecord.Academic_Program__c, 'Transfer');

        Interaction__c internationalRecord = new Interaction__c(Last_Name__c = 'C', Admit_Type__c = 'Transfer', Citizenship__c = 'International');
        rfiSubmissionProcessor.apply(internationalRecord, undergraduateController('Undergraduate'));
        System.assertEquals(transferInternational.Id, internationalRecord.Academic_Program__c, 'International transfer');

        Interaction__c doughertyRecord = new Interaction__c(Last_Name__c = 'D', Admit_Type__c = 'First-Year');
        rfiSubmissionProcessor.apply(doughertyRecord, undergraduateController('Dougherty Family College'));
        System.assertEquals(dougherty.Id, doughertyRecord.Academic_Program__c, 'Dougherty Family College');

        Interaction__c doughertyTransferRecord = new Interaction__c(Last_Name__c = 'E', Admit_Type__c = 'Transfer');
        rfiSubmissionProcessor.apply(doughertyTransferRecord, undergraduateController('Dougherty Family College'));
        System.assertEquals(transfer.Id, doughertyTransferRecord.Academic_Program__c, 'Transfer is checked before Dougherty, as in the old form');
    }

    @IsTest
    static void undergraduateRule_winsOverTheMajor_andKeepsTheMajor_TEST() {
        Program__c major = insertMajor('Biology');
        insertAcademicProgram('Biology Academic', 'BIO_TEST', null, major.Id);
        Program__c firstYear = insertAcademicProgram('Undergraduate First-Year', 'AS_UN_BA', null, null);
        Interaction__c record = new Interaction__c(Last_Name__c = 'Both', Admit_Type__c = 'First-Year', Major_Program_1__c = major.Id);
        rfiSubmissionProcessor.apply(record, undergraduateController('Undergraduate'));
        System.assertEquals(firstYear.Id, record.Academic_Program__c, 'The rule program wins');
        System.assertEquals(major.Id, record.Major_Program_1__c, 'The chosen major is kept');
    }

    @IsTest
    static void undergraduateWithoutRuleProgram_fallsBackToTheMajorsProgram_TEST() {
        Program__c major = insertMajor('Chemistry');
        Program__c majorProgram = insertAcademicProgram('Chemistry Academic', 'CHEM_TEST', null, major.Id);
        Interaction__c record = new Interaction__c(Last_Name__c = 'Fallback', Admit_Type__c = 'First-Year', Major_Program_1__c = major.Id);
        rfiSubmissionProcessor.apply(record, undergraduateController('Undergraduate'));
        System.assertEquals(majorProgram.Id, record.Academic_Program__c);
    }

    @IsTest
    static void graduateProgram_followsTheMajor_andIgnoresUndergraduateRules_TEST() {
        insertAcademicProgram('Undergraduate First-Year', 'AS_UN_BA', null, null);
        Program__c major = insertMajor('MBA');
        String sharedSchool = sharedSchoolValue();
        Program__c majorProgram = insertAcademicProgram('MBA Academic', 'MBA_TEST', sharedSchool, major.Id);
        Interaction__c record = new Interaction__c(Last_Name__c = 'Graduate', Major_Program_1__c = major.Id);
        rfiSubmissionProcessor.apply(record, new RFI_Controller__c(Academic_Level__c = 'G'));
        System.assertEquals(majorProgram.Id, record.Academic_Program__c);
        System.assertEquals(majorProgram.Id, record.Recruitment_Program__c);
        if (sharedSchool != null) {
            System.assertEquals(sharedSchool, record.Recruitment_Program_Associated_Schools__c, 'Schools come from the chosen program');
        }
    }

    @IsTest
    static void noProgramFound_leavesProgramsBlank_andDoesNotFail_TEST() {
        Interaction__c record = new Interaction__c(Last_Name__c = 'NoProgram', Admit_Type__c = 'Transfer');
        List<String> warnings = rfiSubmissionProcessor.apply(record, undergraduateController('Undergraduate'));
        System.assertEquals(null, record.Academic_Program__c);
        System.assertEquals(0, warnings.size(), String.join(warnings, ' | '));
    }

    @IsTest
    static void programRuleChoice_isPureLogic_TEST() {
        System.assertEquals('Undergraduate Transfer (INTL)',
                rfiSubmissionProcessor.chooseUndergraduateProgramRule('Transfer', 'International', 'Undergraduate').programName);
        System.assertEquals('DC_UG_AA|LIBA',
                rfiSubmissionProcessor.chooseUndergraduateProgramRule('First-Year', null, 'dougherty family college').programCode);
        System.assertEquals('Undergraduate First-Year',
                rfiSubmissionProcessor.chooseUndergraduateProgramRule(null, null, null).programName);
    }

    // ---------- presets (ECRMSF-6046) ----------

    @IsTest
    static void presets_fillBlankFields_andTranslateOldLeadNames_TEST() {
        String scholarship = firstActivePicklistValue(Interaction__c.Scholarship_of_Interest__c.getDescribe());
        String leadSource = firstActivePicklistValue(Interaction__c.Lead_Source__c.getDescribe());
        System.assertNotEquals(null, scholarship, 'The org has scholarship values');
        Interaction__c record = new Interaction__c(Last_Name__c = 'Preset');
        List<String> warnings = new List<String>();
        rfiSubmissionProcessor.applyPresetValues(record, new List<rfiSubmissionProcessor.PresetValue>{
                new rfiSubmissionProcessor.PresetValue('Scholarship_of_Interest__c', scholarship),
                new rfiSubmissionProcessor.PresetValue('LeadSource', leadSource)
        }, warnings);
        System.assertEquals(scholarship, record.Scholarship_of_Interest__c);
        System.assertEquals(leadSource, record.Lead_Source__c, 'LeadSource is translated to Lead_Source__c');
        System.assertEquals(0, warnings.size(), String.join(warnings, ' | '));
    }

    @IsTest
    static void presets_neverOverwriteTheVisitorsAnswer_TEST() {
        List<String> scholarshipValues = new List<String>();
        for (Schema.PicklistEntry entry : Interaction__c.Scholarship_of_Interest__c.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                scholarshipValues.add(entry.getValue());
            }
        }
        System.assert(scholarshipValues.size() >= 2, 'The test needs two scholarship values');
        Interaction__c record = new Interaction__c(Last_Name__c = 'Answered', Scholarship_of_Interest__c = scholarshipValues[0]);
        rfiSubmissionProcessor.applyPresetValues(record, new List<rfiSubmissionProcessor.PresetValue>{
                new rfiSubmissionProcessor.PresetValue('Scholarship_of_Interest__c', scholarshipValues[1])
        }, new List<String>());
        System.assertEquals(scholarshipValues[0], record.Scholarship_of_Interest__c);
    }

    @IsTest
    static void presets_reportProblemsAsWarnings_andKeepGoing_TEST() {
        String leadSource = firstActivePicklistValue(Interaction__c.Lead_Source__c.getDescribe());
        Interaction__c record = new Interaction__c(Last_Name__c = 'Warnings');
        List<String> warnings = new List<String>();
        rfiSubmissionProcessor.applyPresetValues(record, new List<rfiSubmissionProcessor.PresetValue>{
                new rfiSubmissionProcessor.PresetValue('Not_A_Field__c', 'x'),
                new rfiSubmissionProcessor.PresetValue('Lead_Source__c', 'Not a real source'),
                new rfiSubmissionProcessor.PresetValue('Birthdate__c', 'not a date'),
                new rfiSubmissionProcessor.PresetValue('', 'x'),
                new rfiSubmissionProcessor.PresetValue('LeadSource', leadSource)
        }, warnings);
        System.assertEquals(3, warnings.size(), 'One warning each for the unknown field, bad picklist value and bad date: ' + String.join(warnings, ' | '));
        System.assertEquals(leadSource, record.Lead_Source__c, 'The valid preset after the bad ones is still applied');
    }

    @IsTest
    static void presets_withUnknownController_areEmpty_TEST() {
        Interaction__c record = new Interaction__c(Last_Name__c = 'NoController');
        List<String> warnings = rfiSubmissionProcessor.apply(record, new RFI_Controller__c(Academic_Level__c = 'G'));
        System.assertEquals(null, record.Scholarship_of_Interest__c);
        System.assertEquals(0, warnings.size(), String.join(warnings, ' | '));
    }

    // ---------- picklist helpers ----------

    @IsTest
    static void picklistHelpers_respectRestrictedAndUnrestrictedFields_TEST() {
        System.assertEquals(null, rfiSubmissionProcessor.resolvePicklistValue('Lead_Source__c', 'Not a real source'),
                'Restricted picklists reject unknown values');
        System.assertEquals('Anything', rfiSubmissionProcessor.resolvePicklistValue('Opportunity_Stage__c', ' Anything '),
                'Unrestricted picklists keep the value');
        String realValue = firstActivePicklistValue(Interaction__c.Lead_Source__c.getDescribe());
        System.assertEquals(realValue, rfiSubmissionProcessor.findPicklistValue('Lead_Source__c', realValue.toUpperCase()), 'Matching ignores case');
        System.assertEquals(null, rfiSubmissionProcessor.filterMultiPicklist('Scholarship_of_Interest__c', 'Nope;Also nope'));
        String scholarship = firstActivePicklistValue(Interaction__c.Scholarship_of_Interest__c.getDescribe());
        System.assertEquals(scholarship, rfiSubmissionProcessor.filterMultiPicklist('Scholarship_of_Interest__c', scholarship + ';Nope;' + scholarship));
    }

    // ---------- state and country (ECRMSF-6050) ----------

    @IsTest
    static void stateAndCountry_followTheOrgsOwnLists_TEST() {
        Schema.PicklistEntry countryEntry;
        for (Schema.PicklistEntry entry : Interaction__c.Country__c.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                countryEntry = entry;
                break;
            }
        }
        Schema.PicklistEntry stateEntry;
        for (Schema.PicklistEntry entry : Interaction__c.State__c.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                stateEntry = entry;
                break;
            }
        }
        // The form sends labels; the org's lists decide the value saved
        Interaction__c record = new Interaction__c(
                Last_Name__c = 'Geography',
                Mailing_Country__c = countryEntry.getLabel(),
                Mailing_State__c = stateEntry.getLabel());
        rfiSubmissionProcessor.apply(record, null);
        System.assertEquals(countryEntry.getValue(), record.Country__c);
        System.assertEquals(stateEntry.getValue(), record.State__c);
    }

    @IsTest
    static void stateAndCountry_unknownValuesAreLeftOut_TEST() {
        Interaction__c record = new Interaction__c(Last_Name__c = 'Unknown', Mailing_Country__c = 'Atlantis', Mailing_State__c = 'Nowhere');
        List<String> warnings = rfiSubmissionProcessor.apply(record, null);
        System.assertEquals(null, record.Country__c, 'An unknown country must not break the restricted Country field');
        System.assertEquals(null, record.State__c);
        System.assertEquals(0, warnings.size(), String.join(warnings, ' | '));
    }

    // ---------- school ----------

    @IsTest
    static void school_isFilledFromTheMajorsSchool_whenTheFormHasNone_TEST() {
        String schoolName = firstActivePicklistValue(Account.School_College_Name__c.getDescribe());
        System.assertNotEquals(null, schoolName, 'The org has school names');
        Id departmentType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('University_Department').getRecordTypeId();
        Account school = new Account(Name = 'Test School Account', RecordTypeId = departmentType,
                School_College_Name__c = schoolName, Banner_Key__c = 'STVCOLL-TEST');
        insert school;
        Program__c major = new Program__c(Name = 'School Major', RecordTypeId = recruitmentProgramRecordType(), Active__c = true,
                Primary_School_College_for_Assignment__c = schoolName);
        insert major;
        Interaction__c record = new Interaction__c(Last_Name__c = 'School', Major_Program_1__c = major.Id);
        rfiSubmissionProcessor.apply(record, new RFI_Controller__c(Academic_Level__c = 'G'));
        System.assertEquals(school.Id, record.St_Thomas_College_School__c);
    }

    @IsTest
    static void school_neverOverwritesAnAnswer_TEST() {
        String schoolName = firstActivePicklistValue(Account.School_College_Name__c.getDescribe());
        Id departmentType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('University_Department').getRecordTypeId();
        // A school that WOULD be chosen from the controller if the visitor had not answered
        Account wouldBeChosen = new Account(Name = 'Controller School', RecordTypeId = departmentType,
                School_College_Name__c = schoolName, Banner_Key__c = 'STVCOLL-GUARD');
        insert wouldBeChosen;
        Account chosen = new Account(Name = 'Visitor Chosen School', RecordTypeId = departmentType);
        insert chosen;
        Interaction__c record = new Interaction__c(Last_Name__c = 'Chosen', St_Thomas_College_School__c = chosen.Id);
        rfiSubmissionProcessor.apply(record, undergraduateController(schoolName));
        System.assertEquals(chosen.Id, record.St_Thomas_College_School__c, 'The visitor answer must stay');
    }


    // ---------- lookups the user cannot see ----------

    @IsTest
    static void dropLookupsTheUserCannotSee_keepsAVisibleLookup_TEST() {
        Program__c recruitment = insertMajor('Visible Major');
        Interaction__c record = new Interaction__c(Last_Name__c = 'Kept', Recruitment_Program__c = recruitment.Id);
        List<String> warnings = new List<String>();
        rfiSubmissionProcessor.dropLookupsTheUserCannotSee(record, warnings);
        System.assertEquals(recruitment.Id, record.Recruitment_Program__c, 'A record the user can see stays');
        System.assertEquals(0, warnings.size(), 'Nothing to report: ' + warnings);
    }

    @IsTest
    static void dropLookupsTheUserCannotSee_clearsAHiddenLookupAndKeepsTheRest_TEST() {
        Program__c recruitment = insertMajor('Hidden Major');
        Interaction__c record = new Interaction__c(Last_Name__c = 'Kept', Recruitment_Program__c = recruitment.Id);
        rfiSubmissionProcessor.hiddenLookupIdsForTest = new Set<Id>{ recruitment.Id };
        List<String> warnings = new List<String>();
        rfiSubmissionProcessor.dropLookupsTheUserCannotSee(record, warnings);
        System.assertEquals(null, record.Recruitment_Program__c, 'A record the user cannot see is cleared so the insert cannot fail');
        System.assertEquals('Kept', record.Last_Name__c, 'Other answers are untouched');
        System.assertEquals(1, warnings.size());
        System.assert(warnings[0].contains('Recruitment_Program__c'), warnings[0]);
    }


    // ---------- state code from the form ----------

    @IsTest
    static void state_aCodeFromTheFormIsKept_TEST() {
        Schema.PicklistEntry stateEntry = null;
        for (Schema.PicklistEntry entry : Interaction__c.State__c.getDescribe().getPicklistValues()) {
            if (entry.isActive()) { stateEntry = entry; break; }
        }
        Interaction__c record = new Interaction__c(Last_Name__c = 'Code', State__c = stateEntry.getValue(), Mailing_State__c = 'Anything');
        rfiSubmissionProcessor.apply(record, null);
        System.assertEquals(stateEntry.getValue(), record.State__c);
    }

    @IsTest
    static void state_anUnknownCodeIsDroppedSoTheRestrictedPicklistCannotRejectTheRfi_TEST() {
        Interaction__c record = new Interaction__c(Last_Name__c = 'Code', State__c = 'ZZ-not-a-state');
        rfiSubmissionProcessor.apply(record, null);
        System.assertEquals(null, record.State__c);
    }

    @IsTest
    static void dropLookupsTheUserCannotSee_ignoresABlankLookupValue_TEST() {
        Interaction__c record = new Interaction__c(Last_Name__c = 'Blank');
        record.put('Nominator_Contact__c', '');
        List<String> warnings = new List<String>();
        rfiSubmissionProcessor.dropLookupsTheUserCannotSee(record, warnings);
        System.assertEquals(0, warnings.size(), 'A blank value is not a hidden record: ' + warnings);
    }
}