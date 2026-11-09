# UST Salesforce RFI: Project Guide

**Last Updated:** November 9, 2026

---

## Overview

This project provides Lightning Web Components (LWC) and Apex for managing Request for Information (RFI) forms at the University of
St. Thomas. Administrators configure each form on an `RFI_Controller__c` record. A prospective student fills in the form, which creates an
`Interaction__c` record. The org's Interaction processor then creates the Lead, Contact and Opportunity.

**Who reads what**

| You are... | Start here |
|------------|------------|
| Marketing, an Admissions BA or an admin building forms | [ADMIN_TOOL_GUIDE.md](ADMIN_TOOL_GUIDE.md) |
| Testing the form | [RFI_TEST_PLAN.md](RFI_TEST_PLAN.md) |
| A developer | This guide, then [AI-TOOLS-CONFIG.md](AI-TOOLS-CONFIG.md) |
| Looking for why a design choice was made, or what is deployed where | [RFI_FORM_ROBUSTNESS_PLAN.md](RFI_FORM_ROBUSTNESS_PLAN.md) |

---

## The Two Forms

| Form | Component | Writes To | Status |
|------|-----------|-----------|--------|
| Modern RFI | `rfiForm` | `Interaction__c` | Active. Use this. |
| Legacy RFI | `requestForInformationForm` | `Lead` | Reference only. Do not modify. Still serves other lead sources. |

---

## What Happens When Someone Submits

```
Visitor fills in rfiForm
   |
   v
rfiFormController.submitRfiForm (Apex)
   |  rfiSubmissionGuard      keeps only fields this form is allowed to set
   |  rfiSubmissionProcessor  sets defaults, picks programs, term, state/country, presets
   |  rfiErrorLogger          records any failure or dropped data in hed__Error__c
   v
Interaction__c is created        (Interaction_Status__c = New)
   |
   v
INT_Interaction trigger -> INT_InteractionProcessor
   |  Lead -> converts to Contact + Account
   |  Opportunity created, or an existing matching one updated
   v
Interaction_Status__c = Imported   (or Audit Required, with Audit_Reason__c)
```

The form no longer goes through the old "Lead: Convert to Interaction" flow. The Apex now sets what that flow used to set.

**What the server sets on every Interaction** (the visitor cannot change these): `Interaction_Source__c` = Webform, `Date_Inquiry__c` = today,
`Opportunity_Stage__c` = Inquiry, `Opportunity_Record_Type__c` = the Inquiry Opportunity record type, `Term__c`, the Academic and Recruitment
Program, `Recruitment_Program_Associated_Schools__c`, `State__c`, `Country__c`, the school, the controller's Lead Source and owner, and any
per-controller presets from `Lead_Preset_Value__mdt`.

**Opportunity name.** The processor names the Opportunity `Contact last name | Term | Program Name on Application`. An existing Opportunity for the
same Contact with a matching name is updated instead of duplicated. A form with no Expected Start Term question gives an empty term part.
Details are in [ADMIN_TOOL_GUIDE.md](ADMIN_TOOL_GUIDE.md) section 7 and [RFI_TEST_PLAN.md](RFI_TEST_PLAN.md) section 5.

---

## Admin Tools (on RFI Controller Record Page)

See [ADMIN_TOOL_GUIDE.md](ADMIN_TOOL_GUIDE.md) for the step-by-step guide. A summary:

### 1. Unified Question Manager: `rfiUnifiedQuestionManager`
The primary configuration tool. Manages every question in one sorted list.

**Question types**

| Type | Description |
|------|-------------|
| **Pre-configured** | Standard questions from the catalog (`rfiQuestionCatalog`): names, email, phones, address, start term, high school, and more. The catalog decides which Interaction field each saves to. |
| **Custom** | Free-form: Text box, Textarea, Email, Picklist, Checkbox, Date, Static content. Every type except Static content has a "required" variant. A Picklist on a picklist field always shows that field's live values. |
| **Program Filter** | Narrows the Academic Interest list. The list stays locked until every filter is answered. School/College, Citizenship and Generic Filter 3 save their answer; the other filters only narrow the list. |

