# UST Salesforce RFI — Project Guide

**Last Updated:** March 5, 2026

---

## Overview

This project provides Lightning Web Components (LWC) for managing Request for Information (RFI) forms at the University of St. Thomas. Administrators configure forms via components on `RFI_Controller__c` records. Prospective students fill out the public-facing form, which creates an `Interaction__c` record.

---

## The Two Forms

| Form | Component | Writes To | Status |
|------|-----------|-----------|--------|
| Modern RFI | `rfiForm` | `Interaction__c` | ✅ Active — use this |
| Legacy RFI | `requestForInformationForm` | `Lead` | 📦 Reference only — do not modify |

The legacy form exists for reference only. All active development is on `rfiForm`.

---

## Admin Tools (on RFI Controller Record Page)

### 1. Unified Question Manager — `rfiUnifiedQuestionManager` ⭐
**The primary admin configuration tool.** Manages all questions in a single sorted list.

**Replaces:** `rfiFieldManager` + `rfiAdditionalQuestionsInteractions` (both removed)

**Question types available:**
| Type | Description |
|------|-------------|
| **Pre-configured** | Standard fields (Name, Email, Phone, Address, etc.) with editable labels |
| **Custom** | Free-form questions — text, textarea, email, picklist, or static content |
| **Program Filter** | Drives filtering of Academic Programs picklist; user must answer all filters before programs unlock |

**Features:**
- Drag-and-drop reordering across all question types
- Arrow button fallback for accessibility
- Inline label and required-field editing
- Edit modal for full question configuration
- Color-coded badges: blue = pre-configured, green = custom, purple = filter
- Save writes to `Unified_Questions__c` (JSON) and to the relevant `_To_Display__c` filter fields

**Program Filter Questions:**
- Admin selects a filter slot (School/College, Citizenship, Degree Type, etc.)
- Admin picks which values from that picklist appear on the form via dual-listbox
- Selected values saved to both `Unified_Questions__c` and the `_To_Display__c` field
- On the RFI form, Academic Programs is locked until all filter questions are answered

### 2. Academic Interest Selector — `academicInterestSelector`
Selects which academic programs appear in the Academic Interest question on the RFI form.

- Dual-listbox grouped by school and degree
- Saves to `Academic_Interests_To_Display__c`
- See [ADMIN_TOOL_GUIDE.md](ADMIN_TOOL_GUIDE.md) for full details

### 3. RFI Additional Questions (Lead) — `rfiAdditionalQuestions`
Legacy tool for the Lead-based form. Manages questions for `requestForInformationForm` only. Not used by `rfiForm`.

---

## Data Storage

| Field on `RFI_Controller__c` | Type | Used By |
|------------------------------|------|---------|
| `Unified_Questions__c` | Long Text (131072) | `rfiUnifiedQuestionManager`, `rfiFormController` |
| `Academic_Interests_To_Display__c` | Multi-select Picklist | `academicInterestSelector`, `rfiFormController` |
| `School_College_To_Display__c` | Multi-select Picklist | Filter questions (School/College) |
| `Citizen_Types_To_Display__c` | Multi-select Picklist | Filter questions (Citizenship) |
| `Degree_Types_To_Display__c` | Multi-select Picklist | Filter questions (Degree Type) |
| *(+ other `_To_Display__c` fields)* | Multi-select Picklist | Other filter question slots |
| `Fields_to_Display__c` | Multi-select Picklist | Legacy path only |
| `Interaction_Questions__c` | Long Text (131072) | Legacy path only |
| `Additional_Questions__c` | Long Text (131072) | `requestForInformationForm` (Lead form) only |

### Unified Questions JSON Structure
```json
[
  { "id": 0, "type": "preconfigured", "fieldName": "First Name",
    "questionLabel": "First Name", "fieldInteractionAPIName": "First_Name__c", "isRequired": true },
  { "id": 1, "type": "custom", "questionLabel": "How did you hear about us?",
    "questionType": "Picklist", "fieldToApplyTo": "Heard_About_Us__c",
    "isRequired": false, "picklistValues": [...], "valuesFlat": "Friend;Website;..." },
  { "id": 2, "type": "filter", "questionLabel": "School / College",
    "filterControllerField": "School_College_To_Display__c",
    "filterInteractionAPIName": "St_Thomas_College_School__c",
    "isFilterSchoolList": true, "filterSelectedValues": ["School of Law", "College of Arts & Sciences"] },
  { "id": 3, "type": "custom", "questionType": "Static content",
    "valuesFlat": "<p>Thank you for your interest.</p>" }
]
```

