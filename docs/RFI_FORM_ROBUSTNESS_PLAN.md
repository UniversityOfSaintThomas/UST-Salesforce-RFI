# RFI Form Robustness Plan

**Jira:** ECRMSF-5545 (parent), ECRMSF-5588, 5764, 5732, 5800, 5856, 6020
**Prepared:** 2026-10-27
**Branch:** `ECRMSF-619_dynamic-rfi-questions`
**Status:** Draft. Section 6 lists decisions that block parts of the work.

---

## 1. Goal and environment

Make the new `rfiForm` LWC produce Interaction records that match what the old
Lead-based path produced, and make it hard to break that again.

**Target environment.** `rfiForm` must work in the scratch org, but it is built for
the **eda-staging full sandbox** and then production. Everything below was checked
against eda-staging (read-only: describes, queries, and metadata retrieves). Nothing was
submitted or changed in any org.

**Two paths exist side by side in eda-staging and the scratch org:**

| | Old path | New path |
|---|---|---|
| Component | `requestForInformationForm` | `rfiForm` |
| Apex | `requestForInformationFormController.createLead` | `rfiFormController.submitRfiInteraction` |
| Writes | `Lead`, then flow `Auto_Convert_Recruitment_Flow` ("Lead: Convert to Interaction") creates the `Interaction__c` | `Interaction__c` directly |
| Status | Still deployed. Flow is active (last modified 2026-09-03) and still serves LinkedIn, chatbot and referral leads. | Replaces the old form per controller |

Do not remove or edit the flow as part of this work. It still has other lead sources.

**Controller adoption in eda-staging:** 136 `RFI_Controller__c` records. 20 have
`Unified_Questions__c` populated. 116 do not (legacy field lists). Academic level: 98
graduate, 38 undergraduate.

---

## 2. What the old path did that the new path does not

The old path did three things the tickets only partly describe: work in the browser,
work in Apex, and work in the flow. Sources: the retrieved old LWC, old Apex class,
and flow XML from eda-staging.

### 2.1 Old form and old Apex

| Behavior | Old | New today |
|---|---|---|
| Recruitment Program | `getRecruitmentProgram` picks an Academic Program by rule. Undergraduate Transfer: "Undergraduate Transfer" (or "Undergraduate Transfer (INTL)" if citizenship is International). Dougherty Family College: "Dougherty Family College". Other undergraduate: "Undergraduate First-Year". Graduate: the program matching the chosen major. | Only the Academic Program tied to the first Academic Interest. No undergraduate rules. |
| School/College | Derived from the major's `Primary_School_College_for_Assignment__c` when the controller has none | Only from the controller or a question |
| Preset values | `Lead_Preset_Value__mdt` rows applied per controller | Ignored |
| Description | `Questions/Comments from RFI:` and `Tell us about yourself from RFI:` headers, both in one field | Both questions write `Description__c`; last write wins |
| Text messages | Checkbox converted to `Yes` / `No` | Picklist (fixed on this branch) |
| Inquiry date | Set to today | Not set |
| Error handling | Failed submits logged to `hed__Error__c` with controller name and payload | None; generic toast only |
| Value cleanup | Text truncated to field length; `utm_*` and `gclid` HTML-escaped | None |
| Duplicates | `allowSave = false` (duplicate rules block the save) | `allowSave = true` (duplicates are created) |

### 2.2 The flow (`Auto_Convert_Recruitment_Flow`)

Fields the flow set on every Interaction that the new form leaves empty or wrong:

| Interaction field | Flow value | New form today |
|---|---|---|
| `Interaction_Source__c` | `Webform` | Picklist default `Application` (wrong) |
| `Opportunity_Stage__c` | `Inquiry` | Empty |
| `Opportunity_Record_Type__c` | Id of Opportunity record type `Inquiry_Opportunity` (Text, 25) | Empty |
| `Date_Inquiry__c` | Lead inquiry date, else today | Empty |
| `Term__c` | `hed__Term__c` whose name matches the chosen start term | Empty |
| `Recruitment_Program_Associated_Schools__c` | Program's `Associated_Schools__c` | Empty |
| `State__c`, `Country__c` | State code and country label from the Lead | Never written |
| `Mailing_State__c` | State code, only when country is "United States of America" | State code (same) |
| `Mailing_Country__c` | Lead country label | Lead country label (same) |
| `Pardot_Sync_OCB__c` | Computed in flow | Replaced by formula `Pardot_Sync_OCB_Formula__c` (5604, done) |

