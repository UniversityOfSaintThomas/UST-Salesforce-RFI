# RFI Form Robustness Plan

**Jira:** ECRMSF-5545 (parent), ECRMSF-5588, 5764, 5732, 5800, 5856, 6020
**Prepared:** 2026-10-27
**Branch:** `ECRMSF-619_dynamic-rfi-questions`
**Status:** Decisions D1-D9 resolved 2026-10-28 (section 6). Phase 0 is in progress: the
read-only checks are done (section 5, Phase 0 progress); the old-versus-new submission
matrix is waiting for approval to create test records in eda-staging. Jira subtasks wait
until Phase 0 is complete (D10).

---

## 1. Goal and environment

Make the new `rfiForm` LWC produce Interaction records that match what the old
Lead-based path produced, and make it hard to break that again.

**Target environment.** `rfiForm` must work in the scratch org, but it is built for
the **eda-staging full sandbox** and then production. Everything below was checked
against eda-staging with describes, queries, metadata retrieves and, in Phase 0, five test
submissions that were deleted afterwards. No metadata was deployed to eda-staging.

**Working agreement for environments (decided 2026-10-29).** eda-staging is for investigation only:
the assistant reads (describes, queries, retrieves) and does not deploy, run scripts that write data,
or create test records there. The repository owner deploys to eda-staging and production. Changes are
built and tested in scratch orgs first, then deployed by the owner, and differences found in staging
are observed and fixed afterwards. Phase 0 (2026-10-28) wrote five test submissions to eda-staging
before this agreement; they were deleted, and no further writes will be made.

**Scope rule for permissions (decided 2026-10-29).** Permission sets, profiles and sharing rules in
this repo exist only so scratch orgs work. Admins own permissions in eda-staging and production,
and developers never deploy or overwrite them there. Profiles are not tracked in the repo at all.
Where staging or production needs a permission change, it is written up as a note for admins
(section 9) and the admins decide. Fields themselves are metadata and are still deployed by developers;
their field security is then set by admins.

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

