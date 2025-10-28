# Academic Interest Selector - Admin Configuration Tool

## Overview
The **Academic Interest Selector** is a Lightning Web Component designed as an **administrative configuration tool** for RFI Controller records. It helps admins select which academic programs should appear on public-facing RFI forms.

## Purpose

### What It Does
- **Displays ALL available programs** that meet RFI criteria (Active, Program Display includes "RFI", etc.)
- **Shows full program names** grouped by school/degree for easy browsing
- **Allows unlimited selections** - no maximum selection limit
- **Auto-saves selections** to the `Academic_Interests_To_Display__c` field
- **Provides visual feedback** with selection count and save status

### Who Uses It
**Administrators** who configure RFI Controller records to determine which programs appear on public-facing RFI forms.

## How It Works

### 1. Loading Programs
When the component loads on an RFI Controller record page:

```
1. Reads Academic_Level__c (U/G) from RFI Controller
2. Reads School_College__c from RFI Controller  
3. Reads current Academic_Interests_To_Display__c selections
4. Calls getProgramsWithShortCodes() with:
   - academic_level: from controller
   - school_college: from controller
   - academic_interest_codes: NULL (to get ALL programs)
   - filters: null
5. Displays programs grouped by Degree__c
6. Pre-selects currently configured programs
```

### 2. Program Filtering
Programs are automatically filtered by the Apex method to show only:
- ✅ Active programs (`Active__c = true`)
- ✅ RFI-eligible programs (`Program_Display__c` includes "RFI")
- ✅ Matching academic level (Undergraduate or Graduate)
- ✅ Matching school/college (if specified)
- ✅ Correct record type (`Recruitment_Program`)

### 3. Saving Selections
When admin selects/deselects programs:

```
1. Component captures change event
2. Builds semicolon-delimited string of short codes
3. Updates RFI Controller record via updateRecord()
4. Shows success toast notification
5. Refreshes wired data
```

**Example Saved Value:** `"CSCI;BIOL;CHEM;MATH;PHYS"`

## User Interface

### Card Header
- **Title:** "Select Academic Interests to Display on RFI (X selected)"
- **Badge:** Shows count of selected programs
- **Spinner:** Displays when saving

### Content Area
- **Help Text:** Explains purpose and filtering
- **Multi-Select Component:** Grouped list of programs
  - Group headers: Degree/School names
  - Options: Full program names
  - Pills: Selected programs displayed as removable pills

### Visual Feedback
- ✅ Success icon and message after save
- 🔄 Loading spinner during data fetch
- 💾 Saving spinner during update
- ❌ Error message if load/save fails

## Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│ Admin Opens RFI Controller Record                           │
│   Academic_Level__c: "U"                                    │
│   School_College__c: null                                   │
│   Academic_Interests_To_Display__c: "CSCI;MATH"            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ Component Loads All Undergraduate Programs                   │
│   getProgramsWithShortCodes(academic_level: 'U',            │
│                             school_college: null,            │
│                             academic_interest_codes: null)   │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ Display Programs Grouped by Degree                           │
│   Bachelor of Arts                                           │
│     ☑ Computer Science (CSCI) [pre-selected]                │
│     ☐ English (ENGL)                                        │
│     ☑ Mathematics (MATH) [pre-selected]                     │
│   Bachelor of Science                                        │
│     ☐ Biology (BIOL)                                        │
│     ☐ Chemistry (CHEM)                                      │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ Admin Selects Biology                                        │
│   Selection: CSCI;MATH;BIOL                                 │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ Auto-Save to RFI Controller                                  │
│   updateRecord({                                             │
│     Id: [RFI Controller Id],                                │
│     Academic_Interests_To_Display__c: "CSCI;MATH;BIOL"      │
│   })                                                         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ Show Success Message                                         │
│   ✅ "3 academic interest(s) selected"                       │
│   ✅ "Selections saved automatically"                        │
└─────────────────────────────────────────────────────────────┘
```

## Use Cases

### Scenario 1: Undergraduate General Program
**Configuration:**
- Academic Level: "U"
- School College: (blank)

**Result:** Shows ALL undergraduate programs across all schools
- Computer Science, Biology, English, History, Mathematics, etc.
- Grouped by degree type (BA, BS, BFA, etc.)

**Admin Action:** Select 10-15 most popular programs to display on public RFI

### Scenario 2: Graduate Law School
**Configuration:**
- Academic Level: "G"
- School College: "School of Law"

**Result:** Shows ONLY law school graduate programs
- Juris Doctor, JD/MBA Dual Degree, LLM programs

**Admin Action:** Select all law programs to display (usually 3-5)

### Scenario 3: Undergraduate Business School
**Configuration:**
- Academic Level: "U"
- School College: "Opus College of Business"

**Result:** Shows undergraduate business programs
- Accounting, Finance, Marketing, Management, etc.

**Admin Action:** Select business programs to promote

## Component Features

### ✅ No Selection Limit
Unlike end-user forms, admins can select as many programs as needed - no artificial limits.

### ✅ Auto-Save
Every selection/deselection is immediately saved to the RFI Controller record. No "Save" button required.

### ✅ Visual Feedback
- Selection count displayed in title
- Success message confirms save
- Saving spinner prevents double-updates

### ✅ Pre-Selection
Currently configured programs are pre-selected when component loads, making it easy to modify existing configurations.

### ✅ Grouped Display
Programs organized by degree/school make it easy to find and select related programs together.

### ✅ Full Names
Display full program names (not codes) so admins can make informed selections without looking up abbreviations.

## Technical Details

### Component Properties
| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `recordId` | String | (auto) | RFI Controller record ID |
| `label` | String | "Select Academic Interests..." | Card title |

### Reactive Properties
| Property | Type | Description |
|----------|------|-------------|
| `programOptions` | Array | All available programs (grouped) |
| `selectedValues` | Array | Currently selected short codes |
| `isLoading` | Boolean | True while loading programs |
| `isSaving` | Boolean | True while saving to record |
| `error` | Object | Error object if load fails |

### Key Methods
| Method | Purpose |
|--------|---------|
| `wiredRFIController()` | Wire service to load RFI Controller data |
| `loadPrograms()` | Fetch all available programs from Apex |
| `handleChange()` | Handle selection changes |
| `saveSelections()` | Update RFI Controller record |

### Field Mapping
| Source | Destination |
|--------|-------------|
| Selected short codes | `Academic_Interests_To_Display__c` |
| Semicolon-delimited | e.g., "CSCI;BIOL;CHEM" |

## Installation & Setup

### Step 1: Deploy Component
```bash
sfdx force:source:deploy -p force-app/main/default/lwc/academicInterestSelector
```

### Step 2: Add to RFI Controller Record Page
1. Setup → Object Manager → RFI Controller → Lightning Record Pages
2. Edit your record page
3. Drag "Academic Interest Selector" component to page
4. Save and activate

### Step 3: No Configuration Needed!
The component automatically:
- Reads Academic Level and School College from the record
- Loads appropriate programs
- Saves to Academic_Interests_To_Display__c field

## Best Practices

### 1. Configure Academic Level First
Set the `Academic_Level__c` field before using the selector. This filters programs appropriately.

### 2. Set School/College for Focused Lists
If you want a shorter, targeted list, set `School_College__c` to filter programs.

### 3. Select Popular Programs First
Choose the most commonly requested programs to reduce decision fatigue for prospects.

### 4. Review Periodically
Regularly review and update selections based on:
- New programs launched
- Programs being sunsetted
- Marketing campaigns
- Enrollment priorities

### 5. Test Public Form
After making selections, test the public RFI form to ensure programs appear correctly.

## Troubleshooting

### Issue: No Programs Displayed
**Cause:** No programs match the criteria
**Fix:** 
- Check Academic_Level__c is set
- Verify programs exist with Active__c = true
- Confirm programs have Program_Display__c including "RFI"

### Issue: Wrong Programs Showing
**Cause:** Academic Level or School College mismatch
**Fix:**
- Verify Academic_Level__c value (U or G)
- Check School_College__c matches program's Associated_Schools__c

### Issue: Selections Not Saving
**Cause:** Field-level security or validation rule
**Fix:**
- Check FLS for Academic_Interests_To_Display__c
- Review validation rules on RFI Controller
- Check user permissions

### Issue: Component Not Loading
**Cause:** Missing permissions or field access
**Fix:**
- Grant read/write access to RFI_Controller__c fields
- Ensure user can edit RFI Controller records
- Check component is added to Lightning page

## Comparison: Old vs New

### Old Approach (Manual Entry)
```
❌ Admin manually types: "CSCI;BIOL;CHEM"
❌ Risk of typos in codes
❌ Must remember or look up short codes
❌ No validation
❌ Can't see full program names
```

### New Approach (This Component)
```
✅ Admin selects from dropdown
✅ Full program names displayed
✅ Grouped by school/degree
✅ Auto-saves selections
✅ Validates against available programs
✅ Shows selection count
✅ No typing required
```

## Impact on Public RFI Forms

When users fill out the public RFI form:

**Before Admin Selection:**
```
No programs available or all programs shown (overwhelming)
```

**After Admin Selection:**
```
Only selected programs appear in the academic interest dropdown
- Full program names displayed
- Grouped by degree
- Easy to browse
- Focused choices
```

## Integration Points

### Reads From
- `RFI_Controller__c.Academic_Level__c` - Filters programs
- `RFI_Controller__c.School_College__c` - Filters programs  
- `RFI_Controller__c.Academic_Interests_To_Display__c` - Current selections

### Writes To
- `RFI_Controller__c.Academic_Interests_To_Display__c` - Saves selections

### Calls
- `rfiFormController.getProgramsWithShortCodes()` - Fetches programs

### Used By
- RFI Controller record page (admin view)
- Admin users configuring RFI forms

## Future Enhancements

Potential improvements:

1. **Bulk Operations** - Copy selections from another RFI Controller
2. **Program Preview** - Show program descriptions on hover
3. **Usage Analytics** - Show which programs are most selected by prospects
4. **Recommendations** - Suggest popular program combinations
5. **Reordering** - Allow custom sort order beyond alphabetical
6. **Categories** - Add custom groupings beyond degree
7. **History** - Track changes to selections over time

## Support

For questions or issues:
- Review [ACADEMIC_INTEREST_SELECTOR_GUIDE.md](ACADEMIC_INTEREST_SELECTOR_GUIDE.md)
- Check Program__c data meets requirements
- Verify RFI Controller configuration
- Contact Salesforce admin team

---

**Component Type:** Admin Configuration Tool  
**Target Users:** RFI Controller Administrators  
**Purpose:** Configure which programs appear on public RFI forms  
**Field Updated:** `Academic_Interests_To_Display__c`  
**Selection Limit:** None (unlimited selections)

