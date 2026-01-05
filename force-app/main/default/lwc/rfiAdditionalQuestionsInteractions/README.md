# RFI Additional Questions - Interactions Component

## Quick Start

A modern Lightning Web Component for managing interaction questions in RFI forms with drag-and-drop sorting and modal-based editing.

## Features
✅ Drag-and-drop question reordering  
✅ Modal-based inline editing  
✅ Toast notifications for user feedback  
✅ Support for multiple question types (Email, Picklist, Text, Textarea, Static content)  
✅ Maps to Interaction__c object fields  
✅ Responsive design  
✅ Accessibility compliant  

## Deployment

### Quick Deploy
```powershell
.\deploy-interaction-questions.ps1
```

### Manual Deploy
```powershell
# Deploy field
cci task run deploy --path force-app/main/default/objects/RFI_Controller__c/fields/Interaction_Questions__c.field-meta.xml --org dev

# Deploy component
cci task run deploy --path force-app/main/default/lwc/rfiAdditionalQuestionsInteractions --org dev
```

## Files Created
- `rfiAdditionalQuestionsInteractions.js` - Main controller
- `rfiAdditionalQuestionsInteractions.html` - Template with drag-drop UI
- `rfiAdditionalQuestionsInteractions.css` - Drag-drop styling
- `rfiAdditionalQuestionsInteractions.js-meta.xml` - Metadata
- `Interaction_Questions__c.field-meta.xml` - Storage field
- `__tests__/rfiAdditionalQuestionsInteractions.test.js` - Jest tests

## Usage

1. **Add to Page**: Edit RFI Controller record page and add component
2. **Add Question**: Click "Add Question" button
3. **Reorder**: Drag questions or use arrow buttons
4. **Edit**: Click edit icon on any question
5. **Delete**: Click delete icon

## Documentation
See [RFI_INTERACTION_QUESTIONS_GUIDE.md](../docs/RFI_INTERACTION_QUESTIONS_GUIDE.md) for complete documentation.

## Differences from Original Component

| Feature | Original (Leads) | New (Interactions) |
|---------|-----------------|-------------------|
| UI | DataTable | Card list |
| Reordering | Buttons only | Drag-drop + buttons |
| Editing | Inline | Modal |
| Object | Lead | Interaction__c |
| Field | Additional_Questions__c | Interaction_Questions__c |

## Testing
```powershell
npm run test:unit
```

---
**Version:** 1.0  
**Created:** January 5, 2026  
**Author:** Thaddaeus Dahlberg

