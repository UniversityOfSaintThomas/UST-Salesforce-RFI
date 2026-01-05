# AI Tools Configuration - UST Salesforce RFI

**Project:** UST Salesforce RFI (Request for Information)  
**Purpose:** Lightning Web Components for managing RFI forms at University of St. Thomas  
**Last Updated:** January 5, 2026

---

## Project Context

This is a Salesforce Lightning Web Component (LWC) project that provides admin tools for configuring Request for Information (RFI) forms and capturing prospective student data.

### What This Project Does
- Admins configure RFI forms via LWC components on `RFI_Controller__c` records
- Public-facing forms collect information and create Lead/Interaction records
- Components provide drag-and-drop, multi-select, and field management interfaces

### Tech Stack
- **Platform:** Salesforce (Scratch Orgs)
- **Frontend:** Lightning Web Components (LWC)
- **Backend:** Apex controllers
- **Build:** CumulusCI (Python-based Salesforce CLI)
- **Testing:** Jest (JavaScript), Robot Framework (E2E)

---

## Critical Rules for AI Tools

### 1. Deployment Strategy

**✅ ALWAYS USE TARGETED DEPLOYS**
```powershell
# Deploy specific component
cci task run deploy --path force-app/main/default/lwc/componentName --org dev

# Deploy specific metadata type
cci task run deploy --path force-app/main/default/classes --org dev
```

**❌ NEVER USE FOR INCREMENTAL CHANGES**
```powershell
# This rebuilds the ENTIRE scratch org - only for initial setup
cci flow run dev_org --org dev
```

**Why:** The dev org contains configured data. Rebuilding destroys all configuration work.

### 2. Field Deployment Gotcha

**Known Issue:** Salesforce CLI source tracking can mark fields as "Unchanged" even when they don't exist in the org.

**Symptoms:**
- Deploy reports "Success" or "Unchanged"
- Field doesn't actually exist in org
- Queries fail with "No such column" error

**Solution:**
1. **First attempt:** Deploy entire object directory
   ```powershell
   cci task run deploy --path force-app/main/default/objects/ObjectName__c --org dev
   ```

2. **If that fails:** Create field manually through Salesforce UI
   - Setup → Object Manager → [Object] → Fields & Relationships → New

3. **Document the manual step** in deployment guide

**Example:** The `Interaction_Questions__c` field required manual creation (see docs/INTERACTION_QUESTIONS_SETUP.md)

### 3. LWC Reactivity Patterns

**✅ CORRECT - Create new object references**
```javascript
// For objects
this.data = {...this.data, newProp: value};

// For arrays
this.items = [...this.items];

// For nested objects
this.config = {
    ...this.config,
    nested: {...this.config.nested, prop: value}
};
```

**❌ WRONG - Direct mutation won't trigger re-render**
```javascript
this.data.newProp = value;           // Won't update UI
this.items[0].prop = value;          // Won't update UI
this.config.nested.prop = value;     // Won't update UI
```

**Why:** LWC uses @track decorator which tracks object/array **references**, not deep property changes.

### 4. Component Architecture

**Current Components:**
- `academicInterestSelector` - Admin tool for selecting academic programs to display
- `rfiAdditionalQuestions` - Manage Lead questions (DataTable UI)
- `rfiAdditionalQuestionsInteractions` - Manage Interaction questions (Modern drag-drop UI)
- `rfiFieldManager` - Configure field display and ordering
- `rfiForm` - Public-facing form (modern)
- `requestForInformationForm` - Public-facing form (legacy, still in use)
- `reusableLookup` - Reusable lookup component
- `multiSelectPillsGroupable*` - Multi-select UI components (3 components)

**When adding features:**
1. Check if existing component can be extended
2. Follow established patterns (see similar components)
3. Maintain consistent UI/UX across components

### 5. Data Storage Patterns

**JSON in Long Text Area Fields:**
- `Additional_Questions__c` - Lead questions configuration
- `Interaction_Questions__c` - Interaction questions configuration
- `Academic_Interests_To_Display__c` - Selected academic programs (multi-select picklist)

**Structure:**
```json
[
  {
    "id": 0,
    "questionLabel": "Question text",
    "questionType": "Email required",
    "fieldToApplyTo": "Email",
    "position": "top",
    "isRequired": true,
    "picklistValues": [],
    "valuesFlat": ""
  }
]
```

**When modifying:**
- Always validate JSON before saving
- Preserve existing structure
- Add new properties, don't remove old ones (backward compatibility)

---

## Project-Specific Conventions

### Component Naming
- Admin tools: Descriptive names (e.g., `academicInterestSelector`)
- Public forms: `rfi` prefix (e.g., `rfiForm`)
- Reusable utilities: Descriptive names (e.g., `reusableLookup`)

### File Organization
```
force-app/main/default/
├── lwc/                    # Lightning Web Components
├── classes/                # Apex controllers
├── objects/                # Custom objects & fields
├── flexipages/             # Lightning page layouts
├── flows/                  # Flows (if any)
├── layouts/                # Page layouts
└── tabs/                   # Custom tabs
```

### Documentation
- **Active docs:** `docs/` folder (6 core files)
- **Historical:** `docs/archive/` folder (reference only)
- **Root:** Only README.md and essential config files

### Testing
- Jest tests in `__tests__/` subdirectories
- Robot Framework tests in `robot/` directory
- Always include tests for new components

