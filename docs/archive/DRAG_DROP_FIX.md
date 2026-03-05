# Drag-and-Drop Fix - Interaction Questions Component

**Date:** January 5, 2026  
**Issue:** Dragging questions down didn't work correctly  
**Status:** ✅ Fixed and deployed

---

## Problem Description

When dragging a question down in the list, the question would not end up in the expected position. The expectation was that when you drag an item "onto" another item lower in the list, the dragged item should appear AFTER the drop target.

### Example of the Issue

**Before fix:**
```
Questions: [A, B, C, D]
Drag B down to D
Expected: [A, C, D, B]  ✅ B should be after D
Actual: [A, C, B, D]    ❌ B ended up before D
```

---

## Root Cause

The original `handleDrop` function used this logic:

```javascript
// OLD CODE
const newIndex = this.draggedItemId < dropTargetId ? dropTargetId - 1 : dropTargetId;
```

This calculation would:
1. Remove the dragged item from the array
2. When dragging down: insert at `dropTargetId - 1`
3. When dragging up: insert at `dropTargetId`

### Why This Failed for Dragging Down

**Example:** Drag B(1) to D(3)
```
1. Initial: [A(0), B(1), C(2), D(3)]
2. Remove B: [A(0), C(1), D(2)]  ← D is now at index 2!
3. Calculate: newIndex = 3 - 1 = 2
4. Insert B at 2: [A(0), C(1), B(2), D(3)]
   Result: B is BEFORE D ❌
```

The issue: After removing B, D shifted from index 3 to index 2. Inserting at index 2 places B before D, not after.

---

## Solution

Simplified the logic to always use `dropTargetId` as the insert position:

```javascript
// NEW CODE
async handleDrop(event) {
    // ... validation code ...

    try {
        let updatedQuestions = [...this.questionJSON];
        const draggedItem = updatedQuestions[this.draggedItemId];

        // Remove dragged item first
        updatedQuestions.splice(this.draggedItemId, 1);

        // Insert at drop target position (works for both up and down!)
        const newIndex = dropTargetId;
        updatedQuestions.splice(newIndex, 0, draggedItem);

        // Reindex and save...
    }
}
```

### Why This Works

**Dragging DOWN - Example:** Drag B(1) to D(3)
```
1. Initial: [A(0), B(1), C(2), D(3)]
2. Remove B: [A(0), C(1), D(2)]  ← D is at index 2
3. Insert at dropTargetId (3): [A(0), C(1), D(2), B(3)]
   Result: B is AFTER D ✅
```

**Dragging UP - Example:** Drag D(3) to B(1)
```
1. Initial: [A(0), B(1), C(2), D(3)]
2. Remove D: [A(0), B(1), C(2)]  ← B stays at index 1
3. Insert at dropTargetId (1): [A(0), D(1), B(2), C(3)]
   Result: D is BEFORE B ✅
```

The key insight: When you remove an item from the array, indices shift. Using `dropTargetId` directly gives us the correct behavior:
- **Dragging down:** Item goes AFTER the target (because target shifted back)
- **Dragging up:** Item goes BEFORE the target (because target didn't move)

---

## Additional Improvements

1. **Added cleanup:** Set `this.draggedItemId = null` at the end to ensure state is cleared
2. **Better comments:** Explained the logic clearly for future maintainers
3. **Simplified code:** Removed unnecessary if/else since both branches now do the same thing

---

## Testing

To verify the fix:

1. **Create 4+ test questions** in the Interaction Questions Manager
2. **Drag down:** Drag question #1 to question #3
   - Expected: Question #1 appears AFTER question #3
3. **Drag up:** Drag question #4 to question #2
   - Expected: Question #4 appears BEFORE question #2
4. **Verify saving:** Questions should save in new order
5. **Refresh page:** Order should persist

---

## Deployment

```powershell
cci task run deploy --path force-app/main/default/lwc/rfiAdditionalQuestionsInteractions --org dev
```

**Status:** ✅ Deployed successfully on January 5, 2026 at 5:11 PM

---

##Files Changed

- `force-app/main/default/lwc/rfiAdditionalQuestionsInteractions/rfiAdditionalQuestionsInteractions.js`

**Lines modified:** handleDrop function (approximately lines 345-380)

---

**Reported by:** User  
**Fixed by:** GitHub Copilot  
**Status:** ✅ Resolved and deployed

