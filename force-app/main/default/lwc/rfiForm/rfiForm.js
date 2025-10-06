/**
 * Created by Thad-PC-2019 on 9/23/2025.
 */

import {api, LightningElement, wire} from 'lwc';
import {getFieldValue, getRecord} from 'lightning/uiRecordApi';
import getRFIForm from '@salesforce/apex/rfiFormController.getRFIForm';
import submitRFILead from '@salesforce/apex/rfiFormController.submitRFILead';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {NavigationMixin} from 'lightning/navigation';
import RFI_CONTROLLER_NAME from '@salesforce/schema/RFI_Controller__c.Name';
import RFI_CONTROLLER_ID from '@salesforce/schema/RFI_Controller__c.Id';

const RFI_CONTROLLER_FIELDS = [RFI_CONTROLLER_NAME, RFI_CONTROLLER_ID];

export default class RfiForm extends NavigationMixin(LightningElement) {
    @api rfiControllerName;
    @api recordId;
    @api googleApiKey; // optional: enable Google Places lookup for address

    controllerName;
    rfiData;
    fields = [];
    values = {};
    lead = {};
    countryOptions = [];
    stateOptions = [];
    saving = false;

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
            // hydrate lead from wrapper (may be empty new Lead())
            this.lead = {...(this.rfiData.leadRecord || {})};
            this.countryOptions = this.rfiData.country;
            this.stateOptions = this.rfiData.state;
            this.normalizeFields();
        } else if (error) {
            this.rfiData = undefined;
            this.fields = [];
            this.values = {};
            this.lead = {};
        }
    }

    normalizeFields() {
        const list = Array.isArray(this.rfiData?.rfiFieldList) ? this.rfiData.rfiFieldList : [];
        const values = {};
        this.fields = list.map((f, i) => {
            const apiName = (f.fieldLeadAPIName || '').trim();
            const key = apiName ? `${apiName}__${i}` : `field_${i}`;
            const name = key;
            // detect special school lookup field
            const isSchoolLookup = apiName === 'High_School_or_College__c';
            const type = f.fieldType || (isSchoolLookup ? 'school-lookup' : 'text');
            const isCheckbox = type === 'checkbox';
            const isTextarea = type === 'textarea';
            const isMultiSelect = type === 'multi-select';
            const isAddress = type === 'address';
            const isPicklist = type === 'picklist';
            const inputType = isCheckbox || isTextarea || isMultiSelect || isAddress || isPicklist || isSchoolLookup ? undefined : type;

            let initial;
            if (isAddress) {
                initial = {
                    street: this.lead.Street || '',
                    city: this.lead.City || '',
                    province: this.lead.StateCode || this.lead.State || '',
                    postalCode: this.lead.PostalCode || '',
                    country: this.lead.CountryCode || this.lead.Country || ''
                };
            } else if (isCheckbox) {
                initial = Boolean(this.lead[apiName]);
            } else {
                const raw = this.lead[apiName];
                initial = raw === null || raw === undefined ? '' : String(raw);
            }

            const field = {
                ...f,
                index: i,
                key,
                name,
                type,
                inputType,
                isCheckbox,
                isTextarea,
                isMultiSelect,
                isAddress,
                isSchoolLookup,
                value: initial,
                selectedLabel: '',
                options: isMultiSelect && Array.isArray(f.picklistValues)
                    ? f.picklistValues.map(v => ({label: v, value: v}))
                    : undefined
            };
            values[name] = initial;
            return field;
        });
        this.values = values;
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

    // Clear the selected school for a given field (triggered by a small clear button)
    handleSchoolClear(event) {
        const name = event.currentTarget?.dataset?.fieldName;
        if (!name) return;
        // clear values
        this.values = {...this.values, [name]: ''};
        const idx = this.fields.findIndex(f => f.name === name);
        if (idx > -1) {
            const field = this.fields[idx];
            const api = (field.fieldLeadAPIName || '').trim();
            const updated = {...field, value: '', selectedLabel: ''};
            this.fields = [
                ...this.fields.slice(0, idx),
                updated,
                ...this.fields.slice(idx + 1)
            ];
            if (api) {
                // remove mapping from lead
                const {[api]: _, ...rest} = this.lead;
                this.lead = {...rest};
            }
        }
    }

    // change handlers
    handleChange = (event) => {
        const {name, type} = event.target;
        let value;
        if (type === 'checkbox') {
            value = event.target.checked;
        } else {
            value = event.detail?.value ?? event.target.value;
        }
        // update state
        this.values = {...this.values, [name]: value};
        const idx = this.fields.findIndex(f => f.name === name);
        if (idx > -1) {
            const field = this.fields[idx];
            const api = (field.fieldLeadAPIName || '').trim();
            // mirror UI field value
            const updated = {...field, value};
            this.fields = [
                ...this.fields.slice(0, idx),
                updated,
                ...this.fields.slice(idx + 1)
            ];
            // sync into lead record by API name
            if (api) {
                this.lead = {...this.lead, [api]: value};
            }
        }
    }

    handleMultiSelectChange = (event) => {
        const name = event.target.name;
        const arr = Array.isArray(event.detail?.value) ? event.detail.value : [];
        const value = arr.join(';');
        this.values = {...this.values, [name]: value};
        const idx = this.fields.findIndex(f => f.name === name);
        if (idx > -1) {
            const field = this.fields[idx];
            const api = (field.fieldLeadAPIName || '').trim();
            const updated = {...field, value};
            this.fields = [
                ...this.fields.slice(0, idx),
                updated,
                ...this.fields.slice(idx + 1)
            ];
            if (api) {
                this.lead = {...this.lead, [api]: value};
            }
        }
    }

    handleAddressChange = (event) => {
        const name = event.target.dataset.fieldName;
        const detail = event.detail || {};
        const value = {
            street: detail.street || '',
            city: detail.city || '',
            province: detail.province || '',
            postalCode: detail.postalCode || '',
            country: detail.country || ''
        };
        this.values = {...this.values, [name]: value};
        const idx = this.fields.findIndex(f => f.name === name);
        if (idx > -1) {
            const field = this.fields[idx];
            const updated = {...field, value};
            this.fields = [
                ...this.fields.slice(0, idx),
                updated,
                ...this.fields.slice(idx + 1)
            ];
            // sync to Lead SObject fields
            this.lead = {
                ...this.lead,
                Street: value.street,
                City: value.city,
                State: value.province,
                PostalCode: value.postalCode,
                Country: value.country
            };
        }
    }

    async handleSubmit() {
        // validate lightning-input, lightning-textarea, and lightning-input-address
        const baseInputs = [...this.template.querySelectorAll('lightning-input, lightning-textarea, lightning-input-address')];
        const baseValid = baseInputs.reduce((acc, c) => (typeof c.reportValidity === 'function' ? c.reportValidity() : true) && acc, true);
        // validate custom multi-select
        const multiSelects = [...this.template.querySelectorAll('c-multi-select-pills-groupable')];
        const msValid = multiSelects.reduce((acc, c) => (typeof c.checkValidity === 'function' ? c.checkValidity() : true) && acc, true);
        // validate reusable lookup components
        const reusableLookups = [...this.template.querySelectorAll('c-reusable-lookup')];
        const rlValid = reusableLookups.reduce((acc, c) => (typeof c.checkValidity === 'function' ? c.checkValidity() : true) && acc, true);

        if (!baseValid || !msValid || !rlValid) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Fix validation errors',
                message: 'Please correct the highlighted fields and try again.',
                variant: 'error'
            }));
            return;
        }

        this.saving = true;
        try {
            const id = await submitRFILead({leadRecord: this.lead});
            this.dispatchEvent(new ShowToastEvent({
                title: 'Submitted',
                message: `Lead created: ${id}`,
                variant: 'success'
            }));
            // navigate to the newly created lead
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: id,
                    objectApiName: 'Lead',
                    actionName: 'view'
                }
            });
            // optional reset: clear values and lead
            this.normalizeFields();
        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Submit failed',
                message: e?.body?.message || e?.message || 'Unknown error',
                variant: 'error'
            }));
        } finally {
            this.saving = false;
        }
    }

    get hasData() {
        return Array.isArray(this.fields) && this.fields.length > 0;
    }
}