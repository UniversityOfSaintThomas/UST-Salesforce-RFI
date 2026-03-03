/**
 * Unified Question Manager for RFI Forms
 * Combines pre-configured fields and custom questions into a single manageable list
 * Created: March 2, 2026
 */

import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, updateRecord, getFieldValue, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';

import RFI_CONTROLLER_OBJECT from '@salesforce/schema/RFI_Controller__c';
import INTERACTION_OBJECT from '@salesforce/schema/Interaction__c';
import ID_FIELD from '@salesforce/schema/RFI_Controller__c.Id';
import UNIFIED_QUESTIONS_FIELD from '@salesforce/schema/RFI_Controller__c.Unified_Questions__c';
import FIELDS_TO_DISPLAY_FIELD from '@salesforce/schema/RFI_Controller__c.Fields_to_Display__c';
import FIELDS_TO_DISPLAY_ORDER_FIELD from '@salesforce/schema/RFI_Controller__c.Fields_to_Display_Order__c';
import REQUIRED_FIELDS_FIELD from '@salesforce/schema/RFI_Controller__c.Required_Fields__c';
import INTERACTION_QUESTIONS_FIELD from '@salesforce/schema/RFI_Controller__c.Interaction_Questions__c';

// Import all label fields
import ACADEMIC_INTEREST_LABEL from '@salesforce/schema/RFI_Controller__c.Academic_Interest_Label__c';
import ADDRESS_LABEL from '@salesforce/schema/RFI_Controller__c.Address_Label__c';
import BIRTHDATE_LABEL from '@salesforce/schema/RFI_Controller__c.Birthdate_Label__c';
import CITIZENSHIP_LABEL from '@salesforce/schema/RFI_Controller__c.Citizenship_Label__c';
import COMPANY_LABEL from '@salesforce/schema/RFI_Controller__c.Company_Label__c';
import EMAIL_LABEL from '@salesforce/schema/RFI_Controller__c.Email_Label__c';
import EMPLOYER_LABEL from '@salesforce/schema/RFI_Controller__c.Employer_Label__c';
import EXPECTED_START_TERM_LABEL from '@salesforce/schema/RFI_Controller__c.Expected_Start_Term_Label__c';
import FIRST_NAME_LABEL from '@salesforce/schema/RFI_Controller__c.First_Name_Label__c';
import HIGH_SCHOOL_ATTENDED_LABEL from '@salesforce/schema/RFI_Controller__c.High_School_Attended_Label__c';
import HIGH_SCHOOL_GRADUATION_YEAR_LABEL from '@salesforce/schema/RFI_Controller__c.High_School_Graduation_Year_Label__c';
import HOW_DID_YOU_HEAR_ABOUT_US_LABEL from '@salesforce/schema/RFI_Controller__c.How_Did_You_Hear_About_Us_Label__c';
import I_HAVE_A_QUESTION_LABEL from '@salesforce/schema/RFI_Controller__c.I_Have_A_Question_Label__c';
import LAST_NAME_LABEL from '@salesforce/schema/RFI_Controller__c.Last_Name_Label__c';
import MAIL_INFORMATION_LABEL from '@salesforce/schema/RFI_Controller__c.Mail_Information_Label__c';
import PHONE_LABEL from '@salesforce/schema/RFI_Controller__c.Phone_Label__c';
import HOME_PHONE_LABEL from '@salesforce/schema/RFI_Controller__c.Home_Phone_Label__c';
import RECEIVE_TEXT_MESSAGES_LABEL from '@salesforce/schema/RFI_Controller__c.Receive_Text_Messages_Label__c';
import SCHOLARSHIP_OF_INTEREST_LABEL from '@salesforce/schema/RFI_Controller__c.Scholarship_Of_Interest_Label__c';
import ST_THOMAS_COLLEGES_LABEL from '@salesforce/schema/RFI_Controller__c.St_Thomas_Colleges_Label__c';
import TELL_US_ABOUT_YOURSELF_LABEL from '@salesforce/schema/RFI_Controller__c.Tell_Us_About_Yourself_Label__c';
import TIMELINE_TO_ENROLLMENT_LABEL from '@salesforce/schema/RFI_Controller__c.Timeline_To_Enrollment_Label__c';
import TITLE_LABEL from '@salesforce/schema/RFI_Controller__c.Title_Label__c';
import WHEN_START_SCHOOL_LABEL from '@salesforce/schema/RFI_Controller__c.When_Start_School_Label__c';
import APPLY_TO_ST_THOMAS_AS_LABEL from '@salesforce/schema/RFI_Controller__c.Apply_To_St_Thomas_As_Label__c';

