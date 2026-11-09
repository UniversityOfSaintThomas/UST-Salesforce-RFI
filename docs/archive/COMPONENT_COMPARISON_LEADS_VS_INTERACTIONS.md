# Component Comparison: Leads vs Interactions

## Visual Comparison

### Original Component (rfiAdditionalQuestions - Leads)
```
┌─────────────────────────────────────────────────────────┐
│  Add a Question                                    [+]  │
├─────────────────────────────────────────────────────────┤
│  ╔══════════════════════════════════════════════════╗  │
│  ║ # │ Question │ Type │ Field │ Pos │ Values │ ↑↓✕ ║  │
│  ╠══════════════════════════════════════════════════╣  │
│  ║ 1 │ Email?   │ Email│ Email │ Top │        │ ↑↓✕ ║  │
│  ║ 2 │ How?     │ Pick │ Field │ Bot │ A;B;C  │ ↑↓✕ ║  │
│  ╚══════════════════════════════════════════════════╝  │
├─────────────────────────────────────────────────────────┤
│  Form Fields:                                           │
│  ┌─────────────────┐  ┌─────────────────┐             │
│  │ Question Type ▼ │  │ Position      ▼ │             │
│  └─────────────────┘  └─────────────────┘             │
│  ┌─────────────────┐  ┌─────────────────┐             │
│  │ Field to Apply▼ │  │ Question Label  │             │
│  └─────────────────┘  └─────────────────┘             │
│  ┌─────────────────────────────────────┐               │
│  │ Assistive Text                      │               │
│  └─────────────────────────────────────┘               │
│                                          [Add Question] │
└─────────────────────────────────────────────────────────┘
```

### New Component (rfiAdditionalQuestionsInteractions)
```
┌─────────────────────────────────────────────────────────┐
│  Interaction Questions Manager      [+ Add Question]    │
├─────────────────────────────────────────────────────────┤
│  ⚡ Drag questions to reorder, or use arrow buttons     │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │ ☰ Email Address                           ↑↓✎🗑   │ │
│  │   Type: Email required                             │ │
│  │   Field: Email__c  Position: top                   │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │ ☰ How did you hear about us?             ↑↓✎🗑   │ │
│  │   Type: Picklist required                          │ │
│  │   Field: Source__c  Position: bottom               │ │
│  │   Values: Website;Email;Social Media               │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │ ☰ Additional Comments                     ↑↓✎🗑   │ │
│  │   Type: Textarea                                   │ │
│  │   Field: Comments__c  Position: bottom             │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘

When clicking [+ Add Question] or [✎ Edit]:
┌─────────────────────────────────────────┐
│ ✕  Add Question                         │
├─────────────────────────────────────────┤
│ ┌──────────────┐  ┌──────────────────┐ │
│ │ Type       ▼ │  │ Position       ▼ │ │
│ └──────────────┘  └──────────────────┘ │
│ ┌────────────────────────────────────┐  │
│ │ Interaction Field to Apply to    ▼ │  │
│ └────────────────────────────────────┘  │
│ ┌────────────────────────────────────┐  │
│ │ Question Label                     │  │
│ └────────────────────────────────────┘  │
│ ┌────────────────────────────────────┐  │
│ │ Assistive Text                     │  │
│ └────────────────────────────────────┘  │
├─────────────────────────────────────────┤
│              [Cancel]    [Save]         │
└─────────────────────────────────────────┘
```

## Key Differences

### UI/UX Enhancements
| Feature | Original | New (Interactions) |
|---------|----------|-------------------|
| **Layout** | DataTable | Card-based list |
| **Drag-and-Drop** | ❌ No | ✅ Yes (HTML5 Drag API) |
| **Editing** | Below table | Modal popup |
| **Visual Feedback** | Console logs | Toast notifications |
| **Responsive** | Limited | Full mobile support |
| **Empty State** | No data | Helpful guidance |
| **Drag Handle** | N/A | ☰ Icon with cursor change |
| **Action Buttons** | Table cells | Button group |

### Functional Differences
| Feature | Original | New (Interactions) |
|---------|----------|-------------------|
| **Object** | Lead | Interaction__c |
| **Field** | Additional_Questions__c | Interaction_Questions__c |
| **Reordering** | Arrow buttons | Drag-drop + arrows |
| **Add/Edit** | Same form | Separate modal |
| **Delete** | Row action | Button with icon |
| **Validation** | Form validation | Modal validation |
| **Save Feedback** | Silent | Toast messages |

### User Interaction Flow

#### Original Component
```
1. User scrolls to form below table
2. Fills out all fields
3. Clicks "Add Question"
4. Page updates, form resets
5. To edit: Must delete and recreate
```

#### New Component
```
1. User clicks "+ Add Question"
2. Modal opens (focused experience)
3. Fills out fields with live validation
4. Clicks "Save"
5. Toast confirms success
6. To edit: Click ✎ icon, modify in modal
7. To reorder: Drag ☰ handle to new position
```

## Technical Improvements

### Code Architecture
```javascript
// Original: Direct table manipulation
@wire(getRecord, ...) addQuestionJSON({error, data}) { ... }

// New: Cleaner lifecycle with async loading
connectedCallback() { this.loadQuestions(); }
async loadQuestions() { ... }
```

### Reactivity Pattern
```javascript
// Original: Direct mutation
this.inputItem['questionLabel'] = event.target.value;

// New: Immutable updates for better reactivity
this.inputItem = {...this.inputItem, questionLabel: value};
```

### Error Handling
```javascript
// Original: Console logs
.catch(e => console.log(e));

// New: User-facing feedback
.catch(error => {
    this.showToast('Error', 'Failed: ' + error.message, 'error');
});
```

## Performance Considerations

| Aspect | Original | New |
|--------|----------|-----|
| **Initial Load** | Wire service | Wire + connectedCallback |
| **Rerender Triggers** | Table redraw | Selective updates |
| **DOM Manipulation** | Table rows | Card list items |
| **Data Structure** | Same JSON | Same JSON (compatible) |

## Migration Path

The components are **fully compatible** at the data level:

```javascript
// Both use identical JSON structure
{
    "id": 0,
    "questionLabel": "Email?",
    "questionType": "Email required",
    "fieldToApplyTo": "Email",
    // ... same fields
}
```

**Key Difference:** Storage field name
- Original: `Additional_Questions__c` (Leads)
- New: `Interaction_Questions__c` (Interactions)

This allows both components to coexist in the same org!

---

**Legend:**
- ☰ = Drag handle
- ✎ = Edit button
- 🗑 = Delete button
- ↑↓ = Move up/down buttons
- ✕ = Close/Delete
- ▼ = Dropdown