**Measured in Phase 0 (section 5):** with those source values empty, the Opportunity is created
as record type `Donor`, stage `Enrollment Prospect`, with no term, inquiry date or
undergraduate programs (F20). The meaning of `Skip_Mapping__c` on a row was not confirmed.

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
| F5 | Defaults the flow used to set are missing (section 2.2). Measured 2026-10-28 (cases A-E): NEW leaves `Interaction_Source__c` at `Application`, and `Date_Inquiry__c`, `Opportunity_Record_Type__c`, `Term__c` and the associated schools empty. | Flow XML; cases A-E. | Verified (measured) |
| F6 | Recruitment/Academic Program logic differs for undergraduate (section 2.1). Mike's unanswered question on 5588 is answered by `getRecruitmentProgram`: First-Year vs Transfer vs International Transfer vs Dougherty Family College. | Old Apex class. | Verified (rules); port them (D4) |
| F7 | **Multi-select answers never reach the payload, and a second bug sits behind the first.** (1) `handleMultiSelectChange` finds the field with `f.name === name`, but the Apex `rfiField` class has no `name` property, so the lookup never matches and the handler returns without saving. (2) Once that is fixed, the pills component emits `detail.value` as an array (`valueString.split(";")`), which the handler would store as an array; Apex cannot read an array into a multi-select field (server probe: `JSONException`). | Browser test 2026-10-28 on the scratch public site: the component held `Friend` and `Schulze Innovation`, the submitted payload contained neither field, and the saved Interaction was blank. Server probe in eda-staging for (2). The existing Jest test uses an old field shape and cannot see either bug. | Verified in a browser
| F8 | "I can't find my school" writes typed text into `High_School_or_College__c`, which is a Lookup. The flow copied `hed__Most_Recent_School__c` to `School_Name_Text__c`, which looks like the intended home for typed names. Probe 2026-10-28: assigning typed text to the lookup deserializes to null with no error, so the answer is lost silently. | `handleManualSchoolEntry`; flow mapping; probe. | Verified code path and silent loss; old form's manual-school handler not read in detail |
| F9 | `State__c` (restricted) is never written by the form, so `Opportunity.State__c` is blank for NEW (measured, case D: OLD = MN, NEW = blank). `Country__c` appears populated on NEW records only because the field has a picklist default of "United States of America", so an international applicant would be recorded as the USA. The `Mailing_*` pair matches the old flow: Contact mailing fields were identical in OLD and NEW for case D. | Interaction describe; cases A and D. | Verified (measured) |
| F10 | Both Description writers collide (section 2.1). | `rfiFormController.cls`, `Has_Question__c` help text. | Verified |
| F11 | `submitRfiInteraction` copies any creatable field the browser sends, including `OwnerId`, `Lead_Source__c` and opportunity fields. The endpoint is reachable by guests through Lightning Out. | Loop over `getPopulatedFieldsAsMap()`. | Verified code path **Fixed in scratch (2026-11-02):** `rfiSubmissionGuard` accepts only fields that belong to the controller's form, tracking fields and the controller's defaults; owner and lead source come from the controller; ~27 server-controlled fields are never taken from the browser. Ignored fields are reported in one Error record. |
| F12 | Failures are silent: `processUnifiedQuestions` catches every exception and returns a partial form; non-creatable fields are skipped with only a debug line; no error record is written. | `rfiFormController.cls`. | Verified **Fixed in scratch (2026-11-02):** failures write `hed__Error__c` (controller name, what was entered, cause) via `rfiErrorLogger`; `submitRfiForm` returns null instead of throwing so the record is not rolled back, and the page shows an error. A form whose questions cannot be read now fails with a clear message instead of loading partly. |
| F13 | Duplicate behavior changed from block to allow (section 2.1). | Both Apex classes. | Resolved (D6): RFIs are always accepted. Keep `allowSave = true`; do not add blocking. |
| F14 | Deselecting all Academic Interests leaves the previous `Major_Program_1..4__c` values in place. | `handleAcademicInterestChange` returns early when the list is empty. | Verified **Fixed in scratch (2026-11-02):** emptying Academic Interest clears all four `Major_Program_*` fields (`withMajorPrograms`). |
| F15 | Repo did not match eda-staging: 8 custom Interaction fields existed only in the org. **Done 2026-10-28:** 7 retrieved into `force-app` (`Partner_Populations_Supported__c`, `Personal_Email__c`, `Preferred_Email__c`, `Preferred_Phone__c`, `Title_Affiliation__c`, `Work_Email__c`, `Work_Phone__c`). `Pardot_Sync_OCB_Formula__c` is in `unpackaged/staging-only/` because a validate-only deploy to the scratch org fails: "formula references fields across 16 unique relationships while only 15 are allowed". It deploys in eda-staging. The flows and `Lead_Preset_Value__mdt` are still not in the repo. | Org describe vs `force-app`; dry-run deploy of all 9 field files to the scratch org (8 passed). | Verified |
| F16 | `rfiFormController` on eda-staging is **not** the branch version. It still maps `title__c` to `Salutation__c` and still renders the text-message question as a checkbox. The fixes described as deployed on 2026-08-26 are not in staging. | Retrieve of the deployed class and diff against the branch. | Verified |
| F17 | High School Attended "not displaying on 0229" is not explained by configuration: controllers 0229 and 0356 both include the question and are both undergraduate. | Controller JSON. | Needs a browser repro (Phase 0) |
| F18 | **Resolved 2026-10-28.** The branch was behind eda-staging for the shared lookup (staging validates the search field against the object's field map and has extra lookup features). The staging versions of `ReusableLookupController`, `reusableLookup` and the test class are now on the branch (commit `1189288`). Verified by diff: the LWC and test class are identical to staging, and the controller and css differ only in whitespace (one misindented block in the controller; logic identical). | File diffs of staging versus branch. | Resolved |
| F19 | **Resolved 2026-10-28.** The Aura dependency app declared `c:rfiFrom`, which is not a component. It now declares `c:rfiForm` alongside `c:requestForInformationForm`. After the next deploy, make a real content change to the app if Lightning Out serves a stale bundle (see agent-onboarding caching note). | `requestForInformationApp.app` | Resolved |
| F20 | **The Opportunity created from a NEW Interaction is wrong.** For the same inputs, OLD Opportunities were record type `Inquiry_Opportunity`, stage `Inquiry`, with inquiry date, term, programs and a full name (last name, term and program joined by pipe characters). NEW Opportunities were record type `Donor`, stage `Enrollment Prospect`, no inquiry date, no term, no programs for undergraduates, and a name with the term and program parts empty. | Cases A-E, `Opportunity` query in eda-staging. | Verified (measured). Highest priority. |
| F21 | Undergraduate Recruitment/Academic Program is empty for every NEW undergraduate submission; the old rules chose First-Year, Transfer or Transfer (INTL). Graduate programs match OLD. | Cases A, B, C, E versus D. | Verified (measured) |
| F22 | No outbound problems were observed for the five cases: no `hed__Error__c` rows, and the existing Lead-conversion trigger ran for the OLD Leads. Whether Marketing Cloud, Act-On or Journey Builder reacted was not checked. | Phase 0 run. | Partly verified |
| F23 | eda-staging holds two `hed__Term__c` records per term (for example keys `202740` and `202740a`). The flow selects the one whose key contains `a`. A port must replicate this or `Term__c` will point at the wrong record. | `hed__Term__c` query for Fall 2027. | Verified |
| F24 | **The new controller cannot read its own configuration as a guest user.** The old `requestForInformationFormController` was `without sharing`; `rfiFormController` and `ReusableLookupController` are `with sharing`. Guest users see no records unless a guest sharing rule grants them, and `WITH SYSTEM_MODE` does not bypass sharing. Scratch org symptom: `getRFIForm` throws `List has no rows for assignment to SObject` (line 64) for the EASY Applicant Portal guest user. The same would happen in eda-staging: the `Admissions` guest user has guest sharing rules for Programs and school Accounts only, and none for `RFI_Controller__c` or `Academic_Term__c`, and its Account rule does not cover University Department accounts. | Live response from the scratch site; guest sharing rules retrieved from both orgs; class headers. | Verified |
| F25 | **Browser test on the scratch public site (2026-10-28).** As the anonymous EASY Applicant Portal guest, `getRFIForm` succeeded after the controller reader, the field grants and the `RFI_User` permission set changes; the guest then created an Interaction, a Contact and an Opportunity. The Opportunity came out as `Name\|\|` with stage Enrollment Prospect, the same defect as F20. | Live submit on controller 0001; Interaction `a10dq00002zPjnTAAS`. | Verified |
| F26 | **Sharing rules added by the new `config_dev` tasks do not fit the form.** The Account guest rule for EASY Applicant Portal was narrowed to Educational Institution accounts of type College/High School, which removes the University Department accounts the school list needs (live result: College\\School has 0 options). The new `Academic_Term__c` rule is for the Summit Events guest user, not EASY Applicant Portal (live result: Expected Start Term has 0 options). Interaction external default is now ReadWrite. | `unpackaged/sharing`; rules and defaults retrieved from the scratch org; live form option counts. | Verified |
| F27 | **Textareas overwrite each other and the answer is lost.** `_validateForm` copies every textarea and input into the payload by its `name`. Controller 0001 renders nine "Field Label Not Found" textareas (questions the legacy switch does not know: Address 1, 2, 3, City, State, Country, Zipcode, Home and Mobile Phone, St Thomas Law) that all fall back to `Description__c`, so the last blank one overwrites "Tell us about yourself". The "I have a question" box is named `Description`, which is not an Interaction field, so that answer is dropped. | Payload from the browser test: no `Description__c`; a stray `Description` key. | Verified in a browser |
| F28 | **An empty duplicate input overwrites a real answer.** "When do you plan to start school" and "High School Graduation" both map to `High_School_Graduation_Year__c`; the blank one is sent last, so the 2028 entered was submitted as an empty string. | Payload: `High_School_Graduation_Year__c: ""`. | Verified in a browser |
| F29 | **Resolved: `Timeline__c` was saved; the admin could not see it.** A scratch org gives the admin every field it knows at build time. A field created later has no field security for anyone, so the admin user could not describe or query `Timeline__c`, and an earlier note in this plan that the value "was sent but not saved" was wrong. After `RFI Controller User` was assigned to administrators and the field added to it, all three browser test records show `Timeline__c = 0-6 Months`. The guest, which holds `RFI User`, was never affected. | Admin describe and query before and after; three saved test Interactions. | Resolved. Process rule: every new field goes into `RFI User` (guest) and `RFI Controller User` (admins) in the same change |
| F30 | **The single "Phone" question saves to the wrong phone field.** The old form sent it to the Lead mobile phone; the new form sends it to `Home_Phone__c`. It also collides with the Home Phone input: on controller 0001 both write `Home_Phone__c`, and the blank one is copied last, so the typed home phone is lost (payload: `Home_Phone__c: ""`). Open decision: where should "Phone" save? Recommendation: `Mobile_Phone__c`, to match the old form. | Old form handler (`phone_label` case); browser payload; Phase 1 test. | Resolved in scratch (2026-11-02): "Phone" saves to `Mobile_Phone__c`; "Home Phone" keeps `Home_Phone__c`. **Provisional**: expect to revisit, because many people have only one number. |
| F31 | **`RFI Controller User` in the scratch copy was behind staging.** It lacked the controller fields the Question Manager saves (`Unified_Questions__c`, `Fields_to_Display_Order__c`, four filter fields, `School_College__c`), `Account.School_College_Name__c`, and Apex class access to `rfiFormController`, `ReusableLookupController` and `AcademicInterestSelectorController`. 22 field grants and the 3 class accesses were added to the repo copy on 2026-10-29. In staging 19 users hold this set (14 Enrollment Staff, 1 of them inactive, and 5 administrators, 1 of them inactive), so the repo copy is for scratch orgs only and is never deployed to staging. The differences are recorded for admins in section 9. | Retrieve of both copies; holders query; deploy to scratch. | Verified |
| F32 | **One missing field permission loses the whole RFI.** The first guest submission after Phase 2 failed with "fields being inaccessible on Interaction__c" for eight fields the server now sets (`Interaction_Source__c`, `Date_Inquiry__c`, `Opportunity_Stage__c`, `Country__c`, `Recruitment_Program__c`, `Academic_Program__c`, `Recruitment_Program_Associated_Schools__c`, `Term__c`). The scratch `RFI User` had them read-only; staging's copy already grants edit on all of them. | Guest browser run; staging and repo `RFI User` compared field by field. | Fixed in scratch: repo `RFI User` grants edit on the ten server-set fields, and `submitRfiForm` now drops any field the user cannot create (`Security.stripInaccessible`) and writes a warning to the debug log, so the RFI is still saved. |
| F33 | **Per-controller presets never applied on the live path.** The controller reader did not select `Name`, so the preset lookup failed with "SObject row was retrieved via SOQL without querying the requested field: RFI_Controller__c.Name". The processor swallowed it as a warning. Unit tests missed it because they pass a fully loaded record. | Guest debug log (trace flag extended for one hour). | Fixed: `Name` is selected; test `loadControllerByName_includesTheNameSoPresetsCanBeFound_TEST` fails without it. |
| F34 | **A lookup to a record the user cannot see makes the insert fail.** The processor finds Ids in system mode, but Salesforce refuses the insert when the guest cannot see the record a lookup points to (error: "insufficient access rights on cross-reference id" for the Term). `hed__Term__c` is controlled by its parent Account, and every Term the form uses belongs to the one Administrative account "University of St Thomas". | Guest browser run; `EntityDefinition` sharing models; Term parent query in scratch and staging. | Fixed: the processor clears (and reports) any lookup the running user cannot see. Scratch gets a narrow guest rule for that one account. Staging's Account external default is `Read`, so the guest can probably see it already (check, see section 9 G). |
| F35 | **`State__c` holds the state code, not the name.** The flow stored `StateCode` (MN); the form saved only the name (`Mailing_State__c` = Minnesota), so name matching could never fill `State__c`. | Flow text; describe of `State__c` in scratch and staging (values are two-letter codes). | Fixed: the form sends the code as `State__c`; Apex keeps it only when it is in the org's own list and falls back to a name match. |
| F36 | **Phase 2 deleted `handleAcademicInterestChange` from `rfiForm.js`.** The template still bound it, so choosing academic interests saved nothing to `Major_Program_1..4__c`. Neither the Jest tests nor the first guest runs noticed, because no run selected an Academic Interest. Found while starting F14. | Diff of method names between HEAD and the working file; guest payload before and after. | Fixed and covered: the handler is back and two component tests choose programs and empty the selection. Nothing was deployed outside scratch. |
| F37 | **The page echoes the controller's own owner and lead source back to the server.** The form returns its whole Interaction, so with the allowlist every normal submission would have been reported as having ignored fields. | First guest run after the allowlist (Error record listing `Lead_Source__c`). | Fixed: the echo is recognised and not reported; any different value is. |
| F38 | **A Birthdate typed as text makes the server reject the whole submission.** Both form definitions marked Birthdate as a date, but the page never used that flag (the template read `inputType`, which nothing set), so Birthdate was a plain text box. Text such as `01/15/2000`, the format the older label asks for, cannot be read into a Date field, so Aura rejects the request before any code runs: nothing is saved and nothing is logged. A blank value is dropped by the page, so only visitors who typed a birthdate were affected. Found by the new type audit. | `JSON.deserialize` probe in scratch (`01/15/2000`, `1/5/2000` and an empty string all fail; `2000-01-15` works); template and wrapper. Whether this was already happening in production is not known; the old Lead form is a separate component. | Fixed in scratch: any question that saves to a Date field is drawn as a date picker (`inputType = 'date'`), on both paths and for custom questions. Live guest check: `1999-12-31` sent and saved. The older label still says "Birthday (MM/DD/YYYY)"; shorten it if the picker makes that confusing. |
| F39 | **Eight of the twelve program filters name an Interaction field that does not exist** (`Degree_Type__c`, `Student_Type__c`, `Delivery_Type__c`, `Generic_Filter_2__c`, `_4__c`, `_5__c`, `_6__c`, `_7__c`, `_8__c`; only school, citizenship and `Generic_Filter_3__c` exist), in both scratch and eda-staging. Their answers only narrow the program list and are not saved, which is probably fine, but after the Phase 3 allowlist each submit on a form with such a filter would have written a "saved with gaps" Error record. | Interaction describe in both orgs; the manager's filter list and the Apex filter map. | Handled: the catalog marks each filter as storing its answer or not, a test keeps that statement true (it fails if someone creates one of those fields), and the guard drops filter-only answers without a report. Decision for the business, not for this work: should any of those answers be saved? If yes, the fields must be created. |
| F40 | **The newer form depended on the manager to include First Name and Last Name.** The older form adds them when missing; the newer one did not. A saved list without them (edited by hand, or saved before the manager protected them) would make every submission fail on the object's required fields. Found by the parity test. | `olderAndNewerForms_giveTheSameFieldsAndControlsForTheSameQuestions_TEST`. | Fixed: the newer form adds both at the front when missing. All 20 staging controllers that use the newer form already contain them (checked read-only). |
| F41 | **A field the running user cannot read behaves as if it does not exist.** For such a field, Apex describe leaves it out of the field map, `put` fails with "Invalid field", and `stripInaccessible` reports nothing. New fields deployed to a org are not readable by anyone until a permission set grants them (measured in scratch with a throwaway field). So if the person who validates the deployment in eda-staging cannot read `Timeline__c`, `rfiQuestionCatalog_TEST` fails with "Timeline__c is not a field on Interaction__c" even though the code is right. | Scratch probe (create a field, describe it as a user without access); staging field access for `School_Name_Text__c` comes only from permission sets. | Handled in the hand-off order: create `Timeline__c`, give the deploying user read access through a permission set, then validate. No code change. |
| F42 | **A custom picklist question kept a copy of the field's values, so it went stale.** The manager copied the values into the saved question; the form used the copy. A value added later never appeared, and a retired value was still offered, which the platform rejects on save (the RFI is lost, with an Error record and an error message for the visitor). | Manager and Apex code read; the 2026-11-02 end-to-end test below. | Fixed in scratch: a Picklist question on a picklist or multi-select field always shows the field's live active values, the manager saves no copy, and old copies are ignored and dropped when the question is next edited. A question on a text field still uses the list the admin typed. |
| F43 | **A saved question list of `[]` made the newer form crash.** The Phase 4 change that adds First and Last Name when missing used `add(0, ...)`, which Apex rejects on an empty list. Before that change an empty list loaded as an empty form. Found while testing how the form reacts to unexpected shapes of the saved JSON. | Probe of 13 crafted shapes in scratch (see the answer on schema changes in the 2026-11-02 conversation notes); `ListException: List index out of bounds: 0`. | Fixed in scratch with a test (`newerForm_withAnEmptySavedList_stillLoadsWithFirstAndLastName_TEST`); the test fails without the fix. |
| F44 | **The saved question list had no protection against change.** There was no format version, and questions had no stable identity (`id` is the list position and changes on every move or delete). Reading was scattered casts, so a value of the wrong type stopped the whole form (13 shapes tested in scratch: a label saved as a number, picklist choices saved as text, an entry that is not an object, a list wrapped in an object). Others failed silently: `"isRequired":"true"` as text made a question stop being required; an unknown question type produced a question that saves nowhere. Every one of the 179 questions in eda-staging also carried 10 display flags the manager works out for itself. | Probe of 13 shapes against `getRFIForm`; inventory of the saved JSON in eda-staging (20 controllers, 179 questions). | Fixed in scratch: one tolerant reader (`rfiQuestionReader`), a stable `key` and a `schemaVersion` on every question, display flags no longer saved, a broken question skipped and reported instead of stopping the form. Rules for future changes are in `docs/AI-TOOLS-CONFIG.md`, "Changing the question format". |
| F45 | **A question that appeared or disappeared redrew every question below it.** Found while testing dependent questions as a visitor on the public scratch site, not by the Jest tests. The form hid a question with `lwc:if` inside the loop, which leaves an empty slot, and LWC then matches questions by position. So when "Visa status" appeared, the "Send me mail" tick box below it was replaced by a new, unticked one. The saved record had `Mailed_Program_Information_Requested__c` = false although the visitor had ticked it, and text typed in later questions would have been emptied the same way. | Browser probe that tags the checkbox element: after the dependent question appeared the element was new and unticked (`NEW ELEMENT`, `checked:false`). Three Jest tests that compare element identity failed before the fix and pass after it. | Fixed in scratch: the loop draws only the shown questions (`shownFields`), so LWC matches by key and keeps the elements. The same probe now reports the original element, still ticked, with the typed text intact. Rule recorded in `docs/AI-TOOLS-CONFIG.md`. |

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
| I will apply to St Thomas as a / St Thomas Law as a | `Admit_Type__c` | OK, two questions share one field | Confirmed (D9): "St Thomas" wins when both are filled. Document and test. |
| Expected Start Term | `Intended_Start_Term__c` (Lookup) | Renders as text in unified path (F2) | Use `getTerms()`; also set `Term__c` |
| St Thomas Colleges | `St_Thomas_College_School__c` (Lookup) | Renders as text in unified path (F2) | Use `getUSTSchoolList()` |
| Address | `Mailing_Street__c`, `Mailing_City__c`, `Mailing_State__c`, `Mailing_Country__c`, `Mailing_Postal_Code__c` | OK, parity with flow | Also write `State__c`, `Country__c` (F9). Source all values from the org's own country/state lists, never a hard-coded label (D8, see below). |
| Address 1/2/3, City, State, Zipcode, Country | none | Dropped (F3) | Migrate saved configs to the combined Address question |
| I have a question | `Has_Question__c` (Checkbox) plus text | Collides (F10) | Compose into `Description__c` with headers |
| Tell us about yourself | `Description__c` | Collides (F10) | Same |
| Employer / Company | `Employer__c` | OK | None |
| Birthdate | `Birthdate__c` (Date) | Works per Cheng | Parity check only |
| How did you hear about us | `Heard_About_Us__c` (Multi-select) | Hypothesis F7 | Serialize as semicolon string |
| Scholarship of Interest | `Scholarship_of_Interest__c` (Multi-select) | F4, F7 | Presets plus serialization |
| Title | `Contact_Title__c` (Text) | Manager still emits `Salutation__c` (F1) | Fix manager and remap |
| I would like program information to be mailed | `Mailed_Program_Information_Requested__c` (Checkbox, exists) | `Mail_Information__c` does not exist (F1) | Fix manager and remap |
| Timeline to Enrollment | `Timeline__c` (restricted picklist) | Field created in the repo 2026-10-28 (D1): 0-6 Months, 6-12 Months, More than 1 Year, Undecided. It does not exist on Interaction in eda-staging, so it was copied from `Lead.Timeline__c`. | Deploy to eda-staging; nothing maps it onward |
| When do you plan to start school | none | **Remove** (D2). No old-form counterpart. | Delete from the Question Manager choices and from controller 0357's saved JSON in the migration script |
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

**Phase 0 progress (2026-10-28)**

Done, read-only:
- Deployed code retrieved from eda-staging and diffed against the branch: F16, F18, F19.
- Org-only Interaction fields retrieved into the repo; `Timeline__c` created; dry-run
  deploy to the scratch org run (F15).
- Undergraduate rule data confirmed in eda-staging: Academic Programs "Undergraduate
  First-Year", "Undergraduate Transfer", "Undergraduate Transfer (INTL)" (all code
  `AS_UN_BA`) and "Dougherty Family College" (code `DC_UG_AA|LIBA`) exist and are active.
  Opportunity record types `Inquiry_Opportunity` and `Applicant_Opportunity` exist.
