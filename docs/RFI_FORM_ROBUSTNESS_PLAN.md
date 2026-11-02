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
  `getRFIForm_unifiedPath_preconfiguredTextarea_TEST`).
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
  this change (verified against the pre-edit class); they expect labels removed in commit 51fd7cd.
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

Tests: Apex 140 run, 138 pass (the same 2 older failures); Jest 33 pass. Sixteen Apex mutations and four
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

**Hand-off checklist for the person deploying to eda-staging.** Order matters; fields and
value sets come before the code that uses them.
1. Fields: `Interaction__c.Timeline__c` (new); the deactivated value in
   `RFI_Controller__c.Fields_to_Display__c` and `Required_Fields__c`.
2. Apex, in this order: `rfiErrorLogger`, `rfiSubmissionGuard`, `rfiSubmissionProcessor`, `rfiFormController`,
   then the tests `rfiErrorLogger_TEST`, `rfiSubmissionGuard_TEST`, `rfiSubmissionProcessor_TEST`,
   `rfiFormController_TEST` (the two older `getRFIForm_*` failures in `rfiFormController_TEST` were failing
   before this work). The shared lookup and the Aura app were brought up to date with staging on 2026-10-28.
3. LWC: `rfiFormUtils` (new), `rfiForm`, `rfiUnifiedQuestionManager`, then the Aura dependency app (make a
   real content change to the app if a browser keeps an old bundle).
4. Admins apply the section 9 notes (class access for `rfiFormController` first).
5. Run the controller repair, `scripts/apex/migrate_rfi_questions.apex` (dry run first, read the report, then save). In a non-sandbox org the
   script refuses to save until its safety check is edited on purpose.
6. Smoke test as an anonymous visitor: the form loads, the school and start term lists have choices,
   a submit saves, and no new row appears in the Error object (`hed__Error__c`) for a normal submit.

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

**B. New field to be created by developers, then given field security by admins.** `Interaction__c.Timeline__c` (picklist: 0-6 Months, 6-12 Months, More than 1 Year, Undecided). Guest needs edit; admin users need read or edit.

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
