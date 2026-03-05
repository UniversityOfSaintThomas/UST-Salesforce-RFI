# Quick Start: Unified Question Manager

**Component Name:** Unified Question Manager  
**Use Case:** Manage ALL RFI form questions in one place  
**Replaces:** RFI Field Manager + RFI Additional Questions Interactions

---

## Adding to Page Layout

1. Go to any RFI Controller record
2. Click ⚙️ (gear icon) → **Edit Page**
3. From the left sidebar, find **Unified Question Manager**
4. Drag it onto the page (recommend placing it in a prominent tab)
5. **Save** → **Activate**
6. (Optional) Remove old components: RFI Field Manager, RFI Additional Questions Interactions

---

## First Time Use (Migration)

When you open the component for the first time:

1. **Orange banner appears:** "Auto-migrated from legacy structure"
2. All your existing questions appear in order:
   - Top custom questions
   - Pre-configured fields (First Name, Email, etc.)
   - Bottom custom questions
3. Click **"Save Configuration"** to finalize
4. Banner disappears - you're now using the unified structure!

**Note:** Your old fields are NOT deleted. They remain as a backup.

---

## Adding Questions

### Add Pre-configured Question

1. Click **"Add Pre-configured Question"**
2. Select from dropdown (First Name, Email, Academic Interest, etc.)
3. Component automatically maps to correct Interaction field
4. Question appears at bottom of list
5. Drag to reorder if needed

### Add Custom Question

1. Click **"Add Custom Question"**
2. Fill in form:
   - **Question Label:** The text users see (e.g., "What program interests you?")
   - **Question Type:** Text box, Textarea, Picklist, Email, Static content
   - **Interaction Field API Name:** Where to store the answer (e.g., `Program_Interest__c`)
   - **Picklist Values:** (if picklist type) One per line
   - **Help Text:** (optional) Additional guidance for users
   - **Required:** Check if mandatory
3. Click **"Save"**
4. Question appears at bottom - drag to reorder

---

## Managing Questions

### Reorder Questions

**Drag-and-drop:**
- Click and drag the ≡ icon on the left
- Drop wherever you want in the list

**Arrow buttons:**
- Click ↑ to move up one position
- Click ↓ to move down one position

### Edit Question

**Inline editing:**
- Click in the label field to change the text
- Check/uncheck "Required" checkbox

**Full edit:**
- Click ✏️ (edit icon) for advanced settings
- Modify question type, field mapping, etc.
- Click **"Save"**

### Delete Question

- Click 🗑️ (delete icon)
- Question is removed immediately
- **Exception:** First Name and Last Name cannot be deleted (always required)

---

## Understanding Question Types

### Pre-configured Questions (Blue Badge)

These are standard fields from the original RFI design:
- First Name, Last Name, Email
- Academic Interest, Citizenship
- Address, Phone, Birthdate
- Tell us about yourself, etc.

**Benefits:**
- Automatic field mapping
- Consistent labeling
- Standard validation

### Custom Questions (Gray Badge)

Free-form questions you create:
- Any label you want
- Maps to any Interaction__c field
- Flexible question types

**Use cases:**
- Program-specific questions
- Conditional follow-ups
- Static informational content

---

## Question Display Types

| Type | Description | Example |
|------|-------------|---------|
| **Text box** | Single-line input | "Middle Initial" |
| **Text box required** | Single-line, mandatory | "Student ID" |
| **Textarea** | Multi-line input | "Why are you interested?" |
| **Textarea required** | Multi-line, mandatory | "Essay response" |
| **Email** | Email validation | "Alternate email" |
| **Email required** | Email, mandatory | "Contact email" |
| **Picklist** | Dropdown selection | "Preferred contact method" |
| **Picklist required** | Dropdown, mandatory | "Are you a veteran?" |
| **Static content** | HTML display only | Instructions, disclaimers |

---

## Best Practices

### ✅ Do

- Put most important questions first (First Name, Last Name, Email)
- Group related questions together (all address fields)
- Use descriptive labels ("Email Address" not just "Email")
- Add help text for questions that might confuse users
- Test the form after making changes

### ❌ Don't

- Delete First Name or Last Name (system prevents this)
- Use technical jargon in labels (users won't understand)
- Create duplicate questions
- Forget to click "Save Configuration"

---

## Saving & Testing

### Save Your Changes

1. Make all desired changes (add, edit, reorder, delete)
2. Click **"Save Configuration"** (bottom right)
3. Wait for green success message
4. Changes are now live!

### Test the Form

1. Get your RFI form URL (usually from the RFI Controller record)
2. Open in incognito/private browser window
3. Verify questions appear in correct order
4. Submit a test form
5. Check that data saves to Interaction record

---

## Troubleshooting

### Questions not appearing in correct order

- Make sure you clicked "Save Configuration"
- Refresh the page
- Clear browser cache

### Can't add pre-configured question

- Question might already be in the list (check carefully)
- Try scrolling - it might be there

### Changes not appearing on form

- Clear cache on public form
- Check that form is using the correct RFI Controller record
- Verify Apex cache hasn't retained old structure (wait 5 minutes or clear platform cache)

### Migration banner won't go away

- Click "Save Configuration"
- If it persists after save, refresh the page

---

## Getting Help

**See also:**
- `UNIFIED_QUESTION_MANAGER_PLAN.md` - Technical architecture
- `UNIFIED_QUESTIONS_FIELD_CREATION.md` - Field setup guide  
- `UNIFIED_QUESTION_MANAGER_SUMMARY.md` - Complete implementation details

**Questions?** Check inline help text in the component or refer to the planning documents.

---

## Quick Reference: Keyboard Shortcuts

| Action | Method |
|--------|--------|
| Reorder | Drag ≡ icon |
| Move up | Click ↑ |
| Move down | Click ↓ |
| Edit inline | Click in label field |
| Edit full | Click ✏️ icon |
| Delete | Click 🗑️ icon |
| Save | Click "Save Configuration" |

---

**You're all set! Start managing your RFI questions in one unified tool.** 🎉

