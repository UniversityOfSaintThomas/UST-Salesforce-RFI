# 🚀 Academic Interest Selector - Quick Reference

## What Is It?
Admin configuration tool to select which academic programs appear on public RFI forms.

## Key Facts
- **Type:** Admin Tool (not for end users)
- **Location:** RFI Controller record page
- **Purpose:** Configure program visibility on public forms
- **Field Updated:** `Academic_Interests_To_Display__c`
- **Selection Limit:** None (unlimited)
- **Save Behavior:** Auto-save on change

## Quick Start

### 1. Add to Page
```
Setup → Object Manager → RFI Controller 
→ Lightning Record Pages → Edit page
→ Drag "Academic Interest Selector" to page
→ Save & Activate
```

### 2. Use It
```
1. Open any RFI Controller record
2. Component shows ALL available programs
3. Select programs you want on public form
4. Selections auto-save
5. Done! ✓
```

### 3. Test It
```
1. Open public RFI form
2. Check academic interest dropdown
3. Should show ONLY selected programs
```

## How Selections Work

### What You See (Admin)
```
Bachelor of Arts
  ☑ Computer Science    ← Selected
  ☐ English            ← Not selected
  ☑ Mathematics        ← Selected

Bachelor of Science
  ☑ Biology            ← Selected
  ☐ Physics            ← Not selected
```

### What Gets Saved
```
Academic_Interests_To_Display__c = "CSCI;MATH;BIOL"
```

### What Public Sees
```
Academic Interests dropdown shows:
- Computer Science
- Mathematics  
- Biology
(Only the 3 selected programs)
```

## Key Features

✅ **Shows full program names** (not codes)  
✅ **Grouped by school/degree**  
✅ **Auto-saves** (no save button needed)  
✅ **Pre-selects current** (easy to modify)  
✅ **Unlimited selections**  
✅ **Visual feedback** (count badge, success message)  

## Common Tasks

### Select Programs
1. Click on program name to select
2. Selected program appears as pill
3. Auto-saves immediately
4. Success message confirms

### Remove Programs
1. Click X on pill
2. Program deselected
3. Auto-saves immediately

### Change Academic Level
1. Change `Academic_Level__c` on RFI Controller
2. Save record
3. Component reloads with new programs

### Filter by School
1. Set `School_College__c` on RFI Controller
2. Save record
3. Component shows only that school's programs

## Troubleshooting

**No programs showing?**
- Check Academic_Level__c is set
- Verify programs exist with Active__c = true
- Confirm Program_Display__c includes "RFI"

**Wrong programs?**
- Verify Academic_Level__c (U or G)
- Check School_College__c matches programs

**Not saving?**
- Check field permissions
- Verify edit access to RFI Controller

## Quick Deploy

```bash
# Deploy component
sfdx force:source:deploy -p force-app/main/default/lwc/academicInterestSelector

# Verify
sfdx force:source:status
```

## Documentation

📚 **Full Guide:** [ADMIN_TOOL_GUIDE.md](ADMIN_TOOL_GUIDE.md)  
📋 **Update Summary:** [COMPONENT_UPDATE_SUMMARY.md](COMPONENT_UPDATE_SUMMARY.md)  
🔧 **Field Fix:** [FORMULA_FIELD_FIX.md](FORMULA_FIELD_FIX.md)

## Need Help?

1. Review [ADMIN_TOOL_GUIDE.md](ADMIN_TOOL_GUIDE.md) for detailed instructions
2. Check Program__c records are configured correctly
3. Verify RFI Controller Academic Level and School College
4. Contact Salesforce admin team

---

**Version:** 2.0 (Admin Tool)  
**Last Updated:** October 27, 2025  
**Status:** ✅ Ready for Production

