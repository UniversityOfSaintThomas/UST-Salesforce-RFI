# RFI Interaction Questions - Setup & User Guide

## Overview

The **rfiAdditionalQuestionsInteractions** component allows administrators to create and manage custom questions that map to Interaction object fields, with modern features like drag-and-drop sorting and modal editing.

---

## Quick Setup (5 Minutes)

### Step 1: Create the Field (Manual - 2 minutes)

The `Interaction_Questions__c` field must be created manually due to Salesforce CLI tracking issues.

1. **Open Salesforce Setup**
   ```powershell
   sf org open --target-org UST-Salesforce-RFI__dev
   ```

2. **Navigate to Field Creation**
   - Setup (gear icon) → Object Manager
   - Find and click **RFI Controller**
   - Click **Fields & Relationships**
   - Click **New**

3. **Create Field**
   - Type: **Text Area (Long)**
   - Click **Next**
   
4. **Enter Details**
   ```
   Field Label:     Interaction Questions
   Length:          131072
   Visible Lines:   10
   Field Name:      Interaction_Questions  (auto-fills)
   Description:     JSON field to store interaction questions configuration
   ```

5. **Save**
   - Click **Next** → **Next** → **Save**
   - Accept all default security settings

### Step 2: Verify Deployment

The component should already be deployed. Verify:

```powershell
# Check if component exists
sf data query --query "SELECT Id FROM LightningComponentBundle WHERE DeveloperName = 'rfiAdditionalQuestionsInteractions'" --target-org UST-Salesforce-RFI__dev
```

If not deployed:
```powershell
cci task run deploy --path force-app/main/default/lwc/rfiAdditionalQuestionsInteractions --org dev
```

### Step 3: Verify Field Creation

```powershell
# This should work without errors after field creation
sf data query --query "SELECT Id, Name, Interaction_Questions__c FROM RFI_Controller__c LIMIT 1" --target-org UST-Salesforce-RFI__dev
```

### Step 4: Access the Component

1. Navigate to any **RFI Controller** record
2. The component appears on the **Detail** tab
3. Look for **"Interaction Questions Manager"** card

---

## User Guide

### Adding a Question

1. Click **"+ Add Question"** button
2. Fill in the modal form:

   **Field** | **Description** | **Required**
   ---|---|---
   Question Type | Email, Picklist, Text box, Textarea, Static content | Yes
   Position | Top or Bottom of form | Yes
   Interaction Field | Which Interaction field to populate | Yes (except static)
   Question Label | Text shown to users | Yes
   Assistive Text | Helper text for required fields | Required fields only
   Picklist Values | One value per line | Picklist types only
   Static Content | Rich text HTML | Static content only

3. Click **Save**

### Editing a Question

1. Click the **✎ (pencil)** icon on any question
2. Modify fields in the modal
3. Click **Save**

### Reordering Questions

**Method 1: Drag and Drop**
1. Click and hold the **☰ (rows icon)** on the left
2. Drag to desired position
3. Release (saves automatically)

**Method 2: Arrow Buttons**
1. Click **↑** to move up one position
2. Click **↓** to move down one position

### Deleting a Question

1. Click the **🗑 (trash)** icon
2. Question is removed immediately (no confirmation)

---

## Features

### Question Types

| Type | Description | Validation | Example Use Case |
|------|-------------|------------|------------------|
| **Email** | Email input field | Email format | "What is your email?" |
| **Email required** | Required email field | Email format + required | Primary contact email |
| **Picklist** | Dropdown selection | - | "How did you hear about us?" |
| **Picklist required** | Required dropdown | Required | Program selection |
| **Text box** | Single-line text | - | "What is your phone number?" |
| **Text box required** | Required text box | Required | Name fields |
| **Textarea** | Multi-line text | - | "Tell us about yourself" |
| **Textarea required** | Required textarea | Required | Essay questions |
| **Static content** | Rich text display only | - | Instructions, disclaimers |

### Position Options

- **Top**: Question appears at beginning of form
- **Bottom**: Question appears at end of form

### Field Filtering

The component automatically excludes tracking fields from the field dropdown:
- Fields starting with `UTM_`
- Fields starting with `GCLID`
- Fields starting with `LinkedIn_`
- Read-only formula fields
- Non-updateable fields

---

## UI Features

### Modern Interface

**Card-Based Layout**
- Each question displayed as a card
- Clear visual hierarchy
- Easy to scan and manage

**Drag Handles**
- **☰ icon** on left for drag-and-drop
- Cursor changes to indicate draggable state
- Visual feedback during drag

**Action Buttons**
- **↑↓** - Move up/down
- **✎** - Edit question
- **🗑** - Delete question

**Toast Notifications**
- Success: "Question added successfully"
- Error: "Failed to save question: [details]"
- Info: "Question order updated successfully"

### Empty State

When no questions exist:
- Helpful icon and message
- Clear call-to-action
- Guidance text

