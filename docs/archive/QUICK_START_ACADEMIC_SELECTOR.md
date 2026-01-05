# Academic Interest Selector - Quick Start Guide

## What Was Created

### 1. Lightning Web Component
📁 **Location:** `force-app/main/default/lwc/academicInterestSelector/`

**Files:**
- `academicInterestSelector.js` - Component logic
- `academicInterestSelector.html` - Template
- `academicInterestSelector.js-meta.xml` - Metadata
- `academicInterestSelector.css` - Styles

### 2. Apex Controller Method
📁 **Location:** `force-app/main/default/classes/rfiFormController.cls`

**New Method:** `getProgramsWithShortCodes()`
- Returns programs with short codes as values
- Filters based on RFI Controller configuration
- Groups results by degree

### 3. Test Coverage
📁 **Location:** `force-app/main/default/classes/rfiFormController_TEST.cls`

**New Test Methods:**
- `testGetProgramsWithShortCodes_undergraduate()`
- `testGetProgramsWithShortCodes_graduate()`
- `testGetProgramsWithShortCodes_withFilter()`

### 4. Documentation
📁 **Location:** `ACADEMIC_INTEREST_SELECTOR_GUIDE.md`

Complete guide with usage, configuration, and troubleshooting

---

## How It Works

### Before (Old Approach)
```
Stores: a0X1234567890 (Program__c Record ID)
Displays: "MBA" (short code or abbreviation)
Problem: Hard to know what program the ID represents
```

### After (New Component)
```
Stores: MBA (Program_Major_Concentration__c short code)
Displays: "Master of Business Administration" (full name)
Grouped by: "Master of Business Administration" (Degree__c)
Benefit: Clear display, efficient storage, easy filtering
```

---

## Quick Deployment

### Option 1: Using Salesforce CLI

```bash
# Deploy all new files
sfdx force:source:deploy -p force-app/main/default/lwc/academicInterestSelector
sfdx force:source:deploy -p force-app/main/default/classes/rfiFormController.cls
sfdx force:source:deploy -p force-app/main/default/classes/rfiFormController_TEST.cls

# Run tests
sfdx force:apex:test:run -n rfiFormController_TEST -r human
```

### Option 2: Using VS Code
1. Right-click `academicInterestSelector` folder → Deploy Source to Org
2. Right-click `rfiFormController.cls` → Deploy Source to Org
3. Right-click `rfiFormController_TEST.cls` → Deploy Source to Org

### Option 3: Deploy All at Once
```bash
# From project root
sfdx force:source:deploy -m "LightningComponentBundle:academicInterestSelector,ApexClass:rfiFormController,ApexClass:rfiFormController_TEST"
```

---

## Adding to Record Page (5 Steps)

### Step 1: Open Lightning App Builder
1. Go to **Setup** → **Object Manager** → **RFI Controller**
2. Click **Lightning Record Pages**
3. Select your record page (e.g., "RFI Controller Record Page")
4. Click **Edit**

### Step 2: Find the Component
- In the Components panel (left side)
- Scroll to **Custom - Managed** section
- Find **Academic Interest Selector**

### Step 3: Drag & Drop
- Drag the component to your desired location on the page
- Common placement: Below the RFI Controller details section

### Step 4: Configure Properties
Click the component to configure:

| Property | Recommended Value | Notes |
|----------|-------------------|-------|
| Label | "Academic Interests" | Displayed above the selector |
| Max Selections | 4 | Match your business rules |
| Required | false | Set to true if mandatory |

### Step 5: Save & Activate
1. Click **Save**
2. Click **Activate** (if not already active)
3. Click **Back** to return to the record

---

## Verification Checklist

After deployment, verify:

- [ ] Component appears in Lightning App Builder
- [ ] Component loads on RFI Controller record page
- [ ] Programs are grouped by degree/school
- [ ] Full program names are displayed
- [ ] Selection saves short codes
- [ ] Filtering works based on RFI Controller settings
- [ ] Max selections enforced
- [ ] Required validation works (if enabled)
- [ ] Apex tests pass with >75% coverage

---

## Configuration Tips

### For Undergraduate Programs
Set on RFI Controller:
```
Academic Level: U
School College: (leave blank or set specific)
Academic Interests to Display: CSCI;BIOL;CHEM (semicolon-separated)
```

