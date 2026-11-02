# AI Tools Configuration — UST Salesforce RFI

**Project:** UST Salesforce RFI (Request for Information)  
**Purpose:** Lightning Web Components for managing RFI forms at University of St. Thomas  
**Last Updated:** March 5, 2026

---

## Project Context

Salesforce LWC project. Admins configure RFI forms via components on `RFI_Controller__c` records. Public-facing `rfiForm` collects prospective student data and creates `Interaction__c` records.

### Tech Stack
- **Platform:** Salesforce Scratch Orgs
- **Frontend:** Lightning Web Components (LWC)
- **Backend:** Apex (`rfiFormController.cls`)
- **Build:** CumulusCI (`cci`) — always use this for deploys
- **Testing:** Jest (JS unit), Robot Framework (E2E)
- **Shell:** PowerShell on Windows

---

## Critical Rules

### 1. Always Targeted Deploys — Never Full Rebuild
```powershell
# ✅ Correct — targeted, safe
cci task run deploy --path force-app/main/default/lwc/rfiUnifiedQuestionManager --org dev 2>&1
cci task run deploy --path force-app/main/default/classes --org dev 2>&1

# ❌ Never — destroys configured data in scratch org
cci flow run dev_org --org dev
```

### 2. Terminal Commands — Always Foreground with 2>&1
```powershell
# ✅ Correct — foreground, output captured
cci task run deploy --path force-app/main/default/lwc/rfiForm --org dev 2>&1

# ❌ Never — background + sleep + poll is unreliable and blocks the user
```
Background (`isBackground: true`) only for non-terminating processes (servers, watchers).

### 3. LWC Reactivity — Always New References
```javascript
// ✅ Correct
this.questions = [...this.questions];
this.currentQuestion = { ...this.currentQuestion, label: newValue };

// ❌ Wrong — won't trigger re-render
this.questions[0].label = newValue;
this.currentQuestion.label = newValue;
```

### 4. Wire + updateRecord — Always refreshApex After
```javascript
// ✅ Correct
await updateRecord(recordInput);
await refreshApex(this.wiredResult);

// ❌ Wrong — wire adapter won't see the change
await updateRecord(recordInput);
```

---

## Component Architecture (Current)

### Public-Facing Forms
| Component | Writes To | Status |
|-----------|-----------|--------|
| `rfiForm` | `Interaction__c` | ✅ Active |
| `requestForInformationForm` | `Lead` | 📦 Legacy — reference only, do not modify |

### Admin Tools on RFI Controller Record Page
| Component | Purpose | Status |
|-----------|---------|--------|
| `rfiUnifiedQuestionManager` | All question management (pre-configured, custom, filter) | ✅ Primary tool |
| `academicInterestSelector` | Select programs for Academic Interest question | ✅ Active |
| `rfiAdditionalQuestions` | Legacy Lead-form questions only | 📦 Legacy |

### Removed (no longer in codebase)
- `rfiFieldManager` — replaced by `rfiUnifiedQuestionManager`
- `rfiAdditionalQuestionsInteractions` — replaced by `rfiUnifiedQuestionManager`

### Supporting Components
| Component | Purpose |
|-----------|---------|
| `multiSelectPillsGroupable` | Multi-select UI used in rfiForm |
| `reusableLookup` | Generic lookup used in rfiForm |
| `requestForInformationAdditionalQuestionForm` | Legacy support |

---

## Data Storage Patterns

### Primary: Unified Questions JSON (`Unified_Questions__c`)
The single source of truth for `rfiForm` question configuration when using the unified manager.

```json
[
  { "id": 0, "type": "preconfigured", "fieldName": "Email",
    "questionLabel": "Email Address", "fieldInteractionAPIName": "Email__c", "isRequired": true },
  { "id": 1, "type": "custom", "questionLabel": "Tell us about yourself",
    "questionType": "Textarea", "fieldToApplyTo": "Description__c", "isRequired": false },
  { "id": 2, "type": "filter", "questionLabel": "School / College",
    "filterControllerField": "School_College_To_Display__c",
    "filterInteractionAPIName": "St_Thomas_College_School__c",
    "isFilterSchoolList": true,
    "filterSelectedValues": ["School of Law", "College of Arts & Sciences"] },
  { "id": 3, "type": "custom", "questionType": "Static content",
    "valuesFlat": "<p>Some informational text.</p>" }
]
```

**question `type` values:** `preconfigured` | `custom` | `filter`

### Legacy Fields (still supported, do not remove)
- `Fields_to_Display__c` + `Interaction_Questions__c` — used by Apex legacy path for controllers not yet using unified questions
- `Additional_Questions__c` — used by `requestForInformationForm` Lead form only

---

## Apex Controller: `rfiFormController.cls`

**`getRFIForm(name)`** — main entry point from `rfiForm` wire adapter.

Dual-path:
1. `Unified_Questions__c` populated → `processUnifiedQuestions()` handles all types
2. Empty → legacy `Fields_to_Display__c` + `Interaction_Questions__c` path

**`processUnifiedQuestions()`** — iterates unified JSON:
- `preconfigured`: maps fieldName to Interaction field, detects picklist/address/email/etc.
- `filter`: reads `filterSelectedValues` from JSON (falls back to `_To_Display__c`), builds picklist options, registers in `filterValues` map
- `custom`: builds field from questionType: `Text box`, `Textarea`, `Email`, `Picklist`, `Checkbox`, `Date`, `Static content`.
  Each type except Static content has a `... required` variant (a required Checkbox must be ticked). A Picklist question on a
  picklist or multi-select Interaction field always shows that field's live active values; any copy saved with the question is
  ignored. A Picklist question on a text field uses the list the admin typed. Any question that saves to a Date field is drawn
  as a date picker.

**Other key methods:**
- `getUSTSchoolList(schoolNames)` — returns Account IDs for school filter (School/College is special: stores Account IDs not text values)
- `getPrograms(...)` / `getProgramsWithShortCodes(...)` — returns filtered academic programs
- `submitRfiInteraction(interaction)` — creates the Interaction__c record

---

## Org Naming

| Context | Alias/Name |
|---------|-----------|
| CumulusCI commands | `--org dev` |
| SF CLI commands | `--target-org UST-Salesforce-RFI__dev` |

See [ORG_NAMING_REFERENCE.md](ORG_NAMING_REFERENCE.md) for full details.

---

## Common Tasks

### Configure a new RFI form
1. Create an `RFI_Controller__c` record
2. Open the record page
3. Use `rfiUnifiedQuestionManager` to add questions in order
4. Use `academicInterestSelector` to pick programs
5. Set `Academic_Level__c`, `School_College__c`, other controller fields as needed

### Add a question type to rfiUnifiedQuestionManager
1. Add type handling in `rfiUnifiedQuestionManager.js` (`stampComputedProps`, modal logic)
2. Add template branch in `rfiUnifiedQuestionManager.html`
3. Add rendering in `rfiForm.html` (new `lwc:elseif` branch)
4. Add field detection in `processUnifiedQuestions()` in `rfiFormController.cls`
5. Deploy: classes, then LWC

### Deploy a single change
```powershell
cci task run deploy --path force-app/main/default/lwc/componentName --org dev 2>&1
cci task run deploy --path force-app/main/default/classes --org dev 2>&1
```
