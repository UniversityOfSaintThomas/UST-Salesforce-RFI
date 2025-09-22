# UST Salesforce RFI

This project provides a Lightning Web Component (LWC) for collecting Requests for Information (RFI) from potential applicants. User input is captured and used to create Salesforce Lead records. The questions presented in the RFI are managed through a custom Salesforce object, `RFI_Controller__c`.

## Development

To work on this project in a scratch org:

1. [Set up CumulusCI](https://cumulusci.readthedocs.io/en/latest/tutorial.html)
2. Run `cci flow run dev_org --org dev` to deploy this project.
3. Run `cci org browser dev` to open the org in your browser.