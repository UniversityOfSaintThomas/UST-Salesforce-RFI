/**
 * Created by Thaddaeus Dahlberg, Software Engineer, University of St. Thomas
 * Enhanced version for Interaction object with drag-and-drop sorting and inline editing
 */

import {api, LightningElement, track, wire} from 'lwc';
import {getObjectInfo} from "lightning/uiObjectInfoApi";
import {getRecord, getFieldValue} from "lightning/uiRecordApi";
import {updateRecord} from "lightning/uiRecordApi";
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import ID_FIELD from "@salesforce/schema/RFI_Controller__c.Id";
import INTERACTION_QUESTIONS_FIELD from "@salesforce/schema/RFI_Controller__c.Interaction_Questions__c";

const FIELDS = [
    ID_FIELD,
    INTERACTION_QUESTIONS_FIELD
];

export default class RfiAdditionalQuestionsInteractions extends LightningElement {

    @api recordId;

    @track questionJSON = [];
    @track showDataTable = false;
    @track showModal = false;
    @track modalMode = 'add'; // 'add' or 'edit'
    @track draggedItemId = null;

    @track inputItem = {
        'id': '',
        'questionLabel': '',
        'questionType': '',
        'fieldToApplyTo': '',
        'assistiveText': '',
        'position': '',
        'isPicklist': false,
        'isRequired': false,
        'isTextBox': false,
        'isTextarea': false,
        'isRichText': false,
        'isStaticContent': false,
        'isEmail': false,
        'picklistValues': [],
        'valuesFlat': ''
    };

    @track questionTypes = [
        {label: 'Email', value: 'Email'},
        {label: 'Email required', value: 'Email required'},
        {label: 'Picklist', value: 'Picklist'},
        {label: 'Picklist required', value: 'Picklist required'},
        {label: 'Static content', value: 'Static content'},
        {label: 'Text box', value: 'Text box'},
        {label: 'Text box required', value: 'Text box required'},
        {label: 'Textarea', value: 'Textarea'},
        {label: 'Textarea required', value: 'Textarea required'}
    ];

    positionOptions = [
        {label: 'Top', value: 'top'},
        {label: 'Bottom', value: 'bottom'}
    ];

    // Wire to get interaction questions from RFI Controller record
    @wire(getRecord, {recordId: "$recordId", fields: FIELDS})
    loadQuestionsWire({error, data}) {
        if (error) {
            let errorMsg = error.body?.message || 'Unknown error';

            // Check if it's a missing field error
            if (errorMsg.includes('Interaction_Questions__c') && errorMsg.includes('No such column')) {
                errorMsg = 'Field "Interaction_Questions__c" not found. Please create it: Setup → Object Manager → RFI Controller → Fields & Relationships → New → Text Area (Long), Length: 131072, Name: Interaction_Questions';
                console.error('FIELD MISSING: The Interaction_Questions__c field needs to be created manually. See MANUAL_FIELD_CREATION_REQUIRED.md for instructions.');
            }

            this.showToast('Setup Required', errorMsg, 'error');
        } else if (data) {
            const JSONString = getFieldValue(data, INTERACTION_QUESTIONS_FIELD);
            if (JSONString === null || JSONString === '[]') {
                this.questionJSON = [];
                this.showDataTable = false;
            } else {
                this.questionJSON = JSON.parse(JSONString.toString());
                this.showDataTable = true;
            }
        }
    }

    @api
    async refresh() {
        // This method can be called externally to refresh the data
        return;
    }

    // Get all the field names and api names for the Interaction object using wire
    @wire(getObjectInfo, {objectApiName: 'Interaction__c'})
    interactionObjectInfo;

    // Getting all available interaction fields
    get interactionFields() {
        const interactionFields = [];
        if (this.interactionObjectInfo && this.interactionObjectInfo.data) {
            const fieldNames = Object.keys(this.interactionObjectInfo.data.fields);
            fieldNames.forEach(fieldName => {
                const field = this.interactionObjectInfo.data.fields[fieldName];
                const fieldType = field.dataType.toLowerCase();

                if ((
                    ((fieldType === 'string' || fieldType === 'textarea') && (this.inputItem.isTextBox || this.inputItem.isTextarea || this.inputItem.isPicklist))
                    || (fieldType === 'email' && this.inputItem.isEmail))
                    && field.updateable && field.createable
                    && !fieldName.toLowerCase().startsWith('utm_')
                    && !fieldName.toLowerCase().startsWith('gclid')
                    && !fieldName.toLowerCase().startsWith('linkedin_')) {
                    interactionFields.push({label: field.label, value: fieldName});
                }
            });
        }
        interactionFields.sort((a, b) => { return a.label.localeCompare(b.label); });
        return interactionFields;
    }