const FIELDS = [
    ID_FIELD,
    UNIFIED_QUESTIONS_FIELD,
    FIELDS_TO_DISPLAY_FIELD,
    FIELDS_TO_DISPLAY_ORDER_FIELD,
    REQUIRED_FIELDS_FIELD,
    INTERACTION_QUESTIONS_FIELD,
    ACADEMIC_INTEREST_LABEL,
    ADDRESS_LABEL,
    BIRTHDATE_LABEL,
    CITIZENSHIP_LABEL,
    COMPANY_LABEL,
    EMAIL_LABEL,
    EMPLOYER_LABEL,
    EXPECTED_START_TERM_LABEL,
    FIRST_NAME_LABEL,
    HIGH_SCHOOL_ATTENDED_LABEL,
    HIGH_SCHOOL_GRADUATION_YEAR_LABEL,
    HOW_DID_YOU_HEAR_ABOUT_US_LABEL,
    I_HAVE_A_QUESTION_LABEL,
    LAST_NAME_LABEL,
    MAIL_INFORMATION_LABEL,
    PHONE_LABEL,
    HOME_PHONE_LABEL,
    RECEIVE_TEXT_MESSAGES_LABEL,
    SCHOLARSHIP_OF_INTEREST_LABEL,
    ST_THOMAS_COLLEGES_LABEL,
    TELL_US_ABOUT_YOURSELF_LABEL,
    TIMELINE_TO_ENROLLMENT_LABEL,
    TITLE_LABEL,
    WHEN_START_SCHOOL_LABEL,
    APPLY_TO_ST_THOMAS_AS_LABEL
];

export default class RfiUnifiedQuestionManager extends LightningElement {
    @api recordId;
    @track questions = [];
    @track isLoading = false;
    @track showModal = false;
    @track modalMode = 'add'; // 'add', 'edit', 'addPreconfigured'
    @track draggedIndex = null;
    @track isSaving = false;
    @track needsMigration = false;

    wiredRecordResult;
    recordData;
    allPreconfiguredOptions = [];
    selectedPreconfiguredField = '';
    objectInfo;

    // Current question being edited in modal
    @track currentQuestion = {};

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