`Recruitment_Interest__c` (Plans) was also set, but Plans are retired per the 5588
thread. Leave it out unless someone says otherwise.

Still working without changes: the nominator fields and the
"Interaction on Create: Nomination Record" flow, which fires on any Interaction whose
`Lead_Source__c` is `Alumni Referral Program`.

### 2.3 Why the missing values matter: `Interaction_Mapping__c`

eda-staging has 140 active `Interaction_Mapping__c` rows that carry Interaction values
to Contact and Opportunity. Examples that depend on the gaps above:

| Interaction field | Feeds |
|---|---|
| `Opportunity_Record_Type__c` | `Opportunity.RecordTypeId` |
| `Opportunity_Stage__c` | `Opportunity.StageName` |
| `Date_Inquiry__c` | `Opportunity.Date_Inquiry__c` |
| `Term__c` | `Opportunity.Term__c` |
| `State__c`, `Country__c` | `Opportunity.State__c`, `Opportunity.Country__c` |
| `Mailing_*` | `Contact.Mailing*`, `Opportunity.Zip_Code__c` |

Not mapped onward (stay on the Interaction only): `Scholarship_of_Interest__c`,
`Receive_Texts__c`, `Description__c`, `Has_Question__c`,
`Mailed_Program_Information_Requested__c`.

**Not tested:** what the Opportunity automation does when those source values are
empty. Treat the gaps as high priority until Phase 0 shows otherwise. The meaning of
`Skip_Mapping__c` on a row was also not confirmed.

---

## 3. Findings

Evidence is from the repo (branch above) and eda-staging. "Hypothesis" means the code
suggests it but no submission was run.

