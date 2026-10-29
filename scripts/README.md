# Scripts

One-off scripts that are not part of the deployed app. Each script explains itself in its header.

| Script | Purpose |
|---|---|
| `apex/migrate_rfi_questions.apex` | Repairs saved RFI Controller question lists (wrong field names, split address questions, removed question). Dry run by default. ECRMSF-6047. |

Run an Apex script with `sf apex run --target-org <alias> --file scripts/apex/<name>.apex`. Read the dry-run
report before saving. Scripts that write data are run by the repository owner in shared environments
(see AGENTS.md).
