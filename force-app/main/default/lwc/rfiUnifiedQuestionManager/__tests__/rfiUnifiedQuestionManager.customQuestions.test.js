import { createElement } from 'lwc';
import RfiUnifiedQuestionManager from 'c/rfiUnifiedQuestionManager';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import getQuestionCatalog from '@salesforce/apex/rfiFormController.getQuestionCatalog';

jest.mock(
    '@salesforce/apex/rfiFormController.getQuestionCatalog',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true }
);

function field(apiName, label, dataType) {
    return { apiName, label, dataType, createable: true, updateable: true };
}

// One field of each kind, so the lists a question type offers can be told apart
const INTERACTION_INFO = {
    defaultRecordTypeId: '012000000000000AAA',
    fields: {
        Zz_Text__c: field('Zz_Text__c', 'Zz Text', 'String'),
        Zz_Area__c: field('Zz_Area__c', 'Zz Area', 'TextArea'),
        Zz_Check__c: field('Zz_Check__c', 'Zz Check', 'Boolean'),
        Zz_Date__c: field('Zz_Date__c', 'Zz Date', 'Date'),
        Zz_Moment__c: field('Zz_Moment__c', 'Zz Moment', 'DateTime'),
        Zz_Pick__c: field('Zz_Pick__c', 'Zz Pick', 'Picklist'),
        utm_hidden__c: field('utm_hidden__c', 'Hidden', 'String')
    }
};

const CATALOG = { questions: [{ name: 'First Name', defaultLabel: 'First Name', targetField: 'First_Name__c', isAlias: false, isComposite: false }], filters: [] };

const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

async function render(savedQuestions = []) {
    const element = createElement('c-rfi-unified-question-manager', { is: RfiUnifiedQuestionManager });
    element.recordId = '001000000000001AAA';
    document.body.appendChild(element);
    await flushPromises();
    getQuestionCatalog.emit(CATALOG);
    getObjectInfo.emit(INTERACTION_INFO);
    getPicklistValuesByRecordType.emit({ picklistFieldValues: { Zz_Pick__c: { values: [{ label: 'Alpha', value: 'Alpha' }, { label: 'Beta', value: 'Beta' }] } } });
    getRecord.emit({
        id: '001000000000001AAA', apiName: 'RFI_Controller__c',
        fields: {
            Unified_Questions__c: { value: JSON.stringify(savedQuestions) },
            Fields_to_Display__c: { value: 'First Name' }, Fields_to_Display_Order__c: { value: 'First Name' }, Required_Fields__c: { value: null }
        }
    });
    await flushPromises();
    return element;
}

function button(element, label) {
    return Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find((b) => b.label === label);
}

function combobox(element, label) {
    return Array.from(element.shadowRoot.querySelectorAll('lightning-combobox')).find((c) => c.label === label);
}

async function choose(element, label, value) {
    const box = combobox(element, label);
    box.value = value;
    box.dispatchEvent(new CustomEvent('change'));
    await flushPromises();
}

async function startCustomQuestion(element, type) {
    button(element, 'Add Custom Question').click();
    await flushPromises();
    const labelInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find((i) => i.label === 'Question Label');
    labelInput.value = 'My question';
    labelInput.dispatchEvent(new CustomEvent('change'));
    await choose(element, 'Question Type', type);
}

function fieldChoices(element) {
    return combobox(element, 'Interaction Field API Name').options.map((o) => o.value).filter((v) => v);
}

// The Jest stubs for the Lightning inputs return nothing from checkValidity(), which the dialog reads as invalid
function makeEverythingValid(element) {
    element.shadowRoot.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea').forEach((el) => {
        Object.defineProperty(el, 'checkValidity', { value: () => true, configurable: true });
        Object.defineProperty(el, 'reportValidity', { value: () => true, configurable: true });
    });
}

async function saveDialogThenConfiguration(element) {
    makeEverythingValid(element);
    Array.from(element.shadowRoot.querySelectorAll('button')).find((b) => b.textContent.trim() === 'Save').click();
    await flushPromises();
    button(element, 'Save Configuration').click();
    await flushPromises();
}

