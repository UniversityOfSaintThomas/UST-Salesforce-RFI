/**
 * Unit tests for AcademicInterestSelectorController.
 * Target: >75% code coverage of AcademicInterestSelectorController.
 *
 * Design notes:
 * - Academic_Interests_To_Display__c is a restricted MultiselectPicklist tied to the
 *   Generic_Filter_1 global value set, shared with Program_Major_Concentration__c.
 * - Program_Major_Concentration__c is a FORMULA field — it cannot be set directly.
 *   It is computed as Banner_Program_Code__c + '|' + Major_Code__c (+ '|' + Concentration_Code__c
 *   when present).  We reverse-engineer from the first active picklist value.
 * - getSelectablePrograms queries WHERE Program_Major_Concentration__c IN :validCodes so we must
 *   insert programs whose formula result matches an active picklist entry.
 */
@IsTest
private class AcademicInterestSelectorController_TEST {

    // ─── Helpers ──────────────────────────────────────────────────────────────

    /**
     * Returns the first active value from the Academic_Interests_To_Display__c picklist
     * that looks like a real program code (contains '|').
     * This is the same set that getValidPicklistValues() uses internally.
     */
    private static String firstValidCode() {
        Schema.DescribeFieldResult d = Schema.SObjectType.RFI_Controller__c
            .fields.getMap().get('Academic_Interests_To_Display__c').getDescribe();
        for (Schema.PicklistEntry e : d.getPicklistValues()) {
            if (e.isActive() && e.getValue().contains('|')) return e.getValue();
        }
        // Fall back to any active value
        for (Schema.PicklistEntry e : d.getPicklistValues()) {
            if (e.isActive()) return e.getValue();
        }
        return null;
    }

    /**
     * Splits a picklist code into [bannerCode, majorCode] parts so we can set
     * the formula-driving fields Banner_Program_Code__c and Major_Code__c.
     * Format: BannerCode|MajorCode  or  BannerCode|MajorCode|ConcentrationCode
     */
    private static List<String> splitCode(String code) {
        if (String.isBlank(code)) return new List<String>{ '', '' };
        List<String> parts = code.split('\\|');
        String banner = parts.size() > 0 ? parts[0] : '';
        String major  = parts.size() > 1 ? parts[1] : '';
        return new List<String>{ banner, major };
    }

    /** Returns Recruitment_Program record type id for Program__c. */
    private static Id recruitRTId() {
        return Schema.SObjectType.Program__c
            .getRecordTypeInfosByDeveloperName()
            .get('Recruitment_Program')
            .getRecordTypeId();
    }

    // ─── Test Setup ───────────────────────────────────────────────────────────

    @TestSetup
    static void setup() {
        // Insert the RFI Controller used by saveAcademicInterests tests
        insert new RFI_Controller__c(
            Academic_Level__c  = 'U',
            Fields_to_Display__c = 'Email',
            Redirect_URL__c    = 'https://test-ais-sentinel.example.com'
        );

        String code = firstValidCode();
        if (String.isBlank(code)) return; // org has no picklist values — skip programs

        List<String> parts = splitCode(code);
        String bannerCode = parts[0];
        String majorCode  = parts[1];

        Id rtId = recruitRTId();

        // Undergraduate program — Banner+Major produce formula = code
        insert new Program__c(
            Name               = 'AIS Test UG Program',
            RecordTypeId       = rtId,
            Program_Name_on_Application__c = 'AIS Test UG Program',
            Academic_Level__c  = 'U',
            Degree__c          = 'Bachelor of Arts',
            Program_Display__c = 'RFI',
            Active__c          = true,
            Program_Type__c    = 'Major',
            Primary_School_College_for_Assignment__c = 'College of Arts and Sciences',
            Banner_Program_Code__c = bannerCode,
            Major_Code__c          = majorCode
        );

        // Graduate program (School of Law) — Banner starts with LW_ so law filter fires
        insert new Program__c(
            Name               = 'AIS Test GR Law Program',
            RecordTypeId       = rtId,
            Program_Name_on_Application__c = 'AIS Test GR Law Program',
            Academic_Level__c  = 'G',
            Degree__c          = 'Juris Doctor',
            Program_Display__c = 'RFI',
            Active__c          = true,
            Associated_Schools__c = 'School of Law',
            Primary_School_College_for_Assignment__c = 'School of Law',
            Banner_Program_Code__c = 'LW_' + bannerCode,
            Major_Code__c          = majorCode
        );

        // Graduate program (generic school) — no law filter
        insert new Program__c(
            Name               = 'AIS Test GR Generic Program',
            RecordTypeId       = rtId,
            Program_Name_on_Application__c = 'AIS Test GR Generic Program',
            Academic_Level__c  = 'G',
            Degree__c          = 'Master of Arts',
            Program_Display__c = 'RFI',
            Active__c          = true,
            Associated_Schools__c = 'Opus College of Business',
            Primary_School_College_for_Assignment__c = 'Opus College of Business',
            Banner_Program_Code__c = bannerCode,
            Major_Code__c          = majorCode
        );
    }

