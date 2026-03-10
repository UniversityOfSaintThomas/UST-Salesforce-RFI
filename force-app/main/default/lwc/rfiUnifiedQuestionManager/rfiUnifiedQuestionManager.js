/**
 * Unified Question Manager for RFI Forms
 * Combines pre-configured fields and custom questions into a single manageable list
 * Created: March 2, 2026
 */

import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, updateRecord, getFieldValue, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { getObjectInfo, getPicklistValues, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';

import RFI_CONTROLLER_OBJECT from '@salesforce/schema/RFI_Controller__c';
import INTERACTION_OBJECT from '@salesforce/schema/Interaction__c';
import ID_FIELD from '@salesforce/schema/RFI_Controller__c.Id';
import UNIFIED_QUESTIONS_FIELD from '@salesforce/schema/RFI_Controller__c.Unified_Questions__c';
import FIELDS_TO_DISPLAY_FIELD from '@salesforce/schema/RFI_Controller__c.Fields_to_Display__c';
import FIELDS_TO_DISPLAY_ORDER_FIELD from '@salesforce/schema/RFI_Controller__c.Fields_to_Display_Order__c';
import REQUIRED_FIELDS_FIELD from '@salesforce/schema/RFI_Controller__c.Required_Fields__c';

// Import all _To_Display__c filter fields for reading current values and writing selections
import SCHOOL_COLLEGE_TO_DISPLAY from '@salesforce/schema/RFI_Controller__c.School_College_To_Display__c';
import CITIZEN_TYPES_TO_DISPLAY from '@salesforce/schema/RFI_Controller__c.Citizen_Types_To_Display__c';
import DEGREE_TYPES_TO_DISPLAY from '@salesforce/schema/RFI_Controller__c.Degree_Types_To_Display__c';
import STUDENT_TYPES_TO_DISPLAY from '@salesforce/schema/RFI_Controller__c.Student_Types_To_Display__c';
import DELIVERY_TYPES_TO_DISPLAY from '@salesforce/schema/RFI_Controller__c.Delivery_Types_To_Display__c';
import PROGRAM_TYPES_TO_DISPLAY from '@salesforce/schema/RFI_Controller__c.Program_Types_To_Display__c';
import GENERIC_FILTER_2_TO_DISPLAY from '@salesforce/schema/RFI_Controller__c.Generic_Filter_2_To_Display__c';
import GENERIC_FILTER_3_TO_DISPLAY from '@salesforce/schema/RFI_Controller__c.Generic_Filter_3_To_Display__c';
import GENERIC_FILTER_4_TO_DISPLAY from '@salesforce/schema/RFI_Controller__c.Generic_Filter_4_To_Display__c';
import GENERIC_FILTER_6_TO_DISPLAY from '@salesforce/schema/RFI_Controller__c.Generic_Filter_6_To_Display__c';
import GENERIC_FILTER_7_TO_DISPLAY from '@salesforce/schema/RFI_Controller__c.Generic_Filter_7_To_Display__c';
import GENERIC_FILTER_8_TO_DISPLAY from '@salesforce/schema/RFI_Controller__c.Generic_Filter_8_To_Display__c';

const FIELDS = [
    ID_FIELD,
    UNIFIED_QUESTIONS_FIELD,
    FIELDS_TO_DISPLAY_FIELD,
    FIELDS_TO_DISPLAY_ORDER_FIELD,
    REQUIRED_FIELDS_FIELD,
    // Filter _To_Display__c fields — needed to read current selections and to save choices
    SCHOOL_COLLEGE_TO_DISPLAY,
    CITIZEN_TYPES_TO_DISPLAY,
    DEGREE_TYPES_TO_DISPLAY,
    STUDENT_TYPES_TO_DISPLAY,
    DELIVERY_TYPES_TO_DISPLAY,
    PROGRAM_TYPES_TO_DISPLAY,
    GENERIC_FILTER_2_TO_DISPLAY,
    GENERIC_FILTER_3_TO_DISPLAY,
    GENERIC_FILTER_4_TO_DISPLAY,
    GENERIC_FILTER_6_TO_DISPLAY,
    GENERIC_FILTER_7_TO_DISPLAY,
    GENERIC_FILTER_8_TO_DISPLAY
];

export default class RfiUnifiedQuestionManager extends LightningElement {
    @api recordId;
    @track questions = [];
    @track isLoading = false;
    @track showModal = false;
    @track modalMode = 'add'; // 'add', 'edit', 'addPreconfigured', 'editPreconfigured', 'addFilter', 'editFilter'
    @track draggedIndex = null;
    @track isSaving = false;
    @track needsMigration = false;

    wiredRecordResult;
    recordData;
    allPreconfiguredOptions = [];
    selectedPreconfiguredField = '';
    selectedFilterField = '';
    objectInfo;

    // Current question being edited in modal
    @track currentQuestion = {};

    // All available program filter slot definitions on RFI_Controller__c
    // Each entry maps: controllerField (the _To_Display__c field) → question label field → interaction API name
    filterFieldDefinitions = [
        {
            value: 'School_College_To_Display__c',
            label: 'School / College',
            interactionAPIName: 'St_Thomas_College_School__c',
            isSchoolList: true,
            schemaField: SCHOOL_COLLEGE_TO_DISPLAY
        },
        {
            value: 'Citizen_Types_To_Display__c',
            label: 'Citizenship Type',
            interactionAPIName: 'Citizenship__c',
            isSchoolList: false,
            schemaField: CITIZEN_TYPES_TO_DISPLAY
        },
        {
            value: 'Degree_Types_To_Display__c',
            label: 'Degree Type',
            interactionAPIName: 'Degree_Type__c',
            isSchoolList: false,
            schemaField: DEGREE_TYPES_TO_DISPLAY
        },
        {
            value: 'Student_Types_To_Display__c',
            label: 'Student Type',
            interactionAPIName: 'Student_Type__c',
            isSchoolList: false,
            schemaField: STUDENT_TYPES_TO_DISPLAY
        },
        {
            value: 'Delivery_Types_To_Display__c',
            label: 'Delivery Type',
            interactionAPIName: 'Delivery_Type__c',
            isSchoolList: false,
            schemaField: DELIVERY_TYPES_TO_DISPLAY
        },
        {
            value: 'Program_Types_To_Display__c',
            label: 'Program Type',
            interactionAPIName: 'Generic_Filter_5__c',
            isSchoolList: false,
            schemaField: PROGRAM_TYPES_TO_DISPLAY
        },
        {
            value: 'Generic_Filter_2_To_Display__c',
            label: 'Generic Filter 2',
            interactionAPIName: 'Generic_Filter_2__c',
            isSchoolList: false,
            schemaField: GENERIC_FILTER_2_TO_DISPLAY
        },
        {
            value: 'Generic_Filter_3_To_Display__c',
            label: 'Generic Filter 3',
            interactionAPIName: 'Generic_Filter_3__c',
            isSchoolList: false,
            schemaField: GENERIC_FILTER_3_TO_DISPLAY
        },
        {
            value: 'Generic_Filter_4_To_Display__c',
            label: 'Generic Filter 4',
            interactionAPIName: 'Generic_Filter_4__c',
            isSchoolList: false,
            schemaField: GENERIC_FILTER_4_TO_DISPLAY
        },
        {
            value: 'Generic_Filter_6_To_Display__c',
            label: 'Generic Filter 6',
            interactionAPIName: 'Generic_Filter_6__c',
            isSchoolList: false,
            schemaField: GENERIC_FILTER_6_TO_DISPLAY
        },
        {
            value: 'Generic_Filter_7_To_Display__c',
            label: 'Generic Filter 7',
            interactionAPIName: 'Generic_Filter_7__c',
            isSchoolList: false,
            schemaField: GENERIC_FILTER_7_TO_DISPLAY
        },
        {
            value: 'Generic_Filter_8_To_Display__c',
            label: 'Generic Filter 8',
            interactionAPIName: 'Generic_Filter_8__c',
            isSchoolList: false,
            schemaField: GENERIC_FILTER_8_TO_DISPLAY
        }
    ];

    // Holds picklist options keyed by controller field API name, populated by wired getPicklistValues calls
    _filterPicklistOptions = {};

    // Holds picklist options keyed by Interaction__c field API name for picklist-type custom questions
    _interactionPicklistOptions = {};
    _interactionDefaultRecordTypeId;

    // Question type options for custom questions
    questionTypes = [
        { label: 'Email', value: 'Email' },
        { label: 'Email required', value: 'Email required' },
        { label: 'Picklist', value: 'Picklist' },
        { label: 'Picklist required', value: 'Picklist required' },
        { label: 'Static content', value: 'Static content' },
        { label: 'Text box', value: 'Text box' },
        { label: 'Text box required', value: 'Text box required' },
        { label: 'Textarea', value: 'Textarea' },
        { label: 'Textarea required', value: 'Textarea required' }
    ];


    // Default labels for pre-configured fields
    defaultLabels = {
        'Academic Interest': 'Academic Interest',
        'Address': 'Address',
        'Birthdate': 'Birthdate',
        'Citizenship': 'Citizenship',
        'Company': 'Company',
        'Email': 'Email',
        'Employer': 'Employer',
        'Expected Start Term at St Thomas': 'Expected Start Term at St Thomas',
        'First Name': 'First Name',
        'High School Attended': 'High School Attended',
        'High School Graduation Year': 'High School Graduation Year',
        'Phone': 'Phone',
        'Home Phone': 'Home Phone',
        'How did you hear about us': 'How did you hear about us',
        'I have a question': 'I have a question',
        'I will apply to St Thomas as a': 'I will apply to St Thomas as a',
        'I will apply to St Thomas Law as a': 'I will apply to St Thomas Law as a',
        'Last Name': 'Last Name',
        // Full picklist fullName values
        'I would like program information to be mailed to me': 'I would like program information to be mailed to me',
        'I would like to receive text messages': 'I would like to receive text messages',
        // Short alias fallbacks (may appear in older saved JSON)
        'Mail Information': 'Mail Information',
        'Receive Text Messages': 'Receive Text Messages',
        'Scholarship of Interest': 'Scholarship of Interest',
        'St Thomas Colleges': 'College\\School',
        'Tell us about yourself': 'Tell us about yourself',
        'Timeline to Enrollment': 'Timeline to Enrollment',
        'Title': 'Title'
    };

    // Field to Interaction__c API name mapping (for pre-configured)
    fieldInteractionAPIMap = {
        'Academic Interest': 'Major_Program_1__c',
        'Address': 'Mailing_Street__c',
        'Birthdate': 'Birthdate__c',
        'Citizenship': 'Citizenship__c',
        'Company': 'Employer__c',
        'Email': 'Email__c',
        'Employer': 'Employer__c',
        'Expected Start Term at St Thomas': 'Intended_Start_Term__c',
        'First Name': 'First_Name__c',
        'High School Attended': 'High_School_or_College__c',
        'High School Graduation Year': 'High_School_Graduation_Year__c',
        'Phone': 'Home_Phone__c',
        'Home Phone': 'Home_Phone__c',
        'How did you hear about us': 'Heard_About_Us__c',
        'I have a question': 'Has_Question__c',
        'I will apply to St Thomas as a': 'Admit_Type__c',
        'I will apply to St Thomas Law as a': 'Admit_Type__c',
        'Last Name': 'Last_Name__c',
        // Full picklist fullName values (what actually gets stored as fieldName in JSON)
        'I would like program information to be mailed to me': 'Mail_Information__c',
        'I would like to receive text messages': 'Receive_Texts__c',
        // Short alias fallbacks (may appear in older saved JSON)
        'Mail Information': 'Mail_Information__c',
        'Receive Text Messages': 'Receive_Texts__c',
        'Scholarship of Interest': 'Scholarship_of_Interest__c',
        'St Thomas Colleges': 'St_Thomas_College_School__c',
        'Tell us about yourself': 'Description__c',
        'Timeline to Enrollment': 'Timeline__c',
        'Title': 'Salutation__c'
    };

    @wire(getObjectInfo, { objectApiName: RFI_CONTROLLER_OBJECT })
    rfiObjectInfo({ data, error }) {
        if (data) {
            this.objectInfo = data;
        } else if (error) {
            console.error('Error loading object info:', error);
        }
    }

    @wire(getObjectInfo, { objectApiName: INTERACTION_OBJECT })
    _wiredInteractionObjectInfo(result) {
        if (result.data) {
            this.interactionObjectInfo = result;
            this._interactionDefaultRecordTypeId = result.data.defaultRecordTypeId;
        }
    }

    @wire(getPicklistValuesByRecordType, {
        objectApiName: INTERACTION_OBJECT,
        recordTypeId: '$_interactionDefaultRecordTypeId'
    })
    _wiredInteractionPicklistValues({ data }) {
        if (data && data.picklistFieldValues) {
            const opts = {};
            Object.keys(data.picklistFieldValues).forEach(fieldApiName => {
                opts[fieldApiName] = data.picklistFieldValues[fieldApiName].values.map(v => ({
                    label: v.label,
                    value: v.value
                }));
            });
            this._interactionPicklistOptions = opts;
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.defaultRecordTypeId',
        fieldApiName: FIELDS_TO_DISPLAY_FIELD
    })
    picklistValues({ data, error }) {
        if (data) {
            this.allPreconfiguredOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
        } else if (error) {
            console.error('Error loading picklist values:', error);
        }
    }

    // Wire getPicklistValues for each _To_Display__c filter field
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.defaultRecordTypeId', fieldApiName: SCHOOL_COLLEGE_TO_DISPLAY })
    _wiredSchoolCollege({ data }) { if (data) { this._filterPicklistOptions = { ...this._filterPicklistOptions, 'School_College_To_Display__c': data.values.map(v => ({ label: v.label, value: v.value })) }; } }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.defaultRecordTypeId', fieldApiName: CITIZEN_TYPES_TO_DISPLAY })
    _wiredCitizenTypes({ data }) { if (data) { this._filterPicklistOptions = { ...this._filterPicklistOptions, 'Citizen_Types_To_Display__c': data.values.map(v => ({ label: v.label, value: v.value })) }; } }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.defaultRecordTypeId', fieldApiName: DEGREE_TYPES_TO_DISPLAY })
    _wiredDegreeTypes({ data }) { if (data) { this._filterPicklistOptions = { ...this._filterPicklistOptions, 'Degree_Types_To_Display__c': data.values.map(v => ({ label: v.label, value: v.value })) }; } }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.defaultRecordTypeId', fieldApiName: STUDENT_TYPES_TO_DISPLAY })
    _wiredStudentTypes({ data }) { if (data) { this._filterPicklistOptions = { ...this._filterPicklistOptions, 'Student_Types_To_Display__c': data.values.map(v => ({ label: v.label, value: v.value })) }; } }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.defaultRecordTypeId', fieldApiName: DELIVERY_TYPES_TO_DISPLAY })
    _wiredDeliveryTypes({ data }) { if (data) { this._filterPicklistOptions = { ...this._filterPicklistOptions, 'Delivery_Types_To_Display__c': data.values.map(v => ({ label: v.label, value: v.value })) }; } }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.defaultRecordTypeId', fieldApiName: PROGRAM_TYPES_TO_DISPLAY })
    _wiredProgramTypes({ data }) { if (data) { this._filterPicklistOptions = { ...this._filterPicklistOptions, 'Program_Types_To_Display__c': data.values.map(v => ({ label: v.label, value: v.value })) }; } }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.defaultRecordTypeId', fieldApiName: GENERIC_FILTER_2_TO_DISPLAY })
    _wiredGenericFilter2({ data }) { if (data) { this._filterPicklistOptions = { ...this._filterPicklistOptions, 'Generic_Filter_2_To_Display__c': data.values.map(v => ({ label: v.label, value: v.value })) }; } }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.defaultRecordTypeId', fieldApiName: GENERIC_FILTER_3_TO_DISPLAY })
    _wiredGenericFilter3({ data }) { if (data) { this._filterPicklistOptions = { ...this._filterPicklistOptions, 'Generic_Filter_3_To_Display__c': data.values.map(v => ({ label: v.label, value: v.value })) }; } }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.defaultRecordTypeId', fieldApiName: GENERIC_FILTER_4_TO_DISPLAY })
    _wiredGenericFilter4({ data }) { if (data) { this._filterPicklistOptions = { ...this._filterPicklistOptions, 'Generic_Filter_4_To_Display__c': data.values.map(v => ({ label: v.label, value: v.value })) }; } }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.defaultRecordTypeId', fieldApiName: GENERIC_FILTER_6_TO_DISPLAY })
    _wiredGenericFilter6({ data }) { if (data) { this._filterPicklistOptions = { ...this._filterPicklistOptions, 'Generic_Filter_6_To_Display__c': data.values.map(v => ({ label: v.label, value: v.value })) }; } }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.defaultRecordTypeId', fieldApiName: GENERIC_FILTER_7_TO_DISPLAY })
    _wiredGenericFilter7({ data }) { if (data) { this._filterPicklistOptions = { ...this._filterPicklistOptions, 'Generic_Filter_7_To_Display__c': data.values.map(v => ({ label: v.label, value: v.value })) }; } }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.defaultRecordTypeId', fieldApiName: GENERIC_FILTER_8_TO_DISPLAY })
    _wiredGenericFilter8({ data }) { if (data) { this._filterPicklistOptions = { ...this._filterPicklistOptions, 'Generic_Filter_8_To_Display__c': data.values.map(v => ({ label: v.label, value: v.value })) }; } }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord(result) {
        this.wiredRecordResult = result;
        const { error, data } = result;

        if (data) {
            this.recordData = data;
            if (!this.isSaving) {
                this.loadQuestions();
            }
        } else if (error) {
            console.error('Error loading record:', error);

            // Check if Unified_Questions__c field is missing
            if (error.body && error.body.message && error.body.message.includes('Unified_Questions__c')) {
                this.showToast(
                    'Field Required',
                    'The Unified_Questions__c field needs to be created. Please create it manually: Setup → Object Manager → RFI Controller → Fields & Relationships → New → Text Area (Long), API Name: Unified_Questions__c, Length: 131072',
                    'error'
                );
            } else {
                this.showToast('Error', 'Error loading record', 'error');
            }
        }
    }

    loadQuestions() {
        if (!this.recordData) return;

        const unifiedQuestionsJSON = this.getFieldValue(UNIFIED_QUESTIONS_FIELD);

        if (unifiedQuestionsJSON) {
            // Load from unified field
            const parsed = JSON.parse(unifiedQuestionsJSON);
            if (parsed && parsed.length > 0) {
                this.questions = parsed;
                this.needsMigration = false;
            } else {
                // Saved as empty array — treat as not yet migrated
                this.migrateFromLegacyStructure();
            }
        } else {
            // Auto-migrate from old structure
            this.migrateFromLegacyStructure();
        }

        // Ensure IDs are sequential and add computed properties
        this.questions = this.stampComputedProps(this.questions);
    }

    migrateFromLegacyStructure() {
        console.log('🔄 Auto-migrating from legacy structure...');
        const migratedQuestions = [];

        // Get legacy data
        const fieldsToDisplayOrder = this.getFieldValue(FIELDS_TO_DISPLAY_ORDER_FIELD);
        const fieldsToDisplay = this.getFieldValue(FIELDS_TO_DISPLAY_FIELD);
        const requiredFields = this.getFieldValue(REQUIRED_FIELDS_FIELD);
        const requiredFieldsArray = requiredFields ? requiredFields.split(';') : [];

        // Add pre-configured fields from Fields_to_Display_Order__c or Fields_to_Display__c
        const fieldsSource = fieldsToDisplayOrder || fieldsToDisplay;

        let rawFields = fieldsSource ? fieldsSource.split(';').map(f => f.trim()).filter(f => f) : [];

        // Collapse any legacy address sub-fields (Address 1/2/3, City, State, Zipcode, Country)
        // into a single 'Address' entry for controllers that were saved before the simplification
        const ADDRESS_SUB_FIELDS = new Set(['Address 1', 'Address 2', 'Address 3', 'City', 'State', 'Zipcode', 'Country']);
        let addressAdded = false;
        let orderedFields = [];
        for (const fieldName of rawFields) {
            if (ADDRESS_SUB_FIELDS.has(fieldName)) {
                if (!addressAdded) {
                    orderedFields.push('Address');
                    addressAdded = true;
                }
            } else {
                orderedFields.push(fieldName);
            }
        }

        // Always ensure First Name and Last Name are present
        if (!orderedFields.includes('First Name')) {
            orderedFields.unshift('First Name');
        }
        if (!orderedFields.includes('Last Name')) {
            const firstNameIndex = orderedFields.indexOf('First Name');
            orderedFields.splice(firstNameIndex + 1, 0, 'Last Name');
        }

        orderedFields.forEach(fieldName => {
            const isRequired = requiredFieldsArray.includes(fieldName) ||
                fieldName === 'First Name' || fieldName === 'Last Name';
            const label = this.getStoredLabel(fieldName) || this.defaultLabels[fieldName] || fieldName;
            const fieldInteractionAPIName = this.fieldInteractionAPIMap[fieldName] || '';

            migratedQuestions.push({
                id: migratedQuestions.length,
                type: 'preconfigured',
                fieldName: fieldName,
                questionLabel: label,
                fieldInteractionAPIName: fieldInteractionAPIName,
                isRequired: isRequired
            });
        });

        this.questions = migratedQuestions;
        this.needsMigration = true;
        console.log(`✅ Migrated ${migratedQuestions.length} pre-configured fields from legacy structure`);
    }

    getFieldValue(field) {
        return getFieldValue(this.recordData, field);
    }

    getStoredLabel(fieldName) {
        // Labels are managed via defaultLabels defaults and the Unified_Questions__c JSON.
        // The legacy _Label__c fields have been removed.
        return null;
    }

    // Modal controls
    openAddPreconfiguredModal() {
        this.modalMode = 'addPreconfigured';
        this.selectedPreconfiguredField = '';
        this.showModal = true;
    }

    openAddCustomModal() {
        this.modalMode = 'add';
        this.currentQuestion = {
            type: 'custom',
            questionLabel: '',
            questionType: '',
            fieldToApplyTo: '',
            isRequired: false,
            picklistValues: [],
            valuesFlat: '',
            assistiveText: ''
        };
        this.showModal = true;
    }

    openAddFilterModal() {
        this.modalMode = 'addFilter';
        this.selectedFilterField = '';
        this.currentQuestion = {
            type: 'filter',
            questionLabel: '',
            filterControllerField: '',
            filterInteractionAPIName: '',
            isFilterSchoolList: false,
            filterSelectedValues: [],
            isRequired: true
        };
        this.showModal = true;
    }

    openEditModal(event) {
        const questionId = parseInt(event.currentTarget.dataset.id);
        const question = this.questions[questionId];
        if (question.type === 'preconfigured') {
            this.modalMode = 'editPreconfigured';
        } else if (question.type === 'filter') {
            this.modalMode = 'editFilter';
        } else {
            this.modalMode = 'edit';
        }
        this.currentQuestion = { ...question };

        // For custom picklist questions, detect whether the mapped field is an org picklist
        // so the HTML can show the read-only org values instead of the textarea
        if (question.type === 'custom' && question.fieldToApplyTo &&
            this.interactionObjectInfo && this.interactionObjectInfo.data) {
            const fieldMeta = this.interactionObjectInfo.data.fields[question.fieldToApplyTo];
            const isOrgPicklist = fieldMeta && fieldMeta.dataType.toLowerCase() === 'picklist';
            if (isOrgPicklist && !this.currentQuestion.isMappedPicklist) {
                // Re-hydrate org values in case they were saved as mapped
                const orgOptions = this._interactionPicklistOptions[question.fieldToApplyTo] || [];
                this.currentQuestion = {
                    ...this.currentQuestion,
                    isMappedPicklist: true,
                    picklistValues: orgOptions.length > 0 ? orgOptions : question.picklistValues,
                    valuesFlat: orgOptions.length > 0 ? orgOptions.map(o => o.value).join(';') : question.valuesFlat
                };
            }
        }

        // Ensure filterSelectedValues is an array (may be missing in older saved data)
        if (question.type === 'filter' && !Array.isArray(this.currentQuestion.filterSelectedValues)) {
            // Try to read from existing controller field value as fallback
            const existing = this._getExistingFilterValue(question.filterControllerField);
            this.currentQuestion = {
                ...this.currentQuestion,
                filterSelectedValues: existing ? existing.split(';').filter(v => v) : []
            };
        }
        this.showModal = true;
    }

    closeModal() {
        this.showModal = false;
        this.currentQuestion = {};
    }

    // Handle changes in modal form
    handlePreconfiguredSelection(event) {
        this.selectedPreconfiguredField = event.detail.value;
    }

    handleFilterFieldSelection(event) {
        const chosen = event.detail.value;
        const def = this.filterFieldDefinitions.find(d => d.value === chosen);

        // Pre-populate selected values from the existing controller record field
        const existingValue = this._getExistingFilterValue(chosen);
        const preSelected = existingValue ? existingValue.split(';').filter(v => v) : [];

        this.currentQuestion = {
            ...this.currentQuestion,
            filterControllerField: chosen,
            filterInteractionAPIName: def ? def.interactionAPIName : '',
            isFilterSchoolList: def ? def.isSchoolList : false,
            filterSelectedValues: preSelected,
            // Pre-fill label from definition only if user hasn't typed one yet
            questionLabel: this.currentQuestion.questionLabel || (def ? def.label : '')
        };
    }

    // Read the current semicolon-delimited value of a _To_Display__c field from the loaded record
    _getExistingFilterValue(controllerFieldApiName) {
        if (!this.recordData || !controllerFieldApiName) return '';
        const def = this.filterFieldDefinitions.find(d => d.value === controllerFieldApiName);
        if (!def || !def.schemaField) return '';
        return getFieldValue(this.recordData, def.schemaField) || '';
    }

    handleFilterValuesChange(event) {
        this.currentQuestion = {
            ...this.currentQuestion,
            filterSelectedValues: event.detail.value
        };
    }

    handleModalChange(event) {
        const name = event.target.name;
        const value = event.target.value;

        switch (name) {
            case 'questionLabel':
                this.currentQuestion.questionLabel = value;
                break;
            case 'questionType':
                this.currentQuestion.questionType = value;
                this.currentQuestion.isRequired = value.includes('required');
                // Clear field mapping — the compatible fields change with question type
                this.currentQuestion.fieldToApplyTo = '';
                this.currentQuestion.isMappedPicklist = false;
                this.currentQuestion.picklistValues = [];
                this.currentQuestion.valuesFlat = '';
                break;
            case 'fieldToApplyTo': {
                this.currentQuestion.fieldToApplyTo = value;
                // If this field is a picklist on Interaction__c, auto-populate from org values
                if (value && this.interactionObjectInfo && this.interactionObjectInfo.data) {
                    const fieldMeta = this.interactionObjectInfo.data.fields[value];
                    const isOrgPicklist = fieldMeta && fieldMeta.dataType.toLowerCase() === 'picklist';
                    if (isOrgPicklist) {
                        const orgOptions = this._interactionPicklistOptions[value] || [];
                        this.currentQuestion.isMappedPicklist = true;
                        this.currentQuestion.picklistValues = orgOptions;
                        this.currentQuestion.valuesFlat = orgOptions.map(o => o.value).join(';');
                    } else {
                        this.currentQuestion.isMappedPicklist = false;
                    }
                }
                break;
            }
            case 'picklistValues': {
                // Only reachable when NOT a mapped picklist (textarea is hidden for mapped ones)
                const pickValues = value.split('\n').filter(v => v.trim() !== '');
                this.currentQuestion.picklistValues = pickValues.map(v => ({ label: v.trim(), value: v.trim() }));
                this.currentQuestion.valuesFlat = pickValues.map(v => v.trim()).join(';');
                break;
            }
            case 'staticContent':
                this.currentQuestion.valuesFlat = value;
                break;
            case 'assistiveText':
                this.currentQuestion.assistiveText = value;
                break;
        }

        // Force reactivity
        this.currentQuestion = { ...this.currentQuestion };
    }

    handleRequiredChange(event) {
        this.currentQuestion.isRequired = event.target.checked;
        this.currentQuestion = { ...this.currentQuestion };
    }

    // Stamps display-only computed flags onto each question after any mutation
    stampComputedProps(questions) {
        const last = questions.length - 1;
        return questions.map((q, index) => {
            const qt = (q.questionType || '').toLowerCase();
            return {
                ...q,
                id: index,
                typePreconfigured: q.type === 'preconfigured',
                typeCustom: q.type === 'custom',
                typeFilter: q.type === 'filter',
                // Consumer flags for requestForInformationAdditionalQuestionForm
                isPicklist: qt === 'picklist' || qt === 'picklist required',
                isTextBox: qt === 'text box' || qt === 'text box required',
                isTextarea: qt === 'textarea' || qt === 'textarea required',
                isEmail: qt === 'email' || qt === 'email required',
                isStaticContent: qt === 'static content',
                isFirst: index === 0,
                isLast: index === last
            };
        });
    }

    handleStaticContentChange(event) {
        this.currentQuestion.valuesFlat = event.target.value;
        this.currentQuestion = { ...this.currentQuestion };
    }

    handlePreconfiguredLabelChange(event) {
        this.currentQuestion = { ...this.currentQuestion, questionLabel: event.target.value };
    }

    // Save question from modal
    saveQuestion() {
        if (this.modalMode === 'addPreconfigured') {
            this.addPreconfiguredField();
        } else if (this.modalMode === 'editPreconfigured') {
            this.savePreconfiguredQuestion();
        } else if (this.modalMode === 'addFilter' || this.modalMode === 'editFilter') {
            this.saveFilterQuestion();
        } else {
            this.saveCustomQuestion();
        }
    }

    saveFilterQuestion() {
        if (!this.currentQuestion.filterControllerField) {
            this.showToast('Warning', 'Please select a filter field', 'warning');
            return;
        }
        if (!this.currentQuestion.questionLabel) {
            this.showToast('Warning', 'Please enter a question label', 'warning');
            return;
        }

        if (this.modalMode === 'addFilter') {
            // Check not already added
            const exists = this.questions.some(q =>
                q.type === 'filter' && q.filterControllerField === this.currentQuestion.filterControllerField
            );
            if (exists) {
                this.showToast('Warning', 'This filter is already in the list', 'warning');
                return;
            }
            this.questions = this.stampComputedProps([...this.questions, { ...this.currentQuestion }]);
            this.showToast('Success', 'Filter question added', 'success');
        } else {
            const index = this.questions.findIndex(q => q.id === this.currentQuestion.id);
            if (index !== -1) {
                const updated = [...this.questions];
                updated[index] = { ...this.currentQuestion };
                this.questions = this.stampComputedProps(updated);
                this.showToast('Success', 'Filter question updated', 'success');
            }
        }
        this.closeModal();
    }

    savePreconfiguredQuestion() {
        const index = this.questions.findIndex(q => q.id === this.currentQuestion.id);
        if (index !== -1) {
            const updated = [...this.questions];
            updated[index] = { ...this.currentQuestion };
            this.questions = this.stampComputedProps(updated);
            this.showToast('Success', 'Question updated', 'success');
        }
        this.closeModal();
    }

    addPreconfiguredField() {
        if (!this.selectedPreconfiguredField) {
            this.showToast('Warning', 'Please select a field to add', 'warning');
            return;
        }

        // Check if already exists
        const exists = this.questions.some(q =>
            q.type === 'preconfigured' && q.fieldName === this.selectedPreconfiguredField
        );
        if (exists) {
            this.showToast('Warning', 'This field is already in the list', 'warning');
            return;
        }

        const fieldName = this.selectedPreconfiguredField;
        const label = this.getStoredLabel(fieldName) || this.defaultLabels[fieldName] || fieldName;
        const fieldInteractionAPIName = this.fieldInteractionAPIMap[fieldName] || '';

        const newQuestion = {
            id: this.questions.length,
            type: 'preconfigured',
            fieldName: fieldName,
            questionLabel: label,
            fieldInteractionAPIName: fieldInteractionAPIName,
            isRequired: false
        };

        this.questions = this.stampComputedProps([...this.questions, newQuestion]);
        this.closeModal();
        this.showToast('Success', `Added "${fieldName}" to the list`, 'success');
    }

    saveCustomQuestion() {
        // Validate
        const allValid = [...this.template.querySelectorAll('lightning-input,lightning-combobox,lightning-textarea')]
            .reduce((validSoFar, inputCmp) => {
                if (inputCmp) {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
                }
                return validSoFar;
            }, true);

        if (!allValid) {
            return;
        }

        if (this.modalMode === 'add') {
            // Add new
            this.questions = this.stampComputedProps([...this.questions, { ...this.currentQuestion }]);
            this.showToast('Success', 'Custom question added', 'success');
        } else {
            // Edit existing
            const index = this.questions.findIndex(q => q.id === this.currentQuestion.id);
            if (index !== -1) {
                const updated = [...this.questions];
                updated[index] = { ...this.currentQuestion };
                this.questions = this.stampComputedProps(updated);
                this.showToast('Success', 'Question updated', 'success');
            }
        }

        this.closeModal();
    }

    // Inline label edit
    handleLabelChange(event) {
        const index = parseInt(event.target.dataset.index);
        const updated = [...this.questions];
        updated[index] = { ...updated[index], questionLabel: event.target.value };
        this.questions = updated;
    }

    handleInlineRequiredChange(event) {
        const index = parseInt(event.target.dataset.index);
        const updated = [...this.questions];
        updated[index] = { ...updated[index], isRequired: event.target.checked };
        this.questions = updated;
    }

    // Delete question
    deleteQuestion(event) {
        const index = parseInt(event.currentTarget.dataset.id);
        const question = this.questions[index];

        // Prevent deleting First Name and Last Name
        if (question.type === 'preconfigured' &&
            (question.fieldName === 'First Name' || question.fieldName === 'Last Name')) {
            this.showToast('Warning', `"${question.fieldName}" cannot be removed as it is always required`, 'warning');
            return;
        }

        const filtered = this.questions.filter((q, i) => i !== index);
        this.questions = this.stampComputedProps(filtered);
        this.showToast('Success', 'Question removed', 'success');
    }

    // Drag and drop
    handleDragStart(event) {
        this.draggedIndex = parseInt(event.currentTarget.dataset.index);
        event.currentTarget.classList.add('dragging');
        this._draggingEl = event.currentTarget;
        this._dropIndicatorEl = null;
    }

    handleDragEnd(event) {
        event.currentTarget.classList.remove('dragging');
        this._draggingEl = null;
        this._clearDropIndicators();
    }

    handleDragOver(event) {
        event.preventDefault();
        const row = event.currentTarget;
        const targetIndex = parseInt(row.dataset.index);

        if (this.draggedIndex === null || targetIndex === this.draggedIndex) {
            this._clearDropIndicators();
            return;
        }

        const rect = row.getBoundingClientRect();
        const isAbove = event.clientY < rect.top + rect.height / 2;
        const newClass = isAbove ? 'drag-over-above' : 'drag-over-below';
        const oldClass = isAbove ? 'drag-over-below' : 'drag-over-above';

        // Only touch the DOM if something actually changed
        if (this._dropIndicatorEl !== row || this._dropIndicatorClass !== newClass) {
            if (this._dropIndicatorEl) {
                this._dropIndicatorEl.classList.remove('drag-over-above', 'drag-over-below');
            }
            row.classList.remove(oldClass);
            row.classList.add(newClass);
            this._dropIndicatorEl = row;
            this._dropIndicatorClass = newClass;
        }
    }

    handleDrop(event) {
        event.preventDefault();
        this._clearDropIndicators();

        const row = event.currentTarget;
        const targetIndex = parseInt(row.dataset.index);

        if (this.draggedIndex !== null && this.draggedIndex !== targetIndex) {
            const rect = row.getBoundingClientRect();
            const insertBefore = event.clientY < rect.top + rect.height / 2;

            const items = [...this.questions];
            const draggedItem = items.splice(this.draggedIndex, 1)[0];

            let insertAt = targetIndex;
            if (this.draggedIndex < targetIndex) {
                insertAt = targetIndex - 1;
            }
            if (!insertBefore) {
                insertAt += 1;
            }

            items.splice(insertAt, 0, draggedItem);
            this.questions = this.stampComputedProps(items);

            // Flash the dropped row after LWC re-renders
            const landingIndex = insertAt;
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            requestAnimationFrame(() => {
                const rows = this.template.querySelectorAll('tr[data-index]');
                const landedRow = [...rows].find(r => parseInt(r.dataset.index) === landingIndex);
                if (landedRow) {
                    landedRow.classList.add('just-dropped');
                    landedRow.addEventListener('animationend', () => {
                        landedRow.classList.remove('just-dropped');
                    }, { once: true });
                }
            });
        }

        this.draggedIndex = null;
    }

    _clearDropIndicators() {
        if (this._dropIndicatorEl) {
            this._dropIndicatorEl.classList.remove('drag-over-above', 'drag-over-below');
            this._dropIndicatorEl = null;
            this._dropIndicatorClass = null;
        }
    }

    // Move up/down buttons
    moveUp(event) {
        const index = parseInt(event.currentTarget.dataset.id);
        if (index === 0) return;

        const items = [...this.questions];
        [items[index - 1], items[index]] = [items[index], items[index - 1]];
        this.questions = this.stampComputedProps(items);

        const landingIndex = index - 1;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        requestAnimationFrame(() => {
            const rows = this.template.querySelectorAll('tr[data-index]');
            const landedRow = [...rows].find(r => parseInt(r.dataset.index) === landingIndex);
            if (landedRow) {
                landedRow.classList.add('just-dropped');
                landedRow.addEventListener('animationend', () => {
                    landedRow.classList.remove('just-dropped');
                }, { once: true });
            }
        });
    }

    moveDown(event) {
        const index = parseInt(event.currentTarget.dataset.id);
        if (index === this.questions.length - 1) return;

        const items = [...this.questions];
        [items[index], items[index + 1]] = [items[index + 1], items[index]];
        this.questions = this.stampComputedProps(items);

        const landingIndex = index + 1;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        requestAnimationFrame(() => {
            const rows = this.template.querySelectorAll('tr[data-index]');
            const landedRow = [...rows].find(r => parseInt(r.dataset.index) === landingIndex);
            if (landedRow) {
                landedRow.classList.add('just-dropped');
                landedRow.addEventListener('animationend', () => {
                    landedRow.classList.remove('just-dropped');
                }, { once: true });
            }
        });
    }

    // Save to Salesforce
    async handleSave() {
        this.isLoading = true;
        this.isSaving = true;

        try {
            const fields = {
                Id: this.recordId,
                [UNIFIED_QUESTIONS_FIELD.fieldApiName]: JSON.stringify(this.questions)
            };

            // Write each filter question's selected values back to its _To_Display__c field on the controller
            this.questions
                .filter(q => q.type === 'filter' && q.filterControllerField && Array.isArray(q.filterSelectedValues) && q.filterSelectedValues.length > 0)
                .forEach(q => {
                    const def = this.filterFieldDefinitions.find(d => d.value === q.filterControllerField);
                    if (def && def.schemaField) {
                        fields[def.schemaField.fieldApiName] = q.filterSelectedValues.join(';');
                    }
                });

            const recordInput = { fields };
            await updateRecord(recordInput);

            console.log('✅ Saved unified questions successfully');
            this.showToast('Success', 'Questions saved successfully', 'success');

            await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
            this.isSaving = false;
            await refreshApex(this.wiredRecordResult);
        } catch (error) {
            this.isSaving = false;
            console.error('❌ Save error:', error);
            const errorMessage = error?.body?.message || error?.message || 'Unknown error';
            this.showToast('Error', 'Error saving questions: ' + errorMessage, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    // Computed properties
    get hasQuestions() {
        return this.questions && this.questions.length > 0;
    }

    get availablePreconfiguredOptions() {
        const currentFields = this.questions
            .filter(q => q.type === 'preconfigured')
            .map(q => q.fieldName);

        const available = this.allPreconfiguredOptions.filter(
            option => !currentFields.includes(option.value)
        );

        return [
            { label: '-- Select a field to add --', value: '' },
            ...available
        ];
    }

    get hasAvailablePreconfigured() {
        return this.availablePreconfiguredOptions && this.availablePreconfiguredOptions.length > 1;
    }

    get modalTitle() {
        if (this.modalMode === 'addPreconfigured') {
            return 'Add Pre-configured Field';
        } else if (this.modalMode === 'editPreconfigured') {
            return `Edit Pre-configured Question: ${this.currentQuestion.fieldName || ''}`;
        } else if (this.modalMode === 'addFilter') {
            return 'Add Program Filter Question';
        } else if (this.modalMode === 'editFilter') {
            return `Edit Filter Question: ${this.currentQuestion.questionLabel || ''}`;
        } else if (this.modalMode === 'add') {
            return 'Add Custom Question';
        } else {
            return 'Edit Question';
        }
    }

    get isAddPreconfiguredMode() {
        return this.modalMode === 'addPreconfigured';
    }

    get isEditPreconfiguredMode() {
        return this.modalMode === 'editPreconfigured';
    }

    get isAddFilterMode() {
        return this.modalMode === 'addFilter';
    }

    get isEditFilterMode() {
        return this.modalMode === 'editFilter';
    }

    get isFilterMode() {
        return this.modalMode === 'addFilter' || this.modalMode === 'editFilter';
    }

    get isCustomQuestion() {
        return this.modalMode === 'add' ||
               (this.modalMode === 'edit' && this.currentQuestion.type === 'custom');
    }

    // Available filter fields (exclude ones already added, unless editing that one)
    get availableFilterOptions() {
        const usedFields = this.questions
            .filter(q => q.type === 'filter' && q.id !== (this.currentQuestion.id ?? -1))
            .map(q => q.filterControllerField);

        const available = this.filterFieldDefinitions.filter(d => !usedFields.includes(d.value));
        return [
            { label: '-- Select a filter field --', value: '' },
            ...available
        ];
    }

    // Picklist options for the currently selected filter field (for dual-listbox)
    get currentFilterPicklistOptions() {
        const field = this.currentQuestion.filterControllerField;
        if (!field) return [];
        return this._filterPicklistOptions[field] || [];
    }

    get hasFilterPicklistOptions() {
        return this.currentFilterPicklistOptions.length > 0;
    }

    get currentFilterSelectedValues() {
        return Array.isArray(this.currentQuestion.filterSelectedValues)
            ? this.currentQuestion.filterSelectedValues
            : [];
    }

    get isPicklist() {
        const qt = (this.currentQuestion.questionType || '').toLowerCase();
        return qt === 'picklist' || qt === 'picklist required';
    }

    // True when the mapped Interaction field is itself a picklist — values come from org, no textarea needed
    get isMappedPicklist() {
        return !!(this.currentQuestion.isMappedPicklist);
    }

    // True when creator should enter values manually (picklist type but NOT mapped to an org picklist field)
    get showPicklistTextarea() {
        return this.isPicklist && !this.isMappedPicklist;
    }

    // Newline-separated value for the textarea — converts stored ';' delimiter back to newlines for display
    get picklistValuesText() {
        const flat = this.currentQuestion.valuesFlat || '';
        if (!flat) return '';
        return flat.split(';').filter(v => v.trim()).join('\n');
    }

    get isStaticContent() {
        const qt = (this.currentQuestion.questionType || '').toLowerCase();
        return qt === 'static content';
    }

    get needsFieldMapping() {
        return this.isCustomQuestion && !this.isStaticContent;
    }

    // Returns Interaction__c field options filtered to types compatible with the selected question type
    get interactionFieldOptions() {
        if (!this.interactionObjectInfo || !this.interactionObjectInfo.data) {
            // If not yet loaded but there's a saved value, show it as a placeholder option
            if (this.currentQuestion.fieldToApplyTo) {
                return [{ label: this.currentQuestion.fieldToApplyTo, value: this.currentQuestion.fieldToApplyTo }];
            }
            return [];
        }

        const qType = (this.currentQuestion.questionType || '').toLowerCase();
        const fields = this.interactionObjectInfo.data.fields;
        const options = [];

        const EXCLUDED_PREFIXES = ['utm_', 'gclid', 'linkedin_'];

        Object.keys(fields).forEach(apiName => {
            const field = fields[apiName];
            if (!field.updateable || !field.createable) return;
            if (EXCLUDED_PREFIXES.some(p => apiName.toLowerCase().startsWith(p))) return;

            const dt = field.dataType.toLowerCase();
            let include = false;

            if (qType.startsWith('text box') || qType.startsWith('textarea')) {
                include = dt === 'string' || dt === 'textarea';
            } else if (qType.startsWith('email')) {
                include = dt === 'email' || dt === 'string';
            } else if (qType.startsWith('picklist')) {
                include = dt === 'picklist' || dt === 'string';
            }

            if (include) {
                options.push({ label: `${field.label} (${apiName})`, value: apiName });
            }
        });

        options.sort((a, b) => a.label.localeCompare(b.label));
        return [{ label: '-- Select a field --', value: '' }, ...options];
    }

    get showMigrationBanner() {
        return this.needsMigration;
    }
}

