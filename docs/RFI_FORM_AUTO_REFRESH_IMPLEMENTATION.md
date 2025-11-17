# RFI Form Auto-Refresh Implementation

## Overview
The `rfiForm` LWC now automatically refreshes when the RFI Controller record is updated on the record page. This ensures that configuration changes made through admin tools (rfiFieldManager or academicInterestSelector) are immediately reflected in the form without requiring a manual page reload.

## Implementation Date
November 17, 2025

---

## How It Works

### Architecture
The solution uses Salesforce's Lightning Data Service (LDS) reactive data patterns:

1. **Admin components** (`rfiFieldManager`, `academicInterestSelector`) notify LDS when they update the RFI_Controller__c record
2. **LDS** propagates the change notification to all components watching that record
3. **rfiForm component** detects the change and automatically refreshes its data

### Data Flow
```
Admin Tool Save
    ↓
updateRecord() → notifyRecordUpdateAvailable()
    ↓
Lightning Data Service (LDS)
    ↓
rfiForm @wire(getRecord) detects change
    ↓
refreshApex() called
    ↓
Form data refreshed
```

---

## Components Modified

### 1. rfiForm Component
**Location:** `force-app/main/default/lwc/rfiForm/rfiForm.js`

#### Changes Made:

##### A. Added Imports
```javascript
import {refreshApex} from '@salesforce/apex';
import RFI_CONTROLLER_FIELDS_TO_DISPLAY from '@salesforce/schema/RFI_Controller__c.Fields_to_Display__c';
import RFI_CONTROLLER_FIELDS_ORDER from '@salesforce/schema/RFI_Controller__c.Fields_to_Display_Order__c';
import RFI_CONTROLLER_ACADEMIC_INTERESTS from '@salesforce/schema/RFI_Controller__c.Academic_Interests_To_Display__c';
```

##### B. Extended Monitored Fields
The component now monitors these RFI_Controller__c fields:
- `Name` - Controller identifier
- `Id` - Record ID
- `Fields_to_Display__c` - Which fields to show
- `Fields_to_Display_Order__c` - Field display order
- `Academic_Interests_To_Display__c` - Selected academic programs

##### C. Added Tracking Properties
```javascript
// Store wired results for refreshApex
wiredRecordResult;
wiredFormResult;

// Track previous values to detect changes
_lastFieldsToDisplay;
_lastFieldsOrder;
_lastAcademicInterests;
```

##### D. Enhanced Change Detection
The `rfiControllerInfo` wire method now:
- Stores the wired result for refresh capability
- Tracks previous field values
- Detects actual changes (ignoring initial load)
- Automatically triggers refresh when changes are detected
- Logs detailed change information for debugging

**Key Feature:** Only triggers refresh on updates, not initial load:
```javascript
const isUpdate = this._lastFieldsToDisplay !== undefined || 
               this._lastFieldsOrder !== undefined || 
               this._lastAcademicInterests !== undefined;
```

##### E. Added Refresh Methods

**1. Automatic Refresh Method:**
```javascript
async refreshFormData() {
    // Called automatically when monitored fields change
    // Refreshes only the form data
}
```

**2. Public API Method:**
```javascript
@api
async refreshData() {
    // Can be called manually by parent components
    // Refreshes both record and form data
}
```

---

### 2. rfiFieldManager Component
**Location:** `force-app/main/default/lwc/rfiFieldManager/rfiFieldManager.js`

#### Status: ✅ Already Implemented

The component already includes the necessary notification logic:
```javascript
updateRecord(recordInput)
    .then((result) => {
        // Notify LDS that record changed
        return notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
    })
    .then(() => {
        // Refresh local data
        return refreshApex(this.wiredRecordResult);
    })
```

This triggers the refresh in `rfiForm` when fields configuration is saved.

---

### 3. academicInterestSelector Component
**Location:** `force-app/main/default/lwc/academicInterestSelector/academicInterestSelector.js`

#### Status: ✅ Already Implemented

The component already includes notification for both save operations:

**Main Save:**
```javascript
await updateRecord(recordInput);
await getRecordNotifyChange([{recordId: this.recordId}]);
await refreshApex(this.wiredRecordResult);
```

**Quiet Save (cleanup):**
```javascript
await updateRecord(recordInput);
await getRecordNotifyChange([{recordId: this.recordId}]);
await refreshApex(this.wiredRecordResult);
```

This triggers the refresh in `rfiForm` when academic interests are updated.

---

## User Experience

### Before Implementation
- Admin updates fields in rfiFieldManager → saves
- Form displays old configuration
- User must manually refresh the browser page
- Poor admin experience during testing

### After Implementation
- Admin updates fields in rfiFieldManager → saves
- Form automatically refreshes within 1-2 seconds
- No manual page reload needed
- Seamless admin experience

