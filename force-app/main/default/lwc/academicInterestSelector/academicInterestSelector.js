/**
 * Academic Interest Selector Component
 * Admin tool to configure which academic programs appear on public-facing RFI forms
 * - Loads ALL available programs (matching RFI criteria)
 * - Displays full program names with short codes in parentheses
 * - Grouped by school/degree
 * - Saves selected short codes to Academic_Interests_To_Display__c
 * - No selection limit (admins can select as many as needed)
 * - Uses custom dual-listbox UI
 */

import {LightningElement, api, wire, track} from 'lwc';
import {getRecord, updateRecord, getRecordNotifyChange} from 'lightning/uiRecordApi';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {refreshApex} from '@salesforce/apex';
import getProgramsWithShortCodes from '@salesforce/apex/rfiFormController.getProgramsWithShortCodes';
import ACADEMIC_INTERESTS_FIELD from '@salesforce/schema/RFI_Controller__c.Academic_Interests_To_Display__c';
import ID_FIELD from '@salesforce/schema/RFI_Controller__c.Id';

const FIELDS = [
    'RFI_Controller__c.Academic_Level__c',
    'RFI_Controller__c.School_College__c',
    'RFI_Controller__c.Academic_Interests_To_Display__c'
];

export default class AcademicInterestSelector extends LightningElement {
    @api recordId;
    @api label = 'Select Academic Interests to Display on RFI';

    // These properties are kept for backward compatibility but not used by the admin tool
    @api maxSelections = 999; // Not enforced in admin tool
    @api required = false; // Not enforced in admin tool

    @track allPrograms = []; // All programs from server
    @track selectedValues = []; // Array of selected short codes
    @track availableSelection = []; // Currently selected items in available list
    @track selectedSelection = []; // Currently selected items in selected list
    @track lastAvailableClick = null; // Last clicked index in available list
    @track lastSelectedClick = null; // Last clicked index in selected list
    @track isLoading = true;
    @track isSaving = false;
    @track error;

    academicLevel;
    schoolCollege;
    wiredRecordResult;

    @wire(getRecord, {recordId: '$recordId', fields: FIELDS})
    wiredRFIController(result) {
        this.wiredRecordResult = result;
        const {error, data} = result;

        if (data) {
            this.academicLevel = data.fields.Academic_Level__c?.value;
            this.schoolCollege = data.fields.School_College__c?.value;

            // Load currently selected programs
            const currentSelections = data.fields.Academic_Interests_To_Display__c?.value;
            this.selectedValues = currentSelections ? currentSelections.split(';').filter(v => v) : [];

            this.loadPrograms();
        } else if (error) {
            this.error = error;
            this.isLoading = false;
            console.error('Error loading RFI Controller:', error);
        }
    }

    async loadPrograms() {
        try {
            this.isLoading = true;

            // Load ALL programs that meet RFI criteria (don't filter by Academic_Interests_To_Display__c)
            const programs = await getProgramsWithShortCodes({
                academic_level: this.academicLevel,
                school_college: this.schoolCollege,
                academic_interest_codes: null, // Get all programs
                filters: null
            });

            // Store all programs with display labels
            // group_level: 1 = school header, 2 = degree header, 0 = program item
            this.allPrograms = programs.map((prog, index) => ({
                label: prog.label, // Program name or header name
                value: prog.value, // Short code or header identifier
                description: prog.description,
                is_group: prog.is_group,
                group_level: prog.group_level || 0, // 1 for school, 2 for degree, 0 for program
                key: `prog-${index}`,
                // Display format: "Program Name (SHORT_CODE)" for programs, just label for headers
                displayLabel: prog.is_group ? prog.label : `${prog.label} (${prog.value})`,
                // CSS class for headers: school-header for level 1, degree-header for level 2
                headerClass: prog.is_group
                    ? (prog.group_level === 1
                        ? 'slds-listbox__item group-header school-header'
                        : 'slds-listbox__item group-header degree-header')
                    : ''
            }));

            // Clean up selectedValues - only keep values that exist in the loaded programs
            // This removes any artifacts or old program codes that are no longer available
            const validProgramCodes = new Set(
                this.allPrograms
                    .filter(prog => !prog.is_group && prog.value)
                    .map(prog => prog.value)
            );

            const originalSelectedCount = this.selectedValues.length;
            this.selectedValues = this.selectedValues.filter(code => validProgramCodes.has(code));

            // If we filtered out invalid codes, save the cleaned list
            if (originalSelectedCount !== this.selectedValues.length) {
                console.log(`Cleaned ${originalSelectedCount - this.selectedValues.length} invalid program code(s) from selections`);
                // Save the cleaned selections (without showing toast)
                this.saveSelectionsQuietly();
            }

            this.isLoading = false;
        } catch (error) {
            this.error = error;
            this.isLoading = false;
            console.error('Error loading programs:', error);
        }
    }

