# RFI Test Plan: Marketing and Admissions BA Testing on eda-staging

**Status:** Approved. Jira created 2026-11-09: parent ECRMSF-6074, test sets T1 to T9 are ECRMSF-6075 to ECRMSF-6083 (section 11).
**Prepared:** 2026-11-09
**Jira context:** ECRMSF-5545 "New RFI Updates (post testing)" and the work linked to it (see section 11).
**Environment:** eda-staging (full sandbox, refreshed from production about 3 times a year). Test data here harms nothing.
**Testers:** the Marketing team and the Admissions BA team. Both teams run every test set. Marketing leads the Lightning Out set (T9).
**How long:** nine test sets. Each is sized for 1 Jira point (1 to 2 hours). Teams set their own dates.

---

## 1. What we are proving

The new RFI form (`rfiForm`) replaced the old Lead-based form. It now writes an `Interaction__c` record directly. Salesforce
then turns that Interaction into a Lead, a Contact and an Opportunity. Testing must show three things:

1. **The form works.** Every question type shows, accepts answers, and blocks bad input.
2. **The Interaction is correct.** Each answer lands in the right field, and the defaults the old flow used to set are present.
3. **The Opportunity is correct,** above all its **name** (section 5). We do not control the name directly. It is built from
   the data the form puts on the Interaction.

---

## 2. Before anyone starts

Read this section once. Several items are known and should not be reported as new bugs.

| # | Item | What it means for you |
|---|------|------------------------|
| 1 | **Use a test last name and your own email every time.** Last name `ZZTest` plus your initials and the scenario, for example `ZZTestMW1.2`. Use **your own email address**, with a `+tag` per scenario if your mail allows it (for example `yourname+1.2@stthomas.edu`). | Test records are easy to find, and any email the org sends comes to you. A reused email can attach a new RFI to an existing Contact (T7.10), so keep emails unique unless a scenario says to reuse one. |
| 2 | **No clean-up is needed.** | eda-staging is overwritten at the next sandbox refresh. |
| 3 | **Emails may send** (marketing automation, the nomination flow). | eda-staging obfuscates email addresses so real people are not contacted. Use your own address for anything you type. |
| 4 | **Saved-form repair is done.** On 2026-11-09 the repair script updated 14 controllers in eda-staging (12 Phone, 2 Title, 2 mail, 1 start-school, 7 split-address questions). A repeat dry run found nothing left to change, and the rollout check passed 13 of 13 with none failing. | Saved questions now show current field names. Controllers 0229, 0223, 0234, 0239, 0356, 0357 and 0355 were among those changed. If any of them behaves differently from this plan, report it. |
| 5 | **The Apex code and its unit tests are deployed to eda-staging.** The tests ran on 2026-11-09 with no errors and over 75% coverage on each class. One test (`AcademicInterestSelectorController_TEST`) needed a small fix for a field-length difference in staging, and the fixed version was the one that ran. | Nothing to do. If a scenario fails, the cause is not a missing deployment. Report it. |
| 6 | **Some forms have no Expected Start Term question** (for example 0223, 0299, 0229). | Their Opportunity name has an empty term part, like `Smith\|\|Program`. That is how those forms work today. It is not for testers to fix, but you are the end admins, so be aware of it (section 5). To get a term in the name, a form needs the question. |
| 7 | **You need the `RFI Controller User` permission set** to see the admin tools (Question Manager, Academic Interest Selector). | If a tool is missing from the RFI Controller page, ask an admin to check your access. Do not report it as a bug. |
| 8 | **Most forms redirect to a live thank-you page** on a stthomas.edu site right after Submit (every controller in section 4 except 0335 and 0358). The form shows no message first. | Expected. Your browser leaves Salesforce. Go back and open the Interaction. Those thank-you visits may show in site analytics, and Marketing is aware. |
| 9 | **Most controllers have no Lead Owner**, and the Academic Interest question allows only **one** choice on 0223, 0234, 0239 and 0360. | An owner still gets assigned by default; T1.8 asks you to record who. Use 0357 or 0299 when a scenario needs several programs. |

---

## 3. How to check a result

After every submission, check these four places, in this order.

**A. The Interaction** (Interactions tab, list view "All", search by your test last name).

| Field | Correct value |
|-------|---------------|
| Interaction Status | **Imported.** `New` means processing did not run. `Audit Required` means it failed. Copy the **Audit Reason** into your Jira comment. |
| Interaction Source | Webform |
| Date Inquiry | Today |
| Opportunity Stage | Inquiry |
| Opportunity Record Type | Inquiry Opportunity |
| Lead Source | The controller's Lead Source |
| Term (`Term__c`) | The term chosen on the form, only when the form asks for one |
| Academic Program and Recruitment Program | See T5 (undergraduate) and T6 (graduate) |
| Opportunity, Opportunity Name | Filled in |

