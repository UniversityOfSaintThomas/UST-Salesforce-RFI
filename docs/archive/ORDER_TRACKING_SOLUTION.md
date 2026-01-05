# RFI Field Manager - Order Tracking Solution

## The Problem
Multiselect picklist fields in Salesforce do **not guarantee order preservation**, even with `<sorted>false</sorted>`. Salesforce may reorder the values based on internal logic.

## The Solution
Use a **separate Long Text Area field** (`Fields_to_Display_Order__c`) to track the custom order, while keeping `Fields_to_Display__c` as the source of truth for which fields are selected.

---

## How It Works

### Two-Field System

1. **Fields_to_Display__c** (Multiselect Picklist)
   - Source of truth for **which fields are selected**
   - Users can still add/remove fields here
   - May be auto-sorted by Salesforce (doesn't matter)

2. **Fields_to_Display_Order__c** (Long Text Area) 
   - Stores the **custom order** (semicolon-separated)
   - Preserves exact order set by drag & drop
   - Managed automatically by the component

### Component Logic

**On Load:**
```
1. Read Fields_to_Display_Order__c (custom order)
2. Read Fields_to_Display__c (selected fields)
3. If custom order exists:
   - Use it as the base order
   - Filter to only include selected fields
   - Append any new fields not in order
4. If no custom order:
   - Use Fields_to_Display__c order as initial
5. Display ordered list
```

**On Save:**
```
1. Get ordered field names from component
2. Save to Fields_to_Display_Order__c (preserves order)
3. Save to Fields_to_Display__c (for visibility/selection)
4. Save to Required_Fields__c
5. Save all label fields
```

---

## Deployment Steps

### Step 1: Deploy the New Field

```bash
# Deploy the Fields_to_Display_Order__c field
sf project deploy start --source-dir force-app/main/default/objects/RFI_Controller__c/fields/Fields_to_Display_Order__c.field-meta.xml
```

### Step 2: Deploy the Updated Component

```bash
# Deploy the updated component
sf project deploy start --source-dir force-app/main/default/lwc/rfiFieldManager
```

### Step 3: Test the Solution

1. Open an RFI Controller record
2. Go to Details tab
3. Open browser console (F12)
4. Drag fields to reorder them
5. Click "Save Changes"
6. Check console logs:
   ```
   Saving to Fields_to_Display_Order__c: Email;First Name;Last Name
   Saving to Fields_to_Display__c: Email;First Name;Last Name
   ```
7. Refresh the page
8. **Order should now persist!** ✅

---

## Console Logs Explained

### On Load:
```javascript
=== INITIALIZING FIELD ITEMS ===
Fields_to_Display_Order__c (custom order): Email;First Name;Last Name
Fields_to_Display__c (selected fields): Email;First Name;Last Name;Phone
Final ordered fields: (4) ["Email", "First Name", "Last Name", "Phone"]
=== END INITIALIZATION ===
```

**Note:** If someone adds "Phone" via the multiselect, it's appended to the custom order.

### On Save:
```javascript
=== SAVING FIELDS ===
Current fieldItems order: (3) ["First Name", "Email", "Last Name"]
Saving to Fields_to_Display_Order__c: First Name;Email;Last Name
Saving to Fields_to_Display__c: First Name;Email;Last Name
✅ Save successful!
```

### After Refresh:
```javascript
=== INITIALIZING FIELD ITEMS ===
Fields_to_Display_Order__c (custom order): First Name;Email;Last Name
Fields_to_Display__c (selected fields): Email;First Name;Last Name
Final ordered fields: (3) ["First Name", "Email", "Last Name"]
=== END INITIALIZATION ===
```

**Note:** Even though `Fields_to_Display__c` may be auto-sorted to "Email;First Name;Last Name", we use the custom order field!

---

## User Workflows

### Workflow 1: Reorder Existing Fields
1. User drags fields in component
2. Clicks "Save Changes"
3. `Fields_to_Display_Order__c` is updated
4. Order persists ✅

### Workflow 2: Add New Fields
1. User edits RFI Controller record
2. Adds new field to `Fields_to_Display__c`
3. Saves record
4. Opens component
5. New field appears at the end of the list
6. User can drag it to desired position
7. Clicks "Save Changes"
8. Custom order updated ✅

### Workflow 3: Remove Fields
1. User edits RFI Controller record
2. Removes field from `Fields_to_Display__c`
3. Saves record
4. Opens component
5. Field is automatically removed from display
6. Custom order is cleaned up automatically ✅

---

## Technical Details

### Field Specifications

**Fields_to_Display_Order__c:**
- Type: Long Text Area
- Length: 32,768 characters
- Visible Lines: 5
- Description: "Stores the ordered list of fields to display (semicolon-separated). This field preserves the custom order set by users."
- Managed by: RFI Field Manager component

### Data Sync Logic

The component intelligently syncs between both fields:

```javascript
// Priority: Custom Order > Multiselect Order
if (Fields_to_Display_Order__c exists) {
    orderedFields = Fields_to_Display_Order__c.split(';')
    // Filter to only selected fields
    .filter(field => Fields_to_Display__c.includes(field))
    
    // Add any new fields from multiselect
    Fields_to_Display__c.forEach(field => {
        if (!orderedFields.includes(field)) {
            orderedFields.push(field);
        }
    });
} else {
    // First time: use multiselect order
    orderedFields = Fields_to_Display__c.split(';');
}
```

---

## Benefits

✅ **Order Preservation** - Custom order always maintained
✅ **Backward Compatible** - Works with existing records (uses multiselect as fallback)
✅ **User-Friendly** - Users can still add/remove fields via standard UI
✅ **Automatic Cleanup** - Removed fields are auto-filtered from order
✅ **New Field Handling** - New fields automatically appended to order
✅ **No Data Loss** - Both fields keep same selection list

---

## Migration Notes

### For Existing Records

Existing RFI Controller records will work immediately:
1. First load: Component uses `Fields_to_Display__c` order
2. First save: Component creates `Fields_to_Display_Order__c`
3. Subsequent loads: Component uses custom order

**No manual data migration needed!**

---

## Troubleshooting

### Order Still Not Saving

**Check:**
1. Field Level Security on `Fields_to_Display_Order__c`
2. User has edit permission on the field
3. Console logs show correct order being saved
4. Refresh browser after save

**Console Commands:**
```javascript
// Check if order field has value
console.log('Order field value:', 
  component.getFieldValue(FIELDS_TO_DISPLAY_ORDER_FIELD));

// Check if multiselect has value
console.log('Multiselect field value:', 
  component.getFieldValue(FIELDS_TO_DISPLAY_FIELD));
```

### Fields Appear Out of Order

**Cause:** `Fields_to_Display_Order__c` may be stale

**Solution:**
1. Edit record
2. Change field order in component
3. Save
4. Order field is updated

### New Field Not Appearing

**Cause:** Not added to `Fields_to_Display__c`

**Solution:**
1. Edit RFI Controller record
2. Add field to `Fields_to_Display__c` multiselect
3. Save record
4. Refresh component
5. New field appears at end of list

---

## Files Modified

1. ✅ **NEW:** `Fields_to_Display_Order__c.field-meta.xml`
2. ✅ **UPDATED:** `rfiFieldManager.js`
   - Added import for new field
   - Updated initialization logic
   - Updated save logic
   - Enhanced console logging

---

## Testing Checklist

- [ ] Deploy new field
- [ ] Deploy updated component
- [ ] Open existing RFI Controller record
- [ ] Component loads without errors
- [ ] Fields display in expected order
- [ ] Drag a field to new position
- [ ] Console shows "Reordered fields"
- [ ] Click "Save Changes"
- [ ] Console shows "Saving to Fields_to_Display_Order__c"
- [ ] Success toast appears
- [ ] Refresh page (hard refresh: Ctrl+Shift+R)
- [ ] Order persists after refresh ✅
- [ ] Add new field via standard UI
- [ ] New field appears in component
- [ ] Remove field via standard UI
- [ ] Field disappears from component

---

## Success Criteria

✅ Drag and drop order is preserved after save
✅ Order persists after page refresh
✅ Order persists after logging out and back in
✅ Adding fields via multiselect works
✅ Removing fields via multiselect works
✅ No JavaScript errors in console
✅ Save operation completes successfully

---

**Status:** ✅ **READY TO DEPLOY**

The solution is complete and properly handles order preservation using a dedicated text field!

