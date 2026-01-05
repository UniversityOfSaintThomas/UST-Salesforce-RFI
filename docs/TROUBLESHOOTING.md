# UST Salesforce RFI - Troubleshooting Guide

## Common Issues and Solutions

---

## Interaction Questions Component

### Error: "No such column 'Interaction_Questions__c'"

**Symptoms:**
- Component shows error on page load
- Message: "Failed to load questions: INVALID_FIELD ... No such column 'Interaction_Questions__c'"

**Cause:**
Field wasn't created in Salesforce (CLI deployment tracking issue)

**Solution:**
Create field manually:
1. Setup → Object Manager → RFI Controller
2. Fields & Relationships → New
3. Type: Text Area (Long), Length: 131072, Name: `Interaction_Questions`
4. Save

See [INTERACTION_QUESTIONS_SETUP.md](INTERACTION_QUESTIONS_SETUP.md) for detailed steps.

### Drag-and-Drop Not Working

**Symptoms:**
- Can't drag questions to reorder
- Drag handle doesn't respond

**Solutions:**
1. **Use arrow buttons instead** - Click ↑↓ buttons to reorder
2. **Try different browser** - Chrome/Firefox/Edge recommended
3. **Check browser version** - Update to latest version
4. **Clear browser cache** - Force refresh (Ctrl+Shift+R)

### Fields Not Showing in Dropdown

**Symptoms:**
- "Interaction Field to Apply to" dropdown is empty
- No fields available to select

**Cause:**
No updateable custom fields on Interaction__c object

**Solution:**
Create custom fields on Interaction object:
1. Setup → Object Manager → Interaction
2. Fields & Relationships → New
3. Create fields as needed (Text, Email, Picklist, etc.)

### Questions Not Saving

**Symptoms:**
- Click "Save" but question doesn't appear
- Error toast message appears

**Check:**
1. **Field permissions** - User has edit access to `Interaction_Questions__c`
2. **Object permissions** - User can edit RFI_Controller__c records
3. **Browser console** - Check for JavaScript errors (F12)
4. **Salesforce logs** - Debug → Debug Logs

**Solution:**
Grant permissions:
- Setup → Users → [User] → Permission Sets
- Or Setup → Object Manager → RFI Controller → Fields → Interaction Questions → Set Field-Level Security

---

## Academic Interest Selector

### Selections Not Saving

**Symptoms:**
- Move items to "Selected" list
- Refresh page and selections are gone

**Check:**
1. **Field exists** - `Academic_Interests_To_Display__c` on RFI_Controller__c
2. **User permissions** - Edit access to field
3. **Browser console** - JavaScript errors

**Solution:**
1. Verify field exists: Setup → Object Manager → RFI Controller → Fields
2. Grant edit permission on field
3. Check browser console (F12) for errors

### Programs Not Appearing

**Symptoms:**
- "Available" list is empty or missing programs
- Expected programs don't show

**Cause:**
Program data not loaded from Academic Interest object

**Check:**
1. Academic Interest records exist
2. Records have values in: `hed__Account__c`, `Degree_Type__c`, `Academic_Program__c`
3. User has read access to Academic Interest object

**Solution:**
1. Verify records: Setup → Object Manager → Academic Interest → Records
2. Grant read permission: Setup → Permission Sets

---

## RFI Field Manager

### Fields Not Showing

**Symptoms:**
- Expected fields don't appear in field manager
- Field list is incomplete

**Cause:**
Fields filtered by type or accessibility

**Check:**
1. Field is updateable
2. Field is not read-only formula
3. User has access to field

**Solution:**
Component only shows fields that:
- Are updateable (not read-only)
- User has FLS (Field-Level Security) access
- Are not system fields

---

## Deployment Issues

### Component Not Deploying

**Symptoms:**
```
Error: Could not process MDAPI response
```

**Solutions:**

1. **Check syntax errors**
   ```powershell
   # Validate before deploying
   sf project deploy validate --source-dir force-app/main/default/lwc/componentName
   ```

2. **Check API version compatibility**
   - Component meta.xml should match sfdx-project.json (64.0)

3. **Clear local cache**
   ```powershell
   Remove-Item -Path ".sf" -Recurse -Force
   Remove-Item -Path ".sfdx" -Recurse -Force
   ```

4. **Use targeted deploy**
   ```powershell
   # Deploy specific component
   cci task run deploy --path force-app/main/default/lwc/componentName --org dev
   ```

### Field Deployment Shows "Unchanged" But Doesn't Exist

**Symptoms:**
- Deploy says "Unchanged"
- Field doesn't exist in org
- Query fails with "No such column"

**Cause:**
Salesforce CLI source tracking cache issue

**Solution:**
Deploy entire object instead of just fields:
```powershell
# Deploy whole object
cci task run deploy --path force-app/main/default/objects/RFI_Controller__c --org dev
```

Or create field manually (more reliable).