**B. The Contact** (open it from the Interaction): name, email, phone and mailing address match what you typed.

**C. The Opportunity** (open it from the Interaction):

| Field | Correct value |
|-------|---------------|
| Name | `LastName\|Term\|Program` (section 5) |
| Record Type and Stage | Inquiry Opportunity, Inquiry |
| Close Date | Today |
| Lead Source | The controller's Lead Source |
| Term, Academic Program, Recruitment Program, State, Country, Zip | Match the Interaction |

**D. The Error object** (App Launcher, search "Errors"). A good submission adds **no row**. A row named
`WARNING: RFI Form saved with gaps` means the RFI was saved but something was dropped. A row named
`ERROR: RFI Form submission failed` means nothing was saved. Copy either row into your Jira comment.

Interaction page layouts will not be changed for this testing. If a field is not on your layout, add it as a column to a list view or a report, or ask the dev team. Do not guess.

---

## 4. The test forms (RFI Controllers)

Open a controller from the RFI Controllers tab. The form preview is on the record page. All names start `RFI Controller`.

| Controller | Type | What it is good for |
|------------|------|---------------------|
| **0227** | Undergraduate, Engineering, Lead Source "Landing Page". Questions: name, email, **Expected Start Term**, high school, graduation year, applicant type. | Simple undergraduate form that builds a full Opportunity name. First-Year and Transfer. |
| **0299** | Undergraduate, Lead Source "Landing Page". Name, Academic Interest, email, high school, phone, applicant type. No start term. | Undergraduate program rule with a major picked. |
| **0262** | Undergraduate, **Dougherty Family College**. Older style (no saved question list). Address, birthdate, start term, high school, texts. | Dougherty rule, full address, older form path. |
| **0229** | Undergraduate Schulze, Lead Source "Undergraduate Schulze". | Preset answers. |
| **0230** | Undergraduate GHR/Schulze. Older style. Scholarship, applicant type, start term. | Older form path. |
| **0335** | Alumni Referral Program. Older style. Address, birthdate, start term. | Referral flow. |
| **0356** | Undergraduate "Nominate". Nominator questions, static text, scholarship. | Custom question types, nominator fields. |
| **0223** | Graduate Nursing. Name, Academic Interest, email, phone, title. No start term. Redirects after submit. | Graduate program, a form with no start term. |
| **0234** | Graduate Education. Area-of-interest **filter**, Academic Interest, address, employer, **start term**, phones, texts, mail. | Graduate Opportunity name with term and program, filters. |
| **0239** | Graduate. Three **filters** (Citizenship, Delivery, School type) plus Academic Interest. | Filters that lock the program list. |
| **0357** | Graduate "FULL FIELD TEST". 28 questions. | Every built-in question in one form. |
| **0360** | Graduate. Has two **"Show only when"** questions. Has a Lead Owner set. | Dependent questions. |
| **0358** | Graduate with a **School / College** filter. **No redirect** after submit. | Filter that saves the school, the in-form thank-you message. |

Applicant types are chosen with the question "I will apply to St Thomas as a". Pick Transfer for the transfer scenarios.

---

## 5. How the Opportunity gets its name (read before T5, T6, T7)

The Interaction processor in the org (`INT_InteractionProcessor`) builds the name. It is the single most important thing to check.

**Name = `Contact last name` | `Term` | `Program name on application`**

* **Last name** is the last name on the Contact. If a matching Contact already exists, that Contact's name is used, not what you typed.
* **Term** comes from the Interaction in this order: the Term (`Term__c`), then the Expected Start Term, then the text start term.
  The form sets both from the start term the visitor chooses. No start term question means an empty term part.
* **Program** is the **Program Name on Application** of the Interaction's **Academic Program**. It is not the Academic Interest name.
  Undergraduate forms always get an Academic Program from the rules in T5. Graduate forms get it from the first Academic Interest.

| Situation | Example name |
|-----------|--------------|
| Form has start term and program | `ZZTestMW\|Fall 2027\|Undergraduate First-Year` |
| Form has no start term question | `ZZTestMW\|\|Master of Science in Nursing` |
| Graduate form, nothing chosen in Academic Interest | `ZZTestMW\|Fall 2027\|` |
| Transfer, International | `ZZTestMW\|Fall 2027\|Undergraduate Transfer` (same text as plain Transfer, see T7.7) |

**Matching.** For the same Contact, an existing Opportunity is **updated, not duplicated** when its name matches the new one.
A blank term or program on the new submission matches any value. Capital letters, apostrophes and brackets are ignored.
When several match, the one with the highest probability wins.

