# UST Salesforce RFI

This project provides a Lightning Web Component (LWC) for collecting Requests for Information (RFI) from potential applicants. User input is captured and used to create Salesforce Lead records. The questions presented in the RFI are managed through a custom Salesforce object, `RFI_Controller__c`.

## Components

### RFI Form Components
- **rfiForm** - Public-facing form for lead capture
- **requestForInformationForm** - Legacy RFI form
- **rfiFieldManager** - Field configuration management

### Admin Configuration Tools
- **academicInterestSelector** - NEW! Admin tool to configure which academic programs appear on public RFI forms
  - Shows ALL available programs grouped by school/degree
  - Displays full program names (not codes)
  - Auto-saves to `Academic_Interests_To_Display__c`
  - No selection limits for administrators
  - 📚 [Complete Documentation](docs/README.md)

## Documentation

All documentation for the Academic Interest Selector component is located in the **[docs](docs/)** folder:

- **[Quick Start Guide](docs/QUICK_REFERENCE.md)** - One-page overview
- **[Admin Tool Guide](docs/ADMIN_TOOL_GUIDE.md)** - Complete admin documentation
- **[Deployment Guide](docs/DEPLOYMENT_READY.md)** - Deployment instructions
- **[Full Documentation Index](docs/README.md)** - Complete documentation listing

## Development

To work on this project in a scratch org:

1. [Set up CumulusCI](https://cumulusci.readthedocs.io/en/latest/tutorial.html)
2. Run `cci flow run dev_org --org dev` to deploy this project.
3. Run `cci org browser dev` to open the org in your browser.