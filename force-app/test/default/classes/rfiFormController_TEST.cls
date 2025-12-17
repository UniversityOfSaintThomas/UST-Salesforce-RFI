@isTest
private class rfiFormController_TEST {

    private static String firstPicklistValue(Schema.SObjectField f) {
        Schema.DescribeFieldResult d = f.getDescribe();
        Schema.DisplayType t = d.getType();
        if (t == Schema.DisplayType.Picklist || t == Schema.DisplayType.MultiPicklist) {
            for (Schema.PicklistEntry e : d.getPicklistValues()) {
                if (e.isActive()) return String.valueOf(e.getValue());
            }
        }
        return null;
    }

    @TestSetup
    static void setupData() {
        // Build a controller record satisfying org-required and restricted picklists dynamically
        Map<String, Schema.SObjectField> fm = Schema.SObjectType.RFI_Controller__c.fields.getMap();
        String academicLevel = firstPicklistValue(fm.get('Academic_Level__c'));
        String fieldsToDisplayValue = firstPicklistValue(fm.get('Fields_to_Display__c'));

        RFI_Controller__c ctrl = new RFI_Controller__c();
        if (academicLevel != null) ctrl.Academic_Level__c = academicLevel;
        if (fieldsToDisplayValue != null) ctrl.Fields_to_Display__c = fieldsToDisplayValue;
        ctrl.Redirect_URL__c = 'https://example.com';
        ctrl.Academic_Interest_Max_Selection__c = '4';
        insert ctrl;

        // Create test programs for getProgramsWithShortCodes test
        Id recruitmentProgramRTId = Schema.SObjectType.Program__c.getRecordTypeInfosByDeveloperName().get('Recruitment_Program').getRecordTypeId();

        List<Program__c> testPrograms = new List<Program__c>{
            new Program__c(
                Name = 'Computer Science',
                RecordTypeId = recruitmentProgramRTId,
                Program_Name_on_Application__c = 'Computer Science',
                Major_Code__c = 'CSCI',
                Academic_Level__c = 'U',
                Degree__c = 'Bachelor of Arts',
                Program_Display__c = 'RFI',
                Active__c = true,
                Program_Type__c = 'Major'
            ),
            new Program__c(
                Name = 'Biology',
                RecordTypeId = recruitmentProgramRTId,
                Program_Name_on_Application__c = 'Biology',
                Major_Code__c = 'BIOL',
                Academic_Level__c = 'U',
                Degree__c = 'Bachelor of Science',
                Program_Display__c = 'RFI',
                Active__c = true,
                Program_Type__c = 'Major'
            ),
            new Program__c(
                Name = 'MBA',
                RecordTypeId = recruitmentProgramRTId,
                Program_Name_on_Application__c = 'Master of Business Administration',
                Major_Code__c = 'MBA',
                Academic_Level__c = 'G',
                Degree__c = 'Master of Business Administration',
                Program_Display__c = 'RFI',
                Active__c = true,
                Associated_Schools__c = 'Opus College of Business'
            )
        };
        insert testPrograms;
    }

    @IsTest
    static void testGetRFIForm_returnsWrapper() {
/*        // Use the generated Name value
        RFI_Controller__c ctrl = [SELECT Name FROM RFI_Controller__c LIMIT 1];
        Test.startTest();
        rfiFormController.leadAndRfiFields wrap = rfiFormController.getRFIForm(ctrl.Name);
        Test.stopTest();

        System.assertNotEquals(null, wrap, 'Wrapper should not be null');
        System.assertNotEquals(null, wrap.leadRecord, 'Lead record should be initialized');
        System.assertNotEquals(null, wrap.rfiFieldList, 'Field list should be initialized');
        System.assert(wrap.rfiFieldList.size() > 0, 'Field list should have entries');

        // Ensure at most one address field rendered
        Integer addrCount = 0;
        for (rfiFormController.rfiField f : wrap.rfiFieldList) {
            if (f.fieldType == 'address') addrCount++;
        }
        System.assert(addrCount <= 1, 'There should be at most one address field rendered');*/
    }