**Features**
* Drag-and-drop reordering, with arrow buttons as a keyboard fallback.
* Inline label and Required editing, plus an edit dialog.
* **Show only when** rules (dependent questions, ECRMSF-6061). See below.
* A warning above the table, and a refused save, when a rule cannot work.
* Color-coded badges: blue pre-configured, green custom, purple filter.
* Every question gets a permanent `key` and a `schemaVersion`. Saving never writes display flags.
* Save writes `Unified_Questions__c` (JSON) and the `_To_Display__c` filter fields.

### 2. Academic Interest Selector: `academicInterestSelector`
Chooses which programs appear in the Academic Interest question. Auto-saves to `Academic_Interests_To_Display__c`. No selection limit for admins.
The form's own limit is `Academic_Interest_Max_Selection__c` on the controller.

### 3. RFI Additional Questions (Lead): `rfiAdditionalQuestions`
Legacy tool for the Lead-based form only. Not used by `rfiForm`.

### 4. Form health banner
When `rfiForm` sits on the controller record page, it shows a yellow banner for any saved question it had to skip and why. Visitors never see it.

---

## Dependent Questions ("Show only when")

A question can carry a rule: show it only when an **earlier** question has one of the listed answers.

* Stored as `visibleWhen: { "key": "<key of the earlier question>", "equals": ["answer"] }` on the question.
* One condition, one level. The earlier question must be above it and be a picklist-type choice or a tick box.
* A hidden question is not drawn, never required, its answer is thrown away in the browser and again on the server
  (`rfiSubmissionGuard.dropAnswersToHiddenQuestions`).
* A rule that cannot work is ignored and the question shows. The problem goes to the banner and to the Error object.
* Older code ignores the rule, so the question simply always shows.

Full rules and the reasoning are in [AI-TOOLS-CONFIG.md](AI-TOOLS-CONFIG.md). A working example is controller 0360.

---

## Data Storage

| Field on `RFI_Controller__c` | Type | Used By |
|------------------------------|------|---------|
| `Unified_Questions__c` | Long Text (131072) | `rfiUnifiedQuestionManager`, `rfiFormController` |
| `Academic_Interests_To_Display__c` | Multi-select Picklist | `academicInterestSelector`, `rfiFormController` |
| `School_College_To_Display__c` | Multi-select Picklist | Filter questions (School/College) |
| `Citizen_Types_To_Display__c` | Multi-select Picklist | Filter questions (Citizenship) |
| `Degree_Types_To_Display__c` | Multi-select Picklist | Filter questions (Degree Type) |
| *(+ other `_To_Display__c` fields)* | Multi-select Picklist | Other filter slots |
| `Academic_Level__c`, `School_College__c` | Picklist | Program list, program rules, school on the Interaction |
| `Lead_Source__c`, `Lead_Owner__c` | Picklist, Lookup | Copied to the Interaction (and Opportunity Lead Source) |
| `Redirect_After_Form_Submission__c`, `Redirect_URL__c` | Checkbox, URL | Where the visitor goes after Submit |
| `Hide_Form_Title__c`, `Multi_Select_Display_Type__c`, `Academic_Interest_Max_Selection__c` | Checkbox, Picklist | Form appearance and limits |
| `Fields_to_Display__c`, `Required_Fields__c`, `Interaction_Questions__c` | Multi-select, Long Text | Legacy path only |
| `Additional_Questions__c` | Long Text (131072) | `requestForInformationForm` (Lead form) only |