---

## Common Tasks

### Adding a New Question Type
1. Update component JavaScript with new type logic
2. Update template to handle new type
3. Test with all existing question types
4. Update user documentation

### Adding a New LWC Component
1. Create in `force-app/main/default/lwc/componentName/`
2. Include: .js, .html, .css, .js-meta.xml files
3. Add Jest tests in `__tests__/` subdirectory
4. Deploy: `cci task run deploy --path force-app/main/default/lwc/componentName --org dev`
5. Add to flexipage if needed
6. Document in appropriate guide

### Modifying Apex Controller
1. Update `.cls` file
2. Update `.cls-meta.xml` if needed
3. Deploy: `cci task run deploy --path force-app/main/default/classes --org dev`
4. Test thoroughly (Apex changes affect all forms)

### Adding a Custom Field
1. Create field metadata XML in `force-app/main/default/objects/ObjectName__c/fields/`
2. **Attempt automated deploy first:**
   ```powershell
   cci task run deploy --path force-app/main/default/objects/ObjectName__c --org dev
   ```
3. **If field doesn't appear:** Create manually through UI
4. **Document manual step** if required for future deployments
5. Update component to reference new field

---

## Known Issues & Workarounds

### Issue: Field Deployment Tracking
**Problem:** CLI thinks field exists but it doesn't  
**Workaround:** Create field manually through Salesforce UI  
**Documented in:** INTERACTION_QUESTIONS_SETUP.md

### Issue: Drag-and-Drop on Mobile
**Problem:** HTML5 drag API unreliable on some mobile browsers  
**Workaround:** Provide arrow button alternatives  
**Example:** rfiAdditionalQuestionsInteractions component

### Issue: Formula Fields in Field Manager
**Problem:** Formula fields are read-only, can't be used for form inputs  
**Workaround:** Filter out read-only fields in field queries  
**Example:** All field manager components check `updateable` property

---

## Testing Checklist

Before marking work complete:

- [ ] Component deployed successfully
- [ ] Tested in dev org (not just "deploy succeeded")
- [ ] All features work as expected
- [ ] No JavaScript errors in console
- [ ] Mobile responsive (if applicable)
- [ ] Documentation updated
- [ ] No deployment errors
- [ ] Existing functionality still works (regression test)

---

## Deployment Checklist

Before deploying to higher environments:

- [ ] Tested in dev/sandbox
- [ ] All dependencies deployed
- [ ] Field-level security configured
- [ ] Permission sets updated
- [ ] Documentation updated
- [ ] Rollback plan documented
- [ ] Stakeholders notified

---

## Key Contacts & Resources

### Documentation
- **Main Guide:** `docs/MAIN_GUIDE.md`
- **Troubleshooting:** `docs/TROUBLESHOOTING.md`
- **Component Guides:** See `docs/README.md`

### External Resources
- **CumulusCI Docs:** https://cumulusci.readthedocs.io/
- **LWC Guide:** https://developer.salesforce.com/docs/component-library/documentation/en/lwc
- **Salesforce CLI:** https://developer.salesforce.com/tools/salesforcecli

### Project-Specific
- **Org:** Dev scratch org (14-day lifecycle)
- **Namespace:** None (unmanaged package)
- **API Version:** 64.0

---

## AI Tool Specific Guidance

### When Asked to Create Documentation
- **Location:** Always in `docs/` folder
- **Format:** Markdown
- **Structure:** Follow existing guides (see docs/MAIN_GUIDE.md)
- **Consolidate:** Don't create redundant docs, update existing

### When Asked to Deploy
- **Default:** Use targeted deploys
- **Verify:** Run `cci org browser dev` and manually test
- **Document:** If manual steps required, add to docs

### When Asked to Create Components
- **Pattern:** Follow existing component structure
- **Reactivity:** Use proper LWC patterns (new object references)
- **Tests:** Include Jest tests
- **Documentation:** Update component guide

### When Asked to Fix Bugs
- **Reproduce:** Verify issue in dev org
- **Fix:** Make minimal changes
- **Test:** Verify fix works
- **Document:** Update troubleshooting guide if common issue

### When Documentation Is Cluttered
- **Consolidate:** Merge overlapping docs
- **Archive:** Move historical docs to `archive/`
- **Update:** Keep only current, relevant docs active
- **Index:** Update README.md with navigation

---

## Project History Context

### Recent Major Changes (2026)
- **Jan 5:** Added `rfiAdditionalQuestionsInteractions` component with drag-drop
- **Jan 5:** Consolidated 41 docs into 6 core guides
- **2025:** Added Academic Interest Selector with dual-listbox UI
- **2025:** Multiple bug fixes (checkbox errors, validation, refresh issues)

### Evolution
- Started with basic RFI form
- Added admin configuration tools
- Expanded to support both Lead and Interaction objects
- Modernized UI with drag-drop and improved UX

### Design Philosophy
- **Admin-friendly:** Non-technical users can configure forms
- **Developer-friendly:** Clear code structure, good documentation
- **Maintainable:** Consolidated docs, clear patterns
- **Salesforce-native:** Uses standard LWC patterns and UI

---

**Remember:** When in doubt, check existing components for patterns. This codebase has proven solutions for most common scenarios.

**Last Updated:** January 5, 2026  
**Maintained By:** GitHub Copilot (with human oversight)