    // Map field API names to label field schema references
    fieldLabelMap = {
        'Academic Interest': ACADEMIC_INTEREST_LABEL,
        'Address': ADDRESS_LABEL,
        'Birthdate': BIRTHDATE_LABEL,
        'Citizenship': CITIZENSHIP_LABEL,
        'Email': EMAIL_LABEL,
        'Employer': EMPLOYER_LABEL,
        'Expected Start Term at St Thomas': EXPECTED_START_TERM_LABEL,
        'High School Attended': HIGH_SCHOOL_ATTENDED_LABEL,
        'High School Graduation Year': HIGH_SCHOOL_GRADUATION_YEAR_LABEL,
        'Phone': PHONE_LABEL,
        'Home Phone': HOME_PHONE_LABEL,
        'How did you hear about us': HOW_DID_YOU_HEAR_ABOUT_US_LABEL,
        'I have a question': I_HAVE_A_QUESTION_LABEL,
        'I will apply to St Thomas as a': APPLY_TO_ST_THOMAS_AS_LABEL,
        'I will apply to St Thomas Law as a': APPLY_TO_ST_THOMAS_AS_LABEL,
        'Mail Information': MAIL_INFORMATION_LABEL,
        'Scholarship of Interest': SCHOLARSHIP_OF_INTEREST_LABEL,
        'St Thomas Colleges': ST_THOMAS_COLLEGES_LABEL,
        'Tell us about yourself': TELL_US_ABOUT_YOURSELF_LABEL,
        'Timeline to Enrollment': TIMELINE_TO_ENROLLMENT_LABEL,
        'Title': TITLE_LABEL,
        'When Start School': WHEN_START_SCHOOL_LABEL,
        'Company': COMPANY_LABEL,
        'First Name': FIRST_NAME_LABEL,
        'Last Name': LAST_NAME_LABEL,
        'Receive Text Messages': RECEIVE_TEXT_MESSAGES_LABEL
    };

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
    interactionObjectInfo;

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
        const interactionQuestionsJSON = this.getFieldValue(INTERACTION_QUESTIONS_FIELD);

        const requiredFieldsArray = requiredFields ? requiredFields.split(';') : [];

        // Step 1: Add "top" questions from Interaction_Questions
        if (interactionQuestionsJSON) {
            try {
                const interactionQuestions = JSON.parse(interactionQuestionsJSON);
                const topQuestions = interactionQuestions.filter(q => q.position === 'top');

                topQuestions.forEach(q => {
                    migratedQuestions.push({
                        id: migratedQuestions.length,
                        type: 'custom',
                        questionLabel: q.questionLabel || '',
                        questionType: q.questionType || 'Text box',
                        fieldToApplyTo: q.fieldToApplyTo || '',
                        isRequired: q.isRequired || false,
                        picklistValues: q.picklistValues || [],
                        valuesFlat: q.valuesFlat || '',
                        assistiveText: q.assistiveText || ''
                    });
                });
            } catch (e) {
                console.error('Error parsing Interaction_Questions__c:', e);
            }
        }

        // Step 2: Add pre-configured fields (middle section)
        // Use Fields_to_Display_Order__c if available, otherwise fall back to Fields_to_Display__c
        const fieldsSource = fieldsToDisplayOrder || fieldsToDisplay;

        // Address sub-fields from the old system that get collapsed into a single 'Address' entry
        const ADDRESS_SUB_FIELDS = new Set(['Address 1', 'Address 2', 'Address 3', 'City', 'State', 'Zipcode', 'Country']);

        // Build the ordered field list; always ensure First Name and Last Name are present
        // (they were hard-coded in the old form and never stored in the picklist fields)
        let rawFields = fieldsSource ? fieldsSource.split(';').map(f => f.trim()).filter(f => f) : [];

        // Collapse address sub-fields: replace the first occurrence with 'Address', drop the rest
        let addressAdded = false;
        let orderedFields = [];
        for (const fieldName of rawFields) {
            if (ADDRESS_SUB_FIELDS.has(fieldName)) {
                if (!addressAdded) {
                    orderedFields.push('Address');
                    addressAdded = true;
                }
                // Skip subsequent address sub-fields
            } else {
                orderedFields.push(fieldName);
            }
        }

        // Prepend First Name and Last Name if not already present
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

        console.log(`📋 Migrated ${orderedFields.length} pre-configured fields (address sub-fields collapsed to single Address entry)`);

        // Step 3: Add "bottom" questions from Interaction_Questions
        if (interactionQuestionsJSON) {
            try {
                const interactionQuestions = JSON.parse(interactionQuestionsJSON);
                const bottomQuestions = interactionQuestions.filter(q => q.position === 'bottom' || !q.position);

                bottomQuestions.forEach(q => {
                    migratedQuestions.push({
                        id: migratedQuestions.length,
                        type: 'custom',
                        questionLabel: q.questionLabel || '',
                        questionType: q.questionType || 'Text box',
                        fieldToApplyTo: q.fieldToApplyTo || '',
                        isRequired: q.isRequired || false,
                        picklistValues: q.picklistValues || [],
                        valuesFlat: q.valuesFlat || '',
                        assistiveText: q.assistiveText || ''
                    });
                });
            } catch (e) {
                console.error('Error parsing Interaction_Questions__c:', e);
            }
        }

