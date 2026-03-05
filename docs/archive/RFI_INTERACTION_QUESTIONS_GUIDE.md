# RFI Additional Questions - Interactions Component

## Overview
The `rfiAdditionalQuestionsInteractions` Lightning Web Component is an enhanced version of the original `rfiAdditionalQuestions` component, specifically designed to manage questions for the **Interaction** object instead of Leads. This component features modern UI enhancements including drag-and-drop sorting and modal-based inline editing.

## Key Features

### 1. **Drag-and-Drop Sorting**
- Questions can be reordered by dragging and dropping
- Visual feedback during drag operations (opacity change, drag-over styling)
- Automatic save to Salesforce after reordering
- Alternative arrow buttons for accessibility

### 2. **Modal-Based Editing**
- Clean modal dialog for adding and editing questions
- Inline validation with required field checks
- Separate "Add" and "Edit" modes
- All question properties editable in one place

### 3. **Enhanced UI/UX**
- Modern card-based layout
- Clear visual hierarchy with badges and icons
- Responsive design (mobile-friendly)
- Toast notifications for user feedback
- Empty state guidance

### 4. **Supported Question Types**
- Email (required/optional)
- Picklist (required/optional)
- Text box (required/optional)
- Textarea (required/optional)
- Static content (rich text)

## Component Files

```
rfiAdditionalQuestionsInteractions/
├── rfiAdditionalQuestionsInteractions.js          # Main JavaScript controller
├── rfiAdditionalQuestionsInteractions.html        # Template with drag-drop UI
├── rfiAdditionalQuestionsInteractions.css         # Styling for drag-drop
└── rfiAdditionalQuestionsInteractions.js-meta.xml # Component metadata
```

## Data Storage

Questions are stored as JSON in the new custom field:
- **Object:** `RFI_Controller__c`
- **Field:** `Interaction_Questions__c` (Long Text Area, 131,072 characters)

### JSON Structure
```json
[
  {
    "id": 0,
    "questionLabel": "How did you hear about us?",
    "questionType": "Picklist required",
    "fieldToApplyTo": "Custom_Field__c",
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
      {"label": "Email", "value": "Email"}
    ],
    "valuesFlat": "Website;Email"
  }
]
```

## Installation & Deployment

### 1. Create the Custom Field
First, deploy the new field to your org:
```powershell
cci task run deploy --path force-app/main/default/objects/RFI_Controller__c/fields/Interaction_Questions__c.field-meta.xml --org dev
```

### 2. Deploy the Component
```powershell
cci task run deploy --path force-app/main/default/lwc/rfiAdditionalQuestionsInteractions --org dev
```

### 3. Add to Record Page
1. Navigate to an RFI Controller record
2. Click the gear icon and select **Edit Page**
3. Drag the **rfiAdditionalQuestionsInteractions** component onto the page
4. Save and activate the page

## Usage Guide

### Adding a Question
1. Click the **"Add Question"** button in the component header
2. Fill in the modal form:
   - **Question Type:** Select the input type (Email, Picklist, Text box, etc.)
   - **Position:** Choose "Top" or "Bottom" placement on form
   - **Interaction Field:** Select which Interaction field to populate
   - **Question Label:** The text shown to users
   - **Assistive Text:** Helper text (required for required fields)
   - **Picklist Values:** One value per line (for picklist types)
   - **Static Content:** Rich text HTML (for static content)
3. Click **"Save"**

### Editing a Question
1. Click the **edit icon** (pencil) on any question
2. Modify fields in the modal
3. Click **"Save"**

### Reordering Questions
**Method 1: Drag and Drop**
1. Click and hold on the drag handle (rows icon) on the left
2. Drag the question to the desired position
3. Release to drop (saves automatically)

**Method 2: Arrow Buttons**
1. Click the **up arrow** to move question up one position
2. Click the **down arrow** to move question down one position

### Deleting a Question
1. Click the **delete icon** (trash can) on the right
2. Question is removed immediately (no confirmation)

## Technical Details

### Key Differences from Original Component
| Feature | Original (Leads) | New (Interactions) |
|---------|-----------------|-------------------|
| UI Layout | DataTable | Card-based list |
| Reordering | Button only | Drag-drop + buttons |
| Editing | Inline in table | Modal dialog |
| Field Source | Lead object | Interaction__c object |
| Storage Field | `Additional_Questions__c` | `Interaction_Questions__c` |
| Validation | Form-based | Modal-based |
| User Feedback | Console logs | Toast notifications |

### JavaScript Architecture
- **Reactive Properties:** Uses `@track` for reactive state management
- **Wire Service:** Loads Interaction object metadata and record data
- **LDS (Lightning Data Service):** For record updates (updateRecord)
- **Event Handling:** Drag events, click handlers, input changes
- **Validation:** Built-in Lightning component validation

### CSS Customizations
- `.question-item`: Card styling with hover effects
- `.dragging`: Visual feedback during drag
- `.drag-over`: Drop target highlight
- `.drag-handle`: Cursor changes for grab/grabbing

### Accessibility Features
- Keyboard navigation support
- ARIA labels and roles
- Alternative text for icons
- Focus management in modals
- Screen reader friendly

## Best Practices

### Configuration
1. **Field Mapping:** Only map to updatable, creatable Interaction fields
2. **Question Order:** Place most important questions at the top
3. **Assistive Text:** Always provide for required fields
4. **Picklist Values:** Use clear, concise options

### Performance
- JSON is parsed only when data changes
- Drag-drop reindexes efficiently
- Toast notifications prevent console clutter

### Maintenance
- Questions stored as JSON (easily portable)
- No dependencies on external libraries
- Standard Lightning components only
- Future-proof with modern LWC patterns

## Troubleshooting

### Component Not Appearing
- Verify the component is added to the record page
- Check `Interaction_Questions__c` field is deployed
- Ensure user has access to RFI_Controller__c records

### Drag-and-Drop Not Working
- Check browser compatibility (modern browsers required)
- Verify CSS file is deployed correctly
- Try using arrow buttons as alternative

### Fields Not Showing in Dropdown
- Verify Interaction__c object has custom fields
- Check field-level security
- Ensure fields are updateable and creatable

### Questions Not Saving
- Check user permissions on `Interaction_Questions__c`
- Verify JSON is valid (check browser console)
- Ensure record ID is valid

## Future Enhancements

Potential improvements for future versions:
- [ ] Bulk import/export questions (CSV/JSON)
- [ ] Question templates library
- [ ] Conditional logic (show/hide based on answers)
- [ ] Multi-language support
- [ ] Question preview mode
- [ ] Duplicate question feature
- [ ] Undo/redo functionality
- [ ] Search/filter questions

## Related Components

- **rfiAdditionalQuestions:** Original component for Lead questions
- **requestForInformationForm:** Main RFI form component
- **academicInterestSelector:** Academic interest picker

## Support

For issues or questions:
1. Check Salesforce debug logs
2. Review browser console for errors
3. Verify field permissions and security
4. Test in sandbox before production deployment

---

**Created by:** Thaddaeus Dahlberg, Software Engineer, University of St. Thomas  
**Last Updated:** January 5, 2026  
**Version:** 1.0