    // Modal controls
    openAddModal() {
        this.modalMode = 'add';
        this.resetInputItem();
        this.showModal = true;
    }

    openEditModal(event) {
        const questionId = parseInt(event.currentTarget.dataset.id);
        this.modalMode = 'edit';
        this.inputItem = {...this.questionJSON[questionId]};
        this.showModal = true;
    }

    closeModal() {
        this.showModal = false;
        this.resetInputItem();
    }

    resetInputItem() {
        this.inputItem = {
            'id': '',
            'questionLabel': '',
            'questionType': '',
            'fieldToApplyTo': '',
            'assistiveText': '',
            'position': '',
            'isPicklist': false,
            'isRequired': false,
            'isTextBox': false,
            'isTextarea': false,
            'isRichText': false,
            'isStaticContent': false,
            'isEmail': false,
            'picklistValues': [],
            'valuesFlat': ''
        };
    }

    get isPicklist() {
        return this.inputItem.isPicklist;
    }

    get isTextarea() {
        return this.inputItem.isTextarea;
    }

    get isTextBox() {
        return this.inputItem.isTextBox;
    }

    get isEmail() {
        return this.inputItem.isEmail;
    }

    get isStaticContent() {
        return this.inputItem.isStaticContent;
    }

    get assistiveTextRequired() {
        return this.inputItem.isRequired;
    }

    get modalTitle() {
        return this.modalMode === 'add' ? 'Add Question' : 'Edit Question';
    }

    // Handle input changes
    handleChange(event) {
        const name = event.target.name;
        const value = event.target.value;

        switch (name) {
            case 'questionType':
                this.inputItem.isPicklist = false;
                this.inputItem.isEmail = false;
                this.inputItem.isTextarea = false;
                this.inputItem.isTextBox = false;
                this.inputItem.isStaticContent = false;

                if (value === 'Picklist' || value === 'Picklist required') {
                    this.inputItem.isPicklist = true;
                }
                if (value === 'Text box' || value === 'Text box required') {
                    this.inputItem.isTextBox = true;
                }
                if (value === 'Textarea' || value === 'Textarea required') {
                    this.inputItem.isTextarea = true;
                }
                if (value === 'Email' || value === 'Email required') {
                    this.inputItem.isEmail = true;
                }
                if (value === 'Static content') {
                    this.inputItem.isStaticContent = true;
                }
                this.inputItem.questionType = value;
                this.inputItem.isRequired = value.includes('required');

                // Force re-render
                this.inputItem = {...this.inputItem};
                break;

            case 'fieldToApplyTo':
                this.inputItem.fieldToApplyTo = value;
                this.inputItem = {...this.inputItem};
                break;

            case 'picklistValues': {
                const pickValues = value.split('\n');
                const pickValuesArray = [];
                pickValues.forEach(function (val) {
                    if (val !== '') {
                        pickValuesArray.push({label: val, value: val});
                    }
                });
                this.inputItem.picklistValues = pickValuesArray;
                this.inputItem.valuesFlat = pickValues.join(';');
                this.inputItem = {...this.inputItem};
                break;
            }

            case 'staticContent':
                this.inputItem.valuesFlat = value;
                this.inputItem = {...this.inputItem};
                break;

            case 'questionLabel':
                this.inputItem.questionLabel = value;
                this.inputItem = {...this.inputItem};
                break;

            case 'assistiveText':
                this.inputItem.assistiveText = value;
                this.inputItem = {...this.inputItem};
                break;

            case 'position':
                this.inputItem.position = value;
                this.inputItem = {...this.inputItem};
                break;
        }
    }

    // Save question (add or edit)
    async saveQuestion() {
        // Validate inputs
        const allValid = [...this.template.querySelectorAll('lightning-input,lightning-combobox,lightning-textarea')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);

        if (!allValid) {
            return;
        }

        try {
            let updatedQuestions = [...this.questionJSON];

            if (this.modalMode === 'add') {
                // Add new question
                this.inputItem.id = updatedQuestions.length;
                updatedQuestions.push({...this.inputItem});
            } else {
                // Edit existing question
                const index = updatedQuestions.findIndex(q => q.id === this.inputItem.id);
                if (index !== -1) {
                    updatedQuestions[index] = {...this.inputItem};
                }
            }

            await this.saveToSalesforce(updatedQuestions);
            this.questionJSON = updatedQuestions;
            this.showDataTable = updatedQuestions.length > 0;
            this.closeModal();
            this.showToast('Success', `Question ${this.modalMode === 'add' ? 'added' : 'updated'} successfully`, 'success');
        } catch (error) {
            this.showToast('Error', 'Failed to save question: ' + error.message, 'error');
        }
    }

