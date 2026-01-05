# Data Validation Fix - Clean Artifact Codes

## ✅ Issue Fixed

Added automatic validation and cleanup to ensure only valid program codes from the Selected Programs list are saved to `Academic_Interests_To_Display__c`, removing any artifacts from other processes.

---

## Problem

**Symptom:** The field `Academic_Interests_To_Display__c` could contain program codes that:
- No longer exist in the available programs list
- Were added by another process
- Are from old/deprecated programs
- Don't meet current RFI criteria

**Root Cause:** The component was loading ALL codes from the field and saving them back without validating they exist in the current program list.

---

## Solution

Added automatic validation when programs load that:
1. ✅ **Builds valid code set** - Creates a Set of all valid program codes from loaded programs
2. ✅ **Filters selectedValues** - Removes any codes not in the valid set
3. ✅ **Auto-saves if changed** - Quietly saves the cleaned list back to the field
4. ✅ **Logs cleanup** - Console logs how many invalid codes were removed

---

## How It Works

### Step 1: Load Programs
```javascript
// Get all available programs from Apex
const programs = await getProgramsWithShortCodes(...);
```

### Step 2: Build Valid Code Set
```javascript
// Extract only valid program codes (not groups)
const validProgramCodes = new Set(
    this.allPrograms
        .filter(prog => !prog.is_group && prog.value)
        .map(prog => prog.value)
);
```

### Step 3: Filter Selected Values
```javascript
// Keep only codes that exist in valid programs
this.selectedValues = this.selectedValues.filter(code => 
    validProgramCodes.has(code)
);
```

### Step 4: Auto-Save if Cleaned
```javascript
// If we removed invalid codes, save the cleaned list
if (originalSelectedCount !== this.selectedValues.length) {
    console.log(`Cleaned ${diff} invalid program code(s)`);
    this.saveSelectionsQuietly(); // No toast notification
}
```

---

## Example Scenarios

### Scenario 1: Old Program Code Removed
```
Field Contains: "CSCI;BIOL;OLD_CODE;CHEM"
Available Programs: CSCI, BIOL, CHEM (OLD_CODE no longer exists)

Result After Load:
  Selected Values: ["CSCI", "BIOL", "CHEM"]
  Field Saved: "CSCI;BIOL;CHEM"
  Console: "Cleaned 1 invalid program code(s) from selections"
```

### Scenario 2: Program No Longer Meets RFI Criteria
```
Field Contains: "MBA;JD;INACTIVE_PROG"
Available Programs: MBA, JD (INACTIVE_PROG not Active or not RFI)

Result After Load:
  Selected Values: ["MBA", "JD"]
  Field Saved: "MBA;JD"
  Console: "Cleaned 1 invalid program code(s) from selections"
```

### Scenario 3: External Process Added Code
```
Field Contains: "CSCI;BIOL;EXTERNAL_CODE;CHEM"
Available Programs: CSCI, BIOL, CHEM (EXTERNAL_CODE from other system)

Result After Load:
  Selected Values: ["CSCI", "BIOL", "CHEM"]
  Field Saved: "CSCI;BIOL;CHEM"
  Console: "Cleaned 1 invalid program code(s) from selections"
```

### Scenario 4: All Codes Valid
```
Field Contains: "CSCI;BIOL;CHEM"
Available Programs: CSCI, BIOL, CHEM (all valid)

Result After Load:
  Selected Values: ["CSCI", "BIOL", "CHEM"]
  Field Saved: (no save needed)
  Console: (no message)
```

---

## New Methods

### saveSelectionsQuietly()
**Purpose:** Save selections without showing toast notification

**Used For:** Automatic cleanup when loading component

**Behavior:**
- Updates the field with cleaned values
- Refreshes wired data
- Does NOT show success toast
- Logs error to console if save fails

