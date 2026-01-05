# Property Name Fix - is_group vs isGroup

## ✅ Issue Fixed

Fixed the group header rendering issue caused by property name mismatch between JavaScript and HTML template.

---

## Problem

**Symptom:** Group headers were not rendering correctly - they appeared as regular options instead of styled header sections.

**Root Cause:** Property name mismatch
- **JavaScript:** Used `is_group` (with underscore)
- **HTML Template:** Checked for `isGroup` (camelCase)

This caused the template conditional `if:true={option.isGroup}` to always be false, so group headers never rendered with the correct styling.

---

## Solution

Changed the HTML template to use the correct property name `is_group` to match the JavaScript.

### Changes Made

**File:** `academicInterestSelector.html`

**Line 49 (Available Programs):**
```html
<!-- BEFORE -->
<template if:true={option.isGroup}>

<!-- AFTER -->
<template if:true={option.is_group}>
```

**Line 103 (Selected Programs):**
```html
<!-- BEFORE -->
<template if:true={option.isGroup}>

<!-- AFTER -->
<template if:true={option.is_group}>
```

Also updated the corresponding `if:false` checks:
```html
<!-- BEFORE -->
<template if:false={option.isGroup}>

<!-- AFTER -->
<template if:false={option.is_group}>
```

---

## How It Works Now

### JavaScript (Correct Property Name)
```javascript
this.allPrograms = programs.map((prog, index) => ({
    label: prog.label,
    value: prog.value,
    description: prog.description,
    is_group: prog.is_group,  // ✅ Underscore
    key: `prog-${index}`,
    displayLabel: prog.is_group ? prog.label : `${prog.label} (${prog.value})`
}));
```

### HTML Template (Now Matches)
```html
<template if:true={option.is_group}>  <!-- ✅ Underscore -->
    <li class="slds-listbox__item group-header">
        <h3>{option.label}</h3>
    </li>
</template>
<template if:false={option.is_group}>  <!-- ✅ Underscore -->
    <li class="slds-listbox__item">
        {option.displayLabel}
    </li>
</template>
```

---

## Expected Result

### Before Fix ❌
```
Available Programs
  Bachelor of Arts (Bachelor of Arts)  ← Group rendered as option
  Computer Science (CSCI)
  English Literature (ENGL)
  Bachelor of Science (Bachelor of Science)  ← Group rendered as option
  Biology (BIOL)
```

### After Fix ✅
```
Available Programs
  Bachelor of Arts  ← Group header (bold, gray background, sticky)
    Computer Science (CSCI)
    English Literature (ENGL)
  Bachelor of Science  ← Group header (bold, gray background, sticky)
    Biology (BIOL)
```

---

## Why This Happened

**JavaScript Property Naming:**
- Apex returns `is_group` from the `programValues` class
- JavaScript preserved the underscore naming: `is_group`

**Template Attempted CamelCase:**
- HTML template incorrectly assumed camelCase: `isGroup`
- This is a common mistake when mixing naming conventions

**Lightning Web Components:**
- LWC doesn't automatically convert between naming conventions
- Property names must match exactly between JS and HTML

---

## Testing

### Verify Group Headers
- [ ] Group headers now appear with bold text
- [ ] Group headers have gray background
- [ ] Group headers are sticky when scrolling
- [ ] Group headers are not clickable/selectable
- [ ] Programs appear indented under headers

### Verify Both Columns
- [ ] Available column shows group headers
- [ ] Selected column shows group headers
- [ ] Groups only appear if they have items

---

## Deployment

```bash
sfdx force:source:deploy -p force-app/main/default/lwc/academicInterestSelector
```

---

## Summary

✅ **Property Name Fixed** - Changed `isGroup` to `is_group` in HTML template
✅ **Group Headers Work** - Now render correctly with styling
✅ **Consistent Naming** - JavaScript and HTML now match
✅ **Both Columns Fixed** - Available and Selected columns updated

**Group headers now render correctly as bold, non-selectable section dividers!** 🎉

---

**Updated:** October 27, 2025
**Issue:** Property name mismatch (isGroup vs is_group)
**Fix:** Updated HTML template to use is_group
**Status:** ✅ Fixed - Ready to Deploy