| # | Finding | Evidence | Type |
|---|---|---|---|
| F1 | The Question Manager writes invalid targets for new questions: Title to `Salutation__c`, mail to `Mail_Information__c`, Timeline to `Timeline__c`. The Apex remap only catches older lowercase keys (`title__c`), so `Salutation__c` passes through. | `rfiUnifiedQuestionManager.js` `fieldInteractionAPIMap`; `legacyApiNameRemap` in `rfiFormController.cls`. Saved JSON in eda-staging already holds these: Title 2 controllers, Mail 2, Timeline 2. | Verified |
| F2 | The unified path treats two Lookup-backed questions as plain text: Expected Start Term (`Intended_Start_Term__c`, 5 controllers) and St Thomas Colleges (`St_Thomas_College_School__c`). The legacy path handles both. This matches Mike's "becomes a text field after Save Configuration" report and the St. Thomas Colleges submit error. No ticket tracks it. | `processUnifiedQuestions` has no branch for either; legacy `getRFIForm` uses `getTerms()` and `getUSTSchoolList()`. | Verified |
| F3 | Saved questions with no mapping at all, so answers are dropped: "Home and Mobile Phone" (4 controllers); Address 1/2/3, City, State, Zipcode, Country (controller 0357); "When do you plan to start school" (0357). Cheng's "Address 1, 2, 3 aren't coming through" refers to these split questions. The combined "Address" question works. | Question usage counts from `Unified_Questions__c` across 20 unified controllers. | Verified |
| F4 | Per-controller presets are ignored. Controllers 0229, 0245 (Schulze Innovation), 0266 and 0288 (GHR Fellows) preset `Scholarship_of_Interest__c`. This explains empty Scholarship on 0229, which has no Scholarship question. | `Lead_Preset_Value__mdt` rows; new code has no reference to presets. | Verified |
| F5 | Defaults the flow used to set are missing (section 2.2). | Flow XML. | Verified |
| F6 | Recruitment/Academic Program logic differs for undergraduate (section 2.1). Mike's unanswered question on 5588 is answered by `getRecruitmentProgram`: First-Year vs Transfer vs International Transfer vs Dougherty Family College. | Old Apex class. | Verified (rules); whether to port them is Decision D4 |
| F7 | Multi-select answers may be sent as an array where Apex expects a semicolon string. Affects `Scholarship_of_Interest__c` and `Heard_About_Us__c` when a user answers the question (controller 0356 has the Scholarship question). | `handleMultiSelectChange` stores the array from the pills component. | Hypothesis. The submit payload is already logged to the browser console. |
| F8 | "I can't find my school" writes typed text into `High_School_or_College__c`, which is a Lookup. The flow copied `hed__Most_Recent_School__c` to `School_Name_Text__c`, which looks like the intended home for typed names. | `handleManualSchoolEntry`; flow mapping. | Verified code path; old form's manual-school handler not read in detail |
| F9 | `State__c` and `Country__c` (restricted picklists, feed Opportunity) are never written. The `Mailing_*` pair receives the same values the old flow wrote, so the 5764 claim that these are silently dropped is not supported: `Mailing_Country__c` and `Mailing_State__c` are unrestricted. | Describes of Lead and Interaction in eda-staging: `State__c` accepts `MN`, `Mailing_State__c` accepts `Minnesota`; the form sends `MN`. | Verified |
| F10 | Both Description writers collide (section 2.1). | `rfiFormController.cls`, `Has_Question__c` help text. | Verified |
| F11 | `submitRfiInteraction` copies any creatable field the browser sends, including `OwnerId`, `Lead_Source__c` and opportunity fields. The endpoint is reachable by guests through Lightning Out. | Loop over `getPopulatedFieldsAsMap()`. | Verified code path |
| F12 | Failures are silent: `processUnifiedQuestions` catches every exception and returns a partial form; non-creatable fields are skipped with only a debug line; no error record is written. | `rfiFormController.cls`. | Verified |
| F13 | Duplicate behavior changed from block to allow (section 2.1). | Both Apex classes. | Verified; intent unknown |
| F14 | Deselecting all Academic Interests leaves the previous `Major_Program_1..4__c` values in place. | `handleAcademicInterestChange` returns early when the list is empty. | Verified |
| F15 | Repo does not match eda-staging: 8 custom Interaction fields exist only in the org (`Pardot_Sync_OCB_Formula__c`, `Partner_Populations_Supported__c`, `Personal_Email__c`, `Preferred_Email__c`, `Preferred_Phone__c`, `Title_Affiliation__c`, `Work_Email__c`, `Work_Phone__c`). The flows and `Lead_Preset_Value__mdt` are not in the repo. | Org describe vs `force-app`. | Verified |
| F16 | Mike reports `rfiFormController` on eda-staging was not updated although the story says it was deployed on 2026-08-26. | Comment on 5764. | Needs a retrieve and diff (Phase 0) |
| F17 | High School Attended "not displaying on 0229" is not explained by configuration: controllers 0229 and 0356 both include the question and are both undergraduate. | Controller JSON. | Needs a browser repro (Phase 0) |

---

## 4. Interaction field map

Target fields are verified against the eda-staging describe. "Change" is what this plan
proposes.