- D8 verified: `Contact.MailingCountryCode` and `Lead.CountryCode` are identical in
  eda-staging (249 values, United States = "United States of America"), as are the 76
  state codes. `Interaction.Country__c` and `State__c` use the standard `Country` and
  `State` value sets and accept every one of them.
- `Intended_Start_Term__c` is a lookup to `Academic_Term__c`; `Term__c` is a lookup to
  `hed__Term__c`. These are different objects, which is why the flow had a name-matching
  lookup to fill `Term__c`.

**Submission matrix (run 2026-10-28 in eda-staging, a sandbox).** Five cases, each as an OLD
submission (the old form's logic, then `createLead`, then the flow) and a NEW submission
(`getRFIForm` defaults, then `submitRfiInteraction`), both through the real deployed Apex.
The NEW side is the build currently deployed in staging, not the branch. Test records use
last names starting `ZZPhase0` and `@example.invalid` emails.

| Case | Controller | Scenario |
|---|---|---|
| A | 0299 | Undergraduate First-Year, major, start term |
| B | 0299 | Undergraduate Transfer |
| C | 0299 | Undergraduate Transfer, International |
| D | 0223 | Graduate, address, program |
| E | 0229 | Schulze preset and a question |

All ten submissions succeeded and no `hed__Error__c` rows were written. Results:

- **Downstream is wrong, not just incomplete (F20).** Every OLD submission produced an
  Opportunity with record type `Inquiry_Opportunity`, stage `Inquiry`, an inquiry date, the
  term and programs, and a name like `Name|Fall 2027|Program`. Every NEW submission produced
  an Opportunity with record type **`Donor`**, stage `Enrollment Prospect`, no inquiry date,
  no term, and a name like `Name||`. For undergraduates the Opportunity also had no
  Academic or Recruitment Program.
- **Graduate programs are fine.** In case D the Academic Program, Recruitment Program,
  Academic Level and Program Code are identical in OLD and NEW. The graduate gap is only
  the defaults, `Term__c`, the associated schools and `State__c`.
- **Undergraduate rules confirmed.** The old logic chose "Undergraduate First-Year" (A, E),
  "Undergraduate Transfer" (B) and "Undergraduate Transfer (INTL)" (C). NEW chose nothing.
- **Presets and Description confirmed.** E: OLD stored `Scholarship_of_Interest__c` =
  Schulze Innovation; NEW stored nothing. OLD Description carried the header
  "Questions/Comments from RFI:"; NEW stored the bare text.
- **Address.** Contact mailing fields came out identical in OLD and NEW (case D). Opportunity
  `State__c` was MN for OLD and blank for NEW.
- **Two Term records per term (F23).** eda-staging has two `hed__Term__c` records per term
  (for example `202740` and `202740a`). The flow picks the one whose key contains `a`.

Server-side probes of how an `Interaction__c` deserializes input:

- A JSON array for a multi-select field (`Scholarship_of_Interest__c`, `Heard_About_Us__c`)
  throws `JSONException`; a semicolon-separated string works.
- Typed text for the lookup `High_School_or_College__c` is accepted and silently becomes
  null (F8).

**Test records removed (2026-10-28).** The five cases' records in eda-staging were deleted with
`ai-logs/phase0/cleanup.apex` (5 Leads, 10 Interactions, 10 Contacts, 10 Opportunities, 10
Accounts; the script refuses to run if more than that match). A follow-up query found zero
records named `ZZPhase0*` of any of those types. They are in the recycle bin for 15 days. The
scratch org still holds two browser-submitted test Interactions (`ZZPhase0Scratch`,
`ZZPhase0Two`) and their Contacts and Opportunities.

Not measured:
- The browser side: what the LWC actually sends (F7), the High School question on 0229
  (F17), and the guest user's field access. No query found a guest-license profile with
  explicit `Interaction__c` permissions, so how anonymous visitors are granted access is
  unresolved. These need a browser session.
- Alumni referral (sends email), Dougherty Family College, and a legacy-path controller (0230).
- Whether Marketing Cloud, Act-On or Journey Builder reacted to the test records.

### Phase 1: Mapping hotfix (ECRMSF-5764)

- Fix the Question Manager map: Title, mail, Timeline, and add Home and Mobile Phone.
- Make the Apex remap key on the saved `fieldName` as well as the API name, so already-saved
  configs are corrected without admin action.
- Add unified-path handling for Expected Start Term and St Thomas Colleges (F2).
- Add the missing Interaction fields (D1). Permission sets that grant them are kept in the repo for scratch orgs only; staging changes go to admins as notes (section 9).
- Script a one-time, idempotent update of `Unified_Questions__c` in eda-staging (anonymous
  Apex run from `ai-logs/`) that rewrites bad targets and replaces the split Address
  questions. The same script runs in production at release.

**Done when:** a controller with every preconfigured question submits and every answer
lands on the Interaction (the 0357 case in Phase 0 is clean).

**Phase 1 progress (2026-10-29).** Done in code, tested and deployed to the scratch org only:
- Question Manager mapping table fixed (Title, mail question, Home and Mobile Phone).
- Corrected-target table in `rfiFormController` keyed by question name, so forms saved with the old names are fixed at run time.
- Both code paths now understand Home and Mobile Phone (two phone inputs), the split address questions (collapse to one Address) and the St Thomas Law applicant question. Live result on controller 0001: "Field Label Not Found" boxes went from 9 to 0.
- Expected Start Term and St Thomas Colleges render as drop-downs in the unified path (unit-tested; the live lists are empty until the guest sharing rules in ECRMSF-6053 exist).
- "When do you plan to start school" deactivated in `Fields_to_Display__c` and `Required_Fields__c` (deactivated, not deleted, so existing records stay valid).
- Repair script `scripts/apex/migrate_rfi_questions.apex` (dry run by default, safe to repeat). A dry run in eda-staging (read-only) reports that it would change 3 controllers: 0223 (Title), 0234 (mail question) and 0357 (split address, mail question, start-school question), plus one older field list. Applied in the scratch org (2 controllers); a second run changed nothing. It is not applied in eda-staging: the owner runs it at deployment (see the hand-off checklist in Phase 5).
- 9 new Apex tests. With the fixes switched off, 7 of the original 8 fail (the 8th tests a helper in isolation). One of the 9 guards that every corrected target exists on Interaction; it caught the old bad field name when I put it back.
- Not changed: the single "Phone" question (F30), pending your decision.

### Phase 2: Server-side parity (ECRMSF-5588)

Move submit-time logic into one testable Apex class (suggested name
`rfiSubmissionProcessor`, called from `submitRfiInteraction`). The browser sends the
controller name; Apex reads the controller and decides what is allowed.

- Defaults: `Interaction_Source__c = Webform`, `Date_Inquiry__c`, `Opportunity_Stage__c =
  Inquiry`, `Opportunity_Record_Type__c` (look up the Inquiry_Opportunity record type Id
  by developer name, never hard-code an Id), `Term__c`, `Recruitment_Program_Associated_Schools__c`,
  `State__c`, `Country__c`, and School/College from the major when the controller has none.
- Presets: apply per-controller preset values from `Lead_Preset_Value__mdt`, translating
  Lead field names to Interaction names (`LeadSource` to `Lead_Source__c`; names that match
  on both objects, such as `Scholarship_of_Interest__c`, pass through) (D5).
- Programs: port the flow and old-form rules (D4): Undergraduate Transfer, Transfer (INTL)
  when citizenship is International, Dougherty Family College, otherwise First-Year;
  graduate keeps the major-based program. Look the programs up by name and code, not by Id.
- Description: compose with the old headers (D3).
- Values: multi-select to semicolon string (F7), typed school to `School_Name_Text__c`
  (F8), truncate to field length, escape `utm_*` / `gclid`.

Defaults live in Apex rather than a flow because they are then covered by tests and
versioned in the repo (D7).

**Done when:** every row in section 2.2 matches the old flow for the Phase 0 cases.

**Status (2026-11-02, scratch org only; nothing deployed to staging).**

Built:
- `rfiSubmissionProcessor` (with sharing; a private `without sharing` reader for the few lookups) and
  `rfiFormController.submitRfiForm(interaction, controllerName)`. The old `submitRfiInteraction` calls it
  with no controller name, so existing callers keep working. Completion runs in a try/catch and never blocks the save.
- Defaults, State/Country from the org's own picklists (D8), undergraduate program rules (D4), school from the
  major, Term, per-controller presets with `LeadSource` translated (D5), lookups the user cannot see cleared.
- LWC: new `rfiFormUtils` helper bundle; `rfiForm` sends the controller name, saves multi-selects as
  semicolon lists, saves a typed school to `School_Name_Text__c`, never lets a blank box overwrite an answer,
  composes Description with the old headings, and sends the state code.

Tests:
- Apex: `rfiSubmissionProcessor_TEST` and `rfiFormController_TEST` run together: 117 tests, 115 pass. The
  2 failures were failing before Phase 2 (`getRFIForm_legacyPath_customLabels_TEST`,
  `getRFIForm_unifiedPath_preconfiguredTextarea_TEST`). Both were fixed on 2026-11-02 (see the Phase 3 status).
- Jest: `rfiFormUtils.test.js` (16) and `rfiForm.submit.test.js` (9) pass. The older `rfiForm.test.js`
  mocks Apex modules that do not exist and is left alone.
- Mutation checks (break the code on purpose, confirm a test fails): 19 Apex mutations on the processor and
  controller, 7 Jest mutations that reintroduce the original bugs, and 6 later ones (strip, lookup clearing,
  `Name` in the reader, state code kept, unknown code dropped, blank guard). All caught. One Apex mutation
  first survived (the school overwrite guard); that test was strengthened.
- Browser, as the anonymous guest on the public scratch site, with every question answered (international
  transfer applicant): the RFI saves with no warnings, and the Interaction and its Opportunity hold
  `Webform`, today's inquiry date, stage Inquiry, record type `Inquiry_Opportunity`, program
  "Undergraduate Transfer (INTL)", `State__c` = MN, Term = Fall 2026, both multi-selects, the typed
  school, Description with both headings, Timeline, and both phone numbers.

Found only by the guest run (not by unit tests): F32, F33, F34, F35, and a guest sharing gap for Terms.
Lesson: run as the real guest before calling a change done.

Not done in this phase: the College/School drop-down is populated in scratch by a new guest rule for
University Department accounts (F26); staging needs the same decision from admins (section 9 C).

### Phase 3: Hardening

- Allow only the fields the controller's questions, UTM parameters and tracking fields
  can legitimately set (F11). Reject or ignore everything else; log what was ignored.
- Write failures to `hed__Error__c` with the controller name and payload, as the old form
  did (F12). Make `processUnifiedQuestions` report failure instead of returning a partial
  form.
- Fix F24 in code, not per environment: read configuration (controller, programs, terms,
  school accounts) through a small `without sharing` inner class that returns only the fields
  the form needs, as the old controller effectively did. The alternative, guest sharing rules
  per site and per environment, exposes those records to the guest user everywhere and has
  to be redone for each site guest user. Replace the `isCreateable()` field skipping in
  `submitRfiInteraction` with the controller-based allowlist (F11, F12) so the guest profile
  does not need field-level create on every Interaction field.
- **F24 progress (2026-10-28):** step 1 done and deployed to the scratch org. `getRFIForm` now
  reads `RFI_Controller__c` through `rfiControllerReader` (private, `without sharing`, system
  mode, exact Name match), so no guest sharing rule is needed for controllers. A missing or
  blank name now raises a readable `AuraHandledException` (two new tests). Live result: the
  public site's `getRFIForm` moved past the controller query and now stops at the school
  Account query. Still to move behind the same pattern: school Accounts, Programs, Academic
  Terms, and the reads inside `submitRfiInteraction`. Two tests in `rfiFormController_TEST`
  (`legacyPath_customLabels`, `unifiedPath_preconfiguredTextarea`) were already failing before
  this change (verified against the pre-edit class); they expected behaviour removed in commits 51fd7cd
  and ba5ff56. Fixed 2026-11-02.
- Keep `allowSave = true` so an RFI is never blocked by a duplicate rule (D6). Any failure
  is logged and the visitor still gets a success path where the data was saved.
- Clear `Major_Program_*` when Academic Interest is emptied (F14).
- Because the form is served through Lightning Out, change the Aura dependency app with a
  real content change after deploying the Apex and LWC, then verify a fresh `auraCmpDef`
  request (see the agent-onboarding caching note).

**Status (2026-11-02, scratch org only; nothing deployed to staging).**

Built:
- `rfiSubmissionGuard` (allowlist, F11), `rfiErrorLogger` (F12), and `rfiFormController.buildForm`, the form-building
  code that `getRFIForm` and `submitRfiForm` now share, so the fields a submission may set are exactly the fields
  the visitor was shown. Reading the form on submit costs 18 SOQL queries and about 0.5 s CPU in total for a
  guest submission (limits: 100 and 10 s).
- `submitRfiForm` returns null when the RFI cannot be saved (after writing the Error record); the older
  `submitRfiInteraction` throws in that case so an older page does not show success. An exception would
  roll the Error record back, which is why the new method returns instead.
- `rfiForm`: a null result shows the error toast and keeps the answers; a form that cannot load shows a
  message instead of a spinner; the academic interest handler is back and clears on deselect (F14, F36).
- Unchanged by design: `allowSave = true` (D6); the RFI is saved without any field the user cannot create.

Tests: Apex 140 run, 140 pass; Jest 33 pass. The 2 older failures were stale tests, not code bugs, and were
rewritten the same day: `getRFIForm_legacyPath_customLabels_TEST` asserted custom labels ("Given Name",
"Email Address") that commit 51fd7cd removed with the label fields, and is now
`getRFIForm_legacyPath_usesTheStandardLabels_andFirstAndLastNameAreAlwaysRequired_TEST`;
`getRFIForm_unifiedPath_preconfiguredTextarea_TEST` expected "I have a question" to be a textarea, which
commit ba5ff56 changed to a checkbox that reveals the question box, and is now
`getRFIForm_unifiedPath_iHaveAQuestion_isACheckboxThatRevealsTheQuestionBox_TEST`. Both were mutation-checked. Sixteen Apex mutations and four
Jest mutations were each caught by a test. Two survived at first and led to new tests: the
unexpected-exception path, and the older method throwing on a failed save.

Guest checks on the public scratch site: a normal full submission writes no Error record; a request with
six extra fields injected in flight (owner set to another user, `Pardot_Sync_OCB__c`, `Banner_ID__c`,
`Opportunity_Stage__c`, `Lead_Only__c`, and a field the form does not ask for) is saved with the controller's
owner and none of the injected values, and one Error record lists the ignored fields; a forced failure (invalid
Citizenship) saves nothing, shows the error toast, and writes one Error record with the controller name and
what was entered.

Not done, needs an admin decision (also in the 6051 subtask): how the guest reaches Programs, Academic Terms and
school Accounts. Scratch uses guest sharing rules; the plan's other option is more `without sharing` reader
code. Read-only check in eda-staging: all 20 controllers with unified questions parse, so none would newly
fail to load for malformed JSON.

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

**Status (2026-11-02, scratch org only; nothing deployed to staging).**

Built:
- **One catalog, `rfiQuestionCatalog`.** It holds, for each pre-configured question, the Interaction field it saves to
  and its default label; for each program filter, its field and whether the answer is saved; the table that corrects
  field names older saved forms hold; the split-address and retired question names. The older form definition (25
  switch branches), the newer one, the filter map and the Question Manager all read it. The three duplicate mappings
  and the correction table are gone from `rfiFormController` and the manager. The manager gets the catalog through
  `rfiFormController.getQuestionCatalog` (cacheable), which the admin permission set already allows, and builds no
  questions until it arrives so it cannot save blank field names.
- **One behaviour change by design:** the older form now saves Address to `Mailing_Street__c` like the newer one (it
  used a placeholder name that the page never read).
- **Read-only migration check in eda-staging before changing anything:** all 153 saved pre-configured questions in 20
  controllers resolve to the same field under the catalog as before (the 4 Home and Mobile Phone questions are the
  two-input composite, and 1 is the retired start-school question).
- **`rfiQuestionCatalog_TEST` (14 tests):** every question the manager offers has a catalog entry; no duplicates or
  blank targets; aliases save where their full names do; every target exists on Interaction, is not a formula or
  auto number, and is a writable type; every filter names a real controller field and states truthfully whether it is
  saved; every form (older and newer) saves each question to its catalog field with a field type that fits how the
  question is drawn; older and newer forms give the same fields and controls for the same questions; every date
  question is a date picker; the newer form always has first and last name; and a test fills in every question,
  submits through `submitRfiForm`, and compares each saved field with what was sent (and expects no Error record).
- **Jest:** `rfiUnifiedQuestionManager.catalog.test.js` (4) uses a deliberately fake catalog, so any built-in copy of
  the mapping fails it; plus the date picker test in `rfiForm.submit.test.js`.

Found by the new audits, not by hand: F38 (typed birthdates), F39 (filters with no field), F40 (names). Three Phase 1
tests were updated because they counted every field on a form and the form now always has the two name questions.

Tests: Apex 156 run, 156 pass (five classes); Jest 38 pass (rfiFormUtils 20, rfiForm.submit 14, manager catalog 4).
Mutation checks, each a deliberate reintroduction of a known mistake, all caught with a message that names it:
Title back to `Salutation__c`; the mail question pointed at the missing `Mail_Information__c`; a question dropped from
the catalog; a checkbox question pointed at a text field; a filter that wrongly claims to store, and one that wrongly
claims not to; no date picker; names not guaranteed; the older form's Address and Phone reverted; the newer form
ignoring the catalog; the guard reporting filter answers; the guard dropping an allowed field (the round trip names
`Timeline__c`). Manager: a built-in copy of one mapping, no wait for the catalog, labels ignored, the filter target
ignored. Date picker removed from the template.

Guest check on the public scratch site (controller 0001, older path, with a Birthday): the question is a date input,
`1999-12-31` is sent and saved, `State__c` is `MN`, and no Error record is written.

Not applicable: the "repeat `load` event" test. None of the RFI components use a record edit form.

### Phase 5: Rollout

1. Scratch org: seed `Program__c`, `Academic_Term__c` and record types needed so the form
   can be exercised end to end. Apex tests create their own data.
2. eda-staging: the owner deploys, once the scratch work is tightened up (see the hand-off
   checklist below). Permission sets, profiles and sharing rules are not deployed by anyone from
   the repo; admins apply the notes in section 9. After the owner deploys, the assistant observes
   differences with read-only checks and records them here.
3. Production is a separate story. Deployment order, the JSON repair and the new fields go in its
   checklist, plus a copy of the section 9 notes for admins. Anything in the org but not in the
   repo (F15) gets retrieved first so production is not surprised.
4. Related tracks: 5800 (test dynamic program-filter questions) runs against the Phase 2
   build. 5856 includes the Question Manager bug where the Question Label does not update
   after the Filter Field is changed.

**Status (2026-11-02, scratch org only; eda-staging was read from, never written to).**

Done:
- **Scratch seed data:** nothing to build. The scratch org is created from the `EASY` snapshot (`orgs/dev.json`), which
  carries the programs, terms and controllers. Apex tests create their own data.
- **Drift check (read-only retrieve of every Apex class, LWC and Aura bundle in the repo from eda-staging):** 25 components
  are identical to the repo, 6 differ, 12 are not in staging. Staging's `rfiFormController` and all the LWC files are
  identical to the staging snapshot taken on 2026-10-28, so nobody has edited them there since, and the deploy overwrites
  only known differences (F16: the old Title mapping and the text-message checkbox). Left out of the deploy on purpose:
  `ReusableLookupController` (staging differs by blank lines and brace placement only) and
  `AcademicInterestSelectorController_TEST` (an older repo test that staging never got; unrelated to this work).
- **Readiness for the code and the tests in eda-staging:** the only field the new code needs that staging lacks is
  `Timeline__c`. `hed__Error__c` has no required fields, validation rules or triggers (it has an extra optional restricted
  picklist, `Error_Status__c`, which the logger does not set). Required fields match scratch for all ten objects the
  tests write. The record types, the `Minimum Access - Salesforce` profile and `Lead_Preset_Value__mdt` exist.
  Staging has four active validation rules that scratch lacks (Account, Contact x2, Opportunity); read in full, none can fire
  for the tests (profile-specific and on edits only, or they need values the tests never set).
- **Not verifiable without running the tests there:** staging has many more triggers on Contact, Opportunity and Account
  than scratch (Act-On, DLRS, PS_* and others), and those fire when a test submission creates a Contact and Opportunity.
  Nothing in the metadata says they will interfere, but only the validation run can show it. That is the main thing to
  watch in the validation step below.
- **Repair script:** `scripts/apex/migrate_rfi_questions.apex` held a fourth copy of the mapping. It now reads
  `rfiQuestionCatalog`, so it must run after the Apex is deployed. Predicted on the real staging data: the same 16 fixes in
  the same 14 controllers as before. In scratch, seeded with five real staging question lists: the dry run printed the same
  lines as the old script, a real save followed by a second run changed nothing, and every repaired form built correctly.
- **Read-only check you can run any time:** `scripts/apex/verify_rfi_rollout.apex` (no writes). Scratch: 13 pass, 0 fail.
  Baseline in eda-staging before the deploy: 5 pass, 4 fail (all four are things this deploy adds: nine classes, `Timeline__c`,
  and the two picklist values still active). It also reports the repair counts: 12 Phone, 2 Title and 2 mail questions,
  1 controller with the start-school question, 1 form with the older split address, and 0 forms without name questions.
- **Deployment manifest:** `manifest/rfi-staging-deploy.xml`, 19 named components, no permissions and no sharing. A check-only
  deploy of it to scratch with the six test classes: 19 of 19 components, 222 tests, 0 failures (re-run after the dependent questions work; it was 191, 163 and 155 before).

Not done, and why: the deploy itself (yours); the repair script's dry run against staging (it needs the catalog class, which staging
does not have yet; run it right after the Apex deploy); production (separate story, see below).

