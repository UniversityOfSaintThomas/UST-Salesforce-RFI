// Read-only rollout check for the RFI form. It never writes anything, so it is safe in any org.
//
// Run:    sf apex run --target-org <alias> --file scripts/apex/verify_rfi_rollout.apex
// Read:   look for lines that start with "VERIFY". Each check is PASS, FAIL or INFO. The last line is a summary.
// Use:    before the deploy (to see what is missing) and after it (everything should PASS).
//
// It checks what the deployment needs and what admins control. It cannot list Lightning web components or act as
// the public site guest, so it prints those two checks for you to do by hand. The question catalog is checked by rfiQuestionCatalog_TEST during
// the deploy, not here, so this script also works before those classes exist.
//
// The names in the two lists below are copied from the code on purpose, so this script has no dependency on the
// classes it is checking: keep them in step with rfiSubmissionProcessor (fields it sets) and the class list.

List<List<String>> checks = new List<List<String>>();

// ---------------------------------------------------------------- code
Set<String> expectedClasses = new Set<String>{
    'rfiFormController', 'rfiSubmissionProcessor', 'rfiSubmissionGuard', 'rfiErrorLogger', 'rfiQuestionCatalog',
    'rfiFormController_TEST', 'rfiSubmissionProcessor_TEST', 'rfiSubmissionGuard_TEST', 'rfiErrorLogger_TEST', 'rfiQuestionCatalog_TEST'
};
Set<String> foundClasses = new Set<String>();
for (ApexClass apexClass : [SELECT Name FROM ApexClass WHERE Name IN :expectedClasses]) {
    foundClasses.add(apexClass.Name);
}
List<String> missingClasses = new List<String>();
for (String className : expectedClasses) {
    if (!foundClasses.contains(className)) { missingClasses.add(className); }
}
missingClasses.sort();
checks.add(new List<String>{ missingClasses.isEmpty() ? 'PASS' : 'FAIL', 'Apex classes deployed',
    missingClasses.isEmpty() ? 'all ' + expectedClasses.size() + ' present' : 'missing: ' + String.join(missingClasses, ', ') });

// Lightning web components cannot be listed from Apex. Check them from the command line:
//   sf data query --use-tooling-api --target-org <alias> --query "SELECT DeveloperName FROM LightningComponentBundle WHERE DeveloperName IN ('rfiForm','rfiFormUtils','rfiUnifiedQuestionManager')"
// (three rows are expected).

// ---------------------------------------------------------------- schema
Map<String, Schema.SObjectField> interactionFields = Schema.SObjectType.Interaction__c.fields.getMap();
checks.add(new List<String>{ interactionFields.containsKey('timeline__c') ? 'PASS' : 'FAIL', 'Interaction__c.Timeline__c exists',
    interactionFields.containsKey('timeline__c') ? interactionFields.get('timeline__c').getDescribe().getType().name() : 'create it first (step 1 of the hand-off)' });

List<String> setByServer = new List<String>{
    'Interaction_Source__c', 'Date_Inquiry__c', 'Opportunity_Stage__c', 'Opportunity_Record_Type__c', 'Term__c',
    'Academic_Program__c', 'Recruitment_Program__c', 'Recruitment_Program_Associated_Schools__c', 'Country__c', 'State__c'
};
List<String> missingServerFields = new List<String>();
for (String fieldName : setByServer) {
    if (!interactionFields.containsKey(fieldName.toLowerCase())) { missingServerFields.add(fieldName); }
}
checks.add(new List<String>{ missingServerFields.isEmpty() ? 'PASS' : 'FAIL', 'Fields the server sets exist on Interaction__c',
    missingServerFields.isEmpty() ? String.valueOf(setByServer.size()) + ' of ' + setByServer.size() : 'missing: ' + String.join(missingServerFields, ', ') });