function savedQuestions() {
    expect(updateRecord).toHaveBeenCalledTimes(1);
    return JSON.parse(updateRecord.mock.calls[0][0].fields.Unified_Questions__c);
}

describe('c-rfi-unified-question-manager custom question types', () => {
    beforeEach(() => {
        updateRecord.mockClear();
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('offers Checkbox and Date as question types, each with a required variant', async () => {
        const element = await render();
        button(element, 'Add Custom Question').click();
        await flushPromises();
        const values = combobox(element, 'Question Type').options.map((o) => o.value);
        ['Checkbox', 'Checkbox required', 'Date', 'Date required'].forEach((type) => expect(values).toContain(type));
    });

    it('offers only yes/no fields for a Checkbox question', async () => {
        const element = await render();
        await startCustomQuestion(element, 'Checkbox');
        expect(fieldChoices(element)).toEqual(['Zz_Check__c']);
    });

    it('offers only date fields for a Date question, not date and time fields', async () => {
        const element = await render();
        await startCustomQuestion(element, 'Date required');
        expect(fieldChoices(element)).toEqual(['Zz_Date__c']);
    });

    it('still offers text fields for a text box and hides tracking fields', async () => {
        const element = await render();
        await startCustomQuestion(element, 'Text box');
        expect(fieldChoices(element)).toEqual(['Zz_Text__c', 'Zz_Area__c'].sort((a, b) => a.localeCompare(b)).sort());
        expect(fieldChoices(element)).not.toContain('utm_hidden__c');
    });

    it('saves a required Checkbox as required', async () => {
        const element = await render();
        await startCustomQuestion(element, 'Checkbox required');
        await choose(element, 'Interaction Field API Name', 'Zz_Check__c');
        await saveDialogThenConfiguration(element);
        const saved = savedQuestions().find((q) => q.type === 'custom');
        expect(saved.questionType).toBe('Checkbox required');
        expect(saved.isRequired).toBe(true);
        expect(saved.fieldToApplyTo).toBe('Zz_Check__c');
    });

    it('saves no copy of the values for a picklist on a picklist field, because the form reads the live values', async () => {
        const element = await render();
        await startCustomQuestion(element, 'Picklist');
        await choose(element, 'Interaction Field API Name', 'Zz_Pick__c');
        // The dialog shows the live values read-only
        expect(element.shadowRoot.textContent).toContain('Alpha');
        expect(element.shadowRoot.textContent).toContain('Beta');
        await saveDialogThenConfiguration(element);
        const saved = savedQuestions().find((q) => q.type === 'custom');
        expect(saved.fieldToApplyTo).toBe('Zz_Pick__c');
        expect(saved.picklistValues).toEqual([]);
        expect(saved.valuesFlat).toBe('');
    });

    it('drops an old saved copy of the values when a picklist question is edited', async () => {
        const stale = [{
            id: 0, type: 'custom', questionLabel: 'Old', questionType: 'Picklist', fieldToApplyTo: 'Zz_Pick__c', isRequired: false,
            isMappedPicklist: true, picklistValues: [{ label: 'Retired', value: 'Retired' }], valuesFlat: 'Retired'
        }];
        const element = await render(stale);
        element.shadowRoot.querySelector('lightning-button-icon[data-id="0"][icon-name="utility:edit"]')?.click();
        if (!element.shadowRoot.querySelector('.slds-modal')) {
            const edit = Array.from(element.shadowRoot.querySelectorAll('lightning-button-icon')).find((b) => b.dataset.id === '0' && /edit/i.test(b.iconName || b.alternativeText || ''));
            edit.click();
        }
        await flushPromises();
        await saveDialogThenConfiguration(element);
        const saved = savedQuestions().find((q) => q.type === 'custom');
        expect(saved.picklistValues).toEqual([]);
        expect(saved.valuesFlat).toBe('');
    });
});
