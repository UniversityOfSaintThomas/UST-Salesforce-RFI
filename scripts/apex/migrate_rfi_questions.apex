// ECRMSF-6047: repair saved RFI Controller question lists.
//
// Run:     sf apex run --target-org <alias> --file scripts/apex/migrate_rfi_questions.apex
// Default: DRY_RUN = true. It only prints what would change (look for "MIGRATION change:" lines).
// Save:    set DRY_RUN = false below and run again. Safe to run more than once; the second run changes nothing.
// Guard:   outside a sandbox it refuses to save until the IsSandbox check below is edited on purpose.
//
// What it repairs
//   Saved question JSON (RFI_Controller__c.Unified_Questions__c):
//     - Title, the mail question, Timeline: set the correct Interaction field
//     - "I will apply to St Thomas Law as a": set Admit_Type__c
//     - "When do you plan to start school": removed
//     - Address 1/2/3, City, State, Zipcode, Country: collapsed into one "Address" question
//   Older field lists (Fields_to_Display__c, Fields_to_Display_Order__c, Required_Fields__c):
//     - "When do you plan to start school": removed
//     - The split address entries in these lists are left alone (restricted picklist, no plain
//       "Address" value). The form code handles them at run time.
Boolean DRY_RUN = true;

Organization org = [SELECT IsSandbox, Name FROM Organization LIMIT 1];
System.debug('MIGRATION org=' + org.Name + ' sandbox=' + org.IsSandbox + ' dryRun=' + DRY_RUN);
if (!DRY_RUN && !org.IsSandbox) {
    throw new AuraHandledException('Refusing to save in a non-sandbox org from this script. Review and run deliberately.');
}

Map<String, String> correctedTarget = new Map<String, String>{
    'Title' => 'Contact_Title__c',
    'I would like program information to be mailed to me' => 'Mailed_Program_Information_Requested__c',
    'Mail Information' => 'Mailed_Program_Information_Requested__c',
    'Timeline to Enrollment' => 'Timeline__c',
    'I will apply to St Thomas Law as a' => 'Admit_Type__c'
};
Set<String> splitAddress = new Set<String>{ 'Address 1', 'Address 2', 'Address 3', 'City', 'State', 'Zipcode', 'Country' };
String removedQuestion = 'When do you plan to start school';

List<RFI_Controller__c> controllers = [
    SELECT Id, Name, Unified_Questions__c, Fields_to_Display__c, Fields_to_Display_Order__c, Required_Fields__c
    FROM RFI_Controller__c
];
List<RFI_Controller__c> toUpdate = new List<RFI_Controller__c>();
Map<String, Integer> tally = new Map<String, Integer>();
List<String> report = new List<String>();

for (RFI_Controller__c controller : controllers) {
    Boolean changed = false;
    List<String> notes = new List<String>();

    // ---- saved question JSON
    if (String.isNotBlank(controller.Unified_Questions__c)) {
        List<Object> questions = (List<Object>) JSON.deserializeUntyped(controller.Unified_Questions__c);
        Boolean hasAddress = false;
        Boolean splitRequired = false;
        for (Object o : questions) {
            Map<String, Object> q = (Map<String, Object>) o;
            String name = String.valueOf(q.get('fieldName') != null ? q.get('fieldName') : '');
            if (name == 'Address') { hasAddress = true; }
            if (splitAddress.contains(name) && q.get('isRequired') == true) { splitRequired = true; }
        }
        List<Object> rebuilt = new List<Object>();
        Boolean addressInserted = false;
        for (Object o : questions) {
            Map<String, Object> q = (Map<String, Object>) o;
            String name = String.valueOf(q.get('fieldName') != null ? q.get('fieldName') : '');
            if (q.get('type') == 'preconfigured') {
                if (name == removedQuestion) {
                    notes.add('removed start-school question'); tally.put('startSchoolRemoved', (tally.containsKey('startSchoolRemoved') ? tally.get('startSchoolRemoved') : 0) + 1);
                    changed = true; continue;
                }
                if (splitAddress.contains(name)) {
                    if (!hasAddress && !addressInserted) {
                        rebuilt.add(new Map<String, Object>{
                            'id' => 0, 'type' => 'preconfigured', 'fieldName' => 'Address', 'questionLabel' => 'Address',
                            'fieldInteractionAPIName' => 'Mailing_Street__c', 'isRequired' => splitRequired
                        });
                        addressInserted = true;
                    }
                    notes.add('collapsed ' + name + ' into Address'); tally.put('splitAddressCollapsed', (tally.containsKey('splitAddressCollapsed') ? tally.get('splitAddressCollapsed') : 0) + 1);
                    changed = true; continue;
                }
                if (correctedTarget.containsKey(name)) {
                    String current = String.valueOf(q.get('fieldInteractionAPIName') != null ? q.get('fieldInteractionAPIName') : '');
                    if (current != correctedTarget.get(name)) {
                        notes.add(name + ': ' + current + ' -> ' + correctedTarget.get(name));
                        tally.put('targetFixed:' + name, (tally.containsKey('targetFixed:' + name) ? tally.get('targetFixed:' + name) : 0) + 1);
                        q.put('fieldInteractionAPIName', correctedTarget.get(name));
                        changed = true;
                    }
                }
            }
            rebuilt.add(q);
        }
        if (changed) {
            // renumber ids so they stay 0..n-1
            Integer nextId = 0;
            for (Object o : rebuilt) { ((Map<String, Object>) o).put('id', nextId); nextId++; }
            controller.Unified_Questions__c = JSON.serialize(rebuilt);
        }
    }

    // ---- older field lists: remove the start-school question only (picklists are restricted)
    for (String fieldApi : new List<String>{ 'Fields_to_Display__c', 'Fields_to_Display_Order__c', 'Required_Fields__c' }) {
        String raw = (String) controller.get(fieldApi);
        if (String.isNotBlank(raw) && raw.contains(removedQuestion)) {
            List<String> kept = new List<String>();
            for (String part : raw.split(';')) {
                if (part.trim() != removedQuestion) { kept.add(part); }
            }
            controller.put(fieldApi, kept.isEmpty() ? null : String.join(kept, ';'));
            notes.add(fieldApi + ': removed start-school question');
            tally.put('fieldListStartSchool', (tally.containsKey('fieldListStartSchool') ? tally.get('fieldListStartSchool') : 0) + 1);
            changed = true;
        }
    }

    if (changed) {
        toUpdate.add(controller);
        report.add(controller.Name + ' | ' + String.join(notes, '; '));
    }
}

System.debug('MIGRATION controllers=' + controllers.size() + ' toChange=' + toUpdate.size());
System.debug('MIGRATION tally=' + JSON.serialize(tally));
for (String line : report) { System.debug('MIGRATION change: ' + line); }

if (!DRY_RUN && !toUpdate.isEmpty()) {
    List<String> errors = new List<String>();
    for (Database.SaveResult r : Database.update(toUpdate, false)) {
        if (!r.isSuccess()) { errors.add(r.getId() + ': ' + r.getErrors()[0].getMessage()); }
    }
    System.debug('MIGRATION saved=' + (toUpdate.size() - errors.size()) + ' errors=' + JSON.serialize(errors));
}