On a match, the stage only moves **forward** (by probability). `Denied` and `Withdrawn` never change. The Close Date becomes today.
The original Lead Source is kept. The record type becomes Inquiry Opportunity for early stages (Suspect, Moderately Suspect,
Inquiry, Engaged, No Longer Interested) and Applicant Opportunity for any later stage.

---

## 6. Test sets

Each set lists what to do and what you should see. Mark each scenario Pass, Fail or Blocked in the Jira subtask comment (section 8).
Where a scenario says **Observe**, there is no fixed answer yet. Record what happened.

### T1. Get started and run one full end-to-end check (1 point, about 1 hour)

Covers ECRMSF-5588, 6044, 5725. Controller **0227**.

| ID | Do this | You should see |
|----|---------|----------------|
| 1.1 | Open RFI Controller 0227 from the RFI Controllers tab. | The record page opens with the form preview. If the Question Manager and Academic Interest Selector are missing, stop and ask an admin about your permission set. |
| 1.2 | Submit the form as a First-Year applicant: name `ZZTest<initials>1.2`, a unique email, Expected Start Term "Fall 2027", any high school, a graduation year, applicant type First-Year. | 0227 redirects to its thank-you page on www.stthomas.edu (section 2, item 8). Return to Salesforce. |
| 1.3 | Check the Interaction (section 3A). | Status Imported. Source Webform. Date Inquiry today. Stage Inquiry. Record type Inquiry Opportunity. Lead Source "Landing Page". Term "Fall 2027". Academic and Recruitment Program "Undergraduate First-Year". |
| 1.4 | Check the Contact (3B). | Name, email and high school as typed. |
| 1.5 | Check the Opportunity (3C). | Name `ZZTest...\|Fall 2027\|Undergraduate First-Year`. Inquiry Opportunity, Inquiry, Close Date today. |
| 1.6 | Check the Error object (3D). | No new row for your submission. |
| 1.7 | Open the Interaction page layout. | The fields **Academic Interest** and **Recruitment Interest** are not on the layout (ECRMSF-5725, Plans retired). **Observe** and report if either shows. |
| 1.8 | Look at the Interaction owner and the Opportunity owner. | **Observe.** 0227 has no Lead Owner set. Admissions BAs: are these the right owners? Record the names. |

### T2. Every question type and where each answer lands (1 point, about 2 hours)

Covers ECRMSF-5764, 6047, 6049, 6050, 5732. Controllers **0357**, **0234**, **0239**, **0227**. 0357 redirects to a stthomas.edu page after submit.

| ID | Do this | You should see |
|----|---------|----------------|
| 2.1 | Open 0357 (28 questions). Read the whole form. | Every question has a readable label. Required ones are marked. There is **one** address block (street, city, state, zip, country), not separate Address 1, 2, 3 boxes. There is **no** "When do you plan to start school" question. The College\School question is a drop-down. |
| 2.2 | Fill in every question with easy-to-spot values (`Phone` ends 1111, home phone 2222, and so on). Submit. | Success. Nothing is left blank on the Interaction that you filled in. |
| 2.3 | On the Interaction, compare each answer with the table in section 7. | Every answer is in the field the table names. Record any answer that is missing or in the wrong field. |
| 2.4 | In "How did you hear about us" and "Scholarship of Interest", pick **two or more** values. | Both values are saved, separated by semicolons (ECRMSF-6049). |
| 2.5 | Tick "I have a question", type a question, and also fill "Tell us about yourself". | Description holds **both** answers, each under its own heading ("Questions/Comments from RFI:" and "Tell us about yourself from RFI:"). Neither overwrites the other. |
| 2.6 | Pick a Birthdate with the date picker. | The picker works and the date is saved. |
| 2.7 | Fill the single "Phone" question on 0239 and submit. Then fill both boxes of "Home and Mobile Phone" on 0234 and submit. | "Phone" saves to **Mobile Phone**. "Home and Mobile Phone" saves the home number to **Home Phone** and the mobile number to **Mobile Phone**. |
| 2.8 | On 0234 enter a US address with state Minnesota and country United States of America. | **State** is the two-letter code `MN`. **Country** is "United States of America". The Contact mailing address matches. The Opportunity State and Zip match (ECRMSF-6050). |
| 2.9 | On 0234 enter an address in another country (for example Canada, province Ontario). | Country is Canada. The Opportunity Country matches. The state does not turn into a US state. **Observe** and report anything odd. |
| 2.10 | On 0227 in High School, search for a school, then choose "I can't find my school" and type a school name. | The typed name saves to **School Name Text**. The submission is not rejected (ECRMSF-6049). |
| 2.11 | On 0227 choose a real high school from the search. | The High School lookup on the Interaction shows that school. |
| 2.12 | Leave a required question blank and press Submit. | Submit is blocked and the blank question is flagged. Fill it and submit. It succeeds. |
| 2.13 | Type an apostrophe and an accent in the names (`O'Brien`, `Zoë`) and a very long answer (about 1,000 characters) in a text box. | The form accepts them. They are saved intact. No error row. |
| 2.14 | On 0234 tick "I would like to receive text messages" and "I would like program information to be mailed to me", then submit. Submit a second record with both unticked. | **Receive Texts** is **Yes** when ticked and **No** when not. The mail checkbox follows the tick box. |

