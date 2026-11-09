# RFI Admin Guide

**Audience:** Marketing, Admissions BAs and Salesforce admins who build and maintain RFI forms. You know Salesforce. You do not need to write code.
**Last updated:** 2026-11-09
**Related:** [MAIN_GUIDE.md](MAIN_GUIDE.md) (how the pieces fit together), [RFI_TEST_PLAN.md](RFI_TEST_PLAN.md) (what testers check), [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## 1. The idea in one minute

* One **RFI Controller** record is one form. It holds the questions, the settings and the programs the form offers.
* A visitor fills in the form. The form creates an **Interaction** record.
* Salesforce then turns the Interaction into a **Lead, Contact and Opportunity**. You do not build any of that. You control the Opportunity
  only through the data the form puts on the Interaction (section 7).
* The same form can sit on a Salesforce page (to preview) and on a website page (through Lightning Out, section 9).

You need the **RFI Controller User** permission set to see the tools below. If a tool is missing from the RFI Controller page, ask an admin.

---

## 2. Build a new form

1. Open the **RFI Controllers** tab and click **New**.
2. Fill in the settings (section 3). At minimum: **Descriptive Name**, **Academic Level**, **Lead Source**. Save.
   Salesforce gives the record a name like `RFI Controller 0361`. That name is what a web page uses to find the form.
3. On the new record page, use the **Unified Question Manager** to add questions (section 4).
4. Use the **Academic Interest Selector** to choose the programs people can pick (section 5).
5. Use the form preview on the same page to try it. Fill it in and submit. Then check the Interaction (section 8).

---

## 3. Controller settings

These are fields on the RFI Controller record.

| Setting | What it does |
|---------|--------------|
| **Descriptive Name** | A label for people (for example "Grad / SOE / Website / All Programs"). Not shown to visitors. |
| **Academic Level** | Undergraduate or Graduate. Decides which programs are offered **and which program rules apply** (section 7). |
| **School / College** | Narrows the program list. Also becomes the school on the Interaction. For undergraduate forms, **Dougherty Family College** here sends the inquiry to the Dougherty program. |
| **Lead Source** | Copied onto the Interaction and the Opportunity. Use it to tell campaigns and pages apart in reports. |
| **Lead Owner** | The person who should own the Interaction. If it is blank, the org's default ownership applies. |
| **Redirect After Form Submission?** and **Redirect URL** | On: after Submit the visitor goes straight to the URL, usually a thank-you page, with no message first. Off: the form clears and shows "Thank you! We received your request for information." |
| **Hide Form Title** | Hides the title above the form. Useful on pages that have their own heading. |
| **Academic Interest Max Selection** | How many programs a visitor may choose. The Academic Interest Selector for admins has no limit. |
| **Multi Select Display Type** | How multi-choice questions look (for example pills). |

Fields named `... To Display` (for example `School College To Display`) are filled in by the Question Manager. Do not edit them by hand.

**Preset answers.** Some forms fill in a value the visitor never sees (for example the Schulze forms fill **Scholarship of Interest**).
These are kept in the **Lead Preset Value** custom metadata (`Lead_Preset_Value__mdt`), one row per controller and field. The preset is used only
when the visitor left that field blank. Ask the dev team to add or change one.

---

## 4. Unified Question Manager

The manager is the list of every question on the form, in the order a visitor sees them. Work in the list, then press **Save Configuration**.
Nothing changes on the live form until you save.

### What each button and column does

| Control | What it does |
|---------|--------------|
| **Add Pre-configured Question** | Adds a standard question from the catalog (Email, Phone, Address, Expected Start Term and so on). The catalog already knows which Interaction field it saves to. |
| **Add Custom Question** | Adds your own question. You pick the type and the Interaction field that stores the answer. |
| **Add Program Filter Question** | Adds a question that narrows the program list (section 4.3). |
| **Order** (drag handle, Move Up, Move Down) | Reorders. Drag works across all question types. The arrow buttons do the same for keyboard use. |
| **Question Label** | The text the visitor sees. Edit it in the list. |
| **Type** badge | Blue is pre-configured, green is custom, purple is a program filter. |
| **Required** | Marks the question as required. Visitors cannot submit without it. |
| **Edit** and **Remove** | Open the full dialog or delete the question. |
| **Save Configuration** | Saves the whole list. |

**First Name and Last Name** are always on the form. The Interaction needs them.

### 4.1 Pre-configured questions

Pick the question from the list and set the label and Required. The catalog today:

Academic Interest, Address, Birthdate, Citizenship, Company, Email, Employer, Expected Start Term at St Thomas, First Name, High School
Attended, High School Graduation Year, Home Phone, Home and Mobile Phone, How did you hear about us, I have a question, I will apply to
St Thomas as a, I will apply to St Thomas Law as a, I would like program information to be mailed to me, I would like to receive text
messages, Last Name, Phone, Scholarship of Interest, St Thomas Colleges (shown as College\School), Tell us about yourself, Timeline to
Enrollment, Title.

Things worth knowing:

* **Phone** saves to the Mobile Phone. **Home and Mobile Phone** shows two boxes and saves both. **Home Phone** saves to Home Phone.
* **Address** is one block (street, city, state, zip, country). Older forms may still list separate Address 1, Address 2, City, State and
  Zipcode questions. The form turns these into the one block for you.
* **Expected Start Term** and **College\School** are drop-downs of real records. They are not text boxes.
* **I will apply to St Thomas as a** and **...Law as a** share one field. If a visitor fills both, "St Thomas" wins.
* **Birthdate** is a date picker.
* **Employer** and **Company** save to the same field.
* **I have a question** is a tick box that reveals a question box. **Tell us about yourself** is a separate long box. The Interaction
  keeps both answers, each under its own heading, so neither replaces the other.
* **High School Attended** searches schools. If the visitor chooses "I can't find my school", the name they type is kept in **School Name Text**.
* **How did you hear about us** and **Scholarship of Interest** allow several choices. They are saved separated by semicolons.
* **When do you plan to start school** is retired. Do not add it.

### 4.2 Custom questions

Choose a **Question Type**, write the **Question Label**, and pick the **Interaction Field** that stores the answer. The field list only
shows fields that fit the type.

| Type | What the visitor sees |
|------|-----------------------|
| **Text box** | One line of text. |
| **Textarea** | A long text box. |
| **Email** | One line that checks for a valid email address. |
| **Picklist** | A drop-down. See below. |
| **Checkbox** | A tick box. |
| **Date** | A date picker. |
| **Static content** | Text only (a heading or a paragraph). It asks nothing and saves nothing. |

Each type except Static content also has a **... required** version (for example "Text box required"). A required Checkbox must be ticked.
**Help Text** shows small text under the question.

**Picklist questions.** If the field you chose is a picklist on the Interaction, the form always shows that field's **current active
values**. The dialog shows the values and you cannot edit them there. If someone adds or retires a value on the field, the form follows
with no edit to the question. If the field is plain text, type the choices yourself, one per line.

**Before a new field can be used,** the field must exist on the Interaction and the website's guest user and admins must be able to use it.
Ask the dev team and the Salesforce admin. If a visitor's answer cannot be saved, the rest of the RFI is still saved and a row in the Error
object names the field (section 10).

### 4.3 Program filter questions

A filter question asks something that narrows the program list. Example: a Citizenship question limits the programs to those open to that group.

1. Add a **Program Filter Question** and choose a **Filter Field** (School / College, Citizenship Type, Degree Type, Student Type,
   Delivery Type, Program Types or a Generic Filter).
2. In **Values to Display on RFI Form** keep the answers you want visitors to choose from.
3. Save. On the form, the **Academic Interest** list stays **locked** until every filter question is answered.

Which filter answers are **saved** on the Interaction:

| Saved on the Interaction | Only narrows the list (not saved) |
|--------------------------|-----------------------------------|
| School / College, Citizenship Type, Generic Filter 3 | Degree Type, Student Type, Delivery Type, Program Types, Generic Filter 2, 4, 6, 7, 8 |

If the business wants one of the "not saved" answers kept, a field must be created first. Ask the dev team.

### 4.4 "Show only when" (dependent questions)

Some questions only matter after an earlier answer. Example: ask "Which sport?" only when the visitor says they want text messages.

1. Open the question with **Edit**.
2. Find **Show only when**. Under **Show this question only when the answer to**, choose an earlier question.
3. Under **is one of**, tick the answers that reveal this question.
4. Save the dialog, then **Save Configuration**. The list shows the rule in plain words under the question.

Rules to remember:

* One condition and one level. The earlier question cannot have a rule of its own.
* The earlier question must be **above** this one, and must be a **choice from a list** (a picklist-type question) or a **tick box**.
  Text boxes, dates, multi-choice questions, terms, schools and programs cannot be used.
* A hidden question is **not asked**. It is never required, and anything the visitor typed before it hid is thrown away. Nothing is
  saved for it.
* Deleting or moving the earlier question can break the rule. The manager lists broken rules in a red box above the table and **will not
  save** until you fix each one.
* If a broken rule reaches the live form, the question simply shows (see section 10).

Controller **0360** is a working example.

### 4.5 Saving, and what a saved form looks like

Press **Save Configuration** after any change. A saved list stays valid even if the tool changes later. Each question gets a permanent
internal key, and "Show only when" rules point at that key, so reordering does not break them.

---

## 5. Academic Interest Selector

Chooses which academic programs appear in the **Academic Interest** question. It has no Save button. Each change saves at once.

1. Set **Academic Level** (and **School / College** if you want a shorter list) on the controller first.
2. Open the selector on the record page. It lists every program that is active, flagged for RFI, and matches the level and school.
   Programs are grouped by school and degree and show their full names.
3. Tick the programs to offer. The count appears in the title. Pills show what is selected.

* The selector allows any number of programs. The **form** limits what a visitor can choose through **Academic Interest Max Selection**.
* If no programs show, check Academic Level, that programs are Active and flagged for RFI, and that you can read the program records.
* Review the list when programs launch or retire, and after a marketing campaign changes.

---

## 6. What the form sets for you

Visitors never see these. The form fills them in on every submission so the Opportunity comes out right.

| Interaction field | Value |
|-------------------|-------|
| Interaction Source | Webform |
| Date Inquiry | Today |
| Opportunity Stage | Inquiry |
| Opportunity Record Type | Inquiry Opportunity |
| Lead Source and Owner | From the controller |
| Term | The Term record for the chosen Expected Start Term |
| State and Country | The state code (for example MN) and the country, matched to the org's own lists |
| Academic Program, Recruitment Program, Associated Schools | From the program rules (section 7) |
| St Thomas College/School | From the controller, or from the chosen major's school |
| Preset answers | From the controller's presets, only where the visitor left a field blank |

A submission never lets the visitor set the owner, the stage, or anything else the server controls. Anything unexpected is dropped and
reported (section 10).

---

## 7. How programs and the Opportunity name are decided

### Undergraduate forms

The form picks the Academic Program with these rules, first match wins:

1. Applicant type **Transfer** and citizenship **International**: Undergraduate Transfer (INTL).
2. Applicant type **Transfer**: Undergraduate Transfer.
3. Controller School / College (or the chosen major's school) is **Dougherty Family College**: Dougherty Family College.
4. Anything else: Undergraduate First-Year.

The major a visitor picks is kept in **Major Program 1**. It does not change the Academic Program for undergraduates.
To use the rules, an undergraduate form needs the applicant-type question. Without it every visitor is treated as First-Year.

### Graduate forms

The Academic Program is the program matching the **first Academic Interest** the visitor chose. Up to four fill **Major Program 1 to 4**.
Emptying the Academic Interest also empties those fields.

### The Opportunity name

The org's Interaction processor names the Opportunity **`Contact last name | Term | Program name on application`**.

* The **term** is the one chosen in Expected Start Term. A form with **no** start term question gives an empty term, for example `Smith||Program`.
* The **program** is the Academic Program's **Program Name on Application**, which can differ from the label the visitor clicked.
  Undergraduate Transfer and Undergraduate Transfer (INTL) share the same name on application.
* For the same Contact, an existing Opportunity with a matching name is **updated, not duplicated**. A blank term or program matches any.
  A stage only moves forward. Denied and Withdrawn never change. The original Lead Source is kept.

If you want complete Opportunity names, include an **Expected Start Term** question and a way to get a program (Academic Interest for
graduate forms, applicant type for undergraduate forms).

---

## 8. Check a result

After a test submission:

1. **Interactions** tab, list view All, search by the test last name. The **Interaction Status** should be **Imported**. `Audit Required`
   means processing failed. Read **Audit Reason**.
2. Open the **Contact** and the **Opportunity** from the Interaction. Check the name, stage Inquiry, record type Inquiry Opportunity and
   Close Date today.
3. Open **Errors** (App Launcher). A good submission adds no row.

Use a name like `ZZTest<initials>` and your own email address for tests. The full checklist is in [RFI_TEST_PLAN.md](RFI_TEST_PLAN.md).

---

## 9. Put a form on a website (Lightning Out)

A web page embeds the form with the Lightning Out app **`c:requestForInformationApp`**, which includes the form component `c:rfiForm`.
The page tells the form which controller to use with the **`rfiControllerName`** value (for example `RFI Controller 0227`). The older
`rfi_controller` value is still accepted, so an existing page component keeps working.

On a website:

* The visitor is anonymous (the site's guest user). The guest needs access to the form's data. If a list such as Expected Start Term or
  College\School is empty on the website but full in Salesforce, that is a guest access gap. Tell the Salesforce admin.
* Salesforce messages (toasts) do not exist there. A form with no redirect shows its own thank-you message next to Submit.
* After you change a question in the manager, reload the page to see it (use a hard reload if the old form still shows). The form reads its setup when it loads.
* After a **code** change, the browser may keep an old copy of the form. The dev team handles that with a change to the Lightning Out app.

---

## 10. When something looks wrong

| What you see | What it means | What to do |
|--------------|---------------|------------|
| A **yellow banner** above the form on the controller record page | A saved question cannot be shown, or a rule cannot work. It names the question and the reason. | Fix or delete that question in the manager and save. Visitors never see the banner. |
| A red box in the Question Manager | A "Show only when" rule cannot work. | Fix each rule listed. You cannot save until you do. |
| An Error row **"WARNING: RFI Form saved with gaps"** | The RFI was saved, but something was dropped: an answer the visitor was not allowed to set, a field nobody can write, a lookup the visitor could not see. The row lists what. | Read the row. Fix the question or ask the admin for field access. |
| An Error row **"ERROR: RFI Form submission failed"** | Nothing was saved. The visitor saw an error. | Read the row (it names the controller and the cause) and send it to the dev team. |
| The form says it could not load | The saved question list cannot be read at all. | Open the controller. The Unified Questions field may be damaged. Ask the dev team. |
| An answer is missing on the Interaction | The field may not be writable by the website's guest user. | Check the Error rows. Ask the admin for field access. |
| Opportunity name has empty parts | No start term or program on the Interaction. | See section 7. |

Who should watch the Error object? Pick a person or a report. A broken setting writes one row per submission.

---

## 11. Quick reference

| I want to... | Do this |
|--------------|---------|
| Add a question | Question Manager, Add Pre-configured or Add Custom Question, Save Configuration |
| Make a question required | Tick Required in the list or in Edit |
| Show a question only for some answers | Edit the question, use **Show only when** |
| Choose which programs show | Academic Interest Selector |
| Limit programs by a visitor's answer | Add a Program Filter Question |
| Send visitors to a thank-you page | Redirect After Form Submission? and Redirect URL |
| Tag where leads came from | Lead Source |
| See why a submission failed | Interaction Status, Audit Reason, the Errors tab |