```javascript
async saveSelectionsQuietly() {
    try {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[ACADEMIC_INTERESTS_FIELD.fieldApiName] = this.selectedValues.join(';');
        
        await updateRecord({ fields });
        await refreshApex(this.wiredRecordResult);
    } catch (error) {
        console.error('Error saving cleaned selections:', error);
    }
}
```

---

## Benefits

### Data Quality
✅ **Ensures Validity** - Only valid program codes saved
✅ **Removes Artifacts** - Cleans up codes from other processes
✅ **Self-Healing** - Automatically fixes invalid data on load

### User Experience
✅ **Transparent** - Happens automatically, no user action needed
✅ **No False Selections** - Selected list only shows real programs
✅ **Console Logging** - Admins can see what was cleaned

### Maintenance
✅ **Prevents Data Drift** - Field stays in sync with available programs
✅ **Safe Transitions** - Handles program changes gracefully
✅ **Audit Trail** - Console logs provide cleanup history

---

## Console Output

### When Cleanup Happens
```
Cleaned 2 invalid program code(s) from selections
```

### When All Valid
```
(no output - no cleanup needed)
```

---

## Testing

### Test Invalid Codes
1. Manually add invalid code to field:
   ```
   Academic_Interests_To_Display__c = "CSCI;BIOL;FAKE_CODE"
   ```
2. Open RFI Controller record
3. Check browser console for cleanup message
4. Verify field now contains only: `"CSCI;BIOL"`

### Test All Valid
1. Field contains only valid codes:
   ```
   Academic_Interests_To_Display__c = "CSCI;BIOL;CHEM"
   ```
2. Open RFI Controller record
3. No console message
4. Field unchanged

### Test Empty Field
1. Field is empty or null
2. Open RFI Controller record
3. No console message
4. Selected Programs list is empty

---

## Edge Cases Handled

### Empty or Null Field
- `selectedValues` = empty array
- No cleanup needed
- No save triggered

### All Codes Invalid
- All codes filtered out
- `selectedValues` = empty array
- Saves empty value
- Console logs cleanup count

### Duplicate Codes
- Set operations handle duplicates
- Only unique valid codes kept

### Group Headers
- Filtered out (`!prog.is_group`)
- Never included in validation

### Null/Undefined Values
- Filtered with `.filter(v => v)`
- Empty strings removed

---

## Integration Points

### When Cleanup Runs
✅ **On Component Load** - After programs fetched from Apex
✅ **Before Display** - Cleaned before rendering lists
✅ **Automatic** - No user interaction required

### When Cleanup Doesn't Run
❌ **User Moves Items** - Normal save with toast
❌ **All Codes Valid** - No cleanup needed
❌ **Component Not Loaded** - Field unchanged

---

## Deployment

```bash
sfdx force:source:deploy -p force-app/main/default/lwc/academicInterestSelector
```

### After Deploy
1. Open any RFI Controller record
2. Check browser console (F12)
3. Look for cleanup messages
4. Verify Selected Programs list is correct

---

## Monitoring

### Check for Cleanup Activity
```javascript
// Browser Console Filter: "Cleaned"
// Look for messages like:
// "Cleaned 2 invalid program code(s) from selections"
```

### Find Records with Invalid Codes
Before deploying, you can query:
```sql
SELECT Id, Name, Academic_Interests_To_Display__c
FROM RFI_Controller__c
WHERE Academic_Interests_To_Display__c != null
```
Then check if codes are valid against Program__c records.

---

## Summary

✅ **Validates on Load** - Checks all selected codes against available programs
✅ **Auto-Cleans** - Removes invalid codes automatically
✅ **Quiet Save** - Updates field without user notification
✅ **Console Logging** - Tracks cleanup activity
✅ **Self-Healing** - Fixes data quality issues transparently

**The field will now only contain valid program codes that exist in the Selected Programs list!** 🎉

---

**Updated:** October 27, 2025
**Feature:** Automatic validation and cleanup of program codes
**Status:** ✅ Ready to Deploy