for (String fieldApi : new List<String>{ 'Fields_to_Display__c', 'Required_Fields__c' }) {
    Schema.SObjectField controllerField = Schema.SObjectType.RFI_Controller__c.fields.getMap().get(fieldApi.toLowerCase());
    Boolean stillOffered = false;
    for (Schema.PicklistEntry entry : controllerField.getDescribe().getPicklistValues()) {
        if (entry.isActive() && entry.getValue() == 'When do you plan to start school') { stillOffered = true; }
    }
    checks.add(new List<String>{ stillOffered ? 'FAIL' : 'PASS', 'RFI_Controller__c.' + fieldApi + ' no longer offers the start-school question',
        stillOffered ? 'deploy the field with the value deactivated' : 'value is inactive or absent' });
}

Boolean errorObjectExists = Schema.getGlobalDescribe().containsKey('hed__error__c');
Boolean errorObjectCreateable = errorObjectExists && Schema.SObjectType.hed__Error__c.isCreateable();
checks.add(new List<String>{ errorObjectCreateable ? 'PASS' : 'FAIL', 'hed__Error__c (where failures are recorded) can be created by this user',
    errorObjectExists ? String.valueOf(errorObjectCreateable) : 'object not found' });

Map<String, Schema.RecordTypeInfo> opportunityTypes = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();
checks.add(new List<String>{ opportunityTypes.containsKey('Inquiry_Opportunity') ? 'PASS' : 'FAIL', 'Opportunity record type Inquiry_Opportunity exists',
    opportunityTypes.containsKey('Inquiry_Opportunity') ? 'visible to this user' : 'not found, or not visible to this user' });

Integer activePresets = [SELECT COUNT() FROM Lead_Preset_Value__mdt WHERE Active__c = true];
checks.add(new List<String>{ 'INFO', 'Active per-controller preset values (Lead_Preset_Value__mdt)', String.valueOf(activePresets) });

// ---------------------------------------------------------------- saved forms
Integer needStartSchoolRemoved = [SELECT COUNT() FROM RFI_Controller__c WHERE Fields_to_Display__c INCLUDES ('When do you plan to start school')];
checks.add(new List<String>{ needStartSchoolRemoved == 0 ? 'PASS' : 'INFO', 'Controllers whose field list still holds the start-school question',
    String.valueOf(needStartSchoolRemoved) + (needStartSchoolRemoved == 0 ? '' : ' (run scripts/apex/migrate_rfi_questions.apex, dry run first)') });

Integer oldPhoneTarget = 0;
Integer oldTitleTarget = 0;
Integer oldMailTarget = 0;
Integer splitAddress = 0;
Integer newerForms = 0;
Integer formsMissingNames = 0;
for (RFI_Controller__c controller : [SELECT Unified_Questions__c FROM RFI_Controller__c]) {
    if (String.isBlank(controller.Unified_Questions__c)) { continue; }
    newerForms++;
    List<Object> questions = (List<Object>) JSON.deserializeUntyped(controller.Unified_Questions__c);
    Set<String> names = new Set<String>();
    Boolean oldPhone = false; Boolean oldTitle = false; Boolean oldMail = false; Boolean split = false;
    for (Object item : questions) {
        Map<String, Object> question = (Map<String, Object>) item;
        String name = String.valueOf(question.get('fieldName'));
        String stored = String.valueOf(question.get('fieldInteractionAPIName'));
        names.add(name);
        if (name == 'Phone' && stored == 'Home_Phone__c') { oldPhone = true; }
        if (name == 'Title' && stored == 'Salutation__c') { oldTitle = true; }
        if (name == 'I would like program information to be mailed to me' && stored == 'Mail_Information__c') { oldMail = true; }
        if (new Set<String>{ 'Address 1', 'Address 2', 'Address 3', 'City', 'State', 'Zipcode', 'Country' }.contains(name)) { split = true; }
    }
    if (oldPhone) { oldPhoneTarget++; }
    if (oldTitle) { oldTitleTarget++; }
    if (oldMail) { oldMailTarget++; }
    if (split) { splitAddress++; }
    if (!names.contains('First Name') || !names.contains('Last Name')) { formsMissingNames++; }
}
checks.add(new List<String>{ 'INFO', 'Newer-style forms (Unified_Questions__c is set)', String.valueOf(newerForms) });
Integer needRepair = oldPhoneTarget + oldTitleTarget + oldMailTarget;
checks.add(new List<String>{ needRepair == 0 ? 'PASS' : 'INFO', 'Saved questions still pointing at the old wrong fields',
    'Phone->Home_Phone__c: ' + oldPhoneTarget + ', Title->Salutation__c: ' + oldTitleTarget + ', mail->Mail_Information__c: ' + oldMailTarget
    + (needRepair == 0 ? '' : ' (the form already corrects these at run time; the repair script makes the saved data match)') });