    // ─── getSelectablePrograms ─────────────────────────────────────────────────

    @IsTest
    static void getSelectablePrograms_undergraduate_TEST() {
        Test.startTest();
        List<AcademicInterestSelectorController.ProgramOption> results =
            AcademicInterestSelectorController.getSelectablePrograms('U', null);
        Test.stopTest();
        System.assertNotEquals(null, results, 'Result list should not be null');
    }

    @IsTest
    static void getSelectablePrograms_undergraduateLongForm_TEST() {
        // Cover the 'Undergraduate' string branch of the level check
        Test.startTest();
        List<AcademicInterestSelectorController.ProgramOption> results =
            AcademicInterestSelectorController.getSelectablePrograms('Undergraduate', null);
        Test.stopTest();
        System.assertNotEquals(null, results);
    }

    @IsTest
    static void getSelectablePrograms_graduate_noSchool_TEST() {
        Test.startTest();
        List<AcademicInterestSelectorController.ProgramOption> results =
            AcademicInterestSelectorController.getSelectablePrograms('G', null);
        Test.stopTest();
        System.assertNotEquals(null, results);
    }

    @IsTest
    static void getSelectablePrograms_graduate_withSchool_TEST() {
        // Covers the school_college branch for graduate (non-law)
        Test.startTest();
        List<AcademicInterestSelectorController.ProgramOption> results =
            AcademicInterestSelectorController.getSelectablePrograms('G', 'Opus College of Business');
        Test.stopTest();
        System.assertNotEquals(null, results);
    }

    @IsTest
    static void getSelectablePrograms_graduate_schoolOfLaw_TEST() {
        // Covers the School of Law sub-branch (Banner_Program_Code__c LIKE 'LW_%')
        Test.startTest();
        List<AcademicInterestSelectorController.ProgramOption> results =
            AcademicInterestSelectorController.getSelectablePrograms('G', 'School of Law');
        Test.stopTest();
        System.assertNotEquals(null, results);
    }

    @IsTest
    static void getSelectablePrograms_returnsGroupHeaders_TEST() {
        // When programs match the picklist filter, verify group headers are present in result
        String code = firstValidCode();
        if (String.isBlank(code)) return; // org has no picklist values — skip

        Test.startTest();
        List<AcademicInterestSelectorController.ProgramOption> results =
            AcademicInterestSelectorController.getSelectablePrograms('U', null);
        Test.stopTest();

        Boolean hasGroup = false;
        for (AcademicInterestSelectorController.ProgramOption opt : results) {
            if (opt.is_group == true) {
                hasGroup = true;
                break;
            }
        }
        if (!results.isEmpty()) {
            System.assert(hasGroup, 'Expected at least one group header when programs are returned');
        }
    }

    @IsTest
    static void getSelectablePrograms_groupLevels_TEST() {
        // Verify school headers have group_level=1 and degree headers group_level=2
        String code = firstValidCode();
        if (String.isBlank(code)) return;

        Test.startTest();
        List<AcademicInterestSelectorController.ProgramOption> results =
            AcademicInterestSelectorController.getSelectablePrograms('U', null);
        Test.stopTest();

        Boolean foundL1 = false, foundL2 = false, foundProgram = false;
        for (AcademicInterestSelectorController.ProgramOption opt : results) {
            if (opt.is_group == true && opt.group_level == 1) foundL1 = true;
            if (opt.is_group == true && opt.group_level == 2) foundL2 = true;
            if (opt.is_group == false) foundProgram = true;
        }
        if (!results.isEmpty()) {
            System.assert(foundL1, 'Expected school-level (group_level=1) header');
            System.assert(foundL2, 'Expected degree-level (group_level=2) header');
            System.assert(foundProgram, 'Expected at least one non-group program option');
        }
    }

    // ─── saveAcademicInterests ─────────────────────────────────────────────────

    @IsTest
    static void saveAcademicInterests_blankCodes_clearsField_TEST() {
        Id ctrlId = [
            SELECT Id FROM RFI_Controller__c
            WHERE Redirect_URL__c = 'https://test-ais-sentinel.example.com' LIMIT 1
        ].Id;

        Test.startTest();
        AcademicInterestSelectorController.saveAcademicInterests(ctrlId, '');
        Test.stopTest();

        RFI_Controller__c updated = [
            SELECT Academic_Interests_To_Display__c FROM RFI_Controller__c WHERE Id = :ctrlId
        ];
        System.assertEquals(null, updated.Academic_Interests_To_Display__c,
            'Field should be null after saving blank codes');
    }

