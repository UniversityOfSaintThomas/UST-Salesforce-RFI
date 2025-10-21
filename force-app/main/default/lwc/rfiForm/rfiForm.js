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

const RFI_CONTROLLER_FIELDS = [RFI_CONTROLLER_NAME, RFI_CONTROLLER_ID];

export default class RfiForm extends NavigationMixin(LightningElement) {
    @api rfiControllerName;
    @api recordId;
    @api googleApiKey; // optional: enable Google Places lookup for address

    @track academic_interest_picklist_values;

    controllerName;
    rfiData;
    fields = [];
    values = {};
    lead = {};
    countryOptions = [];
    stateOptions = [];
    saving = false;
    // reactive country used to wire server-side subdivisions
    selectedCountry = '';

    connectedCallback() {
        this.controllerName = this.rfiControllerName;
    }

    // wire server-side subdivisions for the currently selected country
    @wire(getStateProvince, {country: '$selectedCountry'})
    wiredSubdivisions({data, error}) {
        if (data) {
            // Apex returns List<picklistOption> with shape {label, value}
            this.stateOptions = Array.isArray(data) ? data : [];
            console.log('Fetched subdivisions for', this.selectedCountry, '->', JSON.stringify(this.stateOptions));
        } else if (error) {
            // fallback to client-side mapping when server fails
            this.stateOptions = this._getStateOptions(this.selectedCountry);
            console.warn('Failed to fetch subdivisions for', this.selectedCountry, '; falling back to client mapping', error);
        }
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
            console.log('RFI form data', JSON.stringify(data, null, 2));
            this.rfiData = JSON.parse(JSON.stringify(data));
            this.fields = Array.isArray(this.rfiData?.rfiFieldList) ? this.rfiData.rfiFieldList : [];
            this.countryOptions = this.rfiData.countryOptions;
            // initialize selectedCountry so the wired Apex method runs and populates stateOptions
            const initialCountryRaw = this.lead && (this.lead.Country || this.lead.CountryCode) ? (this.lead.Country || this.lead.CountryCode) : '';
            this.selectedCountry = this._resolveCountryKey(initialCountryRaw);
        } else if (error) {
            console.error('Failed to fetch RFI form data', error);
            this.rfiData = undefined;
        }
    }

    // Resolve a raw country string (label or code) to the canonical picklist value from countryOptions if possible.
    _resolveCountryKey(raw) {
        if (!raw) return '';
        const c = String(raw).toLowerCase().trim();
        if (Array.isArray(this.countryOptions)) {
            // try exact match on value or label
            const exact = this.countryOptions.find(o => String(o.value).toLowerCase() === c || String(o.label).toLowerCase() === c);
            if (exact) return exact.value || exact.label || raw;
            // try contains match on label
            const partial = this.countryOptions.find(o => String(o.label).toLowerCase().includes(c));
            if (partial) return partial.value || partial.label || raw;
        }
        return raw;
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


    // change handlers
    handleChange = (event) => {
        /*        const name = event.target.name;
                console.log('handleChange for', name);
                const rawValue = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
                const field = this.fields.find(f => f.name === name);
                if (!field) return;

                field.value = rawValue;

                if (field.fieldLeadAPIName) {
                    this.lead = { ...this.lead, [field.fieldLeadAPIName]: rawValue };
                }*/
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

    handleAddressChange = (event) => {
        const fieldName = event.target.dataset.fieldName;
        const field = this.fields.find(f => f.name === fieldName);
        if (!field) return;

        const addressValue = event.detail; // adapt to event contract
        field.value = addressValue;
        if (field.fieldLeadAPIName) {
            this.lead = {...this.lead, [field.fieldLeadAPIName]: addressValue};
        }
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
            });
        } else {
            console.log('Form is invalid. Please correct the errors.');
        }
    }

    get hasData() {
        return Array.isArray(this.fields) && this.fields.length > 0;
    }
}