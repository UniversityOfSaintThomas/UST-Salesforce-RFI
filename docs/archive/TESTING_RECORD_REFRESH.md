# Testing RFI Controller Record Refresh

## Overview
This document provides step-by-step testing procedures to verify that the RFI Controller record refresh is working correctly across all components.

## Prerequisites
- Access to a Salesforce org with UST-Salesforce-RFI package deployed
- At least one RFI_Controller__c record configured
- Browser with developer tools (Chrome/Firefox recommended)

## Components Being Tested
1. **rfiFieldManager** - Updates `Fields_to_Display__c` and `Fields_to_Display_Order__c`
2. **academicInterestSelector** - Updates `Academic_Interests_To_Display__c`
3. **rfiForm** - Monitors all three fields and refreshes when they change

---

## Test 1: Field Manager Updates

### Setup
1. Open an RFI_Controller__c record page
2. Open browser Developer Tools (F12)
3. Go to Console tab
4. Clear console (to see fresh logs)

### Test Steps - Same Page
1. Ensure both `rfiFieldManager` and `rfiForm` components are visible on the page
2. In `rfiFieldManager`:
   - Add a new field OR
   - Remove an existing field OR
   - Reorder fields by dragging
3. Click **Save** button
4. Observe the console logs

### Expected Results
```
Console Output:
=== SAVING FIELDS ===
Current fieldItems order: [...]
Saving to Fields_to_Display_Order__c: ...
Saving to Fields_to_Display__c: ...
✅ Save successful! Result: ...
Notifying LDS of record change for recordId: ...
✅ LDS notification complete
Refreshing wire service data...
✅ Refresh complete

(From rfiForm component)
🔄 RFI Controller record updated, refreshing form...
  Previous Fields_to_Display: ...
  New Fields_to_Display: ...
  Previous Fields_Order: ...
  New Fields_Order: ...
RFI fields loaded: [...]
```

### Visual Verification
- [ ] Loading spinner appears briefly on rfiFieldManager
- [ ] Success toast appears: "Fields configuration saved successfully"
- [ ] rfiForm component re-renders with updated fields
- [ ] New field order matches what was saved
- [ ] No page reload required

---

## Test 2: Academic Interest Selector Updates

### Setup
1. Open an RFI_Controller__c record page
2. Open browser Developer Tools (F12)
3. Go to Console tab
4. Clear console

### Test Steps - Same Page
1. Ensure both `academicInterestSelector` and `rfiForm` components are visible
2. In `academicInterestSelector`:
   - Move programs from Available to Selected (or vice versa)
3. Click **Save** button
4. Observe the console logs

### Expected Results
```
Console Output:
Notifying LDS of record change for recordId: ...

(From rfiForm component)
🔄 RFI Controller record updated, refreshing form...
  Previous Academic_Interests: ...
  New Academic_Interests: ...
RFI fields loaded: [...]
```

### Visual Verification
- [ ] Loading spinner appears briefly on academicInterestSelector
- [ ] Success toast appears with selection count
- [ ] rfiForm component re-renders
- [ ] Academic interest options reflect the new selections
- [ ] No page reload required

---

## Test 3: Cross-Tab Refresh

### Setup
1. Open an RFI_Controller__c record in **Tab 1** with `rfiForm` component visible
2. Open the SAME record in **Tab 2** with `rfiFieldManager` component visible
3. Open Developer Tools (F12) in **Tab 1**

### Test Steps
1. In **Tab 2** (rfiFieldManager):
   - Make changes to field configuration
   - Click Save
2. Switch to **Tab 1** (rfiForm)
3. Wait 2-3 seconds
4. Observe console logs and UI

### Expected Results
- **Tab 2**: Shows save success toast
- **Tab 1**: 
  - Console shows: "🔄 RFI Controller record updated, refreshing form..."
  - Form automatically refreshes (may take 1-3 seconds)
  - Updated fields appear without manual page reload

