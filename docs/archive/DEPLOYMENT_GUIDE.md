# RFI Field Manager - Deployment Guide

## Overview
This guide provides step-by-step instructions for deploying and using the RFI Field Manager component.

## What Was Created

### 1. Lightning Web Component Files
- **rfiFieldManager.js** - Main component logic with drag-drop and data management
- **rfiFieldManager.html** - Component template with sortable field list UI
- **rfiFieldManager.css** - Styling for drag-drop interactions and responsive layout
- **rfiFieldManager.js-meta.xml** - Component metadata and configuration
- **README.md** - Component documentation

### 2. Updated Record Page
- **RFI_Controller_Record_Page.flexipage-meta.xml** - Added component to the Detail tab

## Pre-Deployment Checklist

Before deploying, verify:
- [ ] You have deployment access to the target Salesforce org
- [ ] The RFI_Controller__c custom object exists
- [ ] The following fields exist on RFI_Controller__c:
  - Fields_to_Display__c (Multiselect Picklist)
  - Required_Fields__c (Multiselect Picklist)
  - All label fields (e.g., Academic_Interest_Label__c, Address_Label__c, etc.)

## Deployment Options

### Option 1: Using Salesforce CLI (Recommended)

#### Step 1: Authenticate to Your Org
```bash
# For production/developer orgs
sf org login web --alias myorg

# For scratch orgs
sf org login web --alias myorg --instance-url https://test.salesforce.com
```

#### Step 2: Deploy the Component
```bash
# Deploy just the LWC component
sf project deploy start --source-dir force-app/main/default/lwc/rfiFieldManager

# Deploy component and updated record page
sf project deploy start --source-dir force-app/main/default/lwc/rfiFieldManager,force-app/main/default/flexipages/RFI_Controller_Record_Page.flexipage-meta.xml
```

#### Step 3: Verify Deployment
```bash
sf project deploy report --job-id <JOB_ID>
```

### Option 2: Using VS Code with Salesforce Extensions

#### Step 1: Open Command Palette
- Press `Ctrl+Shift+P` (Windows) or `Cmd+Shift+P` (Mac)

#### Step 2: Deploy Component
1. Right-click on the `rfiFieldManager` folder
2. Select "SFDX: Deploy Source to Org"
3. Wait for deployment to complete

#### Step 3: Deploy Record Page (Optional)
1. Right-click on `RFI_Controller_Record_Page.flexipage-meta.xml`
2. Select "SFDX: Deploy Source to Org"

### Option 3: Using Change Sets (Production)

#### Step 1: Create Change Set in Source Org
1. Go to Setup → Environments → Change Sets
2. Click "New" under Outbound Change Sets
3. Name it "RFI Field Manager Component"

#### Step 2: Add Components
1. Add "Lightning Component Bundle" → rfiFieldManager
2. Add "Lightning Page" → RFI_Controller_Record_Page (if updated)
3. Add any dependencies if prompted

#### Step 3: Upload and Deploy
1. Upload to target org
2. In target org, go to Inbound Change Sets
3. Deploy the change set

### Option 4: Manual Deployment via Setup

#### Step 1: Create Component in Setup
1. Go to Setup → Custom Code → Lightning Components
2. Click "New"
3. Name: rfiFieldManager
4. Copy and paste contents from each file

#### Step 2: Update Record Page
1. Navigate to an RFI Controller record
2. Click gear icon → Edit Page
3. Add "rfiFieldManager" component from custom components
4. Save and activate

## Post-Deployment Configuration

### Step 1: Verify Component is Available
1. Navigate to Setup → Custom Code → Lightning Components
2. Search for "rfiFieldManager"
3. Verify it appears in the list

### Step 2: Add to Record Page (if not already done)
1. Go to any RFI Controller record
2. Click the gear icon → Edit Page
3. In the Lightning App Builder:
   - Find "RFI Field Manager" in the Custom components section
   - Drag it to the desired location (recommended: Detail tab)
   - Click Save
   - Click Activate
   - Choose activation options (Org Default, App Default, etc.)

