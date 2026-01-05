# Academic Interest Selector - Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         RFI CONTROLLER RECORD PAGE                       │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │                    RFI Controller Details                          │ │
│  │  Name: Undergraduate RFI Form                                      │ │
│  │  Academic Level: U                                                 │ │
│  │  School College: (blank)                                           │ │
│  │  Academic Interests to Display: CSCI;BIOL;CHEM;MATH;PHYS          │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │          📦 ACADEMIC INTEREST SELECTOR COMPONENT                   │ │
│  │                                                                    │ │
│  │  Academic Interests (Max 4 selections) *                          │ │
│  │  ┌──────────────────────────────────────────────────────────────┐ │ │
│  │  │ [Computer Science] [Biology]                             ▼  │ │ │
│  │  ├──────────────────────────────────────────────────────────────┤ │ │
│  │  │ ┌────────────────────────────────────────────────────────┐   │ │ │
│  │  │ │ Bachelor of Arts                                       │   │ │ │
│  │  │ │   ☑ Computer Science                                   │   │ │ │
│  │  │ │   ☐ English Literature                                 │   │ │ │
│  │  │ │   ☐ Mathematics                                        │   │ │ │
│  │  │ │                                                        │   │ │ │
│  │  │ │ Bachelor of Science                                    │   │ │ │
│  │  │ │   ☑ Biology                                            │   │ │ │
│  │  │ │   ☐ Chemistry                                          │   │ │ │
│  │  │ │   ☐ Physics                                            │   │ │ │
│  │  │ └────────────────────────────────────────────────────────┘   │ │ │
│  │  └──────────────────────────────────────────────────────────────┘ │ │
│  │                                                                    │ │
│  │  Value Stored: "CSCI;BIOL" (short codes only)                     │ │
│  └────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

## Component Architecture

```
┌───────────────────────────────────────────────────────────────────────┐
│                    COMPONENT ARCHITECTURE                              │
└───────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│  academicInterestSelector.html (Presentation Layer)                 │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  <template>                                                   │  │
│  │    <c-multi-select-pills-groupable                            │  │
│  │       label={displayLabel}                                    │  │
│  │       options={programOptions}                                │  │
│  │       value={value}                                           │  │
│  │       required={required}                                     │  │
│  │       max={maxSelections}                                     │  │
│  │       onchange={handleChange}>                                │  │
│  │    </c-multi-select-pills-groupable>                          │  │
│  │  </template>                                                  │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   │ Uses
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│  academicInterestSelector.js (Logic Layer)                          │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Properties:                                                  │  │
│  │  • @api recordId           (RFI Controller ID)                │  │
│  │  • @api label              (Display label)                    │  │
│  │  • @api maxSelections      (Max programs to select)           │  │
│  │  • @api required           (Is selection required?)           │  │
│  │                                                               │  │
│  │  Tracked State:                                               │  │
│  │  • @track programOptions   (List of programs to display)      │  │
│  │  • @track selectedValues   (Currently selected short codes)   │  │
│  │  • @track isLoading        (Loading state)                    │  │
│  │  • @track error            (Error state)                      │  │
│  │                                                               │  │
│  │  Methods:                                                     │  │
│  │  • loadPrograms()          (Fetch programs from Apex)         │  │
│  │  • handleChange()          (Handle selection changes)         │  │
│  │  • checkValidity()         (Validate selections)              │  │
│  │  • reportValidity()        (Show validation errors)           │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   │ Calls
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│  @wire getRecord (Lightning Data Service)                           │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Fetches RFI Controller fields:                               │  │
│  │  • Academic_Level__c                                          │  │
│  │  • School_College__c                                          │  │
│  │  • Academic_Interests_To_Display__c                           │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   │ Then calls
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│  rfiFormController.getProgramsWithShortCodes() (Apex Method)        │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  @AuraEnabled(Cacheable=true)                                 │  │
│  │  Parameters:                                                  │  │
│  │  • academic_level           (U or G)                          │  │
│  │  • school_college           (School filter)                   │  │
│  │  • academic_interest_codes  (Program codes filter)            │  │
│  │  • filters                  (Additional filters)              │  │
│  │                                                               │  │
│  │  Returns:                                                     │  │
│  │  List<programValues> {                                        │  │
│  │    label: "Computer Science"                                  │  │
│  │    value: "CSCI"                                              │  │
│  │    description: "Bachelor of Arts - CSCI"                     │  │
│  │    is_group: false                                            │  │
│  │  }                                                            │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   │ Queries
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│  Program__c Object (Salesforce Database)                            │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Query Filters:                                               │  │
│  │  • RecordType = 'Recruitment_Program'                         │  │
│  │  • Active__c = true                                           │  │
│  │  • Program_Display__c INCLUDES 'RFI'                          │  │
│  │  • Academic_Level__c matches parameter                        │  │
│  │  • Program_Major_Concentration__c IN specified codes          │  │
│  │                                                               │  │
│  │  Fields Retrieved:                                            │  │
│  │  • Program_Name_on_Application__c  (Full name)                │  │
│  │  • Program_Major_Concentration__c  (Short code)               │  │
│  │  • Degree__c                       (Grouping)                 │  │
│  │  • Associated_Schools__c           (School filter)            │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

## Data Flow Diagram

```
USER SELECTS PROGRAMS
        │
        ▼
