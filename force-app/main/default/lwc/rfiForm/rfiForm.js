/**
 * Created by Thad-PC-2019 on 9/23/2025.
 */

import {api, LightningElement, track, wire} from 'lwc';
import {getFieldValue, getRecord} from 'lightning/uiRecordApi';
import getRFIForm from '@salesforce/apex/rfiFormController.getRFIForm';
import submitRFILead from '@salesforce/apex/rfiFormController.submitRFILead';
import getStateProvince from '@salesforce/apex/rfiFormController.getStateProvince';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {NavigationMixin} from 'lightning/navigation';
import RFI_CONTROLLER_NAME from '@salesforce/schema/RFI_Controller__c.Name';
import RFI_CONTROLLER_ID from '@salesforce/schema/RFI_Controller__c.Id';
import getPrograms from "@salesforce/apex/rfiFormController.getPrograms";

const RFI_CONTROLLER_FIELDS = [RFI_CONTROLLER_NAME, RFI_CONTROLLER_ID];

export default class RfiForm extends NavigationMixin(LightningElement) {
    @api rfiControllerName;
    @api recordId;
    @api googleApiKey; // optional: enable Google Places lookup for address

    @track lead = {};
    @track selectedCountry = 'US';
    @track stateOptions = [];
    @track filterValues;
    @track programValues;

    controllerName;
    rfiData;
    fields = [];
    values = {};
    countryOptions = [];
    saving = false;

    // reactive country used to wire server-side subdivisions
    connectedCallback() {
        this.controllerName = this.rfiControllerName;
    }

    @wire(getRecord, {recordId: '$recordId', fields: RFI_CONTROLLER_FIELDS})
    wiredRecord({data}) {
        if (data) {
            this.controllerName = getFieldValue(data, RFI_CONTROLLER_NAME);
        }
    }

    @wire(getRFIForm, {rfiControllerName: '$controllerName'})
    wiredForm(result) {
        const {data, error} = result;
        if (data) {
            this.rfiData = JSON.parse(JSON.stringify(data));
            this.fields = Array.isArray(this.rfiData?.rfiFieldList) ? this.rfiData.rfiFieldList : [];
            console.log('RFI fields loaded:', JSON.stringify(this.fields, null, 2));
            this.lead = this.rfiData.leadRecord || {};
            console.log('RFI lead record loaded:', JSON.stringify(this.lead, null, 2));
            this.countryOptions = this.rfiData.countryOptions;
            this.filterValues = this.rfiData.filterValues;
            this.programValues = this.rfiData.programValues;
            console.log('program values:', JSON.stringify(this.programValues, null, 2));
            console.log('filter values:', JSON.stringify(this.filterValues, null, 2));
            //this.stateOptions = this.rfiData.stateOptions;
        } else if (error) {
            console.error('Failed to fetch RFI form data', error);
            this.rfiData = undefined;
        }
    }

    // Handler for the reusable lookup component's custom event 'valueselected'
    handleSchoolSelect = (event) => {
        // the lookup component may communicate the target field name in a few ways.
        // Try event.detail.fieldName first, then dataset on currentTarget/target.
        let name = event.detail?.fieldName || event.currentTarget?.dataset?.fieldName || event.target?.dataset?.fieldName;
        const detail = event.detail || {};
        const selectedId = detail.id || '';
        const display = detail.mainField ? (detail.mainField + (detail.subField ? ' - ' + detail.subField : '')) : '';

        // fallback: if name is still not found, pick the first field marked as isSchoolLookup
        if (!name) {
            const fallbackIdx = this.fields.findIndex(f => f.isSchoolLookup);
            if (fallbackIdx > -1) {
                name = this.fields[fallbackIdx].name;
            }
        }

        if (!name) {
            // nothing we can do
            return;
        }

        // update values map
        this.values = {...this.values, [name]: selectedId};

        // find field and update its value and the lead SObject mapping
        const idx = this.fields.findIndex(f => f.name === name);
        if (idx > -1) {
            const field = this.fields[idx];
            const api = (field.fieldLeadAPIName || '').trim();
            const updated = {...field, value: selectedId, selectedLabel: display};
            this.fields = [
                ...this.fields.slice(0, idx),
                updated,
                ...this.fields.slice(idx + 1)
            ];
            if (api) {
                this.lead = {...this.lead, [api]: selectedId};
            }
        }
    }

