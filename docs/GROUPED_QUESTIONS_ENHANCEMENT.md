# Grouped Questions by Position - Enhancement

**Date:** January 6, 2026  
**Feature:** Group Top and Bottom questions separately in the UI  
**Status:** ✅ Deployed

---

## What Changed

Previously, all questions were displayed in a single list regardless of their position (top/bottom). This made it confusing to manage since "top" and "bottom" questions were intermixed.

Now, questions are grouped into two distinct sections:
- **Top of Form Questions**
- **Bottom of Form Questions**

---

## User Experience Improvements

### Before
```
All Questions (mixed)
├── Question 1 (top)
├── Question 2 (bottom)
├── Question 3 (top)
└── Question 4 (bottom)
```
❌ Confusing - hard to see which questions appear where  
❌ Dragging between different positions was unintuitive

### After
```
Top of Form Questions
├── Question 1 (top)
└── Question 3 (top)

Bottom of Form Questions
├── Question 2 (bottom)
└── Question 4 (bottom)
```
✅ Clear visual separation  
✅ Drag-drop only within same group  
✅ Easy to understand form structure

---

## Features

### Visual Grouping
- **Section Headers:** Clear headings for "Top of Form" and "Bottom of Form"
- **Separate Lists:** Each group has its own list
- **Only Show if Present:** Empty groups don't display

### Drag-and-Drop Constraints
- **Same-Group Only:** Can only drag within "Top" or "Bottom" group
- **Visual Feedback:** Drag-over styling only appears for valid drop targets
- **Prevented Cross-Group:** Attempting to drag from Top to Bottom (or vice versa) does nothing

### Arrow Buttons
- **Still Work:** Up/down arrows function as before
- **Within Same Group:** Moving follows the same position constraint

---

## Implementation Details

### JavaScript Changes

**Added Getters for Grouped Questions:**
```javascript
get topQuestions() {
    return this.questionJSON.filter(q => q.position === 'top');
}

get bottomQuestions() {
    return this.questionJSON.filter(q => q.position === 'bottom');
}

get hasTopQuestions() {
    return this.topQuestions.length > 0;
}

get hasBottomQuestions() {
    return this.bottomQuestions.length > 0;
}
```

**Track Position During Drag:**
```javascript
@track draggedItemPosition = null; // Track position group (top/bottom)

handleDragStart(event) {
    this.draggedItemId = parseInt(event.currentTarget.dataset.id);
    this.draggedItemPosition = event.currentTarget.dataset.position; // NEW
    event.currentTarget.classList.add('dragging');
}
```

**Enforce Same-Group Drops:**
```javascript
handleDragOver(event) {
    event.preventDefault();
    const dropTarget = event.currentTarget;
    const dropPosition = dropTarget.dataset.position;
    
    // Only allow drag-over styling if same position group
    if (this.draggedItemPosition === dropPosition) {
        dropTarget.classList.add('drag-over');
    }
}

async handleDrop(event) {
    // ...
    const dropPosition = event.currentTarget.dataset.position;
    
    // Don't allow drop if different position groups
    if (this.draggedItemPosition !== dropPosition || ...) {
        return;
    }
    // ... rest of drop logic
}
```

### HTML Changes

**Separate Lists by Position:**
```html
<!-- Top Questions Group -->
<template lwc:if={hasTopQuestions}>
    <div class="slds-m-bottom_large">
        <div class="slds-section-title_divider slds-m-bottom_small">
            <h3 class="slds-text-heading_small">Top of Form Questions</h3>
        </div>
        <ul class="slds-has-dividers_around-space question-list">
            <template for:each={topQuestions} for:item="question">
                <li data-position="top" ...>
                    <!-- question content -->
                </li>
            </template>
        </ul>
    </div>
</template>

<!-- Bottom Questions Group -->
<template lwc:if={hasBottomQuestions}>
    <!-- similar structure with data-position="bottom" -->
</template>
```

**Added data-position Attribute:**
- Each `<li>` now has `data-position="top"` or `data-position="bottom"`
- Used by drag handlers to enforce grouping

---

## Benefits

### For Administrators
✅ **Clearer Organization:** Immediately see which questions appear at top vs bottom  
✅ **Easier Management:** Don't have to mentally track position badges  
✅ **Better UX:** Drag-drop behavior matches visual grouping  
✅ **Less Confusion:** Can't accidentally drag questions into wrong section

### For Form Users (Indirect)
✅ **Consistent Order:** Admins less likely to make ordering mistakes  
✅ **Logical Flow:** Questions appear in intended sections

---

## Testing

### Verify Grouping
1. ✅ Create questions with both "top" and "bottom" positions
2. ✅ Verify they appear in separate groups
3. ✅ Verify group headers appear
4. ✅ Verify empty groups don't show

### Verify Drag-Drop Constraints
1. ✅ Drag a top question - can only drop on other top questions
2. ✅ Drag a bottom question - can only drop on other bottom questions
3. ✅ Try to drag from top to bottom - doesn't allow drop
4. ✅ Verify drag-over styling only appears for valid targets

### Verify Arrow Buttons Still Work
1. ✅ Use ↑↓ buttons to reorder within groups
2. ✅ Verify changes save correctly

---

## Files Changed

**Component Files:**
- `force-app/main/default/lwc/rfiAdditionalQuestionsInteractions/rfiAdditionalQuestionsInteractions.js`
  - Added `topQuestions`, `bottomQuestions` getters
  - Added `draggedItemPosition` tracking
  - Updated drag handlers to enforce same-group constraint

- `force-app/main/default/lwc/rfiAdditionalQuestionsInteractions/rfiAdditionalQuestionsInteractions.html`
  - Split single list into two grouped lists
  - Added section headers
  - Added `data-position` attributes
  - Conditional rendering for each group

---

## Deployment

```powershell
cci task run deploy --path force-app/main/default/lwc/rfiAdditionalQuestionsInteractions --org dev
```

**Status:** ✅ Deployed successfully at 8:44 AM

---

## User Instructions

### Current Behavior

When you open the Interaction Questions Manager component:

1. **If you have top questions:**
   - See "Top of Form Questions" heading
   - All questions with position="top" listed below
   
2. **If you have bottom questions:**
   - See "Bottom of Form Questions" heading  
   - All questions with position="bottom" listed below

3. **Reordering:**
   - Drag-drop only works within the same group
   - Arrow buttons work within the same group
   - To move a question from top to bottom (or vice versa), edit it and change the Position field

### To Change a Question's Position

1. Click the **Edit** (✎) button on the question
2. Change the **Position** dropdown to "Top" or "Bottom"
3. Click **Save**
4. Question will move to the appropriate group

---

## Future Enhancements

Potential improvements:
- [ ] Add drag-and-drop to change position (drag from top group to bottom group changes position)
- [ ] Show question count in each group header (e.g., "Top of Form Questions (3)")
- [ ] Add expand/collapse for each group
- [ ] Highlight which group is being dragged over

---

**Implemented by:** GitHub Copilot  
**Deployed:** January 6, 2026, 8:44 AM  
**Status:** ✅ Complete and tested  
**User Impact:** Positive - clearer organization, better UX

