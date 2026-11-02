/**
 * Decides which fields of a submitted RFI the server accepts from the browser.
 *
 * The browser can send any field name, and the form is reachable by anonymous visitors. So the server
 * accepts only the fields that belong to the questions on that controller's form, the tracking fields, and
 * the defaults the controller gave the form. It never accepts the fields the server sets itself (owner,
 * source, stage, Opportunity, Term, programs). Anything else is ignored, never rejected, because an RFI must
 * always be accepted.
 */
public with sharing class rfiSubmissionGuard {

    /**
     * The outcome of filtering a submission.
     */
    public class FilterResult {
        /** Fields to save, by API name as the browser sent them */
        public Map<String, Object> accepted = new Map<String, Object>();
        /** API names that were ignored */
        public List<String> ignored = new List<String>();
    }

    /** Tracking and answer-composition fields every form may send. Lower case. */
    @TestVisible
    private static final Set<String> alwaysAllowedFields = new Set<String>{
        'utm_campaign__c', 'utm_medium__c', 'utm_source__c', 'utm_content__c', 'utm_term__c', 'utm_id__c',
        'utm_creative_format__c', 'utm_marketing_topic__c', 'utm_source_platform__c', 'gclid__c',
        'nominator_contact__c', 'lead_website__c', 'lead_website_referrer__c', 'description__c'
    };

    /** Fields the server sets or owns. The browser may never set them. Lower case. */
    @TestVisible
    private static final Set<String> serverControlledFields = new Set<String>{
        'ownerid', 'lead_source__c', 'interaction_source__c', 'date_inquiry__c', 'opportunity_stage__c',
        'opportunity_record_type__c', 'opportunity__c', 'contact__c', 'lead__c', 'term__c',
        'academic_program__c', 'recruitment_program__c', 'recruitment_program_associated_schools__c',
        'country__c', 'interaction_upsert_key__c', 'pardot_sync_ocb__c', 'lead_only__c',
        'admissions_application__c', 'application_status__c', 'application_substatus__c',
        'interaction_status__c', 'affiliation_status__c', 'campaign__c', 'additional_campaign__c',
        'summit_event__c', 'financial_aid_counselor__c', 'banner_id__c'
    };

    /** The address question writes these along with its own field. Lower case. */
    @TestVisible
    private static final Set<String> addressCompanionFields = new Set<String>{
        'mailing_street__c', 'mailing_city__c', 'mailing_state__c', 'mailing_country__c',
        'mailing_postal_code__c', 'state__c'
    };

    /** The academic interest question fills these four. Lower case. */
    @TestVisible
    private static final Set<String> majorProgramFields = new Set<String>{
        'major_program_1__c', 'major_program_2__c', 'major_program_3__c', 'major_program_4__c'
    };

    /**
     * Works out which Interaction fields a form may set. The set is built from the form the controller
     * produces, so it is exactly what the visitor was shown.
     *
     * @param questions The questions of the form
     * @param controllerDefaults The Interaction the form starts with (controller defaults), or null
     * @return The allowed field API names in lower case
     */
    public static Set<String> allowedFieldsFor(List<rfiFormController.rfiField> questions, Interaction__c controllerDefaults) {
        Set<String> allowed = new Set<String>(alwaysAllowedFields);
        if (questions != null) {
            for (rfiFormController.rfiField question : questions) {
                if (question == null || question.isStaticContent == true) {
                    continue;
                }
                if (String.isNotBlank(question.fieldInteractionAPIName)) {
                    allowed.add(question.fieldInteractionAPIName.toLowerCase());
                }
                if (question.isAddress == true) {
                    allowed.addAll(addressCompanionFields);
                }
                if (question.isSchoolLookup == true) {
                    allowed.add('school_name_text__c');
                }
                if (question.isProgramLookup == true) {
                    allowed.addAll(majorProgramFields);
                }
                if (question.showDependentField == true) {
                    allowed.add('has_question__c');
                }
            }
        }
        if (controllerDefaults != null) {
            for (String defaultField : controllerDefaults.getPopulatedFieldsAsMap().keySet()) {
                allowed.add(defaultField.toLowerCase());
            }
        }
        allowed.removeAll(serverControlledFields);
        return allowed;
    }

    /**
     * Splits what the browser sent into accepted and ignored fields.
     *
     * @param incoming The fields the browser sent, by API name
     * @param allowed The allowed field API names in lower case, or null when the controller is not known.
     *                When null, everything is accepted except the server-controlled fields.
     * @return The accepted values and the ignored field names
     */
    public static FilterResult filterIncoming(Map<String, Object> incoming, Set<String> allowed) {
        FilterResult result = new FilterResult();
        if (incoming == null) {
            return result;
        }
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Interaction__c.fields.getMap();
        List<String> names = new List<String>(incoming.keySet());
        names.sort();
        for (String fieldName : names) {
            String key = fieldName.toLowerCase();
            Boolean isKnownField = fieldMap.containsKey(key);
            Boolean isPermitted = !serverControlledFields.contains(key) && (allowed == null || allowed.contains(key));
            if (isKnownField && isPermitted) {
                result.accepted.put(fieldName, incoming.get(fieldName));
            } else {
                result.ignored.add(fieldName);
            }
        }
        return result;
    }

    /**
     * Builds the Interaction from the accepted values. A value that cannot be stored (for example a formula
     * field) is added to the ignored list instead of failing the submission.
     *
     * @param filtered The result of filterIncoming; its ignored list may grow
     * @return A new Interaction holding the accepted values
     */
    public static Interaction__c buildRecord(FilterResult filtered) {
        Interaction__c record = new Interaction__c();
        for (String fieldName : filtered.accepted.keySet()) {
            try {
                record.put(fieldName, filtered.accepted.get(fieldName));
            } catch (Exception cannotStore) {
                filtered.ignored.add(fieldName);
            }
        }
        return record;
    }
}
