# School/College Filter Question Fix

**Date:** February 17, 2026  
**Status:** ✅ Deployed to Dev

## Problem

Filter questions (like School_College) were not being saved to the Interaction record when answered, despite being required for program filtering.

## Root Causes

### 1. Filter Values Not Stored in Interaction Object (LWC)
The `handleProgramFilterChange` method in `rfiForm.js` was updating `this.filterValues` (used for filtering programs) but **NOT** updating `this.interaction` object with the selected values. When the form submitted, the interaction record didn't contain the filter field values.

### 2. School/College Filter Using Text Instead of Account IDs (Apex)
The School_College filter question was using `getOptionsFromDelineatedString()`, which returns text values (label=value). This meant:
- Users selected text values like "College of Arts and Sciences"
- But the `St_Thomas_College_School__c` field on Interaction expects an Account ID (lookup field)
- The text value couldn't be saved to the lookup field

### 3. Program Filtering Logic Needed Account ID → School Name Conversion (Apex)
When filtering programs by School/College:
- The filter value was an Account ID (from the selected school)
- But `Program__c.Associated_Schools__c` is a multipicklist containing school NAMES
- The filter query failed to match programs because it was comparing IDs to names

## Solutions Implemented

### 1. LWC: Store Filter Values in Interaction Object
**File:** `force-app/main/default/lwc/rfiForm/rfiForm.js`

Updated `handleProgramFilterChange` to also store the filter value in the interaction object:

```javascript
this.interaction = {
    ...this.interaction,
    [name]: value,  // ← NEW: Store the filter value in the interaction
    Major_Program_1__c: '',
    Major_Program_2__c: '',
    Major_Program_3__c: '',
    Major_Program_4__c: ''
};
```

**Impact:** All filter questions (School/College, Citizenship, Degree Type, etc.) now save to the interaction record when submitted.

### 2. Apex: Return Account IDs for School/College Filter
**File:** `force-app/main/default/classes/rfiFormController.cls`

#### A. Enhanced `getUSTSchoolList()` Method to Handle Both Filtered and Full Lists
Combined the original `getUSTSchoolList()` and new filtering logic into a single method that:
- **With parameter:** Takes semicolon-delimited school names and returns only those schools (filtered list)
- **Without parameter:** Gets all schools from `School_College__c` picklist (full list)
- Queries Account records matching the school names
- Returns `picklistOption` objects with Account IDs as values and school names as labels

```apex
/**
 * Get school list with Account IDs for use in picklists
 * If schoolNames parameter is provided, returns only those schools (filtered list)
 * If schoolNames is blank, returns all schools from School_College__c picklist (full list)
 * @param schoolNames Optional semicolon-delimited list of school names to filter by
 * @return List of picklistOption with Account IDs as values and school names as labels
 */
public static List<picklistOption> getUSTSchoolList(String schoolNames) {
    List<String> schoolNameList = new List<String>();
    
    if (String.isBlank(schoolNames)) {
        // No filter provided - get all schools from School_College__c picklist
        Schema.DescribeFieldResult d = Schema.SObjectType.RFI_Controller__c.fields.getMap().get('School_College__c').getDescribe();
        for (Schema.PicklistEntry e : d.getPicklistValues()) {
            if (e.isActive()) {
                schoolNameList.add(String.valueOf(e.getValue()));
            }
        }
    } else {
        // Filter provided - use only specified schools
        schoolNameList = schoolNames.split(';');
    }
    
    // Query for Account records matching the school names
    List<Account> schoolAccounts = [
        SELECT Id, School_College_Name__c
        FROM Account
        WHERE School_College_Name__c IN :schoolNameList
        AND RecordType.DeveloperName = 'University_Department'
        AND Banner_Key__c LIKE 'STVCOLL-%'
        AND Name != 'other'
    ];
    
    // Return Account IDs as values
    List<picklistOption> opts = new List<picklistOption>();
    for (Account acc : schoolAccounts) {
        picklistOption po = new picklistOption();
        po.label = acc.School_College_Name__c;  // Display name
        po.value = acc.Id;                      // Save ID to lookup field
        opts.add(po);
    }
    return opts;
}

// Overloaded method for backward compatibility
public static List<picklistOption> getUSTSchoolList() {
    return getUSTSchoolList(null);
}
```

#### B. Updated Filter Field Loop
Modified the filter field creation loop to use `getUSTSchoolList()` with parameter for School_College filter:

```apex
// Special handling for School_College filter - return Account IDs instead of text values
if (key == 'School_College_To_Display__c') {
    newField.picklistValues = getUSTSchoolList((String) rfiController.get(key));
} else {
    newField.picklistValues = getOptionsFromDelineatedString((String) rfiController.get(key));
}
```

**Impact:** 
- School/College filter returns Account IDs when configured with specific schools
- "St Thomas Colleges" field (full list) continues to work with existing `getUSTSchoolList()` call (no parameter)
- Both use the same method for consistency and maintainability