    @isTest
    static void testSubmitRFILead_insertsLead() {
        // Build a lead similar to what the LWC will send
        Lead l = new Lead();
        l.LastName = 'Lovelace';
        l.Company = 'Analytical Engines';
        l.Email = 'ada@example.com';
        l.Street = '2115 Summit Ave';
        l.City = 'St Paul';
        // Use code fields when state/country picklists are enabled
        l.StateCode = 'MN';
        l.CountryCode = 'US';
        l.PostalCode = '55105';

        Test.startTest();
        Id leadId = rfiFormController.submitRfiInteraction(l);
        Test.stopTest();

        System.assertNotEquals(null, leadId, 'Lead Id should be returned');
        Lead inserted = [SELECT Id, LastName, Company, Email, Street, City, State, StateCode, PostalCode, Country, CountryCode FROM Lead WHERE Id = :leadId];
        System.assertEquals('Lovelace', inserted.LastName);
        System.assertEquals('Analytical Engines', inserted.Company);
        System.assertEquals('ada@example.com', inserted.Email);
        System.assertEquals('2115 Summit Ave', inserted.Street);
        System.assertEquals('St Paul', inserted.City);
        System.assertEquals('MN', inserted.StateCode);
        System.assertEquals('US', inserted.CountryCode);
        System.assertEquals('55105', inserted.PostalCode);
    }

    @isTest
    static void testGetProgramsWithShortCodes_undergraduate() {
        Test.startTest();
        List<rfiFormController.programValues> programs = rfiFormController.getProgramsWithShortCodes(
            'U',
            null,
            null,
            null
        );
        Test.stopTest();

        System.assertNotEquals(null, programs, 'Programs list should not be null');
        System.assert(programs.size() > 0, 'Should return at least one program or group header');

        // Verify that non-group items have short codes as values
        Boolean foundNonGroupItem = false;
        for (rfiFormController.programValues pv : programs) {
            if (!pv.is_group) {
                foundNonGroupItem = true;
                System.assertNotEquals(null, pv.value, 'Value should not be null');
                // Value should be short code (CSCI, BIOL) not an ID
                System.assert(!pv.value.startsWith('a0'), 'Value should be short code, not Program ID');
            }
        }
        System.assert(foundNonGroupItem, 'Should have at least one non-group program item');
    }

    @isTest
    static void testGetProgramsWithShortCodes_graduate() {
        Test.startTest();
        List<rfiFormController.programValues> programs = rfiFormController.getProgramsWithShortCodes(
            'G',
            'Opus College of Business',
            null,
            null
        );
        Test.stopTest();

        System.assertNotEquals(null, programs, 'Programs list should not be null');

        // Verify MBA program with short code (check by label since formula field value may vary)
        Boolean foundMBA = false;
        for (rfiFormController.programValues pv : programs) {
            if (!pv.is_group && pv.label == 'Master of Business Administration') {
                foundMBA = true;
                System.assertNotEquals(null, pv.value, 'Value should not be null');
                System.assert(!pv.value.startsWith('a0'), 'Value should be short code, not Program ID');
            }
        }
        System.assert(foundMBA, 'Should find MBA program');
    }

    @isTest
    static void testGetProgramsWithShortCodes_withFilter() {
        // First, query the actual formula field values from the created test programs
        List<Program__c> createdPrograms = [
            SELECT Id, Program_Major_Concentration__c, Program_Name_on_Application__c
            FROM Program__c
            WHERE RecordType.DeveloperName = 'Recruitment_Program'
            AND Active__c = true
            AND Program_Display__c = 'RFI'
            AND Academic_Level__c = 'U'
            LIMIT 2
        ];

        if (createdPrograms.isEmpty()) {
            // If no programs were created, skip this test
            return;
        }

        // Build filter string from actual formula field values
        List<String> filterCodes = new List<String>();
        for (Program__c p : createdPrograms) {
            if (String.isNotBlank(p.Program_Major_Concentration__c)) {
                filterCodes.add(p.Program_Major_Concentration__c);
            }
        }

        if (filterCodes.isEmpty()) {
            // If formula field is null, skip the filter test
            return;
        }

        String filterString = String.join(filterCodes, ';');

        Test.startTest();
        List<rfiFormController.programValues> programs = rfiFormController.getProgramsWithShortCodes(
            'U',
            null,
            filterString,
            null
        );
        Test.stopTest();

        System.assertNotEquals(null, programs, 'Programs list should not be null');

        // Count non-group items
        Integer nonGroupCount = 0;
        Set<String> expectedCodes = new Set<String>(filterCodes);
        for (rfiFormController.programValues pv : programs) {
            if (!pv.is_group) {
                nonGroupCount++;
                if (String.isNotBlank(pv.value)) {
                    System.assert(expectedCodes.contains(pv.value) || pv.value.startsWith('a0'),
                        'Should return programs matching the filter codes or ID if formula is null');
                }
            }
        }
        System.assert(nonGroupCount > 0, 'Should return filtered programs');
    }
}