    // Compute available options (not yet selected)
    get availableOptions() {
        const selectedSet = new Set(this.selectedValues);
        const result = [];
        let currentSchool = null;
        let currentDegree = null;

        for (const prog of this.allPrograms) {
            if (prog.is_group && prog.group_level === 1) {
                // School header
                currentSchool = prog.label;
                currentDegree = null;
                // Add school header if it has unselected items (in any degree)
                const hasUnselectedItems = this.allPrograms.some(p =>
                    !p.is_group &&
                    p.description &&
                    p.description.startsWith(currentSchool) &&
                    !selectedSet.has(p.value)
                );
                if (hasUnselectedItems) {
                    result.push({...prog, key: `avail-${prog.key}`});
                }
            } else if (prog.is_group && prog.group_level === 2) {
                // Degree header
                currentDegree = prog.label;
                // Add degree header if it has unselected items
                const degreeDescription = currentSchool + ' - ' + currentDegree;
                const hasUnselectedItems = this.allPrograms.some(p =>
                    !p.is_group &&
                    p.description &&
                    p.description.startsWith(degreeDescription) &&
                    !selectedSet.has(p.value)
                );
                if (hasUnselectedItems) {
                    result.push({...prog, key: `avail-${prog.key}`});
                }
            } else if (!selectedSet.has(prog.value)) {
                // Program item (not selected)
                result.push({...prog, key: `avail-${prog.key}`});
            }
        }

        return result;
    }

    // Compute selected options
    get selectedOptions() {
        const selectedSet = new Set(this.selectedValues);
        const result = [];
        let currentSchool = null;
        let currentDegree = null;

        for (const prog of this.allPrograms) {
            if (prog.is_group && prog.group_level === 1) {
                // School header
                currentSchool = prog.label;
                currentDegree = null;
                // Add school header if it has selected items (in any degree)
                const hasSelectedItems = this.allPrograms.some(p =>
                    !p.is_group &&
                    p.description &&
                    p.description.startsWith(currentSchool) &&
                    selectedSet.has(p.value)
                );
                if (hasSelectedItems) {
                    result.push({...prog, key: `selected-${prog.key}`});
                }
            } else if (prog.is_group && prog.group_level === 2) {
                // Degree header
                currentDegree = prog.label;
                // Add degree header if it has selected items
                const degreeDescription = currentSchool + ' - ' + currentDegree;
                const hasSelectedItems = this.allPrograms.some(p =>
                    !p.is_group &&
                    p.description &&
                    p.description.startsWith(degreeDescription) &&
                    selectedSet.has(p.value)
                );
                if (hasSelectedItems) {
                    result.push({...prog, key: `selected-${prog.key}`});
                }
            } else if (selectedSet.has(prog.value)) {
                // Program item (selected)
                result.push({...prog, key: `selected-${prog.key}`});
            }
        }

        return result;
    }

