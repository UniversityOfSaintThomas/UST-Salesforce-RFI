# RFI Form Auto-Refresh - Quick Test Guide

## ✅ Implementation Complete
**Date:** November 17, 2025  
**Status:** Ready to Test

---

## Quick Test Steps

### Test 1: Field Configuration Refresh (2 minutes)

1. **Setup:**
   - Navigate to any RFI Controller record
   - Open the record page
   - Ensure the `rfiForm` component is visible

2. **Action:**
   - Click on the `rfiFieldManager` tab/tool
   - Add a new field (e.g., "Phone")
   - Click "Save"

3. **Expected Result:**
   - Within 1-2 seconds, the `rfiForm` refreshes
   - New field appears in the form
   - No manual page reload needed

4. **Console Check:**
   - Open browser console (F12)
   - Look for: `🔄 RFI Controller record updated - refreshing form data`
   - Look for: `✅ RFI Form data refreshed successfully`

---

### Test 2: Academic Interest Refresh (2 minutes)

1. **Setup:**
   - Navigate to any RFI Controller record
   - Open the record page
   - Ensure the `rfiForm` component is visible

2. **Action:**
   - Click on the `academicInterestSelector` tab/tool
   - Select different programs
   - Click "Save"

3. **Expected Result:**
   - Within 1-2 seconds, the `rfiForm` refreshes
   - Academic interests dropdown updates
   - No manual page reload needed

4. **Console Check:**
   - Open browser console (F12)
   - Look for: `🔄 RFI Controller record updated - refreshing form data`
   - Look for: `Academic Interests changed: true`

---

### Test 3: Multiple Rapid Changes (3 minutes)

1. **Action:**
   - Make 3 quick changes in rfiFieldManager:
     - Add a field
     - Remove a field
     - Reorder fields
   - Save after each change

2. **Expected Result:**
   - Form refreshes after each save
   - All changes appear correctly
   - No errors in console

---

## Console Commands for Manual Testing

### Check if recordId is set:
```javascript
document.querySelector('c-rfi-form').recordId
```

### Check wired results:
```javascript
document.querySelector('c-rfi-form').wiredRecordResult
document.querySelector('c-rfi-form').wiredFormResult
```

### Manually trigger refresh:
```javascript
document.querySelector('c-rfi-form').refreshData()
```

### Check tracking values:
```javascript
const form = document.querySelector('c-rfi-form');
console.log('Last Fields:', form._lastFieldsToDisplay);
console.log('Last Order:', form._lastFieldsOrder);
console.log('Last Interests:', form._lastAcademicInterests);
```

---

## Expected Console Logs

### When Field Configuration Changes:
```
🔄 RFI Controller record updated - refreshing form data
Fields to Display changed: true
Fields Order changed: false
Academic Interests changed: false
✅ RFI Form data refreshed successfully
```

### When Academic Interests Change:
```
🔄 RFI Controller record updated - refreshing form data
Fields to Display changed: false
Fields Order changed: false
Academic Interests changed: true
✅ RFI Form data refreshed successfully
```

### When Manual Refresh Called:
```
✅ All RFI Form data refreshed successfully (manual refresh)
```

---

## Troubleshooting

### ❌ Form Not Refreshing?

**Check 1: Is recordId set?**
```javascript
// Should return a record ID like "a0X..."
document.querySelector('c-rfi-form').recordId
```
- If `null` or `undefined`, component is not on a record page
- Auto-refresh only works with recordId

**Check 2: Are changes being saved?**
- Look for "Success" toast message after saving
- Check if rfiFieldManager/academicInterestSelector logs show save completion

**Check 3: Are notifications being sent?**
- Look for: `Notifying LDS of record change for recordId: xxx`
- This should appear in admin tool's console logs

**Check 4: Browser compatibility**
- Test in latest Chrome, Firefox, or Edge
- Clear browser cache if issues persist

---

## Known Limitations

### ✅ Works:
- On RFI Controller record pages
- When recordId is available
- In Lightning Experience
- For authenticated users

### ❌ Does Not Work (Expected):
- Lightning Out without recordId
- Guest user context (uses rfiControllerName only)
- External websites embedding the form
- Community pages without record context

**Note:** These limitations are by design. The form still functions correctly in these contexts; it just won't auto-refresh (which is acceptable since guests/external users don't modify configuration).

---

## Success Criteria

✅ **Pass Criteria:**
1. Form refreshes within 1-2 seconds of admin tool save
2. Console shows change detection logs
3. New configuration appears in form without manual refresh
4. No JavaScript errors in console
5. Multiple rapid changes all refresh correctly

❌ **Fail Criteria:**
1. Form requires manual page refresh to show changes
2. JavaScript errors appear in console
3. Form data becomes inconsistent
4. Changes don't appear even after waiting 5+ seconds

---

## Report Issues

If tests fail, collect this information:

1. **Browser & Version:**
   - Chrome 119, Firefox 120, etc.

2. **Console Logs:**
   - Copy all logs from browser console

3. **Network Tab:**
   - Check if API calls are completing successfully

4. **Component Context:**
   - Is recordId set? (check with console command above)
   - Are you on a record page or Lightning Out?

5. **Steps to Reproduce:**
   - Exact steps that cause the issue

---

## Files to Deploy

Before testing, ensure these files are deployed:

1. ✅ `force-app/main/default/lwc/rfiForm/rfiForm.js` (modified)
2. ✅ `force-app/main/default/lwc/rfiFieldManager/rfiFieldManager.js` (already has notifications)
3. ✅ `force-app/main/default/lwc/academicInterestSelector/academicInterestSelector.js` (already has notifications)

---

## Quick Reference: Key Changes

### What Fields Trigger Refresh?
1. `Fields_to_Display__c`
2. `Fields_to_Display_Order__c`
3. `Academic_Interests_To_Display__c`

### What Components Send Notifications?
1. `rfiFieldManager` - via `notifyRecordUpdateAvailable()`
2. `academicInterestSelector` - via `getRecordNotifyChange()`

### How Long Does Refresh Take?
- Typically 1-2 seconds
- Depends on network speed and server response time

---

**Ready to test!** 🚀

Follow Test 1, Test 2, and Test 3 above to verify functionality.

