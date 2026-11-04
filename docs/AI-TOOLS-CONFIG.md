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

**Keys on every question (added 2026-11-02):**
- `key` is a stable identity (for example `q1l3x9abc4d`), generated once and never changed. **Anything that refers to a question (such as a dependent-question rule) must use `key`, never `id`.** `id` is only the position in the list and changes whenever a question is moved or deleted.
- `schemaVersion` is the format version the question was saved in (currently 1).
- The manager does not save its own display flags (`isFirst`, `typeCustom`, `isPicklist` and so on). Older saved lists still contain them; they are ignored.
- Keys this version does not know are kept when the manager saves, so data written by a newer version is not damaged.

### Changing the question format

The saved list lives in an org, and older saved lists stay there after the code changes. A change that is safe for new data can still break the old. Rules:

1. **Additive only.** Add new keys as optional, with a sensible default when absent. Never rename, remove or change the type of an existing key. To replace one, add the new key, read both, and rewrite old data later with a repair script (`scripts/apex/migrate_rfi_questions.apex` is the model).
2. **Store identity and choices, work out the rest.** Save what the admin chose. Anything the code can work out (labels from the catalog, field names, display flags) is worked out when the form loads. That is why changing where a question saves needed no data change.
3. **One reader.** All Apex reads the list through `rfiQuestionReader`; the manager reads it through `readSavedQuestions`. Do not add `JSON.deserializeUntyped` of this field anywhere else. New keys are cleaned up in the reader (convert types, supply defaults), so the rest of the code gets a clean question.
4. **Skip and report, never guess.** A question the reader cannot understand is left out and described in a warning (position, label, reason). Warnings reach admins as a banner on the controller record page and are written to the Error object when a visitor submits. Only a list that cannot be read at all stops the form.
5. **Bump `schemaVersion` only when old code would misread new data.** Old code that meets a higher version keeps working on what it understands and reports the rest.
6. **Keep old shapes as fixtures.** `rfiQuestionReader_TEST` and `rfiUnifiedQuestionManager.schema.test.js` hold real lists copied from eda-staging. Every format change must keep loading them. Add a real sample of any new shape the manager starts writing.
7. **Reader first.** When a change adds keys, deploy code that reads both shapes before code that writes the new one. Older code ignores unknown keys, so it fails open: a question simply shows or behaves as before.

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