        this.questions = migratedQuestions;
        this.needsMigration = true;
        console.log(`✅ Migrated ${migratedQuestions.length} questions from legacy structure`);
    }

    getFieldValue(field) {
        return getFieldValue(this.recordData, field);
    }

    getStoredLabel(fieldName) {
        const labelField = this.fieldLabelMap[fieldName];
        if (labelField && this.recordData) {
            return this.getFieldValue(labelField);
        }
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

    openEditModal(event) {
        const questionId = parseInt(event.currentTarget.dataset.id);
        this.modalMode = 'edit';
        this.currentQuestion = { ...this.questions[questionId] };
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
                break;
            case 'fieldToApplyTo':
                this.currentQuestion.fieldToApplyTo = value;
                break;
            case 'picklistValues': {
                const pickValues = value.split('\n').filter(v => v.trim() !== '');
                this.currentQuestion.picklistValues = pickValues.map(v => ({ label: v, value: v }));
                this.currentQuestion.valuesFlat = pickValues.join(';');
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
        return questions.map((q, index) => ({
            ...q,
            id: index,
            typePreconfigured: q.type === 'preconfigured',
            isStaticContent: q.questionType === 'Static content',
            isFirst: index === 0,
            isLast: index === last
        }));
    }

    handleStaticContentChange(event) {
        this.currentQuestion.valuesFlat = event.target.value;
        this.currentQuestion = { ...this.currentQuestion };
    }

    // Save question from modal
    saveQuestion() {
        if (this.modalMode === 'addPreconfigured') {
            this.addPreconfiguredField();
        } else {
            this.saveCustomQuestion();
        }
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
    }

    handleDragEnd(event) {
        event.currentTarget.classList.remove('dragging');
    }

    handleDragOver(event) {
        event.preventDefault();
    }

    handleDrop(event) {
        event.preventDefault();
        const dropIndex = parseInt(event.currentTarget.dataset.index);

        if (this.draggedIndex !== null && this.draggedIndex !== dropIndex) {
            const items = [...this.questions];
            const draggedItem = items[this.draggedIndex];

            items.splice(this.draggedIndex, 1);
            items.splice(dropIndex, 0, draggedItem);

            this.questions = this.stampComputedProps(items);
        }

        this.draggedIndex = null;
    }

    // Move up/down buttons
    moveUp(event) {
        const index = parseInt(event.currentTarget.dataset.id);
        if (index === 0) return;

        const items = [...this.questions];
        [items[index - 1], items[index]] = [items[index], items[index - 1]];
        this.questions = this.stampComputedProps(items);
    }

    moveDown(event) {
        const index = parseInt(event.currentTarget.dataset.id);
        if (index === this.questions.length - 1) return;

        const items = [...this.questions];
        [items[index], items[index + 1]] = [items[index + 1], items[index]];
        this.questions = this.stampComputedProps(items);
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
        } else if (this.modalMode === 'add') {
            return 'Add Custom Question';
        } else {
            return 'Edit Question';
        }
    }

    get isAddPreconfiguredMode() {
        return this.modalMode === 'addPreconfigured';
    }

    get isCustomQuestion() {
        return this.modalMode === 'add' ||
               this.modalMode === 'edit' && this.currentQuestion.type === 'custom';
    }

    get isPicklist() {
        return this.currentQuestion.questionType === 'Picklist' ||
               this.currentQuestion.questionType === 'Picklist required';
    }

    get isStaticContent() {
        return this.currentQuestion.questionType === 'Static content';
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