**Schema hardening (2026-11-02, ahead of the dependent questions work in ECRMSF-6061; scratch only).**
- **`rfiQuestionReader`** reads the saved list for the form: keeps unknown keys, accepts the list or an object holding it under
  `questions`, converts safe wrong types (the text "true", a number used as a label), skips a question it cannot understand
  (unknown type, no name, no field to save to) and describes each problem by position and label. Only text that is not a list of
  questions at all still stops the form.
- **Each question is built on its own.** If one fails while being built, whatever it half-added (the field, a filter
  registration) is removed, the problem is reported, and the rest load.
- **Where admins see problems:** a warning banner on the form when it sits on the controller record page (the component has a
  record id only there, so visitors never see it), and one "saved with gaps" row in the Error object for each submission while the
  problem persists, naming the question.
- **The Question Manager writes the new format:** every question gets a stable `key` (a repeated key on a copy is replaced), a
  `schemaVersion` (never lowered if a newer version wrote it), and the display flags are no longer saved. It keeps keys it does
  not know, and an unreadable saved list no longer breaks the screen. Existing lists are upgraded the next time an admin saves.
- **Tests:** `rfiQuestionReader_TEST` (27) with three real lists copied from eda-staging as fixtures, and
  `rfiUnifiedQuestionManager.schema.test.js` (8) with another. Apex 192 and Jest 56 pass across all suites. Ten reader and
  isolation mutations and eight manager mutations were each caught. One was missed at first (undoing a half-built question), which
  led to a second failure hook and test. The three banner mutations were also caught.