### T3. Admin: build and change a form (1 point, about 2 hours)

Covers ECRMSF-603, 619, 5856, 6048. Admin tools on the RFI Controller record page. Read the admin guide first
(`docs/MAIN_GUIDE.md` and `docs/ADMIN_TOOL_GUIDE.md`).

| ID | Do this | You should see |
|----|---------|----------------|
| 3.1 | Create a **new** RFI Controller: Descriptive Name `ZZ TEST <initials> UG`, Academic Level Undergraduate, School/College of your choice, a Lead Source. Save. | The record saves and gets a name like `RFI Controller 0NNN`. |
| 3.2 | In the **Question Manager**, add pre-configured questions: Email, Expected Start Term at St Thomas, I will apply to St Thomas as a, Citizenship. Save Configuration. | First Name and Last Name are always on the form. The list shows blue "pre-configured" badges. After Save Configuration, Expected Start Term is still a **drop-down** (ECRMSF-6048), not a text box. |
| 3.3 | Add one **custom** question of each type: Text box, Textarea, Email, Picklist, Checkbox, Date, Static content. Make one required. Each one saves to an Interaction field you pick. | Each question appears in the list with a green "custom" badge. A Picklist question on a picklist field shows that field's own current values. |
| 3.4 | Reorder questions by drag and drop, and with the arrow buttons. Edit a label. Remove one. Save. Reload the page. | The order, labels and removal persist after reload. |
| 3.5 | Add a **Program Filter** question (School / College, then another filter). Choose which values appear. Save. | The filter appears with a purple badge. On the form, the Academic Interest list is **locked** until every filter question is answered. |
| 3.6 | Open the filter field list. Compare the names of the Generic Filter slots with the names used on the Application. | **Observe** (ECRMSF-5856). Report any label that does not match. |
| 3.7 | Open the **Academic Interest Selector** and choose three or more programs. | Selections save on their own. The count shows in the title. The form's Academic Interest list shows exactly those programs. |
| 3.8 | Change Lead Source, tick **Hide Form Title**, set **Academic Interest Max Selection** to 2, and set **Redirect After Form Submission** with a Redirect URL. Submit once with the redirect on, then once with it off. | The Lead Source is on the next Interaction. The title is hidden. The form accepts at most two Academic Interests. With the redirect on, the browser goes to the URL; with it off, a thank-you message shows next to Submit and the form clears. |
| 3.9 | Submit your new form once. | The Interaction and Opportunity are correct (section 3). Keep this form. T5.3 and T7 can use it. |

### T4. Admin: "Show only when" rules and form health warnings (1 point, about 1.5 hours)

Covers ECRMSF-6061. Controller **0360** (has two rules) and your own form from T3.

| ID | Do this | You should see |
|----|---------|----------------|
| 4.1 | Open 0360's form. Leave "I would like to receive text messages" unanswered. | The question "This is a dependent question on a text message?" is **not** shown. |
| 4.2 | Answer the text-message question **Yes**. | The dependent question appears and is required if marked so. Answer **No**: it disappears. |
| 4.3 | On 0360, choose a women's varsity sport in "What sport are you interested in?". | "What position do you play?" appears. Choose another kind of answer: it disappears. |
| 4.4 | Type an answer in the dependent question, then change the earlier answer so it hides, then show it again. | The dependent question is empty again (a hidden answer is thrown away). Questions **below** it keep what you already typed and ticked. |
| 4.5 | Submit with the dependent question hidden. Check the Interaction. | Its field is empty. No Error row. |
| 4.6 | On your T3 form add a Picklist or Checkbox question, then a second question with **Show only when** set to it. Save. | The rule is listed in plain words. The form behaves as set. |
| 4.7 | In the Question Manager try to make a question depend on a text box, a date, or a later question. | The list of eligible earlier questions excludes those. You cannot set a rule that cannot work. |
| 4.8 | Delete or move the earlier question that a rule depends on. Try to save. | The manager warns above the table and refuses to save until the rule is fixed. |
| 4.9 | Ask the dev team to put a question with a broken rule on a test controller, then open its record page. | A yellow warning banner names the question and the reason. A visitor on the public form sees no banner. |

