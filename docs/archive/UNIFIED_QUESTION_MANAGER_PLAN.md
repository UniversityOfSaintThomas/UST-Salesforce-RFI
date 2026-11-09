# Unified Question Manager - Implementation Plan

**Created:** March 2, 2026  
**Status:** Planning

## Overview

Consolidate the RFI Field Configuration Manager (`rfiFieldManager`) and Additional Questions Manager (`rfiAdditionalQuestionsInteractions`) into a single unified tool that manages all questions in one place.

## Current Architecture

### Components
1. **rfiFieldManager** - Manages pre-configured questions
   - Uses: `Fields_to_Display__c` (multiselect picklist)
   - Uses: `Fields_to_Display_Order__c` (text field for ordering)
   - Uses: `Required_Fields__c` (multiselect picklist)
   - Uses: Various label fields (`First_Name_Label__c`, etc.)
   - Location: "Middle" section of form

2. **rfiAdditionalQuestionsInteractions** - Manages free-form questions
   - Uses: `Interaction_Questions__c` (JSON long text area)
   - Supports: Top and Bottom positions
   - Allows: Custom question types, field mapping, picklists

### Current Form Structure
```
┌─────────────────────────────────┐
│  TOP QUESTIONS                  │  (Additional Questions - position: 'top')
├─────────────────────────────────┤
│  MIDDLE QUESTIONS               │  (Pre-configured Fields)
│  - First Name                   │
│  - Last Name                    │
│  - Email                        │
│  - etc.                         │
├─────────────────────────────────┤
│  BOTTOM QUESTIONS               │  (Additional Questions - position: 'bottom')
└─────────────────────────────────┘
```

## Proposed Unified Architecture

### New Data Structure

**New Field:** `Unified_Questions__c` (Long Text Area, 131072 characters)

**JSON Schema:**
```json
[
  {
    "id": 0,
    "type": "preconfigured|custom",
    "questionLabel": "First Name",
    "fieldName": "First Name",           // For preconfigured
    "fieldInteractionAPIName": "First_Name__c", // Maps to Interaction field
    "isRequired": true,
    "isVisible": true,
    "questionType": "Text box required", // For custom questions
    "fieldToApplyTo": "Custom_Field__c", // For custom questions
    "picklistValues": [],                // For custom picklist
    "valuesFlat": "",                    // For static content
    "assistiveText": ""                  // Help text
  }
]
```

### Migration Strategy

**Phase 1: Create New Component (Non-Breaking)**
- Create `rfiUnifiedQuestionManager` component
- Read from existing fields AND new `Unified_Questions__c` field
- If `Unified_Questions__c` is blank, auto-migrate on load
- Keep existing components working

**Phase 2: Auto-Migration Logic**
```javascript
// On first load of unified manager:
1. Read Fields_to_Display_Order__c (or Fields_to_Display__c)
2. Read Interaction_Questions__c
3. Combine into unified structure:
   - Top questions first (from Interaction_Questions__c)
   - Pre-configured fields in middle (from Fields_to_Display_Order__c)
   - Bottom questions last (from Interaction_Questions__c)
4. Save to Unified_Questions__c
5. Mark as migrated (optional flag field)
```

**Phase 3: Update Form Renderer**
- Modify `rfiFormController.cls` to read from `Unified_Questions__c`
- Fall back to old structure if unified field is empty (backward compatibility)
- Return single array of questions in order

**Phase 4: Deprecation (Later)**
- After all orgs migrated, old components can be removed
- Old fields can be deprecated

## Implementation Details

### Component: rfiUnifiedQuestionManager

**Features:**
- Drag-and-drop reordering (like current tools)
- Add pre-configured questions from picklist
- Add custom questions with modal form
- Edit question labels inline
- Toggle required checkbox
- Delete questions (except First Name/Last Name)
- Visual indicators for pre-configured vs custom

**UI Design:**
```
┌─────────────────────────────────────────────────────────┐
│ RFI Unified Question Manager                           │
│                                                         │
│ [+ Add Pre-configured Question ▼] [+ Add Custom Question] │
│                                                         │
│ ┌─────────────────────────────────────────────────┐   │
│ │ 1. ≡ First Name (Pre-configured)                 │   │
│ │    Label: [First Name____________] [x] Required  │   │
│ │    Maps to: First_Name__c                        │   │
│ └─────────────────────────────────────────────────┘   │
│ ┌─────────────────────────────────────────────────┐   │
│ │ 2. ≡ Email (Pre-configured)                      │   │
│ │    Label: [Email_________________] [x] Required  │   │
│ │    Maps to: Email__c                             │   │
│ │    [Edit] [Remove]                               │   │
│ └─────────────────────────────────────────────────┘   │
│ ┌─────────────────────────────────────────────────┐   │
│ │ 3. ≡ What program interests you? (Custom)        │   │
│ │    Type: Picklist required                       │   │
│ │    Maps to: Program_Interest__c                  │   │
│ │    Values: MBA, MSW, PhD                         │   │
│ │    [Edit] [Remove]                               │   │
│ └─────────────────────────────────────────────────┘   │
│                                                         │
│                                     [Save Configuration]│
└─────────────────────────────────────────────────────────┘
```