---

## Testing Scenarios

### Test 1: Field Configuration Changes
1. Open RFI Controller record page with rfiForm visible
2. Open rfiFieldManager admin tool
3. Add/remove/reorder fields
4. Save changes
5. **Expected:** rfiForm automatically refreshes to show new field configuration

### Test 2: Academic Interest Changes
1. Open RFI Controller record page with rfiForm visible
2. Open academicInterestSelector admin tool
3. Select different programs
4. Save changes
5. **Expected:** rfiForm automatically refreshes to show new academic interests

### Test 3: Multiple Rapid Updates
1. Make several quick consecutive changes in admin tools
2. **Expected:** Each change triggers a refresh, form stays synchronized

### Test 4: Lightning Out Context
1. Deploy form as Lightning Out on external website
2. **Note:** Auto-refresh requires `recordId` to be set
3. If only `rfiControllerName` is provided (no recordId), refresh won't work
4. This is expected behavior for Lightning Out guest users

---

## Console Logging

The implementation includes detailed console logging for debugging:

### rfiForm Component Logs:
- `🔄 RFI Controller record updated - refreshing form data`
- `Fields to Display changed: true/false`
- `Fields Order changed: true/false`
- `Academic Interests changed: true/false`
- `✅ RFI Form data refreshed successfully`
- `✅ All RFI Form data refreshed successfully (manual refresh)`

### Admin Component Logs:
- `Notifying LDS of record change for recordId: xxx`
- `✅ LDS notification complete`
- `✅ Refresh complete`

---

## Technical Notes

### Why refreshApex?
- `refreshApex()` re-executes the wire service with cached parameters
- Maintains reactivity while minimizing server round trips
- More efficient than re-wiring or manual imperative calls

### Why Track Previous Values?
- Prevents unnecessary refreshes on initial component load
- Only triggers refresh when actual changes occur
- Improves performance and reduces unnecessary API calls

### Lightning Out Compatibility
- Auto-refresh works when `recordId` is available (standard record page)
- Lightning Out deployments (guest users) typically use `rfiControllerName` only
- In Lightning Out context without recordId, form still works but won't auto-refresh
- This is acceptable as guest users don't see real-time admin changes

---

## API Methods

### @api refreshData()
**Purpose:** Manually trigger a full data refresh  
**Usage:** Can be called by parent components if needed  
**Returns:** Promise that resolves when refresh is complete

**Example:**
```javascript
// In a parent component
const rfiFormComponent = this.template.querySelector('c-rfi-form');
if (rfiFormComponent) {
    await rfiFormComponent.refreshData();
}
```

---

## Limitations & Considerations

1. **Requires recordId:** Auto-refresh only works when the component is on a record page with `recordId` available
2. **Not Real-Time:** There's a 1-2 second delay as LDS propagates changes
3. **Network Dependent:** Refresh requires active network connection
4. **Guest User Context:** Lightning Out deployments for guest users won't auto-refresh (by design)

---

## Future Enhancements

Potential improvements for future consideration:

1. **Visual Refresh Indicator:** Show a subtle animation/toast when form refreshes
2. **Optimistic UI Updates:** Update UI immediately while refresh is in progress
3. **Retry Logic:** Implement retry mechanism if refresh fails
4. **Custom Events:** Dispatch custom event when refresh completes for parent component coordination

---

## Related Documentation

- [RFI_FORM_AUTO_REFRESH.md](./RFI_FORM_AUTO_REFRESH.md) - Original planning document
- [RFI_FIELD_MANAGER_RECORD_REFRESH.md](./RFI_FIELD_MANAGER_RECORD_REFRESH.md) - Field manager documentation
- [RECORD_REFRESH_FIX_SUMMARY.md](./RECORD_REFRESH_FIX_SUMMARY.md) - General refresh patterns

---

## Support & Troubleshooting

### Form Not Refreshing?

**Check:**
1. Is `recordId` set on the component?
2. Are console logs showing change detection?
3. Is LDS notification being called in admin tools?
4. Check browser console for errors

**Debug Steps:**
```javascript
// In browser console, check if recordId is set
document.querySelector('c-rfi-form').recordId

// Check if wired results are populated
document.querySelector('c-rfi-form').wiredRecordResult
document.querySelector('c-rfi-form').wiredFormResult
```

### Manual Refresh If Needed:
```javascript
// Force manual refresh via console
document.querySelector('c-rfi-form').refreshData()
```

---

## Conclusion

The auto-refresh implementation provides a seamless experience for administrators configuring RFI forms. Changes made in admin tools are immediately reflected in the form without requiring manual page reloads, significantly improving the configuration workflow and user experience.

The solution leverages Salesforce's Lightning Data Service reactive patterns, ensuring efficient and reliable real-time synchronization across components.