### T5. Undergraduate: program rules and Opportunity name (1 point, about 1.5 hours)

Covers ECRMSF-6045, 6044, 6048. Controllers **0227**, **0299**, **0262**, plus the form from T3.

The rules the system applies to undergraduate forms (first match wins):

1. Applicant type is **Transfer** and citizenship is **International**: Academic Program "Undergraduate Transfer (INTL)".
2. Applicant type is **Transfer**: "Undergraduate Transfer".
3. The controller's School/College (or the major's school) is **Dougherty Family College**: "Dougherty Family College".
4. Anything else: "Undergraduate First-Year".

| ID | Do this | You should see |
|----|---------|----------------|
| 5.1 | 0227, applicant type First-Year, start term Fall 2027. | Program "Undergraduate First-Year". Name `ZZTest...\|Fall 2027\|Undergraduate First-Year`. |
| 5.2 | 0227, applicant type **Transfer**, start term Fall 2027. | Program "Undergraduate Transfer". Name `...\|Fall 2027\|Undergraduate Transfer`. |
| 5.3 | Use your T3 form with Citizenship, applicant type and start term. Choose **Transfer** and citizenship **International**. | Interaction and Opportunity **Academic Program** is "Undergraduate Transfer (INTL)". The Opportunity **name** still ends `\|Undergraduate Transfer`, because both programs share the same Program Name on Application. Record it. |
| 5.4 | 0262 (Dougherty, older style). Fill the full address, birthdate, start term and high school. | Program "Dougherty Family College". Name `...\|<term>\|Dougherty Family College`. Contact mailing address matches. |
| 5.5 | 0299: pick a major in Academic Interest and choose Transfer. | The Academic Program follows the **rule** (Transfer), not the major. The major you picked is kept in **Major Program 1**. The name has an empty term part: `ZZTest...\|\|Undergraduate Transfer`. |
| 5.6 | On 0227 open the Expected Start Term list. | A list of terms, not a text box (ECRMSF-6048). Choose Fall 2027. |
| 5.7 | Open the Term record on the Interaction (5.1). | Its **Term Key** ends in the letter `a` (for example `202740a`). The org holds two Term records per term. The form must use this one. |
| 5.8 | Check **St Thomas College/School** on the Interaction. | It shows the school of the form (0227: School of Engineering; 0262: Dougherty Family College). |
| 5.9 | Check **Recruitment Program Associated Schools** on the Interaction. | It is filled in for the chosen program. |

### T6. Graduate: program, filters and Opportunity name (1 point, about 1.5 hours)

Covers ECRMSF-6044, 5588, 5856. Controllers **0234**, **0239**, **0223**, **0358**.

| ID | Do this | You should see |
|----|---------|----------------|
| 6.1 | 0234. Answer the "area of interest" filter, choose one Academic Interest, pick start term Fall 2027, fill the address, submit. | The Academic Interest list shows only programs that fit the filter. Interaction **Major Program 1**, Academic Program and Recruitment Program are the program chosen. Name `ZZTest...\|Fall 2027\|<Program Name on Application>`. |
| 6.2 | 0357 (no limit on Academic Interest). Choose **several** Academic Interests, up to four. | **Major Program 1, 2, 3, 4** fill in the order chosen. The Academic Program follows the **first**. The name uses the first only. On 0234 only one choice is allowed (its limit is 1). |
| 6.3 | On 0357 choose an Academic Interest, then remove every selection before submitting. | The Major Program fields are all empty (an old choice is not left behind). The name has an empty program part, for example `ZZTest...\|\|`. |
| 6.4 | 0239. Before answering any filter, look at Academic Interest. | The program list is **locked** until all three filters (Citizenship Type, Delivery Type, School Type) are answered. |
| 6.5 | 0239. Answer all three filters, choose a program, submit. | **Citizenship** is saved on the Interaction. Delivery Type and School Type only narrow the list. They do not save on the Interaction. That is expected. |
| 6.6 | 0358. Use the School/College filter, then submit. | **St Thomas College/School** shows the chosen school. |
| 6.7 | 0223 (no start term). Choose the nursing program and submit. | Term is blank. Name `ZZTest...\|\|<Program Name on Application>`. Everything else is correct. The browser then redirects (the controller redirects after submit). |
| 6.8 | Check the Program Name on Application for the program you chose (open the Program record). | The Opportunity name uses **that** text, which may differ from the Academic Interest label. |

### T7. Repeat prospects: Opportunity matching and stage (1 point, about 2 hours)

