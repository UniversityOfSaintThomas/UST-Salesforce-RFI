# Quick Start: RFI Interaction Questions Component

## Deployment (5 Minutes)

### Option 1: Automated Script
```powershell
.\deploy-interaction-questions.ps1
```

### Option 2: Manual Steps
```powershell
# Deploy field first
cci task run deploy --path force-app/main/default/objects/RFI_Controller__c/fields/Interaction_Questions__c.field-meta.xml --org dev

# Deploy component
cci task run deploy --path force-app/main/default/lwc/rfiAdditionalQuestionsInteractions --org dev
```

## Add to Page Layout

1. Open any RFI Controller record
2. Click ⚙️ (gear icon) → **Edit Page**
3. Find **rfiAdditionalQuestionsInteractions** in component list
4. Drag it onto the page layout
5. Click **Save** → **Activate**

## First Use

### Add Your First Question
1. Click **"+ Add Question"** button
2. Fill in:
   - **Question Type**: Email required
   - **Position**: Top
   - **Field to Apply**: Email (or custom field)
   - **Question Label**: What is your email address?
   - **Assistive Text**: We'll use this to contact you
3. Click **Save**

### Reorder Questions
- **Drag**: Click ☰ icon and drag to new position
- **Arrows**: Click ↑ or ↓ buttons

### Edit Question
- Click ✎ (pencil icon)
- Modify fields
- Click **Save**

### Delete Question
- Click 🗑 (trash icon)
- Question removed immediately

## Tips

✅ **Use drag-and-drop** for fast reordering  
✅ **Toast notifications** confirm every action  
✅ **Modal editing** keeps you focused  
✅ **Auto-save** after every change  

## Troubleshooting

❌ **Component not visible?**  
→ Check field security on `Interaction_Questions__c`

❌ **No fields in dropdown?**  
→ Add custom fields to Interaction__c object

❌ **Drag not working?**  
→ Use arrow buttons instead

## Documentation

📚 **Full Guide**: `docs/RFI_INTERACTION_QUESTIONS_GUIDE.md`  
📊 **Comparison**: `docs/COMPONENT_COMPARISON_LEADS_VS_INTERACTIONS.md`  
📝 **Summary**: `INTERACTION_QUESTIONS_IMPLEMENTATION_SUMMARY.md`

---

**Ready to deploy!** 🚀

