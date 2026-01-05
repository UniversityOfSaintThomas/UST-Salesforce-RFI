# UST Salesforce RFI - Documentation

**Last Updated:** January 5, 2026

---

## 📚 Quick Navigation

### Getting Started
- **[Main Guide](MAIN_GUIDE.md)** - Complete overview of all components and features
- **[Interaction Questions Setup](INTERACTION_QUESTIONS_SETUP.md)** - NEW component setup and user guide
- **[Troubleshooting](TROUBLESHOOTING.md)** - Solutions to common issues

### Component-Specific Guides
- **[Academic Interest Selector](ADMIN_TOOL_GUIDE.md)** - Configure academic programs on RFI forms
- **[RFI Interaction Questions](RFI_INTERACTION_QUESTIONS_GUIDE.md)** - Technical deep-dive

---

## 🚀 Quick Start

### I'm an Administrator
**Goal:** Configure RFI forms

1. Read [Main Guide - Components Section](MAIN_GUIDE.md#components)
2. Use [Admin Tool Guide](ADMIN_TOOL_GUIDE.md) for academic interests
3. See [Interaction Questions Setup](INTERACTION_QUESTIONS_SETUP.md) for custom questions

### I'm a Developer
**Goal:** Deploy and maintain components

1. Review [Main Guide - Deployment Section](MAIN_GUIDE.md#deployment)
2. For interaction questions: [Interaction Questions Setup](INTERACTION_QUESTIONS_SETUP.md)
3. Issues? Check [Troubleshooting Guide](TROUBLESHOOTING.md)

---

## 📖 Core Documentation

### 1. Main Guide (Start Here)
**File:** [MAIN_GUIDE.md](MAIN_GUIDE.md)

**Contains:**
- Overview of all components
- Quick start for admins and developers
- Deployment instructions
- Architecture overview
- Best practices

**Read this first** to understand the entire system.

### 2. Interaction Questions Setup
**File:** [INTERACTION_QUESTIONS_SETUP.md](INTERACTION_QUESTIONS_SETUP.md)

**Contains:**
- 5-minute setup guide (includes manual field creation)
- Complete user guide for the new component
- All features explained
- Comparison with Lead questions component
- Technical details

**New component** - requires manual field setup before use.

### 3. Troubleshooting Guide
**File:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

**Contains:**
- Common issues and solutions
- Component-specific troubleshooting
- Deployment issues
- Browser compatibility
- Diagnostic commands

**Start here** when encountering errors.

---

## 🎯 Component Guides

### Academic Interest Selector
**Primary Guide:** [ADMIN_TOOL_GUIDE.md](ADMIN_TOOL_GUIDE.md)

**What it does:**
- Allows admins to select which academic programs appear on public RFI forms
- Dual-listbox interface with search
- Grouped by school and degree type
- Auto-saves selections

**Quick Access:**
- Setup: [Admin Tool Guide - Getting Started](ADMIN_TOOL_GUIDE.md#getting-started)
- Usage: [Admin Tool Guide - Using the Component](ADMIN_TOOL_GUIDE.md#using-the-component)

### RFI Additional Questions (Interactions)
**Primary Guide:** [INTERACTION_QUESTIONS_SETUP.md](INTERACTION_QUESTIONS_SETUP.md)  
**Technical Guide:** [RFI_INTERACTION_QUESTIONS_GUIDE.md](RFI_INTERACTION_QUESTIONS_GUIDE.md)

**What it does:**
- Manage custom questions that map to Interaction object fields
- Modern drag-and-drop interface
- Modal-based editing
- Toast notifications

**Quick Access:**
- Setup: [Interaction Questions Setup - Quick Setup](INTERACTION_QUESTIONS_SETUP.md#quick-setup-5-minutes)
- Usage: [Interaction Questions Setup - User Guide](INTERACTION_QUESTIONS_SETUP.md#user-guide)

---

## 🔧 Additional Resources

### Deployment
See [Main Guide - Deployment Section](MAIN_GUIDE.md#deployment) for:
- Standard deployment commands
- Component-specific deployment
- Verification steps

### Architecture
See [Main Guide - Architecture Section](MAIN_GUIDE.md#architecture) for:
- Data flow diagram
- Configuration storage details
- JSON structure examples

### Best Practices
See [Main Guide - Best Practices Section](MAIN_GUIDE.md#best-practices) for:
- Configuration guidelines
- Development standards
- Testing recommendations

---

## 📁 File Organization

### Active Documentation (Use These)
```
docs/
├── README.md (this file)               # Documentation index
├── MAIN_GUIDE.md                       # Primary reference guide
├── INTERACTION_QUESTIONS_SETUP.md      # New component setup
├── TROUBLESHOOTING.md                  # Common issues & solutions
├── ADMIN_TOOL_GUIDE.md                 # Academic Interest Selector
└── RFI_INTERACTION_QUESTIONS_GUIDE.md  # Interaction questions technical guide
```

### Historical/Reference (Archived)
All other .md files in this folder are historical documentation from past implementations and bug fixes. They are kept for reference but not actively maintained.

To see historical docs:
```powershell
Get-ChildItem -Path docs -Filter "*.md" | Where-Object { $_.Name -notmatch "^(README|MAIN_GUIDE|INTERACTION_QUESTIONS_SETUP|TROUBLESHOOTING|ADMIN_TOOL_GUIDE|RFI_INTERACTION).*\.md$" }
```

---

## 🆘 Getting Help

### Troubleshooting
1. **Check [Troubleshooting Guide](TROUBLESHOOTING.md)** - Most issues covered
2. **Browser console** - F12 for JavaScript errors  
3. **Debug logs** - Setup → Debug Logs in Salesforce
4. **Test in sandbox** - Reproduce in safe environment

### Deployment Issues
- See [Troubleshooting - Deployment Issues](TROUBLESHOOTING.md#deployment-issues)
- Use targeted deploys: `cci task run deploy --path ... --org dev`
- Avoid `cci flow run dev_org` for small changes

### Component Issues
- **Interaction Questions:** [Interaction Questions Setup - Troubleshooting](INTERACTION_QUESTIONS_SETUP.md#troubleshooting)
- **Academic Selector:** [Admin Tool Guide - Troubleshooting](ADMIN_TOOL_GUIDE.md#troubleshooting)
- **General:** [Troubleshooting Guide](TROUBLESHOOTING.md)

---

## 📊 Documentation Status

**Current (Active):**
- ✅ MAIN_GUIDE.md - Complete
- ✅ INTERACTION_QUESTIONS_SETUP.md - Complete
- ✅ TROUBLESHOOTING.md - Complete
- ✅ ADMIN_TOOL_GUIDE.md - Current
- ✅ RFI_INTERACTION_QUESTIONS_GUIDE.md - Current

**Consolidated:** January 5, 2026
- Removed redundant documentation
- Consolidated overlapping guides
- Archived historical bug fix docs
- Created clear documentation hierarchy

---

## 🔄 Version History

### 2.0 - January 5, 2026 (Consolidated)
- Created MAIN_GUIDE.md as primary reference
- Created INTERACTION_QUESTIONS_SETUP.md for new component
- Created TROUBLESHOOTING.md for all issues
- Consolidated 40+ docs into 6 core guides
- Archived historical documentation

### 1.0 - Previous
- Multiple component-specific guides
- Historical bug fix documentation
- Deployment summaries per feature

---

**Need something not covered here?** Check the [Main Guide](MAIN_GUIDE.md) or [Troubleshooting Guide](TROUBLESHOOTING.md).