- **Guest check on the public scratch site:** a saved list with a "matrix" question, a custom question with no field, an email
  question with `"isRequired":"true"` text, and an unknown `visibleWhen` key (at that time not yet a feature) loaded the three good questions, honoured the text
  "true" (Email shows as required), showed no banner or internal text to the visitor, saved the submit, and wrote one Error row
  naming both skipped questions.
- **Not verified live:** the banner as an admin on the record page (it needs a logged-in session; the Jest tests cover shown with a
  record id and hidden without). Please look at it once in eda-staging.
- **Jira:** the dependent-questions work is ECRMSF-6061, a subtask of ECRMSF-5545. Rules in a later change must refer to a
  question by `key`, never `id`.

**Dependent questions (2026-11-04, ECRMSF-6061; scratch only; nothing was written to eda-staging).** A question can now be shown only
when an earlier answer calls for it. Rules and limits are in `docs/AI-TOOLS-CONFIG.md`; in short: one condition, one level, the earlier
question is a choice from a list or a tick box, a hidden question is never required and its answer is thrown away.
- **Format:** an optional `visibleWhen` on a question, `{ "key": <key of the earlier question>, "equals": [answers] }`. Additive, so
  `schemaVersion` stays 1, and code that does not know it shows the question as before (fails open).
- **Server:** `rfiQuestionReader` checks the rule (complete, earlier question exists and comes first, no chain, not a program filter).
  `rfiFormController.applyVisibilityRules` checks it against the fields that were built (the earlier question saves a picklist or a
  tick box value, the dependent one is not a name question). A rule that cannot work is ignored, the question shows, and the problem goes
  to the admin banner and the Error row. `rfiSubmissionGuard.dropAnswersToHiddenQuestions` throws away answers to hidden questions on
  submit and names them in the "saved with gaps" row.