---

## Comparison with Lead Questions Component

| Feature | rfiAdditionalQuestions (Leads) | rfiAdditionalQuestionsInteractions (NEW) |
|---------|-------------------------------|----------------------------------------|
| **UI** | DataTable | Card list |
| **Editing** | Below table | Modal popup |
| **Reordering** | Buttons only | Drag-drop + buttons |
| **Feedback** | Console logs | Toast notifications |
| **Object** | Lead | Interaction__c |
| **Field** | Additional_Questions__c | Interaction_Questions__c |
| **Mobile** | Limited | Fully responsive |

---

## Troubleshooting

### Error: "No such column 'Interaction_Questions__c'"

**Cause:** Field wasn't created in Salesforce

**Solution:** Follow Step 1 above to create the field manually

### Component Not Visible on Page

**Check:**
1. Component is deployed
2. Component is added to page layout
3. User has access to RFI_Controller__c records
4. Field-level security on Interaction_Questions__c

### Drag-and-Drop Not Working

**Solutions:**
1. Use arrow buttons (↑↓) instead
2. Try a different browser (Chrome, Firefox, Edge recommended)
3. Check browser console for JavaScript errors
4. Ensure modern browser (HTML5 Drag API support required)

### Fields Not Showing in Dropdown

**Cause:** No updateable custom fields on Interaction__c object

**Solution:** Create custom fields on Interaction__c:
1. Setup → Object Manager → Interaction
2. Fields & Relationships → New
3. Create fields as needed (Text, Email, etc.)

### Questions Not Saving

**Check:**
1. User has edit permission on `Interaction_Questions__c` field
2. User has edit permission on RFI_Controller__c records
3. Browser console for errors
4. Salesforce debug logs

---

## Technical Details

### Data Storage

Questions are stored as JSON in the `Interaction_Questions__c` Long Text Area field.

**JSON Structure:**
```json
[
  {
    "id": 0,
    "questionLabel": "How did you hear about us?",
    "questionType": "Picklist required",
    "fieldToApplyTo": "Source__c",
    "assistiveText": "Please select one option",
    "position": "top",
    "isPicklist": true,
    "isRequired": true,
    "isTextBox": false,
    "isTextarea": false,
    "isRichText": false,
    "isStaticContent": false,
    "isEmail": false,
    "picklistValues": [
      {"label": "Website", "value": "Website"},
      {"label": "Email", "value": "Email"},
      {"label": "Social Media", "value": "Social Media"}
    ],
    "valuesFlat": "Website;Email;Social Media"
  }
]
```

### Limits

- **Maximum questions:** Limited by JSON size (131,072 characters)
- **Estimated capacity:** ~200-300 questions depending on complexity
- **Field length:** Each picklist value adds to total size

### Browser Compatibility

**Fully Supported:**
- Chrome 90+
- Firefox 88+
- Edge 90+
- Safari 14+

**Limited Support:**
- Older browsers may not support drag-and-drop (use arrow buttons)

---

## Best Practices

### Question Design

1. **Keep labels concise** - Short, clear questions get better responses
2. **Use assistive text** - Provide helpful context for required fields
3. **Limit required fields** - Too many reduce completion rates
4. **Test on mobile** - Ensure questions work on all devices
5. **Use appropriate types** - Email for emails, Picklist for limited options

### Field Mapping

1. **Create specific fields** - Don't reuse fields for multiple purposes
2. **Use naming conventions** - Prefix custom fields (e.g., `RFI_Source__c`)
3. **Document mappings** - Keep track of which questions map to which fields
4. **Consider data types** - Match question type to field type

### Management

1. **Group related questions** - Use position and ordering strategically
2. **Review periodically** - Remove unused questions
3. **Test before deploying** - Verify in sandbox first
4. **Back up configuration** - Export JSON before major changes

---

## Why Manual Field Creation?

The `Interaction_Questions__c` field deployment reported "Success" but wasn't actually created due to a Salesforce CLI source tracking bug:

1. Field metadata file created locally
2. CLI cached it as "existing"
3. Subsequent deploys skip it as "unchanged"  
4. But it never got pushed to the org

This is a known Salesforce issue. Manual creation is the reliable workaround.

---

## Support

**Questions or issues?**
1. Check browser console for errors
2. Review Salesforce debug logs
3. Verify field permissions
4. Test in sandbox first

**Component Location:**
```
force-app/main/default/lwc/rfiAdditionalQuestionsInteractions/
├── rfiAdditionalQuestionsInteractions.js
├── rfiAdditionalQuestionsInteractions.html
├── rfiAdditionalQuestionsInteractions.css
├── rfiAdditionalQuestionsInteractions.js-meta.xml
└── __tests__/rfiAdditionalQuestionsInteractions.test.js
```

---

**Last Updated:** January 5, 2026  
**Version:** 1.0 - Production Ready

