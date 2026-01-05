# UST Salesforce RFI - Documentation

## Overview

This project provides Lightning Web Components (LWC) for managing Request for Information (RFI) forms at the University of St. Thomas. The system allows administrators to configure forms and collect information from prospective students.

---

## Quick Start

### For Administrators
1. **Configure Academic Interests**: Use `academicInterestSelector` component on RFI Controller records
2. **Manage Lead Questions**: Use `rfiAdditionalQuestions` component
3. **Manage Interaction Questions**: Use `rfiAdditionalQuestionsInteractions` component (requires field setup)
4. **Configure Fields**: Use `rfiFieldManager` component

### For Developers
```powershell
# Deploy to dev org
cci task run deploy --path force-app/main/default --org dev

# Targeted deploys
cci task run deploy --path force-app/main/default/lwc/componentName --org dev
```

---

## Components

### 1. Academic Interest Selector
**Purpose:** Admin tool to select which academic programs appear on public RFI forms

**Features:**
- Dual-listbox interface with search
- Grouped by school and degree type
- Auto-saves selections
- No selection limits

**Usage:**
- Add to RFI Controller record page
- Select programs from left list
- Move to right list to display on forms
- Selections save automatically

**Fields Used:**
- `Academic_Interests_To_Display__c` - Stores selected program codes

### 2. RFI Additional Questions (Leads)
**Purpose:** Manage custom questions that map to Lead fields

**Features:**
- DataTable interface
- Question types: Email, Picklist, Text box, Textarea, Static content
- Position control (top/bottom)
- Maps to Lead object fields

**Fields Used:**
- `Additional_Questions__c` - Stores question configuration (JSON)

### 3. RFI Additional Questions Interactions ⭐ NEW
**Purpose:** Manage custom questions that map to Interaction fields

**Features:**
- Modern card-based UI
- Drag-and-drop sorting
- Modal-based editing
- Toast notifications
- Question types: Email, Picklist, Text box, Textarea, Static content

**Setup Required:**
1. Create field: `Interaction_Questions__c` (Long Text Area, 131072 chars)
   - Setup → Object Manager → RFI Controller → Fields & Relationships → New
2. Add component to page layout
3. Start adding questions

**Fields Used:**
- `Interaction_Questions__c` - Stores question configuration (JSON)

**Documentation:**
- [Complete Guide](RFI_INTERACTION_QUESTIONS_GUIDE.md)
- [Setup Instructions](INTERACTION_QUESTIONS_SETUP.md)

### 4. RFI Field Manager
**Purpose:** Configure which fields appear on RFI forms and their order

**Features:**
- Field selection and ordering
- Required field configuration
- Custom field labels

### 5. RFI Form Components
**Components:**
- `rfiForm` - Modern public-facing form
- `requestForInformationForm` - Legacy form (still in use)

---

## Deployment

### Prerequisites
- Salesforce CLI or CumulusCI installed
- Access to target org
- Admin permissions

### Standard Deployment
```powershell
# Full deployment
cci task run deploy --path force-app/main/default --org dev

# Component-specific
cci task run deploy --path force-app/main/default/lwc/academicInterestSelector --org dev
```

### Interaction Questions Component
```powershell
# 1. Deploy component
cci task run deploy --path force-app/main/default/lwc/rfiAdditionalQuestionsInteractions --org dev

# 2. Create field manually (CLI deployment has known issues)
# Setup → Object Manager → RFI Controller → Fields → New
# Type: Text Area (Long), Length: 131072, Name: Interaction_Questions

# 3. Add to page layout
cci task run deploy --path force-app/main/default/flexipages --org dev
```

### Verification
```powershell
# Open org
cci org browser dev

# Verify components on RFI Controller record page
```

---

## Architecture

### Data Flow
```
Public User → RFI Form (LWC) → Lead/Interaction Object → Salesforce
                ↑
         RFI Controller
         (Configuration)
```

### Configuration Storage
- **Academic Programs**: `Academic_Interests_To_Display__c` (Multi-select picklist)
- **Lead Questions**: `Additional_Questions__c` (Long Text Area JSON)
- **Interaction Questions**: `Interaction_Questions__c` (Long Text Area JSON)
- **Field Configuration**: Various fields on `RFI_Controller__c`

### JSON Structure (Questions)
```json
[
  {
    "id": 0,
    "questionLabel": "What is your email?",
    "questionType": "Email required",
    "fieldToApplyTo": "Email",
    "assistiveText": "We'll use this to contact you",
    "position": "top",
    "isRequired": true,
    "isEmail": true,
    "picklistValues": [],
    "valuesFlat": ""
  }
]
```

---

## Troubleshooting

### Interaction Questions Component Not Loading
**Error:** "No such column 'Interaction_Questions__c'"

**Solution:** Field wasn't created. Create manually:
1. Setup → Object Manager → RFI Controller
2. Fields & Relationships → New
3. Text Area (Long), Length: 131072
4. Field Name: `Interaction_Questions`

### Academic Interest Selector Not Saving
**Check:**
1. Field `Academic_Interests_To_Display__c` exists
2. User has edit permissions on RFI Controller
3. Browser console for errors

### Drag-and-Drop Not Working (Interactions)
**Solutions:**
1. Use arrow buttons instead (↑↓)
2. Try different browser
3. Check browser console for errors

---

## Best Practices

### Configuration
1. **Test in sandbox first** - Always test configuration changes before production
2. **Document custom fields** - Keep track of which fields map to which questions
3. **Use descriptive labels** - Make questions clear for users
4. **Limit required fields** - Too many required fields reduce completion rates

### Development
1. **Use targeted deploys** - Don't rebuild entire org for small changes
   ```powershell
   # Good
   cci task run deploy --path force-app/main/default/lwc/componentName --org dev
   
   # Avoid (rebuilds entire org)
   cci flow run dev_org --org dev
   ```

2. **Follow LWC reactivity patterns** - Create new objects instead of mutating
   ```javascript
   // Good
   this.data = {...this.data, newProperty: value};
   
   // Bad (won't trigger re-render)
   this.data.newProperty = value;
   ```

3. **Test deployments** - Verify after each deployment
   ```powershell
   cci task run deploy --path ... --org dev
   cci org browser dev
   ```

---

## Support

### Resources
- **CumulusCI Docs**: https://cumulusci.readthedocs.io/
- **Salesforce LWC Docs**: https://developer.salesforce.com/docs/component-library/documentation/en/lwc
- **Project README**: ../README.md

### Common Issues
See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed solutions to common problems.

---

**Last Updated:** January 5, 2026  
**Version:** 2.0 (Consolidated)