- **Form:** `rfiFormUtils` decides what is shown; `rfiForm` draws only the shown questions, forgets a hidden question's answer (and its
  school and question-box switches) the moment it hides, on load and on reset, and a hidden required question never blocks a submit.
- **Question Manager:** a "Show only when" section in the question dialog (earlier question, then answers from the live picklist), the
  rule in words in the list, a warning above the table and a refused save while a rule cannot work (a deleted or moved question can
  break one). The decision logic is in `visibilityRules.js` inside the manager bundle, so the manifest still has 19 components.
- **Tests:** Apex 223 and Jest 162 pass. Each behaviour was broken on purpose and a test had to fail: 27 on the server, 22 on the form and
  its helpers, 27 in the manager. Several first survived and led to new tests (an answer with stray spaces, a tick box that stores a
  picklist answer, unknown parts of a rule surviving an edit, a broken rule when nothing else qualifies, and the data type of every field a
  built-in question can save to). Four more survived because the code they changed was unreachable or unused (a second clearing step at
  submit, two bits of lookup bookkeeping that nothing reads, an early return); that code was removed. One (the position of a new
  question) changes nothing, because a new question has no id yet, and was left. An Apex parity test builds one form with every built-in
  question and checks that the manager offers a question as an "earlier question" exactly when the form accepts it (picklist or tick
  box); breaking either side was caught.
