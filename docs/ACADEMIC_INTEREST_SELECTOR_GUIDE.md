# Academic Interest Selector Component

## Overview
The **Academic Interest Selector** is a Lightning Web Component (LWC) designed for the RFI Controller record page. It provides an enhanced user interface for selecting academic programs by displaying full program names organized under school/degree headings, while storing only the compact short codes in the backend.

## Key Features

### 1. **User-Friendly Display**
- Shows full program names (e.g., "Master of Business Administration" instead of "MBA")
- Groups programs by degree/school for easy navigation
- Uses the existing `multiSelectPillsGroupable` component for consistent UI

### 2. **Efficient Storage**
- Stores only short codes (Program_Major_Concentration__c field values)
- Examples: "CSCI", "BIOL", "MBA", "LW_JD"
- Reduces database storage and improves query performance

### 3. **Smart Filtering**
- Automatically filters programs based on RFI Controller configuration:
  - Academic Level (Undergraduate/Graduate)
  - School/College
  - Academic Interests to Display
- Only shows programs marked as active and available for RFI display

## Component Files

```
force-app/main/default/lwc/academicInterestSelector/
├── academicInterestSelector.js           # Component logic
├── academicInterestSelector.html         # Template markup
├── academicInterestSelector.js-meta.xml  # Metadata configuration
└── academicInterestSelector.css          # Styling
```

## Usage

### Adding to RFI Controller Record Page

1. **Navigate to Setup** → Object Manager → RFI Controller
2. **Select Lightning Record Pages** → Edit the desired page
3. **Drag the "Academic Interest Selector"** component onto the page
4. **Configure the component** with these properties:
   - **Label**: Display label (default: "Academic Interests")
   - **Max Selections**: Maximum number of programs to select (default: 4)
   - **Required**: Whether selection is mandatory (default: false)

### Component Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `recordId` | String | (auto) | RFI Controller record ID (automatically provided) |
| `label` | String | "Academic Interests" | Display label for the selector |
| `maxSelections` | Integer | 4 | Maximum number of programs that can be selected |
| `required` | Boolean | false | Whether at least one selection is required |

## Backend Support

### New Apex Method: `getProgramsWithShortCodes`

Located in `rfiFormController.cls`, this method queries and returns programs with their short codes as values.

**Method Signature:**
```apex
@AuraEnabled(Cacheable=true)
public static List<programValues> getProgramsWithShortCodes(
    String academic_level, 
    String school_college, 
    String academic_interest_codes, 
    Map<String, String> filters
)
```

**Parameters:**
- `academic_level`: "U" (Undergraduate) or "G" (Graduate)
- `school_college`: School/college name to filter by
- `academic_interest_codes`: Semicolon-delimited list of program codes
- `filters`: Optional additional filters (Student Type, Delivery Type, etc.)

**Returns:**
A list of `programValues` objects containing:
- `label`: Full program name (Program_Name_on_Application__c)
- `value`: Short code (Program_Major_Concentration__c)
- `description`: Formatted string "Degree - ShortCode"
- `is_group`: Boolean indicating if this is a group header

### Query Filters Applied

The method automatically applies these filters:
1. ✅ Record Type = "Recruitment_Program"
2. ✅ Program Display includes "RFI"
3. ✅ Active = true
4. ✅ Academic Level matches the specified level
5. ✅ For Undergraduate: Program Type includes Major, Pre-Professional, Major Concentration, or Co-Major
6. ✅ For Graduate: Filters by Associated Schools and Banner Program Code (for Law programs)
7. ✅ Program_Major_Concentration__c matches specified codes (if provided)
8. ✅ Additional custom filters (if provided)

### Results Grouping

Programs are grouped by the `Degree__c` field and sorted alphabetically:
```
Bachelor of Arts
  └─ Computer Science (CSCI)
  └─ English (ENGL)
Bachelor of Science
  └─ Biology (BIOL)
  └─ Chemistry (CHEM)
Master of Business Administration
  └─ MBA (MBA)
```

## Data Flow

