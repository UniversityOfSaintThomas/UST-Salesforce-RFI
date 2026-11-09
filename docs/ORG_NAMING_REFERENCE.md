# Salesforce CLI Org Naming Quick Reference

## The Rule
**CumulusCI uses aliases, SF CLI uses full org names**

## For This Project (UST-Salesforce-RFI)

### CumulusCI Commands
```powershell
# Always use: --org dev
cci task run run_tests --org dev
cci task run deploy --path force-app/main/default/classes --org dev
cci org info dev
```

### SF CLI Commands
```powershell
# Always use: --target-org UST-Salesforce-RFI__dev
sf apex run test --target-org UST-Salesforce-RFI__dev --class-names MyTest
sf data query --query "SELECT Id FROM Account LIMIT 1" --target-org UST-Salesforce-RFI__dev
sf project deploy start --source-dir force-app --target-org UST-Salesforce-RFI__dev
```

## How to Find the Org Name

1. Open `cumulusci.yml`
2. Look for `project.name` (line 3)
3. Append `__dev` to it

Example from cumulusci.yml:
```yaml
project:
  name: UST-Salesforce-RFI  # This is the project name
```

Full org name = `UST-Salesforce-RFI__dev`

## Common Mistake
❌ **WRONG**: `sf apex run test --target-org dev`
✅ **RIGHT**: `sf apex run test --target-org UST-Salesforce-RFI__dev`

## Why This Matters
- CumulusCI manages org aliases in its config
- SF CLI uses Salesforce's actual org naming convention
- The `__dev` suffix is Salesforce's scratch org naming pattern
- Using the wrong name = "Org not found" errors

## Memory Aid
- **cci** = short alias (`dev`)
- **sf** = full name (`ProjectName__dev`)