### Visual Verification
- [ ] Tab 1 form updates without interaction
- [ ] Changes from Tab 2 are visible in Tab 1
- [ ] May see brief flicker as form re-renders
- [ ] Console in Tab 1 shows the update logs

---

## Test 4: Multiple Rapid Changes

### Setup
1. Open an RFI_Controller__c record page
2. Ensure both `rfiFieldManager` and `rfiForm` are visible

### Test Steps
1. In `rfiFieldManager`:
   - Add a field → Save
   - Immediately reorder fields → Save
   - Immediately remove a field → Save
2. Observe console and UI behavior

### Expected Results
- [ ] Each save triggers proper LDS notification
- [ ] rfiForm refreshes after each change
- [ ] No errors in console
- [ ] Final state matches last saved configuration
- [ ] Loading spinners appear and disappear correctly

---

## Test 5: Record Page Refresh (Manual)

### Setup
1. Open an RFI_Controller__c record page with `rfiForm`
2. Make note of current field configuration

### Test Steps
1. Make changes via `rfiFieldManager`
2. Click browser refresh (F5)
3. Observe if changes persist

### Expected Results
- [ ] Page reloads successfully
- [ ] rfiForm shows updated configuration
- [ ] No stale data displayed
- [ ] Console shows normal initialization (not update) logs

---

## Test 6: Error Handling

### Setup
1. Open an RFI_Controller__c record page
2. Open Developer Tools Network tab

### Test Steps
1. Simulate network error (go offline or use Network throttling)
2. Try to save in `rfiFieldManager` or `academicInterestSelector`
3. Observe error handling

### Expected Results
- [ ] Error toast appears with meaningful message
- [ ] Loading spinner stops
- [ ] Console shows error details
- [ ] Component state resets properly
- [ ] User can retry after network restored

---

## Troubleshooting

### Issue: rfiForm doesn't refresh after save

**Check:**
1. Open Console and look for errors
2. Verify `getRecordNotifyChange` is being called (check for log message)
3. Ensure both components are on the same record page
4. Check that the recordId matches between components
5. Verify no JavaScript errors are blocking execution

**Solution:**
```javascript
// In console, manually trigger refresh:
// Find the rfiForm component and call:
component.refreshData();
```

### Issue: Cross-tab refresh not working

**Check:**
1. LDS cache may be delayed (wait 3-5 seconds)
2. Ensure both tabs are viewing the SAME record (check URL)
3. Some browsers limit background tab updates
4. Try clicking on Tab 1 to bring it to focus

### Issue: Console shows no logs

**Check:**
1. Ensure Developer Tools is open BEFORE performing actions
2. Check Console filter settings (should show all levels)
3. Try clearing console and repeating test
4. Verify components are actually on the page (check Elements tab)

---

## Success Criteria

All tests pass when:
- ✅ Save operations complete successfully with toast notifications
- ✅ Console logs show proper notification and refresh sequence
- ✅ rfiForm automatically updates without page reload
- ✅ Changes persist across page refreshes
- ✅ Cross-tab updates work (with slight delay)
- ✅ No JavaScript errors in console
- ✅ Error handling works gracefully

---

## Additional Verification

### Check Field Values in Record
1. After saving, click "Edit" on the RFI_Controller__c record
2. Verify these fields match what was saved:
   - `Fields_to_Display__c`
   - `Fields_to_Display_Order__c`
   - `Academic_Interests_To_Display__c`
   - `Required_Fields__c`

### Check Form Rendering
1. View the actual RFI form (end-user view)
2. Verify:
   - Fields appear in correct order
   - Required fields show asterisk (*)
   - Academic interests match selected values
   - Field labels display correctly

---

## Reporting Issues

If tests fail, provide:
1. Which test failed
2. Browser and version
3. Console logs (copy full output)
4. Network tab HAR file (if network related)
5. Screenshots of error toasts
6. Org edition and API version

---

## Date Created
October 28, 2025

## Last Updated
October 28, 2025