Covers ECRMSF-6044, 6045. Use the **same** name and email unless the scenario says otherwise. Controllers **0227**, **0234**.
Run the numbered steps in order for each scenario.

| ID | Do this | You should see |
|----|---------|----------------|
| 7.1 | Submit 0227 as `ZZTest<initials>7A`, Fall 2027, First-Year. Submit the **same** person again, the same way. | **One** Contact. **One** Opportunity. **Two** Interactions, both pointing to that Opportunity. The name is unchanged. Close Date is today. |
| 7.2 | Submit 0234 with the same person, Fall 2027 and Program A. Submit again with Program B, same term. | **Two** Opportunities for the one Contact (the program differs). |
| 7.3 | Submit 0227 as First-Year for Fall 2027. Submit again for **Spring 2027**. | **Two** Opportunities (the term differs). |
| 7.4 | Submit 0234 with Program A and **no** start term. Submit again with Program A and start term Fall 2027. | **One** Opportunity. Its name changes from `...\|\|Program A` to `...\|Fall 2027\|Program A`. |
| 7.5 | Submit 0234 with Program A and Fall 2027. Submit again with Program A and **no** start term. | **One** Opportunity. The term stays in the name. |
| 7.6 | After 7.1, change that Opportunity's stage to **Started App** yourself. Submit the same person again. | The stage **stays** Started App (it does not drop back to Inquiry). Record type is now **Applicant Opportunity**. Lead Source is unchanged. Skip and note it if you cannot change the stage. |
| 7.7 | Submit the Transfer form (5.2) for a person. Submit again, the same person on your International form (5.3), same term. | **Observe.** The code treats the two names as the same, so expect **one** Opportunity. Record the result and whether Admissions wants it. |
| 7.8 | Submit with last name `ZZTest O'Brien<initials>` twice. | **One** Opportunity. The apostrophe does not make a duplicate. |
| 7.9 | Submit two different people with the same last name and different emails. | **Two** Contacts, **two** Opportunities. The match is per Contact. |
| 7.10 | Submit the same email with a different first or last name. | **Observe.** Record whether the system reused the existing Contact or created a new one, and the **Interaction Status**. An `Audit Required` status with its Audit Reason is useful to report. |

### T8. Special forms: presets, referrals, older forms (1 point, about 1.5 hours)

Covers ECRMSF-6046, 5764, 603. Controllers **0229**, **0356**, **0335**, **0230**. Use your own email address for the nominator and the student (section 2, items 1 and 3).

| ID | Do this | You should see |
|----|---------|----------------|
| 8.1 | 0229 (Schulze). The form has no scholarship question. Submit. | **Scholarship of Interest** on the Interaction is filled from the controller's preset (Phase 0 saw "Schulze Innovation"). Lead Source is "Undergraduate Schulze". |
| 8.2 | 0356 (Nominate). Read the form. | The static headings "Nominator information" and "Student Information" show as text, not inputs. Five nominator questions are required. |
| 8.3 | 0356. Enter a bad nominator email, then a good one. Submit with the "Identify as reference" and relationship picklists chosen. | The bad email is blocked. On success, the **Nominator** fields on the Interaction hold your answers. The student and Opportunity are correct. |
| 8.4 | 0335 (Alumni Referral Program, older style). Submit with test data. | Lead Source "Alumni Referral Program". **Observe** whether the nomination flow ("Interaction on Create: Nomination Record") created its record, and ask an admin what to expect. |
| 8.5 | 0230 (older style, Scholarship question and applicant type). Choose Transfer and a scholarship. | The older form renders and submits like a newer one. Program is "Undergraduate Transfer". Name is correct. |
| 8.6 | Compare an older-style submission (0230 or 0262) with a newer-style one (0227) by the same person details. | The Interaction defaults match: Source, Date Inquiry, Stage, record type, Term. **Observe** any difference. |

### T9. Lightning Out in the Cascade CMS (1 point, about 2 hours, Marketing leads)

Covers ECRMSF-6051, 6053, 6044, 6045. The RFI is embedded on a Cascade page through Marketing's Vue component. In Lightning Out
the visitor is anonymous (the Admissions site guest user). A form without a redirect shows its own message after submit,
because Salesforce toasts do not exist outside Salesforce.

Setup: Marketing's Vue component for the Cascade CMS is already built, and Marketing manages the Cascade side. For reference, the Lightning Out app is
`c:requestForInformationApp` and it carries `c:rfiForm`. The form takes its controller name from `rfiControllerName`, and it still accepts the old
`rfi_controller` attribute.