    // Delete question
    async deleteQuestion(event) {
        const questionId = parseInt(event.currentTarget.dataset.id);

        try {
            let updatedQuestions = this.questionJSON.filter((q, index) => index !== questionId);

            // Reindex
            updatedQuestions = updatedQuestions.map((q, index) => ({...q, id: index}));

            await this.saveToSalesforce(updatedQuestions);
            this.questionJSON = updatedQuestions;
            this.showDataTable = updatedQuestions.length > 0;
            this.showToast('Success', 'Question deleted successfully', 'success');
        } catch (error) {
            this.showToast('Error', 'Failed to delete question: ' + error.message, 'error');
        }
    }

    // Drag and drop handlers
    handleDragStart(event) {
        this.draggedItemId = parseInt(event.currentTarget.dataset.id);
        event.currentTarget.classList.add('dragging');
    }

    handleDragEnd(event) {
        event.currentTarget.classList.remove('dragging');
        this.draggedItemId = null;
    }

    handleDragOver(event) {
        event.preventDefault();
        const dropTarget = event.currentTarget;
        dropTarget.classList.add('drag-over');
    }

    handleDragLeave(event) {
        event.currentTarget.classList.remove('drag-over');
    }

    async handleDrop(event) {
        event.preventDefault();
        event.currentTarget.classList.remove('drag-over');

        const dropTargetId = parseInt(event.currentTarget.dataset.id);

        if (this.draggedItemId === dropTargetId || this.draggedItemId === null) {
            return;
        }

        try {
            let updatedQuestions = [...this.questionJSON];
            const draggedItem = updatedQuestions[this.draggedItemId];

            // Remove dragged item
            updatedQuestions.splice(this.draggedItemId, 1);

            // Insert at new position
            const newIndex = this.draggedItemId < dropTargetId ? dropTargetId - 1 : dropTargetId;
            updatedQuestions.splice(newIndex, 0, draggedItem);

            // Reindex
            updatedQuestions = updatedQuestions.map((q, index) => ({...q, id: index}));

            await this.saveToSalesforce(updatedQuestions);
            this.questionJSON = updatedQuestions;
            this.showToast('Success', 'Question order updated successfully', 'success');
        } catch (error) {
            this.showToast('Error', 'Failed to reorder questions: ' + error.message, 'error');
        }
    }

    // Move question up
    async moveUp(event) {
        const questionId = parseInt(event.currentTarget.dataset.id);

        if (questionId === 0) {
            return;
        }

        try {
            let updatedQuestions = [...this.questionJSON];
            [updatedQuestions[questionId - 1], updatedQuestions[questionId]] =
                [updatedQuestions[questionId], updatedQuestions[questionId - 1]];

            // Reindex
            updatedQuestions = updatedQuestions.map((q, index) => ({...q, id: index}));

            await this.saveToSalesforce(updatedQuestions);
            this.questionJSON = updatedQuestions;
            this.showToast('Success', 'Question moved up', 'success');
        } catch (error) {
            this.showToast('Error', 'Failed to move question: ' + error.message, 'error');
        }
    }

    // Move question down
    async moveDown(event) {
        const questionId = parseInt(event.currentTarget.dataset.id);

        if (questionId === this.questionJSON.length - 1) {
            return;
        }

        try {
            let updatedQuestions = [...this.questionJSON];
            [updatedQuestions[questionId], updatedQuestions[questionId + 1]] =
                [updatedQuestions[questionId + 1], updatedQuestions[questionId]];

            // Reindex
            updatedQuestions = updatedQuestions.map((q, index) => ({...q, id: index}));

            await this.saveToSalesforce(updatedQuestions);
            this.questionJSON = updatedQuestions;
            this.showToast('Success', 'Question moved down', 'success');
        } catch (error) {
            this.showToast('Error', 'Failed to move question: ' + error.message, 'error');
        }
    }

    // Save to Salesforce
    async saveToSalesforce(questions) {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[INTERACTION_QUESTIONS_FIELD.fieldApiName] = JSON.stringify(questions);
        const recordInput = {fields};

        return updateRecord(recordInput);
    }

    // Show toast message
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}

