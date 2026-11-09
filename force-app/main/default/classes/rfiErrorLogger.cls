/**
 * Writes problems with an RFI submission to the Error object (hed__Error__c), as the old form did.
 *
 * Logging must never make things worse, so nothing here throws. The record is written in the same
 * transaction as the caller, which means it is rolled back if the caller then throws. Callers that want the
 * record to survive must return normally after logging.
 */
public with sharing class rfiErrorLogger {

    public static final String failureType = 'ERROR: RFI Form submission failed';
    public static final String gapsType = 'WARNING: RFI Form saved with gaps';

    @TestVisible
    private static final Integer maxTextLength = 32000;

    /**
     * Writes one Error record.
     *
     * @param errorType Short description of the kind of problem; stored in Error Type
     * @param controllerName The Name of the RFI Controller the form was loaded from, or null
     * @param summary What went wrong, in words
     * @param submittedData What the visitor entered, as text
     * @param cause The exception behind the problem, or null
     * @return The Id of the Error record, or null when it could not be written
     */
    public static Id log(String errorType, String controllerName, String summary, String submittedData, Exception cause) {
        try {
            String message = summary
                + '\n\nRFI Controller of form: ' + (String.isBlank(controllerName) ? '(not known)' : controllerName)
                + '\n\nThe following information was entered on the form to be mapped to Interaction:\n'
                + (submittedData == null ? '' : submittedData);
            hed__Error__c errorRecord = new hed__Error__c(
                hed__Object_Type__c = 'Interaction__c',
                hed__Error_Type__c = errorType,
                hed__Context_Type__c = 'RFI form submission',
                hed__Datetime__c = System.now(),
                hed__Full_Message__c = truncate(message),
                hed__Stack_Trace__c = cause == null ? null : truncate(cause.getTypeName() + ': ' + cause.getMessage() + '\n' + cause.getStackTraceString())
            );
            insert errorRecord;
            return errorRecord.Id;
        } catch (Exception loggingError) {
            System.debug(LoggingLevel.ERROR, 'RFI error could not be written to hed__Error__c: ' + loggingError.getMessage());
            return null;
        }
    }

    /**
     * Shortens text to what a long text area can hold.
     *
     * @param value The text to shorten
     * @return The text, cut to the maximum length
     */
    @TestVisible
    private static String truncate(String value) {
        if (value == null || value.length() <= maxTextLength) {
            return value;
        }
        return value.substring(0, maxTextLength);
    }
}