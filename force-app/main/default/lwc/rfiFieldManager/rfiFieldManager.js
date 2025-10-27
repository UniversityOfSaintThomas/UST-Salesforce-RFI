import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, updateRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import RFI_CONTROLLER_OBJECT from '@salesforce/schema/RFI_Controller__c';
import FIELDS_TO_DISPLAY_FIELD from '@salesforce/schema/RFI_Controller__c.Fields_to_Display__c';
import FIELDS_TO_DISPLAY_ORDER_FIELD from '@salesforce/schema/RFI_Controller__c.Fields_to_Display_Order__c';
import REQUIRED_FIELDS_FIELD from '@salesforce/schema/RFI_Controller__c.Required_Fields__c';

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
import RECEIVE_TEXT_MESSAGES_LABEL from '@salesforce/schema/RFI_Controller__c.Receive_Text_Messages_Label__c';
import SCHOLARSHIP_OF_INTEREST_LABEL from '@salesforce/schema/RFI_Controller__c.Scholarship_Of_Interest_Label__c';
import ST_THOMAS_COLLEGES_LABEL from '@salesforce/schema/RFI_Controller__c.St_Thomas_Colleges_Label__c';
import TELL_US_ABOUT_YOURSELF_LABEL from '@salesforce/schema/RFI_Controller__c.Tell_Us_About_Yourself_Label__c';
import TIMELINE_TO_ENROLLMENT_LABEL from '@salesforce/schema/RFI_Controller__c.Timeline_To_Enrollment_Label__c';
import TITLE_LABEL from '@salesforce/schema/RFI_Controller__c.Title_Label__c';
import WHEN_START_SCHOOL_LABEL from '@salesforce/schema/RFI_Controller__c.When_Start_School_Label__c';
import APPLY_TO_ST_THOMAS_AS_LABEL from '@salesforce/schema/RFI_Controller__c.Apply_To_St_Thomas_As_Label__c';

const FIELDS = [
    FIELDS_TO_DISPLAY_FIELD,
    FIELDS_TO_DISPLAY_ORDER_FIELD,
    REQUIRED_FIELDS_FIELD,
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
    RECEIVE_TEXT_MESSAGES_LABEL,
    SCHOLARSHIP_OF_INTEREST_LABEL,
    ST_THOMAS_COLLEGES_LABEL,
    TELL_US_ABOUT_YOURSELF_LABEL,
    TIMELINE_TO_ENROLLMENT_LABEL,
    TITLE_LABEL,
    WHEN_START_SCHOOL_LABEL,
    APPLY_TO_ST_THOMAS_AS_LABEL
];

export default class RfiFieldManager extends LightningElement {
    @api recordId;
    @track fieldItems = [];
    @track isLoading = false;

    draggedIndex = null;
    isSaving = false;
    wiredRecordResult;
    recordData;
    allPicklistValues = [];
    selectedFieldToAdd = '';

