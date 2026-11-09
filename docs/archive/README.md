# Documentation Archive

This folder contains **historical documentation** that is no longer actively maintained but kept for reference.

## What's Here

These documents were created during the development and evolution of the UST Salesforce RFI project. They include:

- **Bug fix summaries** - Historical issues that have been resolved
- **Implementation summaries** - Feature-specific documentation from past releases
- **Deployment reports** - Past deployment checklists and status reports
- **Consolidation notes** - Old documentation that was merged into current guides
- **Quick reference guides** - Superseded by current documentation

## Why Archived?

As of **January 5, 2026**, all documentation was consolidated into 6 core guides:

1. **README.md** - Documentation index
2. **MAIN_GUIDE.md** - Primary reference guide
3. **INTERACTION_QUESTIONS_SETUP.md** - New component setup
4. **TROUBLESHOOTING.md** - Common issues & solutions
5. **ADMIN_TOOL_GUIDE.md** - Academic Interest Selector guide
6. **RFI_INTERACTION_QUESTIONS_GUIDE.md** - Technical deep-dive

These 6 documents provide all current, relevant information. The archived documents contain:
- Redundant information now consolidated
- Historical bug fixes already implemented
- Legacy deployment notes
- Outdated quick starts

## Using Archived Docs

**Do NOT use these as primary references.** Use the current documentation in the parent `docs/` folder.

**Use archived docs only to:**
- Understand historical context
- Reference old bug fixes
- Review past implementation decisions
- Trace feature evolution

## Archived Files (38 total)

### Bug Fixes & Issues
- CHECKBOX_ERROR_FIX.md
- DATA_VALIDATION_FIX.md
- PROPERTY_NAME_FIX.md
- RECORD_REFRESH_FIX_SUMMARY.md

### Implementation Summaries
- ACADEMIC_INTEREST_SELECTOR_GUIDE.md (superseded by ADMIN_TOOL_GUIDE.md)
- COMPONENT_UPDATE_SUMMARY.md
- CONSOLIDATION_COMPLETE.md
- DUAL_LISTBOX_IMPLEMENTATION.md
- INTERACTION_QUESTIONS_IMPLEMENTATION_SUMMARY.md
- LAYOUT_AND_MULTISELECT_ENHANCEMENT.md
- MULTI_SELECT_ENHANCEMENT.md
- SUMMARY_ACADEMIC_SELECTOR.md
- TWO_LEVEL_GROUPING_SUMMARY.md

### Deployment Docs
- ACTION_REQUIRED_FIELD_CREATION.md (consolidated into INTERACTION_QUESTIONS_SETUP.md)
- ADD_FIELD_FEATURE.md
- COMPONENT_COMPARISON_LEADS_VS_INTERACTIONS.md (consolidated into INTERACTION_QUESTIONS_SETUP.md)
- DEPLOYMENT_CHECKLIST.md
- DEPLOYMENT_CHECKLIST_INTERACTION_QUESTIONS.md
- DEPLOYMENT_COMPLETE.md
- DEPLOYMENT_GUIDE.md
- DEPLOYMENT_READY.md
- INTERACTION_QUESTIONS_INDEX.md
- MANUAL_FIELD_CREATION_REQUIRED.md (consolidated into INTERACTION_QUESTIONS_SETUP.md)

### Quick Starts & References
- LEGACY_FIELD_ORDER_SUPPORT.md
- LEGACY_ORDER_QUICK_REFERENCE.md
- ORDER_TRACKING_SOLUTION.md
- QUICK_REFERENCE.md (superseded by MAIN_GUIDE.md)
- QUICK_REFERENCE_RECORD_REFRESH.md
- QUICK_START.md (superseded by MAIN_GUIDE.md)
- QUICK_START_ACADEMIC_SELECTOR.md (consolidated into ADMIN_TOOL_GUIDE.md)
- QUICK_START_INTERACTION_QUESTIONS.md (consolidated into INTERACTION_QUESTIONS_SETUP.md)

### Technical Docs
- ARCHITECTURE_DIAGRAM.md (consolidated into MAIN_GUIDE.md)
- RFI_FIELD_MANAGER_RECORD_REFRESH.md
- RFI_FIELD_MANAGER_SUMMARY.md
- RFI_FORM_AUTO_REFRESH.md
- RFI_FORM_AUTO_REFRESH_IMPLEMENTATION.md
- RFI_FORM_REFRESH_TEST_GUIDE.md
- TESTING_RECORD_REFRESH.md

### Scripts
- deploy-interaction-questions.ps1 (deployment commands now in MAIN_GUIDE.md)

---

## Migration Path

If you're referencing an archived document, here's where to find current information:

| Old Document | Current Location |
|-------------|------------------|
| Bug fix docs | Fixed in codebase, see TROUBLESHOOTING.md if issues persist |
| QUICK_REFERENCE.md | MAIN_GUIDE.md or README.md |
| QUICK_START*.md | MAIN_GUIDE.md or component-specific guides |
| DEPLOYMENT*.md | MAIN_GUIDE.md → Deployment section |
| *_IMPLEMENTATION*.md | Component-specific guides or MAIN_GUIDE.md |
| ACTION_REQUIRED_FIELD_CREATION.md | INTERACTION_QUESTIONS_SETUP.md → Quick Setup |
| COMPONENT_COMPARISON*.md | INTERACTION_QUESTIONS_SETUP.md → Comparison section |

---

**Last Updated:** January 5, 2026  
**Status:** Archived - For reference only  
**Current Docs:** See parent `docs/` folder