┌───────────────────────────────────────────────────────────────┐
│ Step 1: User Opens RFI Controller Record                     │
│                                                               │
│ RFI Controller Record:                                        │
│   ID: a001234567890ABC                                        │
│   Academic_Level__c: "U"                                      │
│   School_College__c: null                                     │
│   Academic_Interests_To_Display__c: "CSCI;BIOL;CHEM"         │
└───────────────────────────────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────────────────────────────┐
│ Step 2: Component Loads via @wire                            │
│                                                               │
│ getRecord fetches:                                            │
│   recordId: a001234567890ABC                                  │
│   fields: [Academic_Level__c, School_College__c, ...]        │
└───────────────────────────────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────────────────────────────┐
│ Step 3: Component Calls loadPrograms()                       │
│                                                               │
│ Calls Apex: getProgramsWithShortCodes({                       │
│   academic_level: "U",                                        │
│   school_college: null,                                       │
│   academic_interest_codes: "CSCI;BIOL;CHEM",                 │
│   filters: null                                               │
│ })                                                            │
└───────────────────────────────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────────────────────────────┐
│ Step 4: Apex Queries Program__c                              │
│                                                               │
│ SELECT Id, Name,                                              │
│        Program_Name_on_Application__c,                        │
│        Program_Major_Concentration__c,                        │
│        Degree__c                                              │
│ FROM Program__c                                               │
│ WHERE RecordType.DeveloperName = 'Recruitment_Program'       │
│   AND Active__c = true                                        │
│   AND Program_Display__c INCLUDES ('RFI')                     │
│   AND Academic_Level__c = 'U'                                 │
│   AND Program_Major_Concentration__c IN ('CSCI','BIOL','CHEM')│
│ ORDER BY Degree__c, Program_Name_on_Application__c           │
└───────────────────────────────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────────────────────────────┐
│ Step 5: Apex Returns Grouped Programs                        │
│                                                               │
│ [                                                             │
│   {label: "Bachelor of Arts", value: "Bachelor of Arts",     │
│    is_group: true},                                           │
│   {label: "Computer Science", value: "CSCI",                 │
│    description: "Bachelor of Arts - CSCI", is_group: false}, │
│   {label: "Bachelor of Science", value: "Bachelor of Science",│
│    is_group: true},                                           │
│   {label: "Biology", value: "BIOL",                          │
│    description: "Bachelor of Science - BIOL", is_group: false},│
│   {label: "Chemistry", value: "CHEM",                        │
│    description: "Bachelor of Science - CHEM", is_group: false}│
│ ]                                                             │
└───────────────────────────────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────────────────────────────┐
│ Step 6: Component Renders UI                                 │
│                                                               │
│ Displays:                                                     │
│   Bachelor of Arts                                            │
│     ☐ Computer Science                                        │
│   Bachelor of Science                                         │
│     ☐ Biology                                                 │
│     ☐ Chemistry                                               │
└───────────────────────────────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────────────────────────────┐
│ Step 7: User Selects Programs                                │
│                                                               │
│ User clicks:                                                  │
│   ☑ Computer Science                                          │
│   ☑ Biology                                                   │
└───────────────────────────────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────────────────────────────┐
│ Step 8: Component Handles Change                             │
│                                                               │
│ handleChange() triggered                                      │
│   selectedValues = ["CSCI", "BIOL"]                          │
│   Dispatches CustomEvent with:                                │
│     value: "CSCI;BIOL"                                        │
│     values: ["CSCI", "BIOL"]                                  │
└───────────────────────────────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────────────────────────────┐
│ Step 9: Data Stored                                          │
│                                                               │
│ Storage Format: "CSCI;BIOL"                                   │
│                                                               │
│ Benefits:                                                     │
│ ✓ Compact storage (10 chars vs 36 chars for 2 IDs)          │
│ ✓ Human-readable                                              │
│ ✓ Easy to filter/query                                        │
│ ✓ No lookup required to understand                            │
└───────────────────────────────────────────────────────────────┘
```

## Storage Comparison

```
┌────────────────────────────────────────────────────────────────┐
│                     OLD APPROACH (IDs)                         │
├────────────────────────────────────────────────────────────────┤
│ Stored Value:                                                  │
│   "a0X1234567890ABC;a0X9876543210XYZ"                         │
│                                                                │
│ Size: 36 chars × 2 + 1 separator = 73 characters              │
│                                                                │
│ To understand what's stored:                                   │
│   1. Query Program__c WHERE Id IN (...)                        │
│   2. Look up Program_Name_on_Application__c                    │
│   3. Map IDs to names                                          │
│                                                                │
│ Problems:                                                      │
│   ❌ Opaque (can't tell what programs without lookup)          │
│   ❌ Large storage footprint                                    │
│   ❌ Difficult to filter/report on                             │
│   ❌ Hard to debug                                              │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│                  NEW APPROACH (Short Codes)                    │
├────────────────────────────────────────────────────────────────┤
│ Stored Value:                                                  │
│   "CSCI;BIOL"                                                  │
│                                                                │
│ Size: 4 chars + 4 chars + 1 separator = 9 characters          │
│                                                                │
│ To understand what's stored:                                   │
│   • Immediately readable (CSCI = Computer Science)             │
│   • No lookup required for common codes                        │
│   • Optional: Reference metadata for full names                │
│                                                                │
│ Benefits:                                                      │
│   ✅ Human-readable                                             │
│   ✅ Compact storage (87% smaller)                             │
│   ✅ Easy to filter (WHERE field LIKE '%CSCI%')               │
│   ✅ Simple to report on                                        │
│   ✅ Easy to debug                                              │
│   ✅ Can be used in formulas                                    │
└────────────────────────────────────────────────────────────────┘
```

## Component Integration

```
┌──────────────────────────────────────────────────────────────────┐
│                    RFI CONTROLLER ECOSYSTEM                       │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                      RFI Controller Record                        │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ Configuration Fields:                                      │  │
│  │ • Academic_Level__c                                        │  │
│  │ • School_College__c                                        │  │
│  │ • Academic_Interests_To_Display__c                         │  │
│  │ • Lead_Source__c                                           │  │
│  │ • Redirect_URL__c                                          │  │
│  │ • etc.                                                     │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
                            │
                            │ Configuration read by
                            ▼
┌──────────────────────────────────────────────────────────────────┐
│              Academic Interest Selector Component                 │
│  (On RFI Controller Record Page)                                 │
│                                                                  │
│  Reads configuration → Displays programs → Stores short codes    │
└──────────────────────────────────────────────────────────────────┘
                            │
                            │ Works alongside
                            ▼
┌──────────────────────────────────────────────────────────────────┐
│                    Other RFI Components                           │
│  • rfiForm (public form submission)                              │
│  • requestForInformationForm (legacy)                            │
│  • rfiFieldManager (field configuration)                         │
│  • multiSelectPillsGroupable (reused UI component)               │
└──────────────────────────────────────────────────────────────────┘
```

---

## File Structure

```
UST-Salesforce-RFI/
├── force-app/main/default/
│   ├── lwc/
│   │   ├── academicInterestSelector/          ← NEW
│   │   │   ├── academicInterestSelector.js
│   │   │   ├── academicInterestSelector.html
│   │   │   ├── academicInterestSelector.js-meta.xml
│   │   │   └── academicInterestSelector.css
│   │   ├── multiSelectPillsGroupable/         (reused)
│   │   ├── rfiForm/                            (existing)
│   │   └── ...
│   ├── classes/
│   │   ├── rfiFormController.cls              ← UPDATED
│   │   │   └── Added: getProgramsWithShortCodes()
│   │   ├── rfiFormController_TEST.cls         ← UPDATED
│   │   │   └── Added: 3 new test methods
│   │   └── ...
│   └── objects/
│       ├── RFI_Controller__c/                  (existing)
│       ├── Program__c/                         (existing)
│       └── ...
├── ACADEMIC_INTEREST_SELECTOR_GUIDE.md         ← NEW
├── QUICK_START_ACADEMIC_SELECTOR.md            ← NEW
├── SUMMARY_ACADEMIC_SELECTOR.md                ← NEW
├── DEPLOYMENT_CHECKLIST.md                     ← NEW
└── ARCHITECTURE_DIAGRAM.md                     ← THIS FILE
```

---

This diagram provides a complete visual reference for understanding how the Academic Interest Selector component works within the RFI Controller ecosystem.

