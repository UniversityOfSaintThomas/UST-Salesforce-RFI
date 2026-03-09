/**
 * Created by Thad-PC-2019 on 9/23/2025.
 */

import {api, LightningElement, track, wire} from 'lwc';
import {getFieldValue, getRecord} from 'lightning/uiRecordApi';
import {refreshApex} from '@salesforce/apex';
import getRFIForm from '@salesforce/apex/rfiFormController.getRFIForm';
import submitRfiInteraction from '@salesforce/apex/rfiFormController.submitRfiInteraction';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {NavigationMixin, CurrentPageReference} from 'lightning/navigation';
import RFI_CONTROLLER_NAME from '@salesforce/schema/RFI_Controller__c.Name';
import RFI_CONTROLLER_ID from '@salesforce/schema/RFI_Controller__c.Id';
import RFI_CONTROLLER_FIELDS_TO_DISPLAY from '@salesforce/schema/RFI_Controller__c.Fields_to_Display__c';
import RFI_CONTROLLER_FIELDS_ORDER from '@salesforce/schema/RFI_Controller__c.Fields_to_Display_Order__c';
import RFI_CONTROLLER_ACADEMIC_INTERESTS from '@salesforce/schema/RFI_Controller__c.Academic_Interests_To_Display__c';
import RFI_CONTROLLER_UNIFIED_QUESTIONS from '@salesforce/schema/RFI_Controller__c.Unified_Questions__c';
import getPrograms from "@salesforce/apex/rfiFormController.getPrograms";

const RFI_CONTROLLER_FIELDS = [
    RFI_CONTROLLER_NAME,
    RFI_CONTROLLER_ID,
    RFI_CONTROLLER_FIELDS_TO_DISPLAY,
    RFI_CONTROLLER_FIELDS_ORDER,
    RFI_CONTROLLER_ACADEMIC_INTERESTS,
    RFI_CONTROLLER_UNIFIED_QUESTIONS
];


