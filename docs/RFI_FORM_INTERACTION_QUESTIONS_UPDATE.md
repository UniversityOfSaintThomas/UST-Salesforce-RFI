# rfiForm Component Update - Use Interaction Questions

**Date:** January 5, 2026  
**Change:** Updated `rfiForm` to read from `Interaction_Questions__c` instead of `Additional_Questions__c`

---

## Summary

The `rfiForm` component (modern, Interaction-based form) now correctly reads additional questions from the `Interaction_Questions__c` field, which is managed by the `rfiAdditionalQuestionsInteractions` component.

## What Changed

### Apex Controller (rfiFormController.cls)

**File:** `force-app/main/default/classes/rfiFormController.cls`

1. **Added field to SOQL query:**
   ```apex
   Additional_Questions__c,      // Still needed for legacy support
   Interaction_Questions__c,     // NEW - for rfiForm
   ```

2. **Updated additional questions processing:**
   ```apex
   // OLD - Read from Additional_Questions__c (Lead field)
   if (String.isNotBlank(rfiController.Additional_Questions__c)) {
       List<Object> additionalQuestions = (List<Object>) JSON.deserializeUntyped(rfiController.Additional_Questions__c);
       // ...
   }

   // NEW - Read from Interaction_Questions__c (Interaction field)
   if (String.isNotBlank(rfiController.Interaction_Questions__c)) {
       List<Object> additionalQuestions = (List<Object>) JSON.deserializeUntyped(rfiController.Interaction_Questions__c);
       // ...
   }
   ```

3. **Updated comments:**
   - Changed references from `Additional_Questions__c` to `Interaction_Questions__c`
   - Clarified this is for "Interaction forms"

### Documentation (AI-TOOLS-CONFIG.md)

**File:** `docs/AI-TOOLS-CONFIG.md`

1. **Component descriptions updated:**
   - `rfiForm` - Now clearly states: "Creates Interactions, uses Interaction_Questions__c"
   - `requestForInformationForm` - Clarified: "Creates Leads, uses Additional_Questions__c"
   - `rfiAdditionalQuestionsInteractions` - Noted as "Used by rfiForm"

2. **Data storage patterns clarified:**
   - `Interaction_Questions__c` → used by `rfiForm` (modern)
   - `Additional_Questions__c` → used by `requestForInformationForm` (legacy)

---

## Why This Change?

### Previous State (Incorrect)
- `rfiForm` created **Interaction** records
- But read questions from `Additional_Questions__c` (designed for **Lead** fields)
- Questions configured in `rfiAdditionalQuestionsInteractions` were **ignored**
- Field mappings could be incorrect (Lead fields vs Interaction fields)

### Current State (Correct)
- `rfiForm` creates **Interaction** records
- Reads questions from `Interaction_Questions__c` (designed for **Interaction** fields)
- Questions configured in `rfiAdditionalQuestionsInteractions` are **used**
- Field mappings are correct (all Interaction fields)

---

## Component Relationships

### Modern Stack (Interactions)
```
Admin configures:
  rfiAdditionalQuestionsInteractions component
    ↓ saves to
  Interaction_Questions__c field
    ↓ read by
  rfiFormController.getRFIForm() Apex method
    ↓ used by
  rfiForm LWC component
    ↓ creates
  Interaction__c records
```

### Legacy Stack (Leads)
```
Admin configures:
  rfiAdditionalQuestions component (DataTable UI)
    ↓ saves to
  Additional_Questions__c field
    ↓ read by
  requestForInformationFormController Apex method
    ↓ used by
  requestForInformationForm LWC component
    ↓ creates
  Lead records
```

---

## Testing Checklist

Before using in production:

- [ ] Create test questions in `rfiAdditionalQuestionsInteractions` component
- [ ] Verify questions appear on public `rfiForm` 
- [ ] Test all question types:
  - [ ] Email
  - [ ] Picklist
  - [ ] Text box
  - [ ] Textarea
  - [ ] Static content
- [ ] Verify field mappings are correct (Interaction fields)
- [ ] Test form submission creates Interaction with question data
- [ ] Verify required fields validation works
- [ ] Test on mobile devices

---

## Backward Compatibility

### No Breaking Changes

**Legacy form still works:**
- `requestForInformationForm` unchanged
- Still reads from `Additional_Questions__c`
- Still creates Lead records
- Existing Lead-based RFI forms continue to function

**Both fields queried:**
- SOQL query includes both `Additional_Questions__c` and `Interaction_Questions__c`
- Controller can support both form types
- No data migration required

---

## Deployment

### What Was Deployed

```powershell
cci task run deploy --path force-app/main/default/classes --org dev
```

**Status:** ✅ Deployed successfully

**Files Changed:**
- `force-app/main/default/classes/rfiFormController.cls`
- `docs/AI-TOOLS-CONFIG.md`

### Verification

After deployment:
1. ✅ Apex class deployed without errors
2. ✅ Documentation updated
3. ⏳ **Manual testing required** - Create test questions and verify form display

---

## Important Notes

### For Admins

**To configure questions for the modern rfiForm:**
1. Navigate to RFI Controller record
2. Use the **"Interaction Questions Manager"** component (NOT "Add a Question")
3. Create questions that map to **Interaction** fields
4. Questions will automatically appear on public forms using this RFI Controller

**Wrong component:**
- "Add a Question" (rfiAdditionalQuestions) → For Lead-based forms only

**Correct component:**
- "Interaction Questions Manager" (rfiAdditionalQuestionsInteractions) → For rfiForm

### For Developers

**When debugging rfiForm:**
- Check `Interaction_Questions__c` field on RFI_Controller__c record
- Questions stored as JSON array
- Validate JSON structure matches expected format
- Check Apex debug logs for deserialization errors

**Field mapping:**
- Questions must map to valid Interaction__c fields
- Use API names (e.g., `Email__c`, `Phone__c`)
- Field must be updateable and creatable
- Check field-level security

---

## Related Changes

### Today's Work (Jan 5, 2026)
1. Created `rfiAdditionalQuestionsInteractions` component
2. Created `Interaction_Questions__c` field (manual)
3. Updated `rfiForm` to use Interaction questions ← **This change**
4. Updated documentation

### Future Enhancements
- [ ] Create migration tool to copy Lead questions to Interaction questions
- [ ] Add validation to ensure field mappings are correct
- [ ] Add preview mode to test questions before publishing
- [ ] Create question templates library

---

## Troubleshooting

### Questions Not Appearing on rfiForm

**Check:**
1. Questions configured in **Interaction Questions Manager** (not "Add a Question")
2. `Interaction_Questions__c` field has JSON data
3. RFI Controller name matches between admin component and public form
4. Questions map to valid Interaction fields
5. No JSON syntax errors (check debug logs)

### Field Mapping Errors

**Symptoms:**
- Questions appear but don't save data
- Errors on form submission

**Check:**
1. Field API names are correct (e.g., `Email__c` not `Email`)
2. Fields exist on Interaction__c object
3. Fields are updateable and creatable
4. User has field-level security access
5. No validation rules blocking insert

---

## Success Criteria

✅ **Change is successful when:**
1. Questions configured in Interaction Questions Manager appear on rfiForm
2. Form submission creates Interaction with question data populated
3. Field mappings work correctly
4. No errors in browser console or Apex logs
5. Legacy forms (Lead-based) continue to work

---

**Deployment Date:** January 5, 2026, 2:02 PM  
**Deployed By:** GitHub Copilot  
**Status:** ✅ Deployed, ⏳ Testing Required  
**Breaking Changes:** None