### Apex Controller Changes

**File:** `rfiFormController.cls`

**Method:** `getRFIForm()`

**Logic:**
```apex
// Check if unified field exists and has data
if (String.isNotBlank(rfiController.Unified_Questions__c)) {
    // NEW PATH: Use unified questions
    List<Object> unifiedQuestions = (List<Object>) JSON.deserializeUntyped(rfiController.Unified_Questions__c);
    
    for (Object qObj : unifiedQuestions) {
        Map<String, Object> q = (Map<String, Object>) qObj;
        rfiField newField = new rfiField();
        
        // Populate rfiField based on type
        if (q.get('type') == 'preconfigured') {
            // Use existing field mapping logic
            newField.fieldLabel = (String) q.get('questionLabel');
            newField.fieldInteractionAPIName = (String) q.get('fieldInteractionAPIName');
            newField.isRequired = (Boolean) q.get('isRequired');
            // ... set other properties
        } else {
            // Custom question
            newField.fieldLabel = (String) q.get('questionLabel');
            newField.fieldInteractionAPIName = (String) q.get('fieldToApplyTo');
            newField.isRequired = (Boolean) q.get('isRequired');
            // ... handle custom types
        }
        
        interactionAndRfi.rfiFieldList.add(newField);
    }
} else {
    // LEGACY PATH: Use old structure (backward compatibility)
    // Keep existing code that reads Fields_to_Display_Order__c
    // and Interaction_Questions__c
}
```

## Benefits

### For Admins
✅ Single tool to manage all questions  
✅ No confusion about top/middle/bottom sections  
✅ Easier to understand question ordering  
✅ Drag entire list to reorder  
✅ Mix pre-configured and custom questions anywhere  

### For Developers
✅ Single data source  
✅ Cleaner code  
✅ Easier to maintain  
✅ Better extensibility  

### For End Users (Form Submitters)
✅ No change - form loads just as fast  
✅ Questions appear in intuitive order  
✅ Seamless experience  

## Backward Compatibility

### During Migration
- Old components still work
- Old fields still read
- New component reads old fields if unified field is empty
- Auto-migration on first save

### After Migration
- Keep old fields for historical reference
- Document deprecation timeline
- Provide rollback path if needed

## Performance Considerations

### Form Loading
- Current: 2-3 separate data reads (Fields_to_Display, Interaction_Questions)
- New: 1 data read (Unified_Questions)
- Result: **Faster or equal performance**

### Apex Processing
- Current: Multiple switch statements, filtering, ordering
- New: Single loop through unified array
- Result: **Faster processing**

### Caching
- `@AuraEnabled(Cacheable=true)` still applies
- Form still loads quickly
- No impact on end user experience

## Implementation Steps

1. ✅ Create planning document (this file)
2. ⬜ Create `Unified_Questions__c` field on RFI_Controller__c
3. ⬜ Create `rfiUnifiedQuestionManager` LWC component
4. ⬜ Implement auto-migration logic
5. ⬜ Update `rfiFormController.cls` with dual-path logic
6. ⬜ Test with existing RFI configurations
7. ⬜ Deploy to dev org
8. ⬜ User acceptance testing
9. ⬜ Documentation
10. ⬜ Rollout to production

## Risks & Mitigations

### Risk: Data Loss During Migration
**Mitigation:** 
- Don't delete old fields
- Auto-migration creates new field, leaves old intact
- Easy rollback if needed

### Risk: Breaking Existing Forms
**Mitigation:**
- Dual-path logic in Apex (reads old OR new)
- Extensive testing before rollout
- Gradual migration (one RFI at a time)

### Risk: Performance Degradation
**Mitigation:**
- Single JSON parse is faster than multiple
- Caching still applies
- Test with large question lists

### Risk: User Confusion
**Mitigation:**
- Clear documentation
- Training materials
- In-app help text
- Gradual rollout

## Next Steps

1. Review this plan with team
2. Get approval for new field creation
3. Begin implementation of unified component
4. Create comprehensive tests
5. Document migration process

## Questions for Discussion

1. Should migration be automatic or manual (admin-triggered)?
2. Keep old components available or hide them?
3. What's the deprecation timeline for old structure?
4. Need a "Convert to Unified" button in old components?