/**
 * Debounce utility function
 * @param {Function} func - Function to debounce
 * @param {number} wait - Delay in milliseconds
 * @returns {Function} - Debounced function
 */
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func.apply(this, args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

export default class RfiForm extends NavigationMixin(LightningElement) {
    @api rfiControllerName;
    @api recordId;
    @api googleApiKey;

    @track interaction = {};
    @track selectedCountry = 'US';
    @track stateOptions = [];
    @track filterValues;
    @track programValues;
    @track cantFindSchool;
    @track iHaveAQuestion;
    @track loadingPrograms = false;

    // Redirect settings from RFI Controller
    redirectUrl;
    redirectAfterSubmission;

    rfiData;
    _fields = [];
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
    _lastUnifiedQuestions;

    // Memoization caches
    _processedFieldsCache = null;
    _processedFieldsCacheKey = null;
    _programValuesCacheKey = null;
    _urlParamsCache = {};

    // Debounced handlers (initialized in connectedCallback)
    _debouncedProgramFilterChange;

    @wire(CurrentPageReference)
    setCurrentPageReference(pageRef) {
        this.currentPageReference = pageRef;
        // Clear URL params cache when page reference changes
        this._urlParamsCache = {};
    }

    connectedCallback() {
        // Initialize debounced handlers
        this._debouncedProgramFilterChange = debounce(this._processProgramFilterChange.bind(this), 200);
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
            const newUnifiedQuestions = getFieldValue(data, RFI_CONTROLLER_UNIFIED_QUESTIONS);

            // Check if this is an update (not initial load)
            const isUpdate = this._lastFieldsToDisplay !== undefined ||
                           this._lastFieldsOrder !== undefined ||
                           this._lastAcademicInterests !== undefined ||
                           this._lastUnifiedQuestions !== undefined;

            // Check if any relevant fields have changed
            const hasChanges = isUpdate && (
                newFieldsToDisplay !== this._lastFieldsToDisplay ||
                newFieldsOrder !== this._lastFieldsOrder ||
                newAcademicInterests !== this._lastAcademicInterests ||
                newUnifiedQuestions !== this._lastUnifiedQuestions
            );

            if (hasChanges) {
                // Invalidate caches
                this._invalidateCaches();
                // Refresh the form data
                this.refreshFormData();
            }

            // Store current values for next comparison
            this._lastFieldsToDisplay = newFieldsToDisplay;
            this._lastFieldsOrder = newFieldsOrder;
            this._lastAcademicInterests = newAcademicInterests;
            this._lastUnifiedQuestions = newUnifiedQuestions;
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
            // Only process if data actually changed
            const dataString = JSON.stringify(data);
            if (dataString !== this._lastDataString) {
                this._lastDataString = dataString;
                this._processFormData(data);
            }
        } else if (error) {
            console.error('Failed to fetch RFI form data', error);
            this.rfiData = undefined;
        }
    }

    /**
     * Process form data from wire adapter
     * Separated for clarity and potential reuse
     */
    _processFormData(data) {
        this.rfiData = JSON.parse(JSON.stringify(data));
        this._fields = Array.isArray(this.rfiData?.rfiFieldList) ? this.rfiData.rfiFieldList : [];

        // Invalidate field cache when new data arrives
        this._invalidateCaches();

        console.log('RFI fields loaded:', this._fields.length, 'fields');
        this.interaction = this.rfiData.interaction || {};
        this.countryOptions = this.rfiData.countryOptions;
        this.filterValues = this.rfiData.filterValues;
        this.programValues = this.rfiData.programValues;
        this.stateOptions = this.rfiData.stateOptions;
        this.cantFindSchool = this.rfiData.cantFindSchool;
        this.redirectUrl = this.rfiData.redirectUrl;
        this.redirectAfterSubmission = this.rfiData.redirectAfterSubmission;
    }

    /**
     * Invalidate all memoization caches
     */
    _invalidateCaches() {
        this._processedFieldsCache = null;
        this._processedFieldsCacheKey = null;
        this._programValuesCacheKey = null;
    }


    /**
     * Check if all filter questions have been answered
     */
    get allFiltersAnswered() {
        if (!this.filterValues || Object.keys(this.filterValues).length === 0) {
            return true;
        }
        return Object.values(this.filterValues).every(v => v && v.length > 0);
    }

    /**
     * Get processed fields with unique keys.
     * All fields are always visible. The program lookup is disabled until all filters answered.
     * Memoized for performance.
     */
    get fields() {
        // Generate cache key from field state and filter state
        const cacheKey = JSON.stringify({
            fields: this._fields.map(f => ({
                name: f.name,
                value: f.value,
                selectedLabel: f.selectedLabel,
                isProgramFilter: f.isProgramFilter,
                isProgramLookup: f.isProgramLookup
            })),
            filterValues: this.filterValues,
            allFiltersAnswered: this.allFiltersAnswered
        });

        if (this._processedFieldsCacheKey === cacheKey && this._processedFieldsCache) {
            return this._processedFieldsCache;
        }

        const filtersAnswered = this.allFiltersAnswered;
        this._processedFieldsCache = this._fields.map((field, index) => ({
            ...field,
            key: field.fieldInteractionAPIName || field.name || `field-${index}`,
            isVisible: true,
            // Program lookup is disabled (locked) until all filters are selected
            isDisabled: field.isProgramLookup ? !filtersAnswered : (field.isDisabled || false)
        }));

        this._processedFieldsCacheKey = cacheKey;
        return this._processedFieldsCache;
    }

    /**
     * Setter for fields to update internal _fields
     */
    set fields(value) {
        this._fields = value;
        this._processedFieldsCache = null;
        this._processedFieldsCacheKey = null;
    }

    /**
     * Refresh the form data when RFI Controller fields change
     * Called automatically when monitored fields are updated
     */
    async refreshFormData() {
        try {
            this._lastDataString = null;
            if (this.wiredFormResult) {
                await refreshApex(this.wiredFormResult);
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
            this.interaction = {...this.interaction, High_School_or_College__c: ''};
        }
    }

    // Handler for manual school name entry
    handleManualSchoolEntry = (event) => {
        const schoolName = event.target.value;
        // Map to High_School_or_College__c field
        this.interaction = {...this.interaction, High_School_or_College__c: schoolName};
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
            const fallbackIdx = this._fields.findIndex(f => f.isSchoolLookup);
            if (fallbackIdx > -1) {
                name = this._fields[fallbackIdx].name;
            }
        }

        if (!name) {
            // nothing we can do
            return;
        }

        // update values map
        this.values = {...this.values, [name]: selectedId};

        // find field and update its value and the interaction SObject mapping
        const idx = this._fields.findIndex(f => f.name === name);
        if (idx > -1) {
            const field = this._fields[idx];
            const api = (field.fieldInteractionAPIName || '').trim();
            const updated = {...field, value: selectedId, selectedLabel: display};
            this._fields = [
                ...this._fields.slice(0, idx),
                updated,
                ...this._fields.slice(idx + 1)
            ];
            // Invalidate cache
            this._processedFieldsCache = null;
            this._processedFieldsCacheKey = null;

            if (api) {
                this.interaction = {...this.interaction, [api]: selectedId};
            }
        }
    }

    handleAcademicInterestChange = (event) => {
        const value = event.detail?.value ?? event.detail;
        //Apply multi select values to Major_Program__c, Major_Program_2__c, Major_Program_3__c, Major_Program_4__c fields
        if (!Array.isArray(value)) return;
        if (value.length > 0) {
            //map to Major_Program__c, Major_Program_2__c, Major_Program_3__c, Major_Program_4__c
            this.interaction = {
                ...this.interaction,
                Major_Program_1__c: value[0] || '',
                Major_Program_2__c: value[1] || '',
                Major_Program_3__c: value[2] || '',
                Major_Program_4__c: value[3] || ''
            };
        }
    }

    handleCheckboxChange = (event) => {
        const name = event.target.name;
        const checked = event.target.checked;

        // Special handling for "I have a question" to show/hide dependent field
        if (name && name.toLowerCase() === 'has_question__c') {
            this.iHaveAQuestion = checked;
        }

        // Store checkbox value in interaction object if field name is provided
        if (name) {
            this.interaction = {...this.interaction, [name]: checked};
        }
    }

    // Public handler that uses debounced internal method
    handleProgramFilterChange = (event) => {
        const value = event.detail?.value ?? event.detail;
        const name = event.target.name;
        // Update immediately for UI responsiveness
        this.filterValues = {...this.filterValues, [name]: value};

        // IMPORTANT: Also update the interaction object so filter values are saved
        // Filter questions map to interaction fields (e.g., St_Thomas_College_School__c, Citizenship__c, etc.)
        this.interaction = {
            ...this.interaction,
            [name]: value,  // Store the filter value in the interaction
            Major_Program_1__c: '',
            Major_Program_2__c: '',
            Major_Program_3__c: '',
            Major_Program_4__c: ''
        };

        // Set loading state
        this.loadingPrograms = true;

        // Invalidate field cache so visibility updates immediately
        this._processedFieldsCache = null;
        this._processedFieldsCacheKey = null;

        // Debounce the expensive API call
        this._debouncedProgramFilterChange();
    }

    // Internal debounced handler for program filter
    async _processProgramFilterChange() {
        // Check if all filterValues are set
        const allSet = Object.values(this.filterValues).every(v => v && v.length > 0);
        if (allSet) {
            // Generate cache key
            const cacheKey = JSON.stringify({
                academicLevel: this.rfiData.academicLevel,
                schoolCollege: this.rfiData.schoolCollege,
                academicInterestCodes: this.rfiData.academicInterestCodes,
                filters: this.filterValues
            });

            // Always fetch if cache key changed (even if filters were previously answered)
            if (this._programValuesCacheKey !== cacheKey) {
                try {
                    this.programValues = await getPrograms({
                        academic_level: this.rfiData.academicLevel,
                        school_college: this.rfiData.schoolCollege,
                        academic_interest_codes: this.rfiData.academicInterestCodes,
                        filters: this.filterValues
                    });
                    this._programValuesCacheKey = cacheKey;
                } catch (error) {
                    console.error('Error fetching programs:', error);
                } finally {
                    // Clear loading state after fetch completes
                    this.loadingPrograms = false;
                }
            } else {
                // Using cached values, no need to load
                this.loadingPrograms = false;
            }
        } else {
            // If filters are incomplete, clear program values and cache
            this.programValues = [];
            this._programValuesCacheKey = null;
            this.loadingPrograms = false;
        }
    }

    handleMultiSelectChange = (event) => {
        const name = event.target.name;
        const value = event.detail?.value ?? event.detail;
        const fieldIndex = this._fields.findIndex(f => f.name === name);
        if (fieldIndex === -1) return;

        const field = this._fields[fieldIndex];

        // Update field value immutably
        this._fields = [
            ...this._fields.slice(0, fieldIndex),
            {...field, value},
            ...this._fields.slice(fieldIndex + 1)
        ];

        // Invalidate cache
        this._processedFieldsCache = null;
        this._processedFieldsCacheKey = null;

        if (field.fieldInteractionAPIName) {
            this.interaction = {...this.interaction, [field.fieldInteractionAPIName]: value};
        }
    }

    handlePicklistChange = (event) => {
        const selectedValue = event.detail.value;
        const name = event.target.name;
        this.interaction = {...this.interaction, [name]: selectedValue};
    }

    // Store address for processing on submit
    handleAddressChange = (event) => {
        const address = event.detail;
        if (!address) return;
        this._pendingAddress = address;
    }

    /**
     * Process stored address and add to interaction
     * Called during form submission
     */
    _processAddressForSubmit() {
        const address = this._pendingAddress;
        if (!address) return;

        // Get country label from options
        let countryLabel = '';
        let stateLabel = '';
        if (address.country) {
            const countryOption = this.countryOptions.find(option => option.value === address.country);
            countryLabel = countryOption ? countryOption.label : address.country;
        }
        if(address.province) {
            const stateOption = this.stateOptions.find(option => option.value === address.province);
            stateLabel = stateOption ? stateOption.label : address.province;
        }

        this.interaction = {
            ...this.interaction,
            Mailing_Street__c: address.street || '',
            Mailing_City__c: address.city || '',
            Mailing_Country__c: countryLabel || '',
            Mailing_State__c: stateLabel || '',
            Mailing_Postal_Code__c: address.postalCode || ''
        };
    }

    /**
     * Validate all form elements
     * Returns true if all elements are valid
     */
    _validateForm() {
        let isValid = true;

        // Validate all input types in a single pass per type
        const validationConfigs = [
            { selector: 'lightning-input', checkMethod: 'checkValidity', reportMethod: 'reportValidity' },
            { selector: 'lightning-combobox', checkMethod: 'checkValidity', reportMethod: 'reportValidity' },
            { selector: 'lightning-textarea', checkMethod: 'checkValidity', reportMethod: 'reportValidity' },
            { selector: 'c-multi-select-pills-groupable', checkMethod: 'checkValidity', reportMethod: 'reportValidity' }
        ];

        for (const config of validationConfigs) {
            const elements = this.template.querySelectorAll(config.selector);
            elements.forEach(element => {
                if (element[config.checkMethod] && !element[config.checkMethod]()) {
                    isValid = false;
                    if (element[config.reportMethod]) {
                        element[config.reportMethod]();
                    }
                }
            });
        }

        // Collect input values for valid inputs
        if (isValid) {
            const allInputs = this.template.querySelectorAll('lightning-input');
            allInputs.forEach(input => {
                if (input.name) {
                    this.interaction[input.name] = input.type === 'checkbox' ? input.checked : input.value;
                }
            });

            const allTextareas = this.template.querySelectorAll('lightning-textarea');
            allTextareas.forEach(textarea => {
                if (textarea.name) {
                    this.interaction[textarea.name] = textarea.value;
                }
            });
        }

        return isValid;
    }

    /**
     * Add UTM and tracking parameters to Interaction
     */
    _addTrackingParams() {
        const trackingFields = [
            { interactionField: 'utm_campaign__c', param: 'utm_campaign' },
            { interactionField: 'utm_medium__c', param: 'utm_medium' },
            { interactionField: 'utm_source__c', param: 'utm_source' },
            { interactionField: 'utm_content__c', param: 'utm_content' },
            { interactionField: 'utm_term__c', param: 'utm_term' },
            { interactionField: 'utm_id__c', param: 'utm_id' },
            { interactionField: 'utm_creative_format__c', param: 'utm_creative_format' },
            { interactionField: 'utm_marketing_topic__c', param: 'utm_marketing_topic' },
            { interactionField: 'utm_source_platform__c', param: 'utm_source_platform' },
            //{ interactionField: 'gclid__c', param: 'gclid' },
            { interactionField: 'Nominator_Contact__c', param: 'sfcid' }
        ];

        for (const { interactionField, param } of trackingFields) {
            this.interaction[interactionField] = this.getUrlParamValue(param);
        }

        this.interaction.Lead_Website__c = window.location.href;
        this.interaction.Lead_Website_Referrer__c = document.referrer;
    }

    async handleSubmit() {
        // Validate the form
        const isValid = this._validateForm();

        if (isValid) {
            this.saving = true;

            // Process address data before submit
            this._processAddressForSubmit();

            // Add UTM and tracking parameters
            this._addTrackingParams();

            console.log('Submitting Interaction:', JSON.stringify(this.interaction, null, 2));

            try {
                const result = await submitRfiInteraction({ interaction: this.interaction });
                console.log('Interaction submission result:', result);

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Your information has been submitted successfully.',
                        variant: 'success'
                    })
                );

                // Redirect if configured on the RFI Controller
                if (this.redirectAfterSubmission && this.redirectUrl) {
                    window.open(this.redirectUrl, '_self');
                } else {
                    // No redirect - reset the form for new submission
                    this.resetForm();
                }
            } catch (error) {
                console.error('Error submitting Interaction:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'There was an error submitting your information. Please try again later.',
                        variant: 'error'
                    })
                );
            } finally {
                this.saving = false;
            }
        } else {
            console.log('Form is invalid. Please correct the errors.');
        }
    }

    /**
     * Gets url parameters to populate utm fields
     * Checks CurrentPageReference state first (for standard Salesforce pages),
     * then falls back to URL parsing (for Lightning Out on external sites)
     * Memoized for performance
     * @param {string} param - The parameter name to extract
     * @returns {string} - The parameter value or empty string
     */
    getUrlParamValue(param) {
        // Return cached value if available
        if (Object.prototype.hasOwnProperty.call(this._urlParamsCache, param)) {
            return this._urlParamsCache[param];
        }

        try {
            // First try CurrentPageReference state (Lightning-native)
            const pageState = this.currentPageReference?.state || {};
            if (pageState[param]) {
                this._urlParamsCache[param] = pageState[param];
                return pageState[param];
            }
            if (pageState['c__' + param]) {
                this._urlParamsCache[param] = pageState['c__' + param];
                return pageState['c__' + param];
            }

            // Fallback to URL parsing (Lightning Out compatibility)
            const urlObject = new URL(window.location.href);
            const value = urlObject.searchParams.get(param) || urlObject.searchParams.get('c__' + param) || '';
            this._urlParamsCache[param] = value;
            return value;
        } catch (e) {
            console.error('Error parsing URL parameter:', e);
            this._urlParamsCache[param] = '';
            return '';
        }
    }

    get hasData() {
        return Array.isArray(this._fields) && this._fields.length > 0;
    }

    /**
     * Reset the form to allow for another submission
     * Clears all user-entered values while preserving controller defaults
     */
    resetForm() {
        // Reset the interaction object to defaults from rfiData
        this.interaction = this.rfiData?.interaction ? JSON.parse(JSON.stringify(this.rfiData.interaction)) : {};

        // Reset tracked form state
        this.cantFindSchool = false;
        this.iHaveAQuestion = false;
        this.selectedCountry = 'US';
        this.values = {};

        // Reset filter values if they exist
        if (this.filterValues) {
            const resetFilters = {};
            for (const key of Object.keys(this.filterValues)) {
                resetFilters[key] = '';
            }
            this.filterValues = resetFilters;
        }

        // Reset field values in the fields array
        if (Array.isArray(this._fields)) {
            this._fields = this._fields.map(field => ({
                ...field,
                value: undefined,
                selectedLabel: undefined
            }));
        }

        // Invalidate caches
        this._invalidateCaches();

        // Clear all input elements in the template
        const allInputs = this.template.querySelectorAll('lightning-input');
        allInputs.forEach(input => {
            if (input.type === 'checkbox') {
                input.checked = false;
            } else {
                input.value = '';
            }
        });

        // Clear textarea elements
        const allTextareas = this.template.querySelectorAll('lightning-textarea');
        allTextareas.forEach(textarea => {
            textarea.value = '';
        });

        // Clear combobox/picklist elements
        const allComboboxes = this.template.querySelectorAll('lightning-combobox');
        allComboboxes.forEach(combobox => {
            combobox.value = '';
        });

        // Reset multi-select components
        const allMultiSelects = this.template.querySelectorAll('c-multi-select-pills-groupable');
        allMultiSelects.forEach(multiSelect => {
            if (multiSelect.reset) {
                multiSelect.reset();
            }
        });
    }
}