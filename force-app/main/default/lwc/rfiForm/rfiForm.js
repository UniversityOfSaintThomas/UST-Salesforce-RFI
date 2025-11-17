/**
 * Created by Thad-PC-2019 on 9/23/2025.
 */

import {api, LightningElement, track, wire} from 'lwc';
import {getFieldValue, getRecord} from 'lightning/uiRecordApi';
import {refreshApex} from '@salesforce/apex';
import getRFIForm from '@salesforce/apex/rfiFormController.getRFIForm';
import submitRFILead from '@salesforce/apex/rfiFormController.submitRFILead';
import getStateProvince from '@salesforce/apex/rfiFormController.getStateProvince';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {NavigationMixin, CurrentPageReference} from 'lightning/navigation';
import RFI_CONTROLLER_NAME from '@salesforce/schema/RFI_Controller__c.Name';
import RFI_CONTROLLER_ID from '@salesforce/schema/RFI_Controller__c.Id';
import RFI_CONTROLLER_FIELDS_TO_DISPLAY from '@salesforce/schema/RFI_Controller__c.Fields_to_Display__c';
import RFI_CONTROLLER_FIELDS_ORDER from '@salesforce/schema/RFI_Controller__c.Fields_to_Display_Order__c';
import RFI_CONTROLLER_ACADEMIC_INTERESTS from '@salesforce/schema/RFI_Controller__c.Academic_Interests_To_Display__c';
import getPrograms from "@salesforce/apex/rfiFormController.getPrograms";

const RFI_CONTROLLER_FIELDS = [
    RFI_CONTROLLER_NAME,
    RFI_CONTROLLER_ID,
    RFI_CONTROLLER_FIELDS_TO_DISPLAY,
    RFI_CONTROLLER_FIELDS_ORDER,
    RFI_CONTROLLER_ACADEMIC_INTERESTS
];

export default class RfiForm extends NavigationMixin(LightningElement) {
    @api rfiControllerName;
    @api recordId;
    @api googleApiKey;

    @track lead = {};
    @track selectedCountry = 'US';
    @track stateOptions = [];
    @track filterValues;
    @track programValues;
    @track cantFindSchool;
    @track iHaveAQuestion;

    rfiData;
    fields = [];
    values = {};
    countryOptions = [];
    saving = false;

    // Store the current page reference for URL parameters
    currentPageReference;

    // Internal property to store controller name from record (not the @api property)
    _controllerNameFromRecord;

    // Store wired results for refreshApex
    wiredRecordResult;
    wiredFormResult;

    // Track previous values to detect changes
    _lastFieldsToDisplay;
    _lastFieldsOrder;
    _lastAcademicInterests;

    @wire(CurrentPageReference)
    setCurrentPageReference(pageRef) {
        this.currentPageReference = pageRef;
    }

    connectedCallback() {

    }

    @wire(getRecord, {recordId: "$recordId", fields: RFI_CONTROLLER_FIELDS})
    rfiControllerInfo(result) {
        this.wiredRecordResult = result;
        const {error, data} = result;

        if (error) {
            console.log('Error fetching RFI Controller record:', error);
        } else if (data) {
            this._controllerNameFromRecord = getFieldValue(data, RFI_CONTROLLER_NAME);

            // Get field values for change detection
            const newFieldsToDisplay = getFieldValue(data, RFI_CONTROLLER_FIELDS_TO_DISPLAY);
            const newFieldsOrder = getFieldValue(data, RFI_CONTROLLER_FIELDS_ORDER);
            const newAcademicInterests = getFieldValue(data, RFI_CONTROLLER_ACADEMIC_INTERESTS);

            // Check if this is an update (not initial load)
            const isUpdate = this._lastFieldsToDisplay !== undefined ||
                           this._lastFieldsOrder !== undefined ||
                           this._lastAcademicInterests !== undefined;

            // Check if any relevant fields have changed
            const hasChanges = isUpdate && (
                newFieldsToDisplay !== this._lastFieldsToDisplay ||
                newFieldsOrder !== this._lastFieldsOrder ||
                newAcademicInterests !== this._lastAcademicInterests
            );

            if (hasChanges) {
                console.log('🔄 RFI Controller record updated - refreshing form data');
                console.log('Fields to Display changed:', this._lastFieldsToDisplay !== newFieldsToDisplay);
                console.log('Fields Order changed:', this._lastFieldsOrder !== newFieldsOrder);
                console.log('Academic Interests changed:', this._lastAcademicInterests !== newAcademicInterests);

                // Refresh the form data
                this.refreshFormData();
            }

            // Store current values for next comparison
            this._lastFieldsToDisplay = newFieldsToDisplay;
            this._lastFieldsOrder = newFieldsOrder;
            this._lastAcademicInterests = newAcademicInterests;
        }
    }

    // Getter to determine which controller name to use
    // Priority: 1) @api property set by parent, 2) value from record
    get effectiveControllerName() {
        return this.rfiControllerName || this._controllerNameFromRecord;
    }