### For Graduate Programs
Set on RFI Controller:
```
Academic Level: G
School College: School of Law (or specific school)
Academic Interests to Display: LW_JD;LW_JD2 (semicolon-separated)
```

### For All Programs
Leave Academic Interests to Display blank (will show all active RFI programs)

---

## Data Requirements

### Program__c Records Must Have:
✅ RecordType = "Recruitment_Program"
✅ Active__c = true
✅ Program_Display__c includes "RFI"
✅ Program_Name_on_Application__c = Full name
✅ Program_Major_Concentration__c = Short code (e.g., "CSCI", "MBA")
✅ Degree__c = Grouping name (e.g., "Bachelor of Arts")
✅ Academic_Level__c = "U" or "G"

### For Undergraduate:
✅ Program_Type__c includes: Major, Pre-Professional, Major Concentration, or Co-Major

### For Graduate:
✅ Associated_Schools__c matches School_College__c on RFI Controller
✅ For Law programs: Banner_Program_Code__c starts with "LW_"

---

## Common Issues & Solutions

### 🔴 Issue: No programs showing
**Check:**
1. Are there active Program__c records?
2. Is Program_Display__c set to include "RFI"?
3. Does Academic_Level__c match RFI Controller?
4. Are Program_Major_Concentration__c values populated?

**Fix:** Update Program__c records to meet criteria

---

### 🔴 Issue: Wrong programs showing
**Check:**
1. RFI Controller's "Academic Interests to Display" field
2. School_College__c matches Associated_Schools__c on programs

**Fix:** Update RFI Controller configuration

---

### 🔴 Issue: Component not loading
**Check:**
1. Is component deployed successfully?
2. Are field-level security settings correct?
3. Is it added to the Lightning page?

**Fix:** 
- Redeploy component
- Check permissions for RFI_Controller__c fields
- Re-add to Lightning page

---

### 🔴 Issue: Short codes not saving
**Check:**
1. Is Program_Major_Concentration__c populated on programs?
2. Check browser console for JavaScript errors

**Fix:** Ensure all programs have valid short codes

---

## Testing Scenarios

### Scenario 1: Single Selection
```
Configuration:
- Max Selections: 1
- Required: true

Expected:
- User must select exactly 1 program
- Only 1 pill appears after selection
```

### Scenario 2: Multiple Selections
```
Configuration:
- Max Selections: 4
- Required: false

Expected:
- User can select up to 4 programs
- All selections appear as pills
- Short codes stored separated by semicolon
```

### Scenario 3: Filtered Programs
```
RFI Controller:
- Academic Interests to Display: "CSCI;MATH;PHYS"

Expected:
- Only Computer Science, Mathematics, Physics shown
- Other programs filtered out
```

---

## Data Storage Format

### Stored Value Format
```
Single: "MBA"
Multiple: "CSCI;BIOL;CHEM"
Empty: "" (empty string)
```

### Where It's Stored
The component stores selected values in a field on the RFI Controller record. You'll need to create or specify a field to store these values (e.g., `Selected_Academic_Interests__c`).

**Recommended Field Setup:**
- API Name: `Selected_Academic_Interests__c`
- Type: Text Area (Long)
- Length: 131,072
- Description: Stores semicolon-delimited program short codes

---

## Next Steps

1. ✅ **Deploy** the component and Apex class
2. ✅ **Run tests** to verify functionality
3. ✅ **Add to Lightning page** for RFI Controller
4. ✅ **Test** with real data
5. ✅ **Train users** on the new interface
6. ✅ **Monitor** for any issues

---

## Support Resources

- **Full Documentation:** `ACADEMIC_INTEREST_SELECTOR_GUIDE.md`
- **Component Code:** `force-app/main/default/lwc/academicInterestSelector/`
- **Apex Code:** `force-app/main/default/classes/rfiFormController.cls`
- **Test Code:** `force-app/main/default/classes/rfiFormController_TEST.cls`

---

## Questions?

If you encounter issues or need customization:
1. Check the full documentation (ACADEMIC_INTEREST_SELECTOR_GUIDE.md)
2. Review the troubleshooting section above
3. Verify Program__c data meets requirements
4. Check browser console for error messages
5. Review Salesforce debug logs for Apex errors