### Unified Questions JSON Structure
```json
[
  { "id": 0, "key": "q1", "schemaVersion": 1, "type": "preconfigured", "fieldName": "First Name",
    "questionLabel": "First Name", "fieldInteractionAPIName": "First_Name__c", "isRequired": true },
  { "id": 1, "key": "q2", "type": "custom", "questionLabel": "How did you hear about us?",
    "questionType": "Picklist", "fieldToApplyTo": "Heard_About_Us__c", "isRequired": false },
  { "id": 2, "key": "q3", "type": "custom", "questionLabel": "Visa status", "questionType": "Text box required",
    "fieldToApplyTo": "Employer__c", "visibleWhen": { "key": "q4", "equals": ["International"] } },
  { "id": 3, "key": "q5", "type": "filter", "questionLabel": "School / College",
    "filterControllerField": "School_College_To_Display__c",
    "filterInteractionAPIName": "St_Thomas_College_School__c",
    "isFilterSchoolList": true, "filterSelectedValues": ["School of Law", "College of Arts & Sciences"] },
  { "id": 4, "key": "q6", "type": "custom", "questionType": "Static content",
    "valuesFlat": "<p>Thank you for your interest.</p>" }
]
```

Rules for changing this format (additive only, one reader, keep old shapes as test fixtures) are in
[AI-TOOLS-CONFIG.md](AI-TOOLS-CONFIG.md), "Changing the question format".

---

## Apex

| Class | Role |
|-------|------|
| `rfiFormController` | `getRFIForm(name)` builds the form. `submitRfiForm(interaction, controllerName)` saves it. `getQuestionCatalog()` feeds the Question Manager. Dual path: unified questions when `Unified_Questions__c` is set, otherwise the legacy field lists. |
| `rfiQuestionCatalog` | One list of pre-configured questions and filters with the Interaction field each saves to. The form (both paths), the Question Manager and the repair script all read it. |
| `rfiQuestionReader` | The one reader of `Unified_Questions__c`. Tolerates wrong types, skips and reports a bad question instead of stopping the form. |
| `rfiSubmissionProcessor` | Defaults, undergraduate program rules, term, state/country, school, presets, Description headings. |
| `rfiSubmissionGuard` | Allowlist of fields the browser may set. Drops answers to hidden questions. |
| `rfiErrorLogger` | Writes `hed__Error__c` rows for failures and for answers dropped ("saved with gaps"). |
| `AcademicInterestSelectorController` | Backs the Academic Interest Selector. |
| `ReusableLookupController` | Backs `reusableLookup`. |

**Undergraduate program rules** (first match wins): Transfer + International = "Undergraduate Transfer (INTL)"; Transfer = "Undergraduate Transfer";
School/College Dougherty Family College = "Dougherty Family College"; otherwise "Undergraduate First-Year". Graduate forms use the program that matches
the first Academic Interest.

---

## Embedding on a Website (Lightning Out)

The Aura app `requestForInformationApp` (`extends="ltng:outApp"`, `implements="ltng:allowGuestAccess"`) depends on `c:rfiForm` and
`c:requestForInformationForm`. A page creates `c:rfiForm` and passes `rfiControllerName` (the legacy `rfi_controller` is also accepted).

* The visitor is the site's guest user. Guest access to controllers, programs, terms and schools is handled in code and in sharing rules.
  See [RFI_FORM_ROBUSTNESS_PLAN.md](RFI_FORM_ROBUSTNESS_PLAN.md) sections 3 (F24, F26) and 9.
* Toasts do not exist in Lightning Out. The form draws its own message when it has no redirect.
* Lightning Out caches component bundles until the Aura app changes. If a deployed change does not show on an embedded page, make a real
  text change in `requestForInformationApp.app` (the cache stamp comment) and deploy that app.

---

## Deployment

```bash
# Single component
cci task run deploy --path force-app/main/default/lwc/rfiUnifiedQuestionManager --org dev 2>&1

# All LWCs
cci task run deploy --path force-app/main/default/lwc --org dev 2>&1

# Apex only
cci task run deploy --path force-app/main/default/classes --org dev 2>&1

# Flexipage
cci task run deploy --path force-app/main/default/flexipages --org dev 2>&1
```

**Never use `cci flow run dev_org` for incremental changes.** It rebuilds the entire scratch org.