- **Guest check on the public scratch site** (a picklist parent, a tick box parent and a rule that points at a deleted question): the
  hidden questions were not drawn; choosing "International" drew the required "Visa status" and an empty submit was blocked with the
  standard message; changing the answer back removed it and a submit went through with the text never saved; the tick box revealed
  "Mailing note"; the orphaned rule's question showed as normal and one "saved with gaps" row named it. This run found F45.
- **Not verified live:** the manager dialog and the warning above the table as an admin (they need a logged-in session; the Jest tests
  drive both). Please try it once in eda-staging after the deploy: add a Picklist or Checkbox question, then a second question with
  "Show only when" set to it.
- **Left as is:** `rfiForm/__tests__/rfiForm.test.js` (from the Lead to Interaction switch, commit 0434009) cannot load because it
  imports an Apex module that does not exist in the mock setup. It failed before this work and is not part of the six suites above.

**Hand-off checklist for the person deploying to eda-staging.** Order matters; fields come before the code that uses them,
and the Apex before the LWC that imports it.
1. **Fields** (in the manifest): `Interaction__c.Timeline__c` (new) and the deactivated value in
   `RFI_Controller__c.Fields_to_Display__c` and `Required_Fields__c`. Deploy only these three first:
   `sf project deploy start --target-org eda-staging --metadata CustomField:Interaction__c.Timeline__c CustomField:RFI_Controller__c.Fields_to_Display__c CustomField:RFI_Controller__c.Required_Fields__c`
2. **Make `Timeline__c` readable by whoever validates** (F41). A new field is invisible to everyone until a permission set
   grants it, and an invisible field makes `rfiQuestionCatalog_TEST` fail with "not a field on Interaction__c". Use a permission
   set you already hold (or ask admins, section 9 B). Do not use the repo's `RFI_User` or `RFI_Controller_User`: they are not
   deployed to staging.
3. **Validate without saving** (this runs the six test classes in the org; it writes nothing):
   `sf project deploy start --dry-run --manifest manifest/rfi-staging-deploy.xml --target-org eda-staging --test-level RunSpecifiedTests --tests rfiFormController_TEST --tests rfiSubmissionProcessor_TEST --tests rfiSubmissionGuard_TEST --tests rfiErrorLogger_TEST --tests rfiQuestionCatalog_TEST --tests rfiQuestionReader_TEST`
   About 222 tests run and all should pass (the same selection did in scratch; the count can differ by a few in another org). A failure that mentions Act-On, DLRS or another Contact,
   Opportunity or Account trigger is the unknown described in the status above: send it to me. Do not skip it.
4. **Deploy** (same command without `--dry-run`). One deploy handles the Apex and the LWC that imports it together; do not
   deploy the LWC alone before the Apex. Then make a real content change to `requestForInformationApp.app` if a browser keeps an old bundle (the manifest
   already carries the one-line change that adds `c:rfiForm`).
5. **Admins** apply the section 9 notes (class access for `rfiFormController` first, and `Timeline__c` for the guest and
   admin users).
6. **Check:** `sf apex run --target-org eda-staging --file scripts/apex/verify_rfi_rollout.apex` and read the `VERIFY` lines.
   All `FAIL` lines should now be `PASS`. Run
   `sf data query --use-tooling-api --target-org eda-staging --query "SELECT DeveloperName FROM LightningComponentBundle WHERE DeveloperName IN ('rfiForm','rfiFormUtils','rfiUnifiedQuestionManager')"`
   for the three LWC (the script cannot list them).
7. **Repair the saved controllers:** `scripts/apex/migrate_rfi_questions.apex`. Run the dry run first and read the report
   (expect 14 controllers to change). Then set `DRY_RUN = false` and run it again. In a non-sandbox org it refuses to save until
   its safety check is edited on purpose. Run `verify_rfi_rollout.apex` again; the repair counts should be 0.
8. **Smoke test as an anonymous visitor:** the form loads, the school and start term lists have choices, a submit saves, and no
   new row appears in the Error object (`hed__Error__c`) for a normal submit. If a Term or school list is empty, see section 9 C.

**After you deploy, tell me and I will** run `verify_rfi_rollout.apex`, compare the saved test data with what the plan expects, and
record any differences here. I will not write to eda-staging.

**Production checklist (separate story; same order as above, plus these).**
- Retrieve first anything that is in production but not in the repo (F15), and compare each component with the repo as was done for
  eda-staging here (the drift check above is repeatable: retrieve, then diff). Production may not match eda-staging.
- Run `verify_rfi_rollout.apex` in production before deploying to get its baseline, as was done for eda-staging.
- The repair script's counts will differ; read its dry run and do not reuse the staging numbers.
- Give admins the whole of section 9 (A to I) for production; none of it has been applied there.
- Decide who watches the Error object (section 9 H) before turning the form on in production, since a misconfiguration writes
  one row per submission.

---

## 6. Decisions

Resolved 2026-10-28.

| # | Decision | Outcome | Effect on the plan |
|---|---|---|---|
| D1 | `Timeline__c` on Interaction | Create it with the Lead picklist. Retrieve any other missing fields from eda-staging. | Done: `Timeline__c` created; 7 org-only fields retrieved; the formula field is kept under `unpackaged/staging-only/` (F15). |
| D2 | "When do you plan to start school" | Remove the question. | Remove from the Question Manager and from saved JSON (section 4). |
| D3 | Description | Same field as before: `Description__c`. | Compose both answers with the old headers (Phase 2). |
| D4 | Undergraduate program rules | Port the flow's rules where possible. | Port in Phase 2. Open detail: precedence when an undergraduate also picks an Academic Interest (see below). |
| D5 | Presets | Translate `LeadSource` to `Lead_Source__c`. | Reuse `Lead_Preset_Value__mdt` with a Lead-to-Interaction name map (Phase 2). |
| D6 | Duplicates | RFIs always come in and are never blocked. | Keep `allowSave = true`; no blocking logic (Phase 3). |
| D7 | Where defaults live | Apex. | Phase 2. |
| D8 | Country and state values | Follow the org's state/country picklist settings, which differ between the scratch org ("United States") and eda-staging / production ("United States of America", to match Banner). Use the values on Contact `MailingCountry`. | Verified: Contact and Lead lists are identical in eda-staging, so the form's current dropdowns already match. Rule for the code: read the lists from the org at run time and never hard-code a label. Tests must derive the expected label from the org, not assume one. |
| D9 | "St Thomas" vs "St Thomas Law" applicant type | Confirmed: "I will apply to St Thomas as a" wins when both are filled. | Document in code and cover with a test. |
| D10 | Jira subtasks | Wait until Phase 0 is done. | Nothing opened. List below is a draft. |

**Open detail on D4.** The old form set Recruitment Program from the undergraduate rule
whether or not a major was chosen, and kept the chosen major in `Major_Program__c`. The
new form sets Recruitment and Academic Program from the major's program. When both apply to
an undergraduate, keep the old behavior (rule-based program, major preserved in
`Major_Program_1__c`) unless Admissions says otherwise.

**Jira subtasks created under ECRMSF-5545 (2026-10-29).** Written for admins first, with a short
developer section at the end of each. None are assigned or scheduled.

| Key | Subject | Findings | Related to |
|---|---|---|---|
| ECRMSF-6044 | New inquiries create the wrong Opportunity (record type, stage, source, dates) | F5, F20, F23 | 5588 |
| ECRMSF-6045 | Undergraduate inquiries are not assigned a recruitment program | F6, F21 | 5588 |
| ECRMSF-6046 | Apply the preset answers set up on each RFI Controller | F4 | 5588 |
| ECRMSF-6047 | Fix questions that save to the wrong field, and repair saved RFI forms | F1, F3 | 5764 |
| ECRMSF-6048 | Expected Start Term and College/School turn into text boxes after Save Configuration | F2 | 5764 |
| ECRMSF-6049 | Answers typed on the form are lost before they are saved | F7, F8, F10, F27, F28, F29 | 5764 |
| ECRMSF-6050 | Save State and Country in the fields the Opportunity uses | F9 | 5764 |
| ECRMSF-6051 | Make the public form work for anonymous visitors safely (access, errors, logging) | F11, F12, F13, F24 | none |
| ECRMSF-6052 | Automated tests that catch field mapping mistakes | Phase 4 | none |
| ECRMSF-6053 | Guest access in scratch orgs, and a checklist for admins to align staging and production | F15, F25, F26 | none |

Not created because the work is done: the baseline parity matrix (Phase 0) and the shared
lookup and Aura sync (F18, F19).

---

