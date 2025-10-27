# RFI Field Manager Component

## Overview
The RFI Field Manager is a custom Lightning Web Component designed for the RFI Controller object. This component provides a unified interface to manage form fields, their display order, labels, and required status.

## Features

### 1. **Field Display Management**
- Displays all fields currently configured in the "Fields to Display" field
- Visual list interface for easy field management

### 2. **Drag and Drop Sorting**
- Intuitive drag-and-drop functionality to reorder fields
- Visual feedback during drag operations
- Changes are immediately reflected in the component

### 3. **Label Editing**
- Each field has an editable label input
- Labels are synchronized with corresponding label fields on the RFI Controller object
- Supports custom labels for all available fields

### 4. **Required Field Management**
- Checkbox for each field to mark it as required
- Required status is stored in the "Required Fields" field
- Easy visual identification of required fields

### 5. **Data Persistence**
- Single "Save Changes" button to persist all modifications
- Updates three key areas:
  - **Fields to Display**: Ordered list of selected fields
  - **Required Fields**: List of fields marked as required
  - **Label Fields**: Individual label fields for each form field

## Field Mapping

The component maps form fields to their corresponding label fields:

| Field Name | Label Field |
|------------|-------------|
| Academic Interest | Academic_Interest_Label__c |
| Address 1, 2, 3, City, Country | Address_Label__c |
| Birthdate | Birthdate_Label__c |
| Citizenship | Citizenship_Label__c |
| Company | Company_Label__c |
| Email | Email_Label__c |
| Employer | Employer_Label__c |
| Expected Start Term | Expected_Start_Term_Label__c |
| First Name | First_Name_Label__c |
| High School Attended | High_School_Attended_Label__c |
| High School Graduation Year | High_School_Graduation_Year_Label__c |
| Home and Mobile Phone | Phone_Label__c |
| How did you hear about us | How_Did_You_Hear_About_Us_Label__c |
| I have a question | I_Have_A_Question_Label__c |
| I will apply to St Thomas as a | Apply_To_St_Thomas_As_Label__c |
| Last Name | Last_Name_Label__c |
| Mail Information | Mail_Information_Label__c |
| Receive Text Messages | Receive_Text_Messages_Label__c |
| Scholarship of Interest | Scholarship_Of_Interest_Label__c |
| St Thomas Colleges | St_Thomas_Colleges_Label__c |
| Tell us about yourself | Tell_Us_About_Yourself_Label__c |
| Timeline to Enrollment | Timeline_To_Enrollment_Label__c |
| Title | Title_Label__c |
| When Start School | When_Start_School_Label__c |

## Installation & Setup

### 1. Deploy the Component
Deploy the following files to your Salesforce org:
```
force-app/main/default/lwc/rfiFieldManager/
├── rfiFieldManager.js
├── rfiFieldManager.html
├── rfiFieldManager.css
└── rfiFieldManager.js-meta.xml
```

### 2. Add to Record Page
1. Navigate to an RFI Controller record
2. Click the gear icon and select "Edit Page"
3. Find "RFI Field Manager" in the custom components section
4. Drag it onto the page layout
5. Save and activate the page

### 3. Configure Initial Fields
Before using the component:
1. Ensure the "Fields to Display" field on the RFI Controller record has values selected
2. The component will load these fields automatically
3. You can then reorder, edit labels, and mark fields as required

## Usage

### Reordering Fields
1. Click and hold on the drag handle (≡ icon) for any field
2. Drag the field up or down to the desired position
3. Release to drop the field in its new position

### Editing Labels
1. Click in the "Display Label" input field
2. Type the desired label text
3. The label will be saved when you click "Save Changes"

### Marking Fields as Required
1. Check the "Required" checkbox for any field that should be mandatory
2. Uncheck to make a field optional
3. Changes are saved when you click "Save Changes"

### Saving Changes
1. After making any modifications, click the "Save Changes" button
2. A success toast message will appear when changes are saved
3. If there's an error, an error message will display with details

## Technical Details

### Component Structure
- **Language**: JavaScript (Lightning Web Components)
- **API Version**: 64.0
- **Dependencies**:
  - `lightning/uiRecordApi` - For record CRUD operations
  - `lightning/platformShowToastEvent` - For user notifications
  - `lightning/uiObjectInfoApi` - For picklist values

### Data Storage
- **Fields to Display**: Stored as semicolon-separated values (e.g., "Email;First Name;Last Name")
- **Required Fields**: Stored as semicolon-separated values
- **Labels**: Stored in individual text fields on the RFI Controller object

### Responsive Design
- Desktop: Fields displayed in a 12-column grid
- Mobile: Stacks vertically for better usability on smaller screens

## Troubleshooting

### Component doesn't load
- Verify the RFI Controller record has values in the "Fields to Display" field
- Check that all required label fields exist on the object

### Can't drag and drop
- Ensure you're using a modern browser (Chrome, Firefox, Safari, Edge)
- Try clicking directly on the drag handle icon

### Changes not saving
- Check field-level security for all label fields
- Verify you have edit permissions on the RFI Controller object
- Check browser console for error messages

## Future Enhancements
Potential improvements for future versions:
- Add/remove fields directly from the component
- Bulk import/export field configurations
- Field validation rules management
- Preview mode to see how the form will appear
- Undo/redo functionality

## Support
For issues or questions, please contact your Salesforce administrator or development team.