| Question | Target field (type) | Status | Change |
|---|---|---|---|
| First / Last Name, Email | `First_Name__c`, `Last_Name__c`, `Email__c` | OK | None |
| Phone | `Home_Phone__c` | OK | None |
| Home and Mobile Phone | none | Dropped (F3) | `Home_Phone__c` plus `Mobile_Phone__c` (Phone, exists). Confirm against old form lines 645-660. |
| Academic Interest | `Major_Program_1..4__c` | OK | Add clear on deselect (F14); add derived programs (F5, F6) |
| High School Attended | `High_School_or_College__c` (Lookup) | OK for lookup; broken for typed text | Typed text to `School_Name_Text__c` (F8) |
| High School Graduation Year | `High_School_Graduation_Year__c` (Text) | OK | None |
| I would like to receive text messages | `Receive_Texts__c` (Picklist Yes/No) | Fixed on branch | Regression test |
| I will apply to St Thomas as a / St Thomas Law as a | `Admit_Type__c` | OK, two questions share one field | Confirm priority rule (D-list) |
| Expected Start Term | `Intended_Start_Term__c` (Lookup) | Renders as text in unified path (F2) | Use `getTerms()`; also set `Term__c` |
| St Thomas Colleges | `St_Thomas_College_School__c` (Lookup) | Renders as text in unified path (F2) | Use `getUSTSchoolList()` |
| Address | `Mailing_Street__c`, `Mailing_City__c`, `Mailing_State__c`, `Mailing_Country__c`, `Mailing_Postal_Code__c` | OK, parity with flow | Also write `State__c`, `Country__c` (F9) |
| Address 1/2/3, City, State, Zipcode, Country | none | Dropped (F3) | Migrate saved configs to the combined Address question |
| I have a question | `Has_Question__c` (Checkbox) plus text | Collides (F10) | Compose into `Description__c` with headers |
| Tell us about yourself | `Description__c` | Collides (F10) | Same |
| Employer / Company | `Employer__c` | OK | None |
| Birthdate | `Birthdate__c` (Date) | Works per Cheng | Parity check only |
| How did you hear about us | `Heard_About_Us__c` (Multi-select) | Hypothesis F7 | Serialize as semicolon string |
| Scholarship of Interest | `Scholarship_of_Interest__c` (Multi-select) | F4, F7 | Presets plus serialization |
| Title | `Contact_Title__c` (Text) | Manager still emits `Salutation__c` (F1) | Fix manager and remap |
| I would like program information to be mailed | `Mailed_Program_Information_Requested__c` (Checkbox, exists) | `Mail_Information__c` does not exist (F1) | Fix manager and remap |
| Timeline to Enrollment | `Timeline__c` | Field does not exist on Interaction | Create (D1). Lead's field is a restricted picklist: 0-6 Months, 6-12 Months, More than 1 Year, Undecided. |
| When do you plan to start school | none | No old-form counterpart; one test controller | D2 |
| Nominator / referral custom questions | `Nominator_*`, `Relationship_to_Student__c`, `Identify_as_Reference__c`, `St_Thomas_Alumni_Class_Year__c` | OK | Regression test on 0356 |

---

## 5. Plan

Work is ordered so that each phase is deployable on its own and the riskiest unknowns
are measured first.

### Phase 0: Baseline on eda-staging (no code changes)

1. Retrieve `rfiFormController`, `rfiForm` and `rfiUnifiedQuestionManager` from
   eda-staging into `ai-logs/` and diff against the branch (F16).
2. Build a parity matrix. For each case, submit once through the old form and once through
   the new form, then compare the resulting Interactions field by field. Cases:
   - Undergraduate First-Year (0299)
   - Undergraduate Transfer, and International Transfer
   - Dougherty Family College
   - Graduate with Academic Interest and a program filter
   - Schulze with presets (0229)
   - Nominator / alumni referral (0356)
   - Every preconfigured question on one controller (0357)
   - A legacy-path controller (0230)
3. Settle the hypotheses with measurements, not guesses:
   - F7: read the console payload for a Scholarship / Heard About Us submit.
   - F9: confirm the Opportunity effect of empty `State__c` / `Country__c`.
   - Section 2.3: confirm what the Opportunity automation does with empty record type,
     stage and term.
   - F17: reproduce High School Attended on 0229 versus 0356.
   - Field-level access: confirm the submitting user can create every field the form
     sends. Use a throwaway `@IsTest` probe named `ZZ_Probe_TEST`, then delete it from the
     repo and the org.
4. Check that the Program records the old rules rely on exist in eda-staging
   ("Undergraduate First-Year", "Undergraduate Transfer", "Undergraduate Transfer (INTL)",
   "Dougherty Family College", plus their `Program_Major_Concentration__c` codes).