```
┌─────────────────────┐
│  RFI Controller     │
│  Record Page        │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Academic Interest   │
│ Selector Component  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ getProgramsWith     │
│ ShortCodes (Apex)   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Program__c Query    │
│ (Active RFI Progs)  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Return Grouped      │
│ Programs with       │
│ Short Codes         │
└─────────────────────┘
```

## Example Scenarios

### Scenario 1: Undergraduate Programs
**Configuration:**
- Academic Level: "U"
- School College: (not set)

**Result:**
```
Bachelor of Arts
  - Art History (ARTH)
  - Computer Science (CSCI)
  - English (ENGL)
Bachelor of Science
  - Biology (BIOL)
  - Chemistry (CHEM)
```

### Scenario 2: Graduate Law Programs
**Configuration:**
- Academic Level: "G"
- School College: "School of Law"

**Result:**
```
Juris Doctor
  - Juris Doctor (LW_JD)
  - JD/MBA Dual Degree (LW_JD_MBA)
```

### Scenario 3: Filtered Programs
**Configuration:**
- Academic Level: "U"
- Academic Interests to Display: "CSCI;BIOL;CHEM"

**Result:** Only Computer Science, Biology, and Chemistry programs

## Testing

### Test Coverage

Test class: `rfiFormController_TEST.cls`

**Test Methods:**
1. `testGetProgramsWithShortCodes_undergraduate` - Tests undergraduate program retrieval
2. `testGetProgramsWithShortCodes_graduate` - Tests graduate program retrieval with school filter
3. `testGetProgramsWithShortCodes_withFilter` - Tests filtered program retrieval

**Test Data Setup:**
- Creates 3 test programs (CSCI, BIOL, MBA)
- Covers both undergraduate and graduate levels
- Tests different degree groupings

### Running Tests

```bash
# Run specific test class
sfdx force:apex:test:run -n rfiFormController_TEST -r human

# Run all tests
sfdx force:apex:test:run -r human
```

## Best Practices

### 1. **Configure Academic Interests to Display**
Always populate the "Academic Interests to Display" field on the RFI Controller to limit the programs shown to users.

### 2. **Set Appropriate Max Selections**
Consider the use case when setting max selections:
- Single major programs: 1
- Major + minor: 2
- Multiple interests: 3-4

### 3. **Use Consistent Short Codes**
Ensure Program_Major_Concentration__c values are:
- Unique across programs
- Meaningful abbreviations
- Consistent format (e.g., all caps)

### 4. **Group Related Programs**
Use the Degree__c field consistently to create logical groupings that help users navigate options.

## Troubleshooting

### Issue: No Programs Displayed

**Possible Causes:**
1. No programs match the criteria in RFI Controller
2. Programs are not marked as Active
3. Program_Display__c doesn't include "RFI"
4. Academic Level mismatch

**Solution:**
Check the Program__c records and ensure they meet all filter criteria.

### Issue: Wrong Programs Showing

**Possible Causes:**
1. Academic_Interests_To_Display__c field is empty or incorrect
2. School_College__c field doesn't match Associated_Schools__c on programs

**Solution:**
Verify RFI Controller configuration matches intended program set.

### Issue: Component Not Loading

**Possible Causes:**
1. recordId not available on the page
2. Field-level security restricts access to RFI_Controller__c fields

**Solution:**
- Ensure component is placed on RFI Controller record page
- Check field permissions for Academic_Level__c, School_College__c, Academic_Interests_To_Display__c

## Future Enhancements

Potential improvements for future versions:

1. **Real-time Preview** - Show program descriptions on hover
2. **Search Functionality** - Add search within the program list
3. **Recently Selected** - Show recently selected programs at the top
4. **Program Details Modal** - Click to view full program information
5. **Conditional Logic** - Hide/show programs based on other field values
6. **Custom Sorting** - Allow custom sort order beyond alphabetical

## Related Components

- **multiSelectPillsGroupable** - Base multi-select component used for UI
- **rfiForm** - Main RFI form component that uses similar program selection
- **requestForInformationForm** - Legacy RFI form component

## Support

For questions or issues, contact the development team or refer to:
- RFI Controller object documentation
- Program__c object field documentation
- Lightning Web Components developer guide