| ID | Do this | You should see |
|----|---------|----------------|
| 9.1 | Load a Cascade test page that embeds one controller (use 0227). Open the browser developer console. | The form renders. No red errors about blocked content or trusted sites. |
| 9.2 | Load the same page in a private window where you are **not** logged in to Salesforce. | The same form loads. The Expected Start Term and College/School lists have choices (an empty list means a guest access gap, ECRMSF-6053). |
| 9.3 | Submit as that anonymous visitor on 0227, then on 0358. | 0227 sends the browser to its thank-you page. 0358 has no redirect, so a thank-you message appears next to Submit and the form clears. In both cases the Interaction, Contact and Opportunity are correct (section 3) and there is no new Error row. |
| 9.4 | Put three controllers on three Cascade pages: an undergraduate First-Year form (0227), Dougherty (0262), a graduate form (0234). Submit each. | Each Interaction gets the **right program** (First-Year, Dougherty, the chosen graduate program) and the right Opportunity name. |
| 9.5 | In Salesforce, add a question to the controller you embedded. Reload the Cascade page (hard reload if needed). | The new question shows. **Observe** how many reloads it took. |
| 9.6 | Check the page on a phone-width window and with the keyboard (Tab through every field). | The layout holds together. Every field can be reached. Error messages are readable. |
| 9.7 | Click Submit twice quickly. | **Observe.** Record whether one or two Interactions were created. |
| 9.8 | Marketing: after a redirecting form (0227) submits, open the thank-you page. | It loads, and its analytics or tracking fires as you expect. **Observe** whether test submissions should be filtered out of reports. |
| 9.9 | Leave a required question empty and submit. | The message names the missing question and nothing is saved. |

---

## 7. Where each answer should land (for T2.3)

Built-in questions and the Interaction field they save to. The labels are from the Question Manager catalog.

| Question | Interaction field | Notes |
|----------|-------------------|-------|
| First Name, Last Name, Email | `First_Name__c`, `Last_Name__c`, `Email__c` | Always on the form. |
| Phone | `Mobile_Phone__c` | Provisional. It matches the old form and may change. |
| Home Phone | `Home_Phone__c` | |
| Home and Mobile Phone | `Home_Phone__c` and `Mobile_Phone__c` | Two boxes. |
| Academic Interest | `Major_Program_1__c` to `Major_Program_4__c` | Up to four. |
| Address | `Mailing_Street__c`, `Mailing_City__c`, `Mailing_State__c`, `Mailing_Country__c`, `Mailing_Postal_Code__c`, plus `State__c` (code) and `Country__c` | One block. |
| Birthdate | `Birthdate__c` | Date picker. |
| Citizenship | `Citizenship__c` | |
| Employer, Company | `Employer__c` | Both save here. |
| Expected Start Term at St Thomas | `Intended_Start_Term__c`, and `Term__c` | A drop-down of terms. |
| High School Attended | `High_School_or_College__c` (or typed `School_Name_Text__c`) | |
| High School Graduation Year | `High_School_Graduation_Year__c` | |
| How did you hear about us | `Heard_About_Us__c` | Multi-select, semicolons. |
| I have a question | `Has_Question__c` and `Description__c` | |
| Tell us about yourself | `Description__c` | With its own heading. |
| I will apply to St Thomas as a, and St Thomas Law | `Admit_Type__c` | The St Thomas answer wins when both are filled. |
| Mail program information | `Mailed_Program_Information_Requested__c` | |
| Receive text messages | `Receive_Texts__c` | Yes or No. |
| Scholarship of Interest | `Scholarship_of_Interest__c` | Multi-select. |
| St Thomas Colleges (College\School) | `St_Thomas_College_School__c` | |
| Timeline to Enrollment | `Timeline__c` | |
| Title | `Contact_Title__c` | |

---

## 8. Recording results

In each Jira subtask, add **one comment per tester** using this layout, and discuss differences in the thread.

```
Tester: <name>, Team: <Marketing | Admissions BA>, Date: <date>
Controller(s): <numbers used>
Scenarios: 1.2 Pass | 1.3 Pass | 1.7 Fail | 1.8 Observe ...
Failures (one per line):
  <scenario> | what I did | what I expected | what happened | link to Interaction/Opportunity | screenshot
```

A failure is worth a new Jira item only when it is reproducible. Include the controller name, the exact answers, and the
Interaction link. For anything on the Error object, paste the row.

---

## 9. Traceability: which work item each test set covers