## 7. Risks and what is not verified

- **Browser side not measured:** the Phase 0 matrix called the deployed Apex with payloads
  built to match each form. It did not exercise the LWCs, so F7 (array handling in the
  browser), F17 and guest field access still need a browser session.
- **Phase 0 test records** were removed from eda-staging; two browser test Interactions remain in the scratch org.
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

---

## 9. Notes for admins (eda-staging and production)

Information only. Nothing here has been deployed, and developers will not deploy it. Each item says
what the new form needs so admins can decide what to change in their own permission sets, profiles and
sharing rules. Findings come from comparing the form's code with the staging copies of `RFI User` and
`RFI Controller User` retrieved on 2026-10-29. Access can also come from a profile or another
permission set, which this comparison did not read, so each item says "check".

**A. What the public form needs for the guest user (check against the Admissions guest profile and `RFI User`).**

| Item | Staging `RFI User` today | Note |
|---|---|---|
| Apex class `rfiFormController` | **Not granted** (it grants `ReusableLookupController` and the old `requestForInformationFormController`) | The new form cannot run for the guest without it. This is the first thing to check. |
| Create on `Interaction__c` | Granted | |
| Edit on the 50 Interaction fields the form writes | Granted for all except `Timeline__c` | `Timeline__c` is a new field (see B) |
| Read on `Account.School_College_Name__c`, `Account.Type`, `Account.BillingAddress` | Not in `RFI User` | Needed to list schools and search high schools. Check the profile. |
| Read on `Academic_Term__c.Term_Start_Date__c` | Not in `RFI User`; `Academic_Term__c` object read not in the set | Needed for the Expected Start Term drop-down |
| Read on `Program__c` generic filters 6, 7, 8 | Not in `RFI User` | Only for controllers that use those filters |

**B. New field to be created by developers, then given field security by admins.** `Interaction__c.Timeline__c` (picklist: 0-6 Months, 6-12 Months, More than 1 Year, Undecided). Guest needs edit; admin users need read or edit. **Whoever validates the deployment also needs read access before the tests run** (finding F41): without it the catalog test cannot see the field.

**C. Sharing rules the Admissions guest user would need (check what exists).** Staging today has guest rules for Programs (all programs) and high school and college Accounts. It has none for:
- University Department Accounts (the school records the College/School drop-down needs; 32 in eda-staging and 28 in the scratch org)
- Academic Terms for the Admissions guest user (rules exist for the two University of St. Thomas guest users, not for Admissions)

The new form reads the controller record through code that does not need a sharing rule. Accounts stay controlled by sharing rules so admins decide what is visible.

**D. Administrator visibility (`RFI Controller User` in staging).** It does not grant `Timeline__c`, `School_Name_Text__c`, `Heard_About_Us__c` or `Email__c` on Interaction. It does grant the Question Manager fields. Decide whether staff should see the new and form-written fields.

**E. Worth a look while you are there.** Staging `RFI User` is held by 13 active Enrollment Staff and 3 active administrators as well as the Admissions guest user, and grants read on 315 Contact fields, some of which look sensitive (birthdate, donor status, ethnicity and religion codes). That is your call; it is noted because the guest user holds the same set.

**F. Scratch-only items in the repo (for reference).** `RFI User` and `RFI Controller User` permission sets, the guest sharing rules under `unpackaged/sharing`, and the `apply_admin_permissions_sets` task exist to make scratch orgs work. The task is meant to run once at build time, by design.

**G. What Phase 2 adds for admins to check (staging and production).**
- The guest needs **edit** on these Interaction fields, because the server now sets them: `Interaction_Source__c`, `Date_Inquiry__c`, `Opportunity_Stage__c`, `Opportunity_Record_Type__c`, `Term__c`, `Academic_Program__c`, `Recruitment_Program__c`, `Recruitment_Program_Associated_Schools__c`, `Country__c`, `State__c`. Staging `RFI User` already grants all ten. If one is missing, the RFI is still saved without that field and the debug log says which.
- The guest needs the Opportunity record type `Inquiry_Opportunity` to be visible. Staging `RFI User` grants it. Without it the Opportunity gets the wrong record type (F20).
- **Terms:** every Term the form uses belongs to the Administrative account "University of St Thomas" (100 in staging, plus 1 under an Educational Institution account). A Term is visible only if its Account is. Staging's Account external default is `Read`, so this is probably fine; check that the guest can open that Account. If it cannot, the RFI saves without `Term__c` and the debug log says so.
- No extra Apex class access is needed: `rfiSubmissionProcessor` is called from `rfiFormController`.
- The form now sends `State__c` (two-letter code) and expects the org's `State__c` list to contain it. The processor drops a code that is not in the list.

**H. What Phase 3 adds for admins to check (staging and production).**
- **Error object:** the form now writes `hed__Error__c` records. The guest needs create on `hed__Error__c`; staging `RFI User` already grants create and read. There are two kinds: `ERROR: RFI Form submission failed` (nothing was saved) and `WARNING: RFI Form saved with gaps` (saved, but something was dropped or could not be set, listed in the record). **Decide who watches this object and how often.** A submission that works writes no record; a misconfiguration (for example the guest cannot see Terms) writes one record per submission.
- **Personal data in Error records:** the message holds what the visitor entered (name, email, phone, address), as the old form's error records did. Limit who can read the Error object accordingly.
- **Programs, Academic Terms and school Accounts:** still open. The form reads them as the guest (sharing rules in scratch). Choose either guest sharing rules per site (you control what is visible) or more `without sharing` reader code in the controller (same everywhere, no admin work, but the code decides what is visible). Accounts stay under sharing rules unless you say otherwise.
- A form whose saved questions cannot be read now shows "We could not load this form" instead of a partial form. All 20 staging controllers with unified questions parsed in a read-only check.

**I. What Phase 4 adds for admins.**
- **Nothing to grant.** The Question Manager now reads its question list from `rfiFormController.getQuestionCatalog`; the staging `RFI Controller User` already allows `rfiFormController`.
- **If you add a question** to the `Fields_to_Display__c` picklist, a developer must add it to `rfiQuestionCatalog` in the same change. The tests fail until that is done, which is intended; it stops a question from silently saving nowhere.
- **Program filters that save nothing:** eight of the twelve filters (all except school, citizenship and Generic Filter 3) have no matching field on Interaction in eda-staging, so their answers only narrow the program list and are not stored. Decide whether the business wants any of them stored; if so, the fields must be created first (finding F39).
- **Birthdate** is now a date picker. Nothing changes for staff, but anyone who typed the date as text before had their whole submission rejected (finding F38).

**J. Custom questions on new Interaction fields (follow-up after Phase 5 preparation).** An admin can now build a question on a new Interaction field without a developer for these field types: text, text area, email, single picklist, checkbox and date. Steps: create the field, give the guest and the admins access through your permission sets, then add a custom question in the Question Manager and pick the field. If the guest has no access to the field, the RFI is still saved without that answer and an Error record names the field. Not available without a developer: lookup fields and multi-select picklists (the Question Manager does not offer them). In a test with temporary fields in scratch, a picklist value added and another retired on the field showed up on the public form with no edit to the question, and a submit with the new value saved.

**K. What the schema hardening adds for admins.**
- **A warning banner on the form.** When the form sits on the RFI Controller record page and a saved question cannot be shown, a yellow banner lists it by position and label with the reason. Visitors never see it. Fix the question in the Question Manager (or delete it) and save; the banner clears.
- **A row in the Error object for each submission** while a question is skipped (`WARNING: RFI Form saved with gaps`, "Saved question list: Question N ..."). This is the same row type as other gaps, so the decision in section H about who watches the Error object covers it.
- **Saving makes older lists current.** The next Save in the Question Manager adds a stable key and version to every question and drops the display flags. Nothing else about a form changes, and a list nobody saves keeps working as it is.
- **Nothing to grant.** No new permissions are needed.

**L. What dependent questions add for admins (ECRMSF-6061).**
- **A "Show only when" section in the question dialog.** Pick an earlier question that is a choice from a list or a tick box, then the
  answers that reveal this one. Nothing changes for any form until an admin sets a rule.
- **A hidden question is not asked.** Visitors who do not give a revealing answer never see it, it is never required of them, and what they
  typed before changing their answer is not saved. A rule with a wrong or missing earlier question is ignored and the question shows.
- **Check after changing a list.** Deleting or moving a question can break a rule that depends on it. The manager lists the broken rules above
  the table and will not save until each is fixed. On the form, the yellow banner (record page) and the "saved with gaps" row in the Error
  object describe a rule that could not be used.
- **Reports:** an answer to a hidden question is empty on the Interaction, the same as if the question had not been on the form. Where a
  report needs to tell "not asked" from "not answered", use the earlier answer.
- **Nothing to grant.** No new fields, classes or permissions are needed.