---

## General Issues

### Component Not Appearing on Page

**Check:**
1. **Deployed** - Component exists in org
2. **Page layout** - Component added to flexipage
3. **Permissions** - User can view component
4. **Record type** - Page assignment matches record type

**Solution:**
1. Verify deployment:
   ```powershell
   sf data query --query "SELECT Id, DeveloperName FROM LightningComponentBundle WHERE DeveloperName LIKE '%componentName%'" --org dev
   ```

2. Check page layout: Setup → Lightning App Builder → Edit Page

3. Assign page: Gear icon → Activate → Assign as Org Default

### "Script Error" or JavaScript Errors

**Check:**
1. **Browser console** (F12) for detailed error
2. **Component version** - Ensure latest deployed
3. **Cached resources** - Hard refresh (Ctrl+Shift+R)

**Solution:**
1. Check debug logs
2. Redeploy component
3. Clear browser cache
4. Try incognito mode

### Toast Notifications Not Showing

**Check:**
1. Browser supports toast notifications
2. Not blocked by browser settings
3. Component properly imports ShowToastEvent

**Solution:**
Check browser console - errors may be showing there instead.

---

## Performance Issues

### Component Loads Slowly

**Causes:**
- Large amount of data
- Complex queries
- Network latency

**Solutions:**
1. **Reduce data volume** - Archive old records
2. **Add indexes** - On frequently queried fields
3. **Optimize queries** - Use selective filters

### Page Crashes When Loading Many Questions

**Cause:**
Too many questions in JSON (approaching 131KB limit)

**Solution:**
1. **Remove unused questions** - Keep only active questions
2. **Shorten labels/values** - Use concise text
3. **Split configurations** - Use multiple RFI Controllers if needed

---

## Data Issues

### Questions Displaying Incorrectly

**Check:**
1. **JSON format** - Valid JSON in storage field
2. **Field mappings** - Correct field API names
3. **Picklist values** - Match field picklist values

**Solution:**
1. View raw JSON: Setup → Object Manager → RFI Controller → [Record] → View JSON
2. Validate JSON format: Use online JSON validator
3. Fix and re-save through component

### Data Not Saving to Lead/Interaction

**Check:**
1. **Field mappings** - Question maps to existing field
2. **Field types match** - Email question to Email field, etc.
3. **Required fields** - All required fields have values
4. **Validation rules** - No validation rules blocking insert

**Solution:**
1. Check field API names match exactly
2. Review validation rules: Setup → Object Manager → [Object] → Validation Rules
3. Check debug logs for errors

---

## Browser-Specific Issues

### Internet Explorer

**Status:** Not supported

**Solution:** Use modern browser (Chrome, Firefox, Edge, Safari)

### Safari

**Known Issues:**
- Drag-and-drop may be laggy
- Some CSS animations may differ

**Solution:** Use arrow buttons for reordering if drag is problematic

### Mobile Browsers

**Known Issues:**
- Drag-and-drop may not work
- Modal may need scrolling

**Solution:** Component is responsive but best used on desktop for admin tasks

---

## Getting Help

### Before Reporting an Issue

1. **Check this guide** - Common issues listed above
2. **Check browser console** - F12 for detailed errors
3. **Check debug logs** - Setup → Debug Logs
4. **Test in sandbox** - Reproduce in non-production org
5. **Clear cache** - Hard refresh browser

### Information to Provide

When reporting issues, include:
- **Component name** - Which LWC component
- **Error message** - Exact error text
- **Steps to reproduce** - What you did before error
- **Browser/version** - Chrome 120, Firefox 115, etc.
- **Org type** - Sandbox, dev, production
- **Screenshots** - If applicable
- **Console logs** - From browser (F12)

### Diagnostic Commands

```powershell
# Check component deployment
sf data query --query "SELECT Id, DeveloperName, ApiVersion FROM LightningComponentBundle WHERE DeveloperName LIKE '%rfi%'" --org dev

# Check field existence
sf data query --query "SELECT QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'RFI_Controller__c'" --org dev

# Test field query
sf data query --query "SELECT Id, Name, Interaction_Questions__c FROM RFI_Controller__c LIMIT 1" --org dev

# View org info
cci org info dev
```

---

## Preventive Measures

### Before Deploying

1. **Test in sandbox** - Always test first
2. **Backup configuration** - Export JSON before changes
3. **Document changes** - Keep change log
4. **Review permissions** - Ensure users have access
5. **Validate syntax** - Check for errors before deploy

### Regular Maintenance

1. **Review questions** - Remove unused quarterly
2. **Update documentation** - Keep field mappings current
3. **Monitor logs** - Check for recurring errors
4. **Test functionality** - Verify end-to-end quarterly
5. **Update browsers** - Keep browsers current

---

**Last Updated:** January 5, 2026  
**For additional help:** See [MAIN_GUIDE.md](MAIN_GUIDE.md)