| ECRMSF item | Topic | Test set |
|-------------|-------|----------|
| 6044 | Wrong Opportunity (record type, stage, source, dates) | T1, T5, T6, T7 |
| 6045 | Undergraduate recruitment program | T5, T7 |
| 6046 | Preset answers | T8 |
| 6047 | Fields saved to the wrong field, saved-form repair | T2 |
| 6048 | Start term and College/School turn into text boxes | T3, T5 |
| 6049 | Answers lost | T2 |
| 6050 | State and Country | T2 |
| 6051 | Safe for anonymous visitors | T9 |
| 6053 | Guest access | T9 |
| 6061 | Dependent questions | T4 |
| 5588 | Fields the flow used to populate | T1, T5, T6 |
| 5764 | Field alignment | T2, T3, T8 |
| 5856 | Program generic field labels | T3, T6 |
| 5725 | Remove Academic/Recruitment Interest from layout | T1 |
| 603, 619 | Dynamic RFI questions, rebuilt controller | T3, T4 |
| 5519 | Old-form vs new-form comparison (already Deployed) | T8.6 |
| 6052 | Automated tests | Not in this plan (developer owned) |
| 5546, 5604, 5732 | Lead flow for LinkedIn, OCB formula, mapping review | Not tested here |

---

## 10. Out of scope

* Production. This plan covers eda-staging only. A separate story will cover production.
* The old Lead-based form (`requestForInformationForm`), except when T8.6 compares output.
* The Lead-to-Interaction flow for LinkedIn leads (ECRMSF-5546).
* Marketing Cloud, Act-On and Journey Builder behavior after the Interaction exists. Note anything unusual you see.
* Automated tests (Apex and Jest). The developers run those.

---

## 11. Jira layout (created 2026-11-09)

One parent story with nine subtasks of 1 point each, matching sections 6 and 9. Put the parent in **Needs CRM Review**
(the user moves it there in the Jira UI) before it goes to Needs Prioritization or a current sprint.

| Item | Summary | Points |
|------|---------|--------|
| Parent (Task) ECRMSF-6074 | RFI: Marketing and Admissions BA testing of the new RFI form on eda-staging | n/a |
| Subtask ECRMSF-6075 | T1. Get started and run one full end-to-end check | 1 |
| Subtask ECRMSF-6076 | T2. Every question type and where each answer lands | 1 |
| Subtask ECRMSF-6077 | T3. Admin: build and change a form | 1 |
| Subtask ECRMSF-6078 | T4. Admin: "Show only when" rules and form health warnings | 1 |
| Subtask ECRMSF-6079 | T5. Undergraduate: program rules and Opportunity name | 1 |
| Subtask ECRMSF-6080 | T6. Graduate: program, filters and Opportunity name | 1 |
| Subtask ECRMSF-6081 | T7. Repeat prospects: Opportunity matching and stage | 1 |
| Subtask ECRMSF-6082 | T8. Special forms: presets, referrals, older forms | 1 |
| Subtask ECRMSF-6083 | T9. Lightning Out in the Cascade CMS | 1 |

Created by `acli`. All subtasks are Requested and 1 point each (the parent rolls up to 9). The parent is linked (Relates) to ECRMSF-5545, 603,
619 and 5519. **Still to do in the Jira UI:** link ETA-828 (`acli` was denied Link Issue permission on that project), add the two links on 5545
that `acli` cannot see (Blocks, Discovery - Connected), and drag the parent into the Needs CRM Review sprint bucket.

---

## 12. Decisions made and what is still open

**Decided 2026-11-09**

1. **Test forms.** Testers build their own, for T3 and for the International case in T5.3. Both teams are proficient admins.
2. **Repair script.** Run in eda-staging on 2026-11-09 and checked (section 2 item 4).
   **Deployment and tests.** The code and unit tests are in eda-staging, and the tests pass (section 2 item 5).
3. **Terms missing from names.** Forms without a start term question give names like `Smith||Program`. Testers do not fix this. They are told so
   (section 2 item 6).
4. **International transfer.** Transfer and Transfer (INTL) share a Program Name on Application, so they give the same Opportunity name and match each
   other. The note and the scenario stay (T7.7).
5. **Email.** Testers use their own address. eda-staging obfuscates email addresses to protect real people.
6. **Clean-up.** None. eda-staging is overwritten at the next refresh, and the scratch org will be rebuilt.
7. **Cascade.** Marketing's Vue component is built and Marketing manages the CMS side.
8. **Thank-you pages.** Test submissions may hit the live thank-you pages as they are. Marketing understands this.
9. **Layouts.** Interaction layouts are not adjusted for testing.
10. **Jira.** The plan owner links the two unresolved ECRMSF-5545 links (Blocks, Discovery - Connected) and moves the parent into the sprint bucket in the Jira UI.

**Still open**

Only the Jira UI items in section 11: the ETA-828 link, the two links on ECRMSF-5545 that `acli` cannot see, and moving the parent into the Needs CRM Review bucket.