**Shared orgs.** Develop and test in scratch orgs. eda-staging and production are deployed by the repository owner using
`manifest/rfi-staging-deploy.xml` and the hand-off checklist in [RFI_FORM_ROBUSTNESS_PLAN.md](RFI_FORM_ROBUSTNESS_PLAN.md) section 5. Permission sets,
profiles and sharing rules in this repo exist for scratch orgs only and are never deployed to shared orgs. Admins own those.

**Check a shared org without writing to it:**
```bash
sf apex run --target-org eda-staging --file scripts/apex/verify_rfi_rollout.apex
```
Read the `VERIFY` lines. After a deploy, run the saved-form repair `scripts/apex/migrate_rfi_questions.apex` (dry run first).

---

## Architecture

### RFI Form Data Flow
```
Visitor
    |
    v
rfiForm (LWC)  ---- reads config on load ---->  getRFIForm() [Apex]
    |                                              queries RFI_Controller__c (system mode, exact name)
    |                                              rfiQuestionReader -> processUnifiedQuestions / legacy path
    |                                              applyVisibilityRules
    v
Fields drawn (only the shown ones)
    |-- Filter questions answered -> Academic Interest unlocked
    |-- Hidden "Show only when" questions are not drawn and their answers are forgotten
    v
submitRfiForm() [Apex] -> guard -> processor -> Interaction__c -> INT_Interaction trigger -> Contact, Opportunity
```

### Component Map
```
RFI_Controller__c Record Page
|-- Detail Tab
|   |-- force:detailPanel          (standard fields)
|   |-- rfiUnifiedQuestionManager  <- primary config tool
|   |-- academicInterestSelector   <- program selection
|   +-- rfiAdditionalQuestions     <- Lead form questions (legacy)
+-- Sidebar
    |-- requestForInformationForm  <- legacy form preview (Lead)
    +-- rfiForm                    <- modern form preview (Interaction)
```

---

## Testing

```bash
# Jest unit tests
npm test 2>&1
npm test -- --coverage 2>&1

# Apex tests (CumulusCI, preferred)
cci task run run_tests --org dev 2>&1

# Apex tests (SF CLI, one class)
sf apex run test --class-names rfiFormController_TEST --target-org UST-Salesforce-RFI__dev --result-format human --code-coverage --wait 20 2>&1
```

Apex test classes: `rfiFormController_TEST`, `rfiSubmissionProcessor_TEST`, `rfiSubmissionGuard_TEST`, `rfiErrorLogger_TEST`,
`rfiQuestionCatalog_TEST`, `rfiQuestionReader_TEST`, plus `AcademicInterestSelectorController_TEST`. They run in scratch orgs. On 2026-11-09 they were
deployed to eda-staging and ran with no errors and over 75% coverage on each class. The repo owner runs them as a check-only deploy before releasing to
other shared orgs.

**Business testing** (Marketing and Admissions BAs on eda-staging) follows [RFI_TEST_PLAN.md](RFI_TEST_PLAN.md).

See [JEST_TESTING_GUIDE.md](JEST_TESTING_GUIDE.md) for Jest patterns and [ORG_NAMING_REFERENCE.md](ORG_NAMING_REFERENCE.md) for org aliases.

---

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed solutions. Quick reference:

* Questions not appearing on form: check `Unified_Questions__c` is saved (a non-empty JSON array) and look for the yellow banner on the record page.
* A question is missing or behaves oddly: look at the Error object (`hed__Error__c`). "Saved with gaps" rows name what was skipped.
* Filter list empty: set `filterSelectedValues` in the JSON and the matching `_To_Display__c` field.
* Academic Interest locked although all filters are answered: the `filterValues` keys must match the `filterInteractionAPIName` values in the JSON.
* Expected Start Term or College\School list empty on a website but full in Salesforce: guest access gap. See the admin notes in
  [RFI_FORM_ROBUSTNESS_PLAN.md](RFI_FORM_ROBUSTNESS_PLAN.md) section 9.
* Interaction Status is `Audit Required`: read `Audit_Reason__c`.
* Opportunity name has empty parts: the Interaction has no Term or Academic Program. See the naming rules above.
* Legacy form broken: do not touch `requestForInformationForm` or `Additional_Questions__c`.