### 3. Apex: Convert Account ID to School Name for Program Filtering
**File:** `force-app/main/default/classes/rfiFormController.cls`

#### A. Added Mapping for St_Thomas_College_School__c
```apex
Map<String, String> leadToProgramFieldMap = new Map<String, String>{
    // ...existing mappings...
    'St_Thomas_College_School__c' => 'Associated_Schools__c'  // Filter question uses this field name
};
```

#### B. Added Account ID → School Name Conversion in filterQuery()
```apex
// Special handling for St_Thomas_College_School__c - convert Account ID to School Name
if (filterKey == 'St_Thomas_College_School__c') {
    // filterValue is an Account ID, we need to get the School_College_Name__c
    List<Account> accounts = [
        SELECT School_College_Name__c
        FROM Account
        WHERE Id = :filterValue
        LIMIT 1
    ];
    if (!accounts.isEmpty() && String.isNotBlank(accounts[0].School_College_Name__c)) {
        filterValue = accounts[0].School_College_Name__c;
        System.debug('Converted Account ID to School Name: ' + filterValue);
    }
}
```

**Impact:** Program filtering now works correctly by comparing school names (not IDs) against `Program__c.Associated_Schools__c`.

## How It Works Now

### User Journey
1. User lands on RFI form
2. Sees **School/College** filter question (e.g., "Select your School/College")
3. Picklist shows only configured schools (e.g., "College of Arts and Sciences", "Opus College of Business")
4. User selects a school
5. Form stores **Account ID** in `this.interaction.St_Thomas_College_School__c`
6. Program list filters to show only programs from that school
7. User submits form
8. Interaction record is created with `St_Thomas_College_School__c` = Account ID ✅

### Program Filtering Journey
1. User selects "Opus College of Business" from filter
2. LWC passes `filterValues = { St_Thomas_College_School__c: '001XXXXXXXXXX' }` to `getPrograms()`
3. Apex `filterQuery()` method:
   - Receives Account ID `001XXXXXXXXXX`
   - Queries Account to get `School_College_Name__c = "Opus College of Business"`
   - Builds SOQL: `AND Associated_Schools__c INCLUDES ('Opus College of Business')`
4. Programs filtered correctly ✅

## Testing

### Manual Testing Steps
1. Navigate to RFI form with School_College filter configured
2. Answer the School/College filter question (e.g., select "Opus College of Business")
3. Verify:
   - ✅ Programs list filters to show only programs from that school
   - ✅ Academic interest selector shows only programs from that school
4. Fill out rest of form and submit
5. Check created Interaction record:
   - ✅ `St_Thomas_College_School__c` field is populated with Account ID
   - ✅ Field shows school name in UI (lookup relationship working)

### Expected Results
- ✅ School/College filter shows only configured schools
- ✅ Selecting a school filters programs correctly
- ✅ Submitting form saves Account ID to `St_Thomas_College_School__c`
- ✅ Interaction record displays school name via lookup relationship

## Files Changed

1. **LWC Component**
   - `force-app/main/default/lwc/rfiForm/rfiForm.js`
   - Updated `handleProgramFilterChange()` to store filter values in interaction object

2. **Apex Controller**
   - `force-app/main/default/classes/rfiFormController.cls`
   - Added `getFilteredSchoolList()` method
   - Updated filter field loop to use `getFilteredSchoolList()` for School/College
   - Added `St_Thomas_College_School__c` mapping in `filterQuery()`
   - Added Account ID → School Name conversion logic in `filterQuery()`

## Deployment

```powershell
# Deploy LWC
cci task run deploy --path force-app/main/default/lwc/rfiForm --org dev

# Deploy Apex
cci task run deploy --path force-app/main/default/classes --org dev
```

**Status:** ✅ Successfully deployed to dev org on February 17, 2026

## Related Documentation

- [Main Guide](MAIN_GUIDE.md) - RFI Form system overview
- [Interaction Questions Guide](RFI_INTERACTION_QUESTIONS_GUIDE.md) - Question configuration
- [Troubleshooting](TROUBLESHOOTING.md) - Common issues

## Pattern for Future Reference

**When creating filter questions that map to lookup fields:**

1. **Apex:** Create a dedicated method to return ID/name pairs (like `getFilteredSchoolList()`)
2. **Apex:** Use special handling in the filter field loop to call the dedicated method
3. **Apex:** Add mapping in `filterQuery()` for the Interaction field → Program field
4. **Apex:** Add ID → Name conversion logic if the Program field uses text/multipicklist
5. **LWC:** Ensure `handleProgramFilterChange()` stores values in `this.interaction`

This pattern ensures:
- ✅ Correct values stored in Interaction record
- ✅ Program filtering works correctly
- ✅ Users see human-readable names in UI
- ✅ Lookup relationships maintain data integrity

