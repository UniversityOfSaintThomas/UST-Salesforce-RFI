# Unified Questions Field Creation Guide

## Field Required

The unified question manager requires a new field on the `RFI_Controller__c` object:

**Field Name:** Unified Questions  
**API Name:** `Unified_Questions__c`  
**Field Type:** Text Area (Long)  
**Length:** 131,072 characters  
**Visibility:** All profiles that access RFI Controller records  

## Manual Creation Steps

Since Salesforce CLI source tracking can sometimes fail to deploy new fields properly, **manual creation is recommended**:

1. Log into your Salesforce org
2. Go to **Setup** → **Object Manager**
3. Find and click **RFI Controller** (API name: `RFI_Controller__c`)
4. Click **Fields & Relationships**
5. Click **New**
6. Select **Text Area (Long)** and click **Next**
7. Fill in the details:
   - **Field Label:** `Unified Questions`
   - **Length:** `131072`
   - **Visiblelines:** `5`
   - **Field Name:** `Unified_Questions` (will auto-populate)
8. Click **Next**
9. Set field-level security (make it visible/editable for admin profiles)
10. Click **Next**
11. Do NOT add to page layouts (component handles its own data)
12. Click **Save**

## Verification

After creating the field, verify it exists:

```bash
# Query the field using Salesforce CLI
sf data query --query "SELECT Id, Unified_Questions__c FROM RFI_Controller__c LIMIT 1" --target-org UST-Salesforce-RFI__dev --use-tooling-api
```

## Alternative: Try Metadata Deployment First

You can attempt to deploy the field metadata if you prefer:

```bash
# Deploy the field metadata
cci task run deploy --path force-app/main/default/objects/RFI_Controller__c/fields/Unified_Questions__c.field-meta.xml --org dev
```

If this fails with "Unchanged" or other deployment issues, fall back to manual creation.

## Migration

Once the field exists, the unified question manager will:
1. Automatically detect when it's empty
2. Auto-migrate from legacy fields (`Fields_to_Display_Order__c` and `Interaction_Questions__c`)
3. Preserve all existing questions in the correct order (top → middle → bottom)
4. Save to the new field on first save

## Backward Compatibility

The `rfiFormController` Apex class has dual-path logic:
- **If `Unified_Questions__c` has data:** Uses the unified structure
- **If `Unified_Questions__c` is empty:** Falls back to legacy fields

This ensures existing forms continue to work during migration.

