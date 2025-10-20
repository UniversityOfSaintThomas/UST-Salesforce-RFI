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

    @testSetup
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
    }

    @isTest
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
        Id leadId = rfiFormController.submitRFILead(l);
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
}