### Step 3: Test the Component
1. Open an RFI Controller record
2. Navigate to the Detail tab
3. You should see the "RFI Field Configuration" card
4. Verify fields are displayed correctly

## Initial Setup for End Users

### Step 1: Configure Fields to Display
Before using the component, ensure the RFI Controller record has:
1. At least one value selected in "Fields to Display" field
2. (Optional) Values in "Required Fields" field
3. (Optional) Custom labels in individual label fields

### Step 2: Grant Permissions
Ensure users have:
- Read/Write access to RFI_Controller__c object
- Edit permission on all field types:
  - Fields_to_Display__c
  - Required_Fields__c
  - All label fields

## Testing the Component

### Test Case 1: Load Existing Configuration
1. Open an RFI Controller record with existing field configuration
2. Verify fields appear in correct order
3. Verify labels match configured values
4. Verify required checkboxes match Required Fields setting

### Test Case 2: Reorder Fields
1. Drag a field from position 1 to position 3
2. Click "Save Changes"
3. Refresh the page
4. Verify the new order persists

### Test Case 3: Edit Labels
1. Change the label of any field
2. Click "Save Changes"
3. Check the corresponding label field on the record
4. Verify the value updated correctly

### Test Case 4: Toggle Required Status
1. Check "Required" for a field that wasn't required
2. Uncheck "Required" for a field that was required
3. Click "Save Changes"
4. Check the "Required Fields" field value
5. Verify it reflects the changes

## Troubleshooting

### Component Doesn't Appear on Record Page
**Cause**: Component not deployed or not added to page layout
**Solution**: 
- Verify deployment completed successfully
- Check Lightning App Builder to ensure component is on the page
- Refresh browser cache (Ctrl+Shift+R)

### "No fields configured" Message Appears
**Cause**: Fields_to_Display__c has no values
**Solution**:
- Edit the RFI Controller record
- Select at least one field in "Fields to Display"
- Save the record
- Refresh the page

### Drag and Drop Not Working
**Cause**: Browser compatibility or JavaScript error
**Solution**:
- Check browser console for errors (F12)
- Try a different browser (Chrome, Firefox, Edge)
- Clear browser cache and cookies

### Save Fails with Error
**Cause**: Permission issues or field validation
**Solution**:
- Check user has edit permissions on all label fields
- Verify no validation rules are blocking the update
- Check browser console for specific error messages

### Labels Not Updating
**Cause**: Field mapping issue or permission problem
**Solution**:
- Verify the label field exists for that field type
- Check field-level security on label fields
- Ensure label field is not read-only

### Changes Don't Persist
**Cause**: Caching or permission issues
**Solution**:
- Hard refresh the browser (Ctrl+Shift+R)
- Check user has edit permission on the record
- Verify no process builders or flows are overwriting values

## Rollback Procedure

If you need to remove the component:

### Option 1: Remove from Page Only
1. Edit the RFI Controller record page
2. Delete the rfiFieldManager component
3. Save and activate

### Option 2: Full Uninstall
1. Remove component from all Lightning pages
2. Delete via Salesforce CLI:
   ```bash
   sf project delete source --metadata LightningComponentBundle:rfiFieldManager
   ```
3. Or delete via Setup → Lightning Components

## Monitoring and Maintenance

### Regular Checks
- Monitor debug logs for any JavaScript errors
- Verify component loads within 3 seconds
- Check that drag-drop functionality works across browsers

### Updates and Enhancements
When making changes:
1. Test in sandbox first
2. Deploy during maintenance window
3. Notify users of new features
4. Update documentation as needed

## Support Contacts

For issues with:
- **Deployment**: Contact your Salesforce administrator
- **Functionality**: Check README.md in the component folder
- **Bugs**: Report to development team with:
  - Browser and version
  - Steps to reproduce
  - Expected vs actual behavior
  - Screenshots if applicable

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-10-27 | Initial release with drag-drop, label editing, and required field management |

## Additional Resources

- [Lightning Web Components Developer Guide](https://developer.salesforce.com/docs/component-library/documentation/en/lwc)
- [Lightning App Builder](https://help.salesforce.com/s/articleView?id=sf.lightning_app_builder_overview.htm)
- [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/)