    @wire(getRFIForm, {rfiControllerName: '$effectiveControllerName'})
    wiredForm(result) {
        this.wiredFormResult = result;
        const {data, error} = result;
        if (data) {
            this.rfiData = JSON.parse(JSON.stringify(data));
            this.fields = Array.isArray(this.rfiData?.rfiFieldList) ? this.rfiData.rfiFieldList : [];
            console.log('RFI fields loaded:', JSON.stringify(this.fields, null, 2));
            this.lead = this.rfiData.leadRecord || {};
            this.countryOptions = this.rfiData.countryOptions;
            this.filterValues = this.rfiData.filterValues;
            this.programValues = this.rfiData.programValues;
            this.stateOptions = this.rfiData.stateOptions;
            this.cantFindSchool = this.rfiData.cantFindSchool;
        } else if (error) {
            console.error('Failed to fetch RFI form data', error);
            this.rfiData = undefined;
        }
    }

    /**
     * Refresh the form data when RFI Controller fields change
     * Called automatically when monitored fields are updated
     */
    async refreshFormData() {
        try {
            if (this.wiredFormResult) {
                await refreshApex(this.wiredFormResult);
                console.log('✅ RFI Form data refreshed successfully');
            }
        } catch (error) {
            console.error('Error refreshing RFI Form data:', error);
        }
    }

    /**
     * Public API method to manually refresh all data
     * Can be called programmatically by parent components if needed
     */
    @api
    async refreshData() {
        try {
            const promises = [];
            if (this.wiredRecordResult) {
                promises.push(refreshApex(this.wiredRecordResult));
            }
            if (this.wiredFormResult) {
                promises.push(refreshApex(this.wiredFormResult));
            }
            await Promise.all(promises);
            console.log('✅ All RFI Form data refreshed successfully (manual refresh)');
        } catch (error) {
            console.error('Error refreshing RFI Form data:', error);
        }
    }

    // Handler for the "I can't find my school" checkbox
    handleCantFindSchoolChange = (event) => {
        this.cantFindSchool = event.target.checked;

        // If checkbox is checked, clear the school lookup value
        if (this.cantFindSchool) {
            // Clear High_School_or_College__c field
            this.lead = {...this.lead, High_School_or_College__c: ''};
        }
    }

    // Handler for manual school name entry
    handleManualSchoolEntry = (event) => {
        const schoolName = event.target.value;
        // Map to High_School_or_College__c field
        this.lead = {...this.lead, High_School_or_College__c: schoolName};
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

    handleCheckboxChange = (event) => {
        const name = event.target.name;
        const checked = event.target.checked;
        if (name.toLowerCase() === 'has_question__c') {
            this.iHaveAQuestion = checked;
            console.log('iHaveAQuestion updated to:', this.iHaveAQuestion);
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
            } catch (error) {
                console.error('Error fetching programs:', error);
            }
        }
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

    handlePicklistChange = (event) => {
        const selectedValue = event.detail.value
        const name = event.target.name;
        this.lead = {...this.lead, [name]: selectedValue};
    }

    handleAddressChange = async (event) => {
        //Get an address record from the event detail and apply it to this.lead
        const address = event.detail;
        if (!address) return;
        //If country changes then update state options
        if (address.country && address.country !== this.selectedCountry) {
            this.selectedCountry = address.country;
            this.stateOptions = await getStateProvince(
                {countryCode: this.selectedCountry}
            );
        }
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
                console.log(`Input valid: ${input.name} = ${input.value}`);
                this.lead[input.name] = input.value; // Update lead object with valid input values
            }
        });

        if (isValid) {
            //save lead using submitRFILead apex method
            this.saving = true;

            // Add UTM and tracking parameters to lead before submission
            this.lead.utm_campaign__c = this.getUrlParamValue('utm_campaign');
            this.lead.utm_medium__c = this.getUrlParamValue('utm_medium');
            this.lead.utm_source__c = this.getUrlParamValue('utm_source');
            this.lead.utm_content__c = this.getUrlParamValue('utm_content');
            this.lead.utm_term__c = this.getUrlParamValue('utm_term');
            this.lead.utm_id__c = this.getUrlParamValue('utm_id');
            this.lead.utm_creative_format__c = this.getUrlParamValue('utm_creative_format');
            this.lead.utm_marketing_topic__c = this.getUrlParamValue('utm_marketing_topic');
            this.lead.utm_source_platform__c = this.getUrlParamValue('utm_source_platform');
            this.lead.gclid__c = this.getUrlParamValue('gclid');
            this.lead.nominator_contact__c = this.getUrlParamValue('sfcid');
            this.lead.Lead_Website__c = window.location.href;
            this.lead.Lead_Website_Referrer__c = document.referrer;

            console.log('Submitting lead:', JSON.stringify(this.lead, null, 2));
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

    /**
     * Gets url parameters to populate utm fields
     * Checks CurrentPageReference state first (for standard Salesforce pages),
     * then falls back to URL parsing (for Lightning Out on external sites)
     * @param {string} param - The parameter name to extract
     * @returns {string} - The parameter value or empty string
     */
    getUrlParamValue(param) {
        try {
            // First try CurrentPageReference state (Lightning-native)
            const pageState = this.currentPageReference?.state || {};
            if (pageState[param]) {
                return pageState[param];
            }
            if (pageState['c__' + param]) {
                return pageState['c__' + param];
            }

            // Fallback to URL parsing (Lightning Out compatibility)
            const urlObject = new URL(window.location.href);
            return urlObject.searchParams.get(param) || urlObject.searchParams.get('c__' + param) || '';
        } catch (e) {
            console.error('Error parsing URL parameter:', e);
            return '';
        }
    }

    get hasData() {
        return Array.isArray(this.fields) && this.fields.length > 0;
    }
}