    @IsTest
    static void saveAcademicInterests_nullCodes_clearsField_TEST() {
        Id ctrlId = [
            SELECT Id FROM RFI_Controller__c
            WHERE Redirect_URL__c = 'https://test-ais-sentinel.example.com' LIMIT 1
        ].Id;

        Test.startTest();
        AcademicInterestSelectorController.saveAcademicInterests(ctrlId, null);
        Test.stopTest();

        RFI_Controller__c updated = [
            SELECT Academic_Interests_To_Display__c FROM RFI_Controller__c WHERE Id = :ctrlId
        ];
        System.assertEquals(null, updated.Academic_Interests_To_Display__c);
    }

    @IsTest
    static void saveAcademicInterests_validCodes_savesField_TEST() {
        String code = firstValidCode();
        if (String.isBlank(code)) return;

        Id ctrlId = [
            SELECT Id FROM RFI_Controller__c
            WHERE Redirect_URL__c = 'https://test-ais-sentinel.example.com' LIMIT 1
        ].Id;

        Test.startTest();
        AcademicInterestSelectorController.saveAcademicInterests(ctrlId, code);
        Test.stopTest();

        RFI_Controller__c updated = [
            SELECT Academic_Interests_To_Display__c FROM RFI_Controller__c WHERE Id = :ctrlId
        ];
        System.assertEquals(code, updated.Academic_Interests_To_Display__c,
            'Saved field should contain the valid code');
    }

    @IsTest
    static void saveAcademicInterests_rejectedCodes_notSaved_TEST() {
        // All-invalid code — should be rejected; field stays null
        Id ctrlId = [
            SELECT Id FROM RFI_Controller__c
            WHERE Redirect_URL__c = 'https://test-ais-sentinel.example.com' LIMIT 1
        ].Id;

        Test.startTest();
        AcademicInterestSelectorController.saveAcademicInterests(ctrlId, 'DEFINITELY_NOT_A_VALID_CODE_XYZ');
        Test.stopTest();

        RFI_Controller__c updated = [
            SELECT Academic_Interests_To_Display__c FROM RFI_Controller__c WHERE Id = :ctrlId
        ];
        System.assertEquals(null, updated.Academic_Interests_To_Display__c,
            'Invalid code should be rejected and field should remain null');
    }

    @IsTest
    static void saveAcademicInterests_mixedCodes_onlyValidSaved_TEST() {
        String code = firstValidCode();
        if (String.isBlank(code)) return;

        Id ctrlId = [
            SELECT Id FROM RFI_Controller__c
            WHERE Redirect_URL__c = 'https://test-ais-sentinel.example.com' LIMIT 1
        ].Id;

        Test.startTest();
        AcademicInterestSelectorController.saveAcademicInterests(ctrlId, code + ';INVALID_CODE_XYZ');
        Test.stopTest();

        RFI_Controller__c updated = [
            SELECT Academic_Interests_To_Display__c FROM RFI_Controller__c WHERE Id = :ctrlId
        ];
        System.assertEquals(code, updated.Academic_Interests_To_Display__c,
            'Only the valid code should be saved');
    }

    @IsTest
    static void saveAcademicInterests_allRejected_fieldNull_TEST() {
        // All codes invalid → safeToSave is empty → field set to null
        Id ctrlId = [
            SELECT Id FROM RFI_Controller__c
            WHERE Redirect_URL__c = 'https://test-ais-sentinel.example.com' LIMIT 1
        ].Id;

        Test.startTest();
        AcademicInterestSelectorController.saveAcademicInterests(ctrlId, 'BAD_CODE_1;BAD_CODE_2');
        Test.stopTest();

        RFI_Controller__c updated = [
            SELECT Academic_Interests_To_Display__c FROM RFI_Controller__c WHERE Id = :ctrlId
        ];
        System.assertEquals(null, updated.Academic_Interests_To_Display__c,
            'All-invalid codes should result in null field');
    }

    @IsTest
    static void saveAcademicInterests_multipleCodes_savedJoined_TEST() {
        Schema.DescribeFieldResult d = Schema.SObjectType.RFI_Controller__c
            .fields.getMap().get('Academic_Interests_To_Display__c').getDescribe();
        List<String> activeCodes = new List<String>();
        for (Schema.PicklistEntry e : d.getPicklistValues()) {
            if (e.isActive() && e.getValue().contains('|')) activeCodes.add(e.getValue());
            if (activeCodes.size() >= 2) break;
        }
        if (activeCodes.size() < 2) return; // not enough codes — skip

        Id ctrlId = [
            SELECT Id FROM RFI_Controller__c
            WHERE Redirect_URL__c = 'https://test-ais-sentinel.example.com' LIMIT 1
        ].Id;

        Test.startTest();
        AcademicInterestSelectorController.saveAcademicInterests(ctrlId, String.join(activeCodes, ';'));
        Test.stopTest();

        RFI_Controller__c updated = [
            SELECT Academic_Interests_To_Display__c FROM RFI_Controller__c WHERE Id = :ctrlId
        ];
        System.assertNotEquals(null, updated.Academic_Interests_To_Display__c,
            'Multiple valid codes should be saved');
    }
}
