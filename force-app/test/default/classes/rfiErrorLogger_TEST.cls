@IsTest
private class rfiErrorLogger_TEST {

    @IsTest
    static void log_writesTheControllerNameTheEnteredDataAndTheCause_TEST() {
        Exception cause;
        try {
            Integer boom = 1 / Integer.valueOf('0');
        } catch (Exception caught) {
            cause = caught;
        }
        Id errorId = rfiErrorLogger.log(rfiErrorLogger.failureType, 'RFI Controller 0042', 'It broke.', '{"First_Name__c":"Ada"}', cause);
        System.assertNotEquals(null, errorId);
        hed__Error__c saved = [SELECT hed__Object_Type__c, hed__Error_Type__c, hed__Context_Type__c, hed__Datetime__c, hed__Full_Message__c, hed__Stack_Trace__c
                FROM hed__Error__c WHERE Id = :errorId];
        System.assertEquals('Interaction__c', saved.hed__Object_Type__c);
        System.assertEquals(rfiErrorLogger.failureType, saved.hed__Error_Type__c);
        System.assertNotEquals(null, saved.hed__Datetime__c);
        System.assert(saved.hed__Full_Message__c.contains('It broke.'));
        System.assert(saved.hed__Full_Message__c.contains('RFI Controller 0042'));
        System.assert(saved.hed__Full_Message__c.contains('Ada'));
        System.assert(saved.hed__Stack_Trace__c.contains('MathException'), saved.hed__Stack_Trace__c);
    }

    @IsTest
    static void log_withoutAControllerOrCause_stillWrites_TEST() {
        Id errorId = rfiErrorLogger.log(rfiErrorLogger.gapsType, null, 'A gap.', null, null);
        hed__Error__c saved = [SELECT hed__Full_Message__c, hed__Stack_Trace__c FROM hed__Error__c WHERE Id = :errorId];
        System.assert(saved.hed__Full_Message__c.contains('(not known)'));
        System.assertEquals(null, saved.hed__Stack_Trace__c);
    }

    @IsTest
    static void log_cutsTextThatIsTooLongForTheField_TEST() {
        String tooLong = 'x'.repeat(40000);
        Id errorId = rfiErrorLogger.log(rfiErrorLogger.failureType, 'RFI Controller 0042', 'Long.', tooLong, null);
        System.assertNotEquals(null, errorId, 'The record is written, with the text cut');
        System.assertEquals(rfiErrorLogger.maxTextLength, [SELECT hed__Full_Message__c FROM hed__Error__c WHERE Id = :errorId].hed__Full_Message__c.length());
    }

    @IsTest
    static void log_neverThrows_whenTheRecordCannotBeWritten_TEST() {
        // Error Type holds 255 characters, so this insert fails; the logger must swallow that
        Id errorId = rfiErrorLogger.log('x'.repeat(300), 'RFI Controller 0042', 'Cannot be written.', null, null);
        System.assertEquals(null, errorId);
        System.assertEquals(0, [SELECT COUNT() FROM hed__Error__c]);
    }
}