    // Map field API names to label field schema references
    fieldLabelMap = {
        'Academic Interest': ACADEMIC_INTEREST_LABEL,
        'Address 1': ADDRESS_LABEL,
        'Address 2': ADDRESS_LABEL,
        'Address 3': ADDRESS_LABEL,
        'Birthdate': BIRTHDATE_LABEL,
        'Citizenship': CITIZENSHIP_LABEL,
        'City': ADDRESS_LABEL,
        'Country': ADDRESS_LABEL,
        'Email': EMAIL_LABEL,
        'Employer': EMPLOYER_LABEL,
        'Expected Start Term at St Thomas': EXPECTED_START_TERM_LABEL,
        'High School Attended': HIGH_SCHOOL_ATTENDED_LABEL,
        'High School Graduation Year': HIGH_SCHOOL_GRADUATION_YEAR_LABEL,
        'Home and Mobile Phone': PHONE_LABEL,
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

    // Default labels to use when label fields are blank
    defaultLabels = {
        'Academic Interest': 'Academic Interest',
        'Address 1': 'Address 1',
        'Address 2': 'Address 2',
        'Address 3': 'Address 3',
        'Birthdate': 'Birthdate',
        'Citizenship': 'Citizenship',
        'City': 'City',
        'Country': 'Country',
        'Email': 'Email',
        'Employer': 'Employer',
        'Expected Start Term at St Thomas': 'Expected Start Term at St Thomas',
        'High School Attended': 'High School Attended',
        'High School Graduation Year': 'High School Graduation Year',
        'Home and Mobile Phone': 'Home and Mobile Phone',
        'How did you hear about us': 'How did you hear about us',
        'I have a question': 'I have a question',
        'I will apply to St Thomas as a': 'I will apply to St Thomas as a',
        'I will apply to St Thomas Law as a': 'I will apply to St Thomas Law as a',
        'I would like program information to be mailed to me': 'Mail Information',
        'I would like to receive text messages': 'Receive Text Messages',
        'Mail Information': 'Mail Information',
        'Phone': 'Phone',
        'Scholarship of Interest': 'Scholarship of Interest',
        'St Thomas Colleges': 'St Thomas Colleges',
        'State': 'State',
        'Tell us about yourself': 'Tell us about yourself',
        'Timeline to Enrollment': 'Timeline to Enrollment',
        'Title': 'Title',
        'When do you plan to start school': 'When do you plan to start school'
    };

    objectInfo;

    @wire(getObjectInfo, { objectApiName: RFI_CONTROLLER_OBJECT })
    rfiObjectInfo({ data, error }) {
        if (data) {
            this.objectInfo = data;
        } else if (error) {
            console.error('Error loading object info:', error);
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.defaultRecordTypeId',
        fieldApiName: FIELDS_TO_DISPLAY_FIELD
    })
    picklistValues({ data, error }) {
        if (data) {
            this.allPicklistValues = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
            console.log('All picklist values loaded:', this.allPicklistValues.length);
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
            // Only initialize if not currently saving
            if (!this.isSaving) {
                this.initializeFieldItems();
            }
        } else if (error) {
            console.error('Error loading record:', error);
            this.showToast('Error', 'Error loading record', 'error');
        }
    }

    initializeFieldItems() {
        if (!this.recordData) return;

        // Get the order field (preserves custom order)
        let fieldsOrder = this.getFieldValue(FIELDS_TO_DISPLAY_ORDER_FIELD);

        // Get the multiselect field (source of truth for which fields are selected)
        const fieldsToDisplay = this.getFieldValue(FIELDS_TO_DISPLAY_FIELD);
        const requiredFields = this.getFieldValue(REQUIRED_FIELDS_FIELD);

        console.log('=== INITIALIZING FIELD ITEMS ===');
        console.log('Fields_to_Display_Order__c (custom order):', fieldsOrder);
        console.log('Fields_to_Display__c (selected fields):', fieldsToDisplay);
        console.log('Required_Fields__c:', requiredFields);

        // Parse the selected fields
        const selectedFields = fieldsToDisplay ? fieldsToDisplay.split(';') : [];

        // If we have a custom order, use it; otherwise use the selected fields order
        let orderedFields;
        if (fieldsOrder) {
            const orderArray = fieldsOrder.split(';');
            // Filter to only include fields that are still selected
            orderedFields = orderArray.filter(field => selectedFields.includes(field));
            // Add any new fields that aren't in the order yet
            selectedFields.forEach(field => {
                if (!orderedFields.includes(field)) {
                    orderedFields.push(field);
                }
            });
        } else {
            // No custom order yet, use the multiselect order
            orderedFields = selectedFields;
        }

        const required = requiredFields ? requiredFields.split(';') : [];

        console.log('Final ordered fields:', orderedFields);
        console.log('Required fields array:', required);

        this.fieldItems = orderedFields.map((field, index) => {
            return {
                id: `field-${index}`,
                fieldName: field,
                label: this.getFieldLabel(field),
                isRequired: required.includes(field),
                index: index
            };
        });

        console.log('Final fieldItems array:', this.fieldItems.map(f => f.fieldName));
        console.log('=== END INITIALIZATION ===');
    }

    getFieldValue(field) {
        return getFieldValue(this.recordData, field);
    }

    /**
     * Get the display label for a field, using the following priority:
     * 1. Custom label from label field (if not blank)
     * 2. Default label from defaultLabels map
     * 3. Field name itself as last resort
     */
    getFieldLabel(fieldName) {
        const labelField = this.fieldLabelMap[fieldName];
        let labelValue = null;

        if (labelField && this.recordData) {
            labelValue = this.getFieldValue(labelField);
        }

        // If label is blank/null/empty, use default
        if (!labelValue || labelValue.trim() === '') {
            labelValue = this.defaultLabels[fieldName] || fieldName;
        }

        return labelValue;
    }

    handleLabelChange(event) {
        const index = parseInt(event.target.dataset.index);
        this.fieldItems[index].label = event.target.value;
    }

    handleRequiredChange(event) {
        const index = parseInt(event.target.dataset.index);
        this.fieldItems[index].isRequired = event.target.checked;
    }

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
            // Create a new array to ensure reactivity
            const items = JSON.parse(JSON.stringify(this.fieldItems));
            const draggedItem = items[this.draggedIndex];

            // Remove from old position
            items.splice(this.draggedIndex, 1);

            // Insert at new position
            items.splice(dropIndex, 0, draggedItem);

            // Reassign indices and update the tracked array
            this.fieldItems = items.map((item, index) => ({
                id: `field-${index}`,
                fieldName: item.fieldName,
                label: item.label,
                isRequired: item.isRequired,
                index: index
            }));

            console.log('Reordered fields:', this.fieldItems.map(f => f.fieldName));
        }

        this.draggedIndex = null;
    }

    handleFieldSelection(event) {
        this.selectedFieldToAdd = event.detail.value;
        console.log('Selected field to add:', this.selectedFieldToAdd);
    }

    handleAddField() {
        if (!this.selectedFieldToAdd) {
            this.showToast('Warning', 'Please select a field to add', 'warning');
            return;
        }

        // Check if field already exists
        const exists = this.fieldItems.some(item => item.fieldName === this.selectedFieldToAdd);
        if (exists) {
            this.showToast('Warning', 'This field is already in the list', 'warning');
            return;
        }

        // Get the label for the new field (with default fallback)
        const labelValue = this.getFieldLabel(this.selectedFieldToAdd);

        // Add to the end of the list
        const newField = {
            id: `field-${this.fieldItems.length}`,
            fieldName: this.selectedFieldToAdd,
            label: labelValue,
            isRequired: false,
            index: this.fieldItems.length
        };

        this.fieldItems = [...this.fieldItems, newField];

        console.log('Added new field:', this.selectedFieldToAdd);
        this.showToast('Success', `Field "${this.selectedFieldToAdd}" added to the list`, 'success');

        // Clear selection
        this.selectedFieldToAdd = '';
    }

    handleRemoveField(event) {
        const index = parseInt(event.currentTarget.dataset.index);
        const fieldName = this.fieldItems[index].fieldName;

        // Remove the field
        const items = this.fieldItems.filter((item, i) => i !== index);

        // Reassign indices
        this.fieldItems = items.map((item, index) => ({
            ...item,
            index: index,
            id: `field-${index}`
        }));

        console.log('Removed field:', fieldName);
        this.showToast('Success', `Field "${fieldName}" removed from the list`, 'success');
    }

    handleSave() {
        this.isLoading = true;
        this.isSaving = true;

        const fieldsToDisplayOrder = this.fieldItems.map(item => item.fieldName).join(';');
        const fieldsToDisplay = fieldsToDisplayOrder; // Same for the multiselect (though it may reorder)
        const requiredFields = this.fieldItems
            .filter(item => item.isRequired)
            .map(item => item.fieldName)
            .join(';');

        console.log('=== SAVING FIELDS ===');
        console.log('Current fieldItems order:', this.fieldItems.map(f => f.fieldName));
        console.log('Saving to Fields_to_Display_Order__c:', fieldsToDisplayOrder);
        console.log('Saving to Fields_to_Display__c:', fieldsToDisplay);
        console.log('Saving to Required_Fields__c:', requiredFields);

        const fields = {
            Id: this.recordId,
            [FIELDS_TO_DISPLAY_FIELD.fieldApiName]: fieldsToDisplay,
            [FIELDS_TO_DISPLAY_ORDER_FIELD.fieldApiName]: fieldsToDisplayOrder,
            [REQUIRED_FIELDS_FIELD.fieldApiName]: requiredFields
        };

        // Add label fields
        this.fieldItems.forEach(item => {
            const labelField = this.fieldLabelMap[item.fieldName];
            if (labelField && item.label) {
                fields[labelField.fieldApiName] = item.label;
            }
        });

        const recordInput = { fields };

        console.log('Field API Names being updated:');
        console.log('  - Fields_to_Display__c:', FIELDS_TO_DISPLAY_FIELD.fieldApiName);
        console.log('  - Fields_to_Display_Order__c:', FIELDS_TO_DISPLAY_ORDER_FIELD.fieldApiName);
        console.log('  - Required_Fields__c:', REQUIRED_FIELDS_FIELD.fieldApiName);
        console.log('Complete record input object:', JSON.stringify(recordInput, null, 2));

        updateRecord(recordInput)
            .then((result) => {
                console.log('✅ Save successful! Result:', result);
                this.showToast('Success', 'Fields configuration saved successfully', 'success');

                // Refresh the wire service to get updated data
                console.log('Refreshing wire service data...');
                this.isSaving = false;
                return refreshApex(this.wiredRecordResult);
            })
            .then(() => {
                console.log('✅ Refresh complete');
                this.isLoading = false;
            })
            .catch(error => {
                this.isSaving = false;
                this.isLoading = false;
                console.error('❌ Save error:', error);
                console.error('Error details:', JSON.stringify(error, null, 2));
                const errorMessage = error?.body?.message || error?.message || 'Unknown error';
                this.showToast('Error', 'Error saving fields: ' + errorMessage, 'error');
            });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    get hasFields() {
        return this.fieldItems && this.fieldItems.length > 0;
    }

    get availableFieldOptions() {
        // Filter out fields that are already in the list
        const currentFields = this.fieldItems.map(item => item.fieldName);
        const available = this.allPicklistValues.filter(
            option => !currentFields.includes(option.value)
        );

        // Add placeholder option
        return [
            { label: '-- Select a field to add --', value: '' },
            ...available
        ];
    }

    get hasAvailableFields() {
        return this.availableFieldOptions && this.availableFieldOptions.length > 1;
    }
}