    handleAcademicInterestChange = (event) => {
        const value = event.detail?.value ?? event.detail;
        //Apply multi select values to Major_Program__c, Major_Program_2__c, Major_Program_3__c, Major_Program_4__c fields
        if (!Array.isArray(value)) return;
        if (value.length > 0) {
            //map to Major_Program__c, Major_Program_2__c, Major_Program_3__c, Major_Program_4__c
            this.lead = {
                ...this.lead,
                Major_Program__c: value[0] || '',
                Major_Program_2__c: value[1] || '',
                Major_Program_3__c: value[2] || '',
                Major_Program_4__c: value[3] || ''
            };
        }
    }

    handleProgramFilterChange = async (event) => {
        const value = event.detail?.value ?? event.detail;
        const name = event.target.name;
        this.filterValues[name] = value;
        //check if all filterValues are set
        const allSet = Object.values(this.filterValues).every(v => v && v.length > 0);
        if (allSet) {
            try {
                this.programValues = await getPrograms({
                    academic_level: this.rfiData.academicLevel,
                    school_college: this.rfiData.schoolCollege,
                    academic_interest_codes: this.rfiData.academicInterestCodes,
                    filters: this.filterValues
                });
                console.log('Program values updated:', JSON.stringify(this.programValues, null, 2));
            } catch (error) {
                console.error('Error fetching programs:', error);
            }
        }
        console.log('Updated filterValues:', JSON.stringify(this.filterValues, null, 2));

    }

    handleMultiSelectChange = (event) => {
        const name = event.target.name;
        const value = event.detail?.value ?? event.detail;
        const field = this.fields.find(f => f.name === name);
        if (!field) return;

        field.value = value;
        if (field.fieldLeadAPIName) {
            this.lead = {...this.lead, [field.fieldLeadAPIName]: value};
        }
    }

    handleAddressChange = async (event) => {
        //Get an address record from the event detail and apply it to this.lead
        const address = event.detail;
        if (!address) return;
        //If country changes then update state options
        if (address.country && address.country !== this.selectedCountry) {
            console.log('Country changed to', address.country);
            this.selectedCountry = address.country;
            this.stateOptions = await getStateProvince(
                {countryCode: this.selectedCountry}
            );
            console.log('State options updated:', JSON.stringify(this.stateOptions, null, 2));
        }
        console.log('Address change event received:', JSON.stringify(address, null, 2));
        //update lead object with address fields
        let countryLabel = '';
        if (address.country) {
            //get the country string from the label using the country code value of countryOptions
            const countryOption = this.countryOptions.find(option => option.value === address.country);
            countryLabel = countryOption ? countryOption.label : address.country;
        }

        this.lead = {
            ...this.lead,
            Street: address.street || '',
            City: address.city || '',
            State: address.state || '',
            PostalCode: address.postalCode || '',
            Country: countryLabel || '',
            CountryCode: address.country || ''
        };
    }

    async handleSubmit() {

        //validate the form
        const allInputs = this.template.querySelectorAll('lightning-input');
        let isValid = true;

        // Check validity of each input
        allInputs.forEach(input => {
            if (!input.checkValidity()) {
                isValid = false;
                input.reportValidity(); // Display the error message
            } else {
                //apply the values to lead object using input name for field api name
                this.lead[input.name] = input.value; // Update lead object with valid input values
            }
        });

        if (isValid) {
            //save lead using submitRFILead apex method
            this.saving = true;
            await submitRFILead({
                leadRecord: this.lead
            }).then((result) => {
                console.log('Lead submission result:', result);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Your information has been submitted successfully.',
                        variant: 'success'
                    })
                );
            }).error((error) => {
                console.error('Error submitting lead:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'There was an error submitting your information. Please try again later.',
                        variant: 'error'
                    })
                );
            }).finally(() => {
                this.saving = false;
                //reset the form for new submission and allow submission again
                this.lead = {};
            });
        } else {
            console.log('Form is invalid. Please correct the errors.');
        }
    }

    get hasData() {
        return Array.isArray(this.fields) && this.fields.length > 0;
    }

    checkForErrors() {
        this.errors = [];
        const selection = this.template.querySelector('c-lookup').getSelection();
        // Custom validation rule
        if (this.isMultiEntry && selection.length > this.maxSelectionSize) {
            this.errors.push({message: `You may only select up to ${this.maxSelectionSize} items.`});
        }
        // Enforcing required field
        if (selection.length === 0) {
            this.errors.push({message: 'Please make a selection.'});
        }
    }
}