    // Handle click on available list
    handleAvailableClick(event) {
        const value = event.currentTarget.dataset.value;
        const clickedIndex = this.getAvailableItemIndex(value);
        const isSelected = this.availableSelection.includes(value);

        if (event.shiftKey && this.lastAvailableClick !== null) {
            // Range select with Shift
            const rangeValues = this.getAvailableRangeValues(this.lastAvailableClick, clickedIndex);
            this.availableSelection = [...new Set([...this.availableSelection, ...rangeValues])];
        } else if (event.ctrlKey || event.metaKey) {
            // Multi-select with Ctrl/Cmd
            if (isSelected) {
                this.availableSelection = this.availableSelection.filter(v => v !== value);
            } else {
                this.availableSelection = [...this.availableSelection, value];
            }
            this.lastAvailableClick = clickedIndex;
        } else {
            // Single select
            this.availableSelection = isSelected ? [] : [value];
            this.lastAvailableClick = isSelected ? null : clickedIndex;
        }

        this.updateSelectionHighlights();
    }

    // Get index of item in available list (excluding groups)
    getAvailableItemIndex(value) {
        const items = this.availableOptions.filter(opt => !opt.is_group);
        return items.findIndex(opt => opt.value === value);
    }

    // Get values in range for available list
    getAvailableRangeValues(startIdx, endIdx) {
        const items = this.availableOptions.filter(opt => !opt.is_group);
        const start = Math.min(startIdx, endIdx);
        const end = Math.max(startIdx, endIdx);
        return items.slice(start, end + 1).map(opt => opt.value);
    }

    // Handle double-click on available list (move to selected)
    handleAvailableDoubleClick(event) {
        const value = event.currentTarget.dataset.value;
        this.moveToSelected([value]);
    }

    // Handle click on selected list
    handleSelectedClick(event) {
        const value = event.currentTarget.dataset.value;
        const clickedIndex = this.getSelectedItemIndex(value);
        const isSelected = this.selectedSelection.includes(value);

        if (event.shiftKey && this.lastSelectedClick !== null) {
            // Range select with Shift
            const rangeValues = this.getSelectedRangeValues(this.lastSelectedClick, clickedIndex);
            this.selectedSelection = [...new Set([...this.selectedSelection, ...rangeValues])];
        } else if (event.ctrlKey || event.metaKey) {
            // Multi-select with Ctrl/Cmd
            if (isSelected) {
                this.selectedSelection = this.selectedSelection.filter(v => v !== value);
            } else {
                this.selectedSelection = [...this.selectedSelection, value];
            }
            this.lastSelectedClick = clickedIndex;
        } else {
            // Single select
            this.selectedSelection = isSelected ? [] : [value];
            this.lastSelectedClick = isSelected ? null : clickedIndex;
        }

        this.updateSelectionHighlights();
    }

    // Get index of item in selected list (excluding groups)
    getSelectedItemIndex(value) {
        const items = this.selectedOptions.filter(opt => !opt.is_group);
        return items.findIndex(opt => opt.value === value);
    }

    // Get values in range for selected list
    getSelectedRangeValues(startIdx, endIdx) {
        const items = this.selectedOptions.filter(opt => !opt.is_group);
        const start = Math.min(startIdx, endIdx);
        const end = Math.max(startIdx, endIdx);
        return items.slice(start, end + 1).map(opt => opt.value);
    }

    // Handle double-click on selected list (move to available)
    handleSelectedDoubleClick(event) {
        const value = event.currentTarget.dataset.value;
        this.moveToAvailable([value]);
    }

    // Move selected items from available to selected
    handleMoveToSelected() {
        if (this.availableSelection.length > 0) {
            this.moveToSelected(this.availableSelection);
        }
    }

    // Move selected items from selected to available
    handleMoveToAvailable() {
        if (this.selectedSelection.length > 0) {
            this.moveToAvailable(this.selectedSelection);
        }
    }


    // Core method to move items to selected list
    moveToSelected(values) {
        this.selectedValues = [...new Set([...this.selectedValues, ...values])];
        this.availableSelection = [];
        this.saveSelections();
    }

    // Core method to move items to available list
    moveToAvailable(values) {
        const removeSet = new Set(values);
        this.selectedValues = this.selectedValues.filter(v => !removeSet.has(v));
        this.selectedSelection = [];
        this.saveSelections();
    }

