# Agent Instructions — UST Salesforce RFI

## ⚡ Read First — Every Session

Before taking any action, read the onboarding skill: agent-onboarding

## Project Overview

This repo builds the **Request for Information (RFI) form** for University of St. Thomas — a
Lightning Web Component that collects prospective-student information and creates
`Interaction__c` records (Salesforce Education Cloud). The form is **admin-configurable**: each
form is driven by an `RFI_Controller__c` record, and a set of companion LWCs let admins build and
configure forms without code. The public form is surfaced on external (non-Salesforce) websites
via **Lightning Out**.

### How it fits together

- **`RFI_Controller__c`** — the config object. One record defines one form: which questions appear,
  in what order, which academic programs/filters are offered, lead source, redirect behavior, etc.
- **The form** (`rfiForm`) — reads its controller via Apex, renders the configured questions, and on
  submit creates an `Interaction__c`. Runs on record/home pages, Experience Cloud sites, and
  externally via Lightning Out.
- **The building tools** — admin LWCs placed on the `RFI_Controller__c` record page that let staff
  assemble the form (question manager, academic-program selector).

### Component map

**Public-facing form**
| Component | Writes to | Status |
|---|---|---|
| `rfiForm` | `Interaction__c` | ✅ Active — the form |
| `requestForInformationForm` | `Lead` | 📦 Legacy — reference only, do not modify |

**Admin tools (on the `RFI_Controller__c` record page)**
| Component | Purpose |
|---|---|
| `rfiUnifiedQuestionManager` | Primary tool — manage all questions (preconfigured / custom / filter), order, and settings. Source of truth: `Unified_Questions__c` JSON |
| `academicInterestSelector` | Pick which academic programs appear in the Academic Interest question; auto-saves to `Academic_Interests_To_Display__c` |

**Reusable / supporting components**
| Component | Purpose |
|---|---|
| `multiSelectPillsGroupable` (+ `Item`, `Pill`) | Grouped multi-select with pills, used in the form and selector |
| `reusableLookup` | Generic record lookup used in the form |

**Apex**
| Class | Role |
|---|---|
| `rfiFormController` | Builds the form from its controller (`getRFIForm`), processes unified/legacy questions, fetches programs, and submits the `Interaction__c` |
| `AcademicInterestSelectorController` | Backs the academic interest admin tool |
| `ReusableLookupController` | Backs `reusableLookup` |

### Lightning Out (external embedding)

The form is embedded on external marketing/department websites using Lightning Out. The
`requestForInformationApp` Aura application (`extends="ltng:outApp"`,
`implements="ltng:allowGuestAccess"`) is the dependency app that exposes the form to a guest
(unauthenticated) audience outside of Salesforce.

### Tech & conventions

- **Stack:** Salesforce DX + CumulusCI + IntelliJ IDEA + Illuminated Cloud; LWC + Apex
- **Shell:** PowerShell (Windows) — never use cmd syntax
- **Org type:** Scratch orgs managed by CumulusCI (`--org dev`)
- **Testing:** Jest (LWC unit), Apex tests, Robot Framework (E2E)
- **Deploys:** always **targeted** (`cci task run deploy --path <path> --org dev`) — never
  `cci flow run dev_org` against a configured scratch org, it wipes test data

### Deeper detail

`docs/AI-TOOLS-CONFIG.md` is the authoritative reference for current architecture, the
`Unified_Questions__c` JSON schema, the Apex dual-path (unified vs. legacy) logic, data-storage
patterns, org aliases, and step-by-step common tasks. Read it before changing form behavior or the
question pipeline.