# UST Salesforce RFI — Troubleshooting Guide

**Last Updated:** March 5, 2026

---

## Unified Question Manager (`rfiUnifiedQuestionManager`)

### Questions not appearing on rfiForm
**Symptom:** The form loads but shows only Submit button or is blank.

**Check:**
1. Open the RFI Controller record → Unified Question Manager
2. Verify at least one question is in the list
3. Click **Save Configuration** — confirm success toast
4. Hard-refresh the form page (Ctrl+Shift+R) to bust the wire cache

**Root cause:** `Unified_Questions__c` is empty `[]` or not saved. Apex falls back to legacy path which may also be empty.

---

### Filter picklist is empty on the form
**Symptom:** A filter question (e.g. School/College) appears on the form but the dropdown has no options.

**Check:**
1. Open the filter question's edit modal in the manager
2. Verify the dual-listbox has values in the "Show on Form" side
3. Save Configuration
4. Verify the corresponding `_To_Display__c` field on the controller record is populated (e.g. `School_College_To_Display__c`)

**Root cause:** `filterSelectedValues` in the JSON is empty, and the `_To_Display__c` field is also blank.

---

### Academic Programs stays locked after all filters answered
**Symptom:** User answers all filter questions but the Academic Programs field stays locked.

**Check:**
1. Open browser console — look for `filterValues` log output
2. Verify the `name` attribute on each filter combobox matches the `filterInteractionAPIName` in the JSON
3. In Apex, confirm `filterValues.put(interactionApiName, '')` is called for each filter question

**Root cause:** Mismatch between the interaction API name stored in the JSON and the `name` attribute used on the combobox in the form.

---

### Migration banner appears on every load
**Symptom:** "Unsaved migration" banner keeps showing.

**Fix:** Click **Save Configuration** once to commit the migrated questions to `Unified_Questions__c`. The banner only shows when the field is blank.

---

## rfiForm

### Form loads but all fields are blank inputs (picklist fields show as text)
**Symptom:** Citizenship or other picklist fields render as `<lightning-input>` instead of `<lightning-combobox>`.

**Root cause:** The `fieldInteractionAPIName` stored in the question JSON doesn't match the actual Interaction field API name.

**Fix:**
1. Open the question's edit modal in the manager
2. Re-select the correct Interaction field from the dropdown
3. Save Configuration and redeploy if needed

---

### Form throws "Cannot read property of undefined" on load
**Check browser console for the specific property.** Common causes:
- `rfiData` not yet populated — wire adapter still loading
- `filterValues` null — check Apex `getRFIForm` returns a valid `filterValues` map
- `fields` getter accessing undefined array — check `_fields` is initialized to `[]`

---

### Address field shows individual City/State/Zip inputs instead of combined address
This is correct behavior. The unified manager maps "Address" to a single `lightning-input-address` component. The individual sub-fields (Address 1/2/3, City, State, Zipcode) from the old legacy system are collapsed into one Address entry during migration.

---

## Apex / Data

### Interaction not created on form submit
**Check:**
1. Open browser console for JS errors on submit
2. Check Apex logs in Setup → Debug Logs
3. Verify required fields on `Interaction__c` are being populated
4. Check `submitRfiInteraction()` in `rfiFormController.cls` for validation logic

---

### Field deploy says "Unchanged" but field doesn't exist in org
**Root cause:** SF CLI source tracking cache is stale.

**Solutions (in order):**
1. Deploy the entire object: `cci task run deploy --path force-app/main/default/objects/RFI_Controller__c --org dev 2>&1`
2. Clear cache: `Remove-Item -Path ".sf",".sfdx" -Recurse -Force` then redeploy
3. Create manually: Setup → Object Manager → RFI Controller → Fields & Relationships → New

---

## Legacy Form (`requestForInformationForm`)

⚠️ **Do not modify the legacy form.** It writes to `Lead` and is kept for reference only.

If it appears broken, the issue is pre-existing or environmental — do not attempt fixes that could affect `rfiForm`.

---

## Deployment Issues

### Deploy fails with "conflicts" using sf CLI
Use `cci` instead, which bypasses source tracking conflict detection:
```powershell
cci task run deploy --path force-app/main/default/lwc/componentName --org dev 2>&1
```

Or add `--ignore-conflicts` to the sf CLI command.

### Deploy succeeds but changes don't appear
The `@AuraEnabled(Cacheable=true)` Apex methods are cached. Force a cache bust:
- Hard refresh (Ctrl+Shift+R) in browser
- Or temporarily change the controller name to force a new wire call

---

## Jest Tests

```powershell
# Run all tests
npm test 2>&1

# Run with coverage
npm test -- --coverage 2>&1

# Run single file
npm test -- rfiUnifiedQuestionManager 2>&1
```

See [JEST_TESTING_GUIDE.md](JEST_TESTING_GUIDE.md) for mock setup patterns.