---

## Apex Controller — `rfiFormController.cls`

**Key method:** `getRFIForm(rfiControllerName)` — called by `rfiForm` on load.

**Dual-path logic:**
1. **If `Unified_Questions__c` is populated:** calls `processUnifiedQuestions()` — builds the field list from the JSON, handles all three question types (preconfigured, custom, filter)
2. **If blank (legacy):** falls back to `Fields_to_Display__c` + `Interaction_Questions__c` — for RFI Controllers not yet configured with the unified manager

**Filter question rendering in Apex:**
- Reads `filterSelectedValues` from JSON (admin-chosen subset) — preferred source
- Falls back to the `_To_Display__c` field value if JSON values absent
- School/College filter uses `getUSTSchoolList()` — returns Account IDs as values so programs query correctly
- Other filters use `getOptionsFromDelineatedString()` — splits semicolons into label/value pairs
- Program lookup field is marked `isDisabled = true` until all filters answered

---

## Deployment

```powershell
# Single component
cci task run deploy --path force-app/main/default/lwc/rfiUnifiedQuestionManager --org dev 2>&1

# All LWCs
cci task run deploy --path force-app/main/default/lwc --org dev 2>&1

# Apex only
cci task run deploy --path force-app/main/default/classes --org dev 2>&1

# Flexipage
cci task run deploy --path force-app/main/default/flexipages --org dev 2>&1
```

**⚠️ Never use `cci flow run dev_org` for incremental changes** — this rebuilds the entire scratch org.

---

## Architecture

### RFI Form Data Flow
```
Public User
    │
    ▼
rfiForm (LWC)
    │  reads config on load
    ▼
getRFIForm() [Apex]
    │  queries RFI_Controller__c
    │  processUnifiedQuestions()
    ▼
rfiFieldList returned to LWC
    │
    ├── Filter questions → user selects → filterValues map populated
    │       └── all filters answered → Academic Programs unlocked
    ├── Pre-configured questions → map to Interaction__c fields
    └── Custom questions → map to Interaction__c fields or static display
    │
    ▼
submitRfiInteraction() [Apex] → Interaction__c record created
```

### Component Map (Current)
```
RFI_Controller__c Record Page
├── Detail Tab
│   ├── force:detailPanel          (standard Salesforce fields)
│   ├── rfiUnifiedQuestionManager  ← primary config tool
│   ├── academicInterestSelector   ← program selection
│   └── rfiAdditionalQuestions     ← Lead form questions (legacy)
└── Sidebar
    ├── requestForInformationForm  ← legacy form preview (Lead)
    └── rfiForm                    ← modern form preview (Interaction)
```

---

## Testing

```powershell
# Jest unit tests
npm test 2>&1
npm test -- --coverage 2>&1

# Apex tests (CumulusCI — preferred)
cci task run run_tests --org dev 2>&1

# Apex tests (SF CLI — single class)
sf apex run test --class-names rfiFormController_TEST --target-org UST-Salesforce-RFI__dev --result-format human --code-coverage --wait 10 2>&1
```

See [JEST_TESTING_GUIDE.md](JEST_TESTING_GUIDE.md) for Jest patterns and [ORG_NAMING_REFERENCE.md](ORG_NAMING_REFERENCE.md) for org alias conventions.

---

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed solutions.

**Quick reference:**
- Questions not appearing on form → check `Unified_Questions__c` is saved (non-empty JSON array)
- Filter picklist empty on form → ensure `filterSelectedValues` in JSON and `_To_Display__c` field are set
- Academic Programs locked but all filters answered → check `filterValues` keys match `filterInteractionAPIName` values in the JSON
- Legacy form broken → do not touch `requestForInformationForm` or `Additional_Questions__c`