**Done when:** the matrix lists every difference, each marked as bug, intended change or
accepted.

### Phase 1: Mapping hotfix (ECRMSF-5764)

- Fix the Question Manager map: Title, mail, Timeline, and add Home and Mobile Phone.
- Make the Apex remap key on the saved `fieldName` as well as the API name, so already-saved
  configs are corrected without admin action.
- Add unified-path handling for Expected Start Term and St Thomas Colleges (F2).
- Add the missing Interaction fields (D1) and a permission set that grants them.
- Script a one-time, idempotent update of `Unified_Questions__c` in eda-staging (anonymous
  Apex run from `ai-logs/`) that rewrites bad targets and replaces the split Address
  questions. The same script runs in production at release.

**Done when:** a controller with every preconfigured question submits and every answer
lands on the Interaction (the 0357 case in Phase 0 is clean).

### Phase 2: Server-side parity (ECRMSF-5588)

Move submit-time logic into one testable Apex class (suggested name
`rfiSubmissionProcessor`, called from `submitRfiInteraction`). The browser sends the
controller name; Apex reads the controller and decides what is allowed.

- Defaults: `Interaction_Source__c = Webform`, `Date_Inquiry__c`, `Opportunity_Stage__c =
  Inquiry`, `Opportunity_Record_Type__c` (look up the Inquiry_Opportunity record type Id
  by developer name, never hard-code an Id), `Term__c`, `Recruitment_Program_Associated_Schools__c`,
  `State__c`, `Country__c`, and School/College from the major when the controller has none.
- Presets: apply per-controller preset values (D5).
- Programs: port the undergraduate rules if D4 says so.
- Description: compose with the old headers (D3).
- Values: multi-select to semicolon string (F7), typed school to `School_Name_Text__c`
  (F8), truncate to field length, escape `utm_*` / `gclid`.

Defaults live in Apex rather than a flow because they are then covered by tests and
versioned in the repo (D7).

**Done when:** every row in section 2.2 matches the old flow for the Phase 0 cases.

### Phase 3: Hardening

- Allow only the fields the controller's questions, UTM parameters and tracking fields
  can legitimately set (F11). Reject or ignore everything else; log what was ignored.
- Write failures to `hed__Error__c` with the controller name and payload, as the old form
  did (F12). Make `processUnifiedQuestions` report failure instead of returning a partial
  form.
- Decide duplicate behavior (D6).
- Clear `Major_Program_*` when Academic Interest is emptied (F14).
- Because the form is served through Lightning Out, change the Aura dependency app with a
  real content change after deploying the Apex and LWC, then verify a fresh `auraCmpDef`
  request (see the agent-onboarding caching note).

### Phase 4: Guardrails

- **Schema audit test (Apex):** every mapped target exists, is createable and has a type
  compatible with its question. This would have caught `Timeline__c` and
  `Mail_Information__c`.
- **Parity test:** the legacy and unified paths produce the same field for the same
  question.
- **Unit tests:** presets, defaults, program rules, description composition, address
  normalization, field allowlist.
- **Jest:** manager map matches the Apex catalog; multi-select serialization; manual school;
  clear on deselect; address; a `load`-style repeat-event test where relevant.
- **Single source of truth:** replace the three duplicate mappings (manager JS map, legacy
  Apex `switch`, unified Apex remap) with one catalog the manager reads from Apex.
- Before calling a fix done, break it on purpose and confirm the new test fails, then restore.

### Phase 5: Rollout

1. Scratch org: seed `Program__c`, `Academic_Term__c` and record types needed so the form
   can be exercised end to end. Apex tests create their own data.
2. eda-staging: deploy targeted (classes, then LWC, then Aura dependency app), run the
   Phase 0 matrix again, run the controller JSON migration.
3. Production is a separate story. Deployment order, the JSON migration and the new fields
   go in its checklist. Anything in the org but not in the repo (F15) gets retrieved first so
   production is not surprised.
