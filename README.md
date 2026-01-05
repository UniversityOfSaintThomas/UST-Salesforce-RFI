# UST Salesforce RFI

This project provides a Lightning Web Component (LWC) for collecting Requests for Information (RFI) from potential applicants. User input is captured and used to create Salesforce Lead records. The questions presented in the RFI are managed through a custom Salesforce object, `RFI_Controller__c`.

## Components

### RFI Form Components
- **rfiForm** - Public-facing form for lead capture
- **requestForInformationForm** - Legacy RFI form
- **rfiFieldManager** - Field configuration management

### Admin Configuration Tools
- **academicInterestSelector** - Admin tool to configure which academic programs appear on public RFI forms
  - Shows ALL available programs grouped by school/degree
  - Displays full program names (not codes)
  - Auto-saves to `Academic_Interests_To_Display__c`
  - No selection limits for administrators
- **rfiAdditionalQuestions** - Manage additional questions for Lead objects
- **rfiAdditionalQuestionsInteractions** - NEW! Manage additional questions for Interaction objects
  - Modern drag-and-drop sorting
  - Modal-based editing
  - Toast notifications
  - 🚀 [Setup Guide](docs/ACTION_REQUIRED_FIELD_CREATION.md)
  - 📚 [Complete Documentation](docs/INTERACTION_QUESTIONS_INDEX.md)

## Documentation

📁 **All documentation is located in the [docs](docs/) folder**

### Quick Links
- **[Quick Start](docs/QUICK_START.md)** - Getting started
- **[Deployment Guide](docs/DEPLOYMENT_GUIDE.md)** - Deployment instructions
- **[Interaction Questions Setup](docs/ACTION_REQUIRED_FIELD_CREATION.md)** - New component setup (2 min)
- **[Full Documentation Index](docs/README.md)** - Complete documentation listing

## Development

To work on this project in a scratch org:

1. [Set up CumulusCI](https://cumulusci.readthedocs.io/en/latest/tutorial.html)
2. Run `cci flow run dev_org --org dev` to deploy this project.
3. Run `cci org browser dev` to open the org in your browser.