    // Update visual highlights
    updateSelectionHighlights() {
        // Update available list highlights
        const availableListItems = this.template.querySelectorAll('.slds-dueling-list__column:first-child .slds-listbox__item:not(.group-header)');
        availableListItems.forEach(li => {
            const optionDiv = li.querySelector('[role="option"]');
            if (optionDiv) {
                const value = optionDiv.dataset.value;
                if (this.availableSelection.includes(value)) {
                    li.classList.add('slds-is-selected');
                    optionDiv.classList.add('slds-is-selected');
                    optionDiv.setAttribute('aria-selected', 'true');
                } else {
                    li.classList.remove('slds-is-selected');
                    optionDiv.classList.remove('slds-is-selected');
                    optionDiv.setAttribute('aria-selected', 'false');
                }
            }
        });

        // Update selected list highlights
        const selectedListItems = this.template.querySelectorAll('.slds-dueling-list__column:last-child .slds-listbox__item:not(.group-header)');
        selectedListItems.forEach(li => {
            const optionDiv = li.querySelector('[role="option"]');
            if (optionDiv) {
                const value = optionDiv.dataset.value;
                if (this.selectedSelection.includes(value)) {
                    li.classList.add('slds-is-selected');
                    optionDiv.classList.add('slds-is-selected');
                    optionDiv.setAttribute('aria-selected', 'true');
                } else {
                    li.classList.remove('slds-is-selected');
                    optionDiv.classList.remove('slds-is-selected');
                    optionDiv.setAttribute('aria-selected', 'false');
                }
            }
        });
    }

    async saveSelections() {
        try {
            this.isSaving = true;

            // Prepare record update
            const fields = {};
            fields[ID_FIELD.fieldApiName] = this.recordId;
            fields[ACADEMIC_INTERESTS_FIELD.fieldApiName] = this.selectedValues.join(';');

            const recordInput = {fields};

            // Update the record
            await updateRecord(recordInput);

            // Notify Lightning Data Service that this record has changed
            console.log('Notifying LDS of record change for recordId:', this.recordId);
            await getRecordNotifyChange([{recordId: this.recordId}]);

            // Refresh the wired data
            await refreshApex(this.wiredRecordResult);

            // Show success message
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: `${this.selectedValues.length} academic interest(s) selected`,
                    variant: 'success'
                })
            );

            this.isSaving = false;
        } catch (error) {
            this.isSaving = false;
            console.error('Error saving selections:', error);

            // Show error message
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error saving selections',
                    message: error.body?.message || 'An error occurred while saving',
                    variant: 'error'
                })
            );
        }
    }

    // Save selections without showing toast notification (used for automatic cleanup)
    async saveSelectionsQuietly() {
        try {
            // Prepare record update
            const fields = {};
            fields[ID_FIELD.fieldApiName] = this.recordId;
            fields[ACADEMIC_INTERESTS_FIELD.fieldApiName] = this.selectedValues.join(';');

            const recordInput = {fields};

            // Update the record
            await updateRecord(recordInput);

            // Notify Lightning Data Service that this record has changed
            console.log('Notifying LDS of record change (quiet save) for recordId:', this.recordId);
            await getRecordNotifyChange([{recordId: this.recordId}]);

            // Refresh the wired data
            await refreshApex(this.wiredRecordResult);
        } catch (error) {
            console.error('Error saving cleaned selections:', error);
        }
    }

    @api
    get value() {
        return this.selectedValues.join(';');
    }

    set value(val) {
        this.selectedValues = val ? val.split(';').filter(v => v) : [];
    }

    get selectionCount() {
        return this.selectedValues.length;
    }

    get displayLabel() {
        const count = this.selectionCount;
        if (count > 0) {
            return `${this.label} (${count} selected)`;
        }
        return this.label;
    }

    get hasSelections() {
        return this.selectionCount > 0;
    }

    get moveToSelectedDisabled() {
        return this.availableSelection.length === 0;
    }

    get moveToAvailableDisabled() {
        return this.selectedSelection.length === 0;
    }
}