checks.add(new List<String>{ 'INFO', 'Forms still holding the older split address questions', String.valueOf(splitAddress) });
checks.add(new List<String>{ formsMissingNames == 0 ? 'PASS' : 'INFO', 'Newer-style forms without a First Name or Last Name question',
    String.valueOf(formsMissingNames) + (formsMissingNames == 0 ? '' : ' (the new code adds them at run time)') });

// ---------------------------------------------------------------- admin-owned access (read only; may also come from a profile)
List<PermissionSet> guestSets = [SELECT Id FROM PermissionSet WHERE Name = 'RFI_User'];
if (guestSets.isEmpty()) {
    checks.add(new List<String>{ 'INFO', 'Permission set RFI_User', 'not found, so the public form guest access cannot be read here' });
} else {
    Id guestSetId = guestSets[0].Id;
    Set<String> grantedClasses = new Set<String>();
    for (ApexClass apexClass : [SELECT Name FROM ApexClass WHERE Id IN
            (SELECT SetupEntityId FROM SetupEntityAccess WHERE ParentId = :guestSetId AND SetupEntityType = 'ApexClass')]) {
        grantedClasses.add(apexClass.Name);
    }
    checks.add(new List<String>{ grantedClasses.contains('rfiFormController') ? 'PASS' : 'INFO', 'RFI_User allows the rfiFormController class',
        grantedClasses.contains('rfiFormController') ? 'yes' : 'no (admins decide; the guest may get it from a profile or another set)' });

    Set<String> editable = new Set<String>();
    for (FieldPermissions permission : [SELECT Field FROM FieldPermissions WHERE ParentId = :guestSetId AND SobjectType = 'Interaction__c' AND PermissionsEdit = true]) {
        editable.add(permission.Field.substringAfter('.').toLowerCase());
    }
    List<String> notEditable = new List<String>();
    for (String fieldName : setByServer) {
        if (!editable.contains(fieldName.toLowerCase())) { notEditable.add(fieldName); }
    }
    if (!editable.contains('timeline__c')) { notEditable.add('Timeline__c'); }
    checks.add(new List<String>{ notEditable.isEmpty() ? 'PASS' : 'INFO', 'RFI_User can edit the fields the server sets, and Timeline__c',
        notEditable.isEmpty() ? 'yes' : 'not through RFI_User: ' + String.join(notEditable, ', ') + ' (the RFI is still saved without them and an Error record says which)' });

    List<ObjectPermissions> errorObjectAccess = [SELECT PermissionsCreate FROM ObjectPermissions WHERE ParentId = :guestSetId AND SobjectType = 'hed__Error__c'];
    Boolean canLog = !errorObjectAccess.isEmpty() && errorObjectAccess[0].PermissionsCreate;
    checks.add(new List<String>{ canLog ? 'PASS' : 'INFO', 'RFI_User can create hed__Error__c rows', canLog ? 'yes' : 'no (failures will not be recorded for the guest)' });
}

// ---------------------------------------------------------------- print
Integer passes = 0;
Integer failures = 0;
for (List<String> check : checks) {
    if (check[0] == 'PASS') { passes++; }
    if (check[0] == 'FAIL') { failures++; }
    System.debug('VERIFY ' + check[0] + ' | ' + check[1] + ' | ' + check[2]);
}
System.debug('VERIFY SUMMARY pass=' + passes + ' fail=' + failures + ' info=' + (checks.size() - passes - failures));
System.debug('VERIFY BY HAND: as an anonymous visitor on the public site, (1) the form loads, (2) the College/School and Expected Start Term lists have choices, '
    + '(3) a submit saves and no new row appears in the Error object. Also open the University of St Thomas Administrative account as the guest: '
    + 'if it cannot be seen, Term__c is left blank and one Error row per submit says so.');