4. Related tracks: 5800 (test dynamic program-filter questions) runs against the Phase 2
   build. 5856 includes the Question Manager bug where the Question Label does not update
   after the Filter Field is changed.

---

## 6. Decisions needed

| # | Decision | Recommendation |
|---|---|---|
| D1 | Create `Timeline__c` on Interaction, or drop the question? | Create it, copying Lead's restricted picklist. Nothing maps it onward. |
| D2 | "When do you plan to start school" has no old-form counterpart. | Remove it from the question list, or map it to Timeline. It exists on one test controller. |
| D3 | Description: combine both answers or use a separate field? | Combine with the old headers so anyone reading Description sees the same layout. |
| D4 | Port the undergraduate Recruitment Program rules (First-Year / Transfer / INTL / Dougherty)? When an undergraduate also picks an Academic Interest, which wins? | Port the rules. Confirm precedence with Admissions. |
| D5 | Presets: reuse `Lead_Preset_Value__mdt` (needs a Lead-to-Interaction field name map, for example `LeadSource` to `Lead_Source__c`) or create an Interaction preset type? | New Interaction preset type; copy the 4 active rows. |
| D6 | Duplicates: block (old) or allow (new)? | Needs a business answer; the code comment suggests allow is intended. |
| D7 | Defaults in Apex or in a flow? | Apex. |
| D8 | Address values: keep parity with the old flow, or normalize `Mailing_Country__c` to its own picklist values (for example "United States" instead of "United States of America")? | Parity now. Normalizing changes `Contact.MailingCountry` content. |
| D9 | "I will apply to St Thomas as a" and the Law version both map to `Admit_Type__c`. Is "St Thomas wins when both are filled" intended? | Confirm, then document and test it. |
| D10 | Which Jira subtasks to open (suggested below)? | Open them. |

**Suggested subtasks under 5545:** unified-path lookup parity (F2); invalid mapping
targets and saved-config migration (F1, F3); presets and server defaults (F4, F5); program
rules (F6); submit hardening and error logging (F11, F12); guardrail tests; metadata and
repo drift (F15); baseline parity matrix (Phase 0).

---

## 7. Risks and what is not verified

- **Not tested by submission:** no form was submitted in any org. F7, F9's downstream
  effect, F17 and field-level access are hypotheses until Phase 0.
- **Production may differ from eda-staging** (refresh date, drifted metadata). Compare
  before the production story.
- **Old form's manual-school handling** was not read in detail (F8).
- **Meaning of `Skip_Mapping__c`** on `Interaction_Mapping__c` rows is unconfirmed.
- **Changing `submitRfiInteraction`'s signature** can interact with Lightning Out caching.
  Keep an overload or ship client and Apex together, then verify with a fresh browser
  context.
- **116 of 136 controllers** have no unified configuration. They run through the legacy
  branch of `rfiFormController`, so Phase 1 and 2 changes need tests for that branch too.

---

## 8. Evidence and reproduction

Working files are in `ai-logs/` (gitignored). They contain configuration and metadata only,
no credentials.

| Content | File |
|---|---|
| Jira story, comments, subtasks | `ECRMSF-*.json`, `c-*.json`, `r-5545.txt`, `r-others.txt` |
| Lead-to-Interaction flow digest | `flow-auto-convert.txt` (source in `retrieve/flows/`) |
| Old LWC and Apex | `retrieve/lwc/requestForInformationForm/`, `retrieve2/classes/requestForInformationFormController.cls` |
| Org describes | `interaction-describe.json`, `lead-describe.json` |
| Controllers and mappings | `controllers.json`, `imap.json` |

Reproduce the read-only checks with the `eda-staging` org alias:

```bash
sf sobject describe --sobject Interaction__c --target-org eda-staging --json
sf project retrieve start --target-org eda-staging --output-dir ai-logs/retrieve \
  --metadata "Flow:Auto_Convert_Recruitment_Flow" "LightningComponentBundle:requestForInformationForm"
sf data query --target-org eda-staging --query "SELECT Name, Unified_Questions__c FROM RFI_Controller__c"
```
