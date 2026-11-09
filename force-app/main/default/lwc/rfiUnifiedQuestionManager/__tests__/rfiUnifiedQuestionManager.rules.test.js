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

const INTERACTION_INFO = {
    defaultRecordTypeId: '012000000000000AAA',
    fields: {
        Citizenship__c: field('Citizenship__c', 'Citizenship', 'Picklist'),
        Email__c: field('Email__c', 'Email', 'Email'),
        Employer__c: field('Employer__c', 'Employer', 'String'),
        Mailed_Program_Information_Requested__c: field('Mailed_Program_Information_Requested__c', 'Mailed', 'Boolean'),
        Intended_Start_Term__c: field('Intended_Start_Term__c', 'Term', 'Reference'),
        Heard_About_Us__c: field('Heard_About_Us__c', 'Heard', 'MultiselectPicklist')
    }
};
const LIVE_VALUES = {
    Citizenship__c: { values: [{ label: 'US Citizen', value: 'US Citizen' }, { label: 'International', value: 'International' }, { label: 'Other', value: 'Other' }] }
};
const CATALOG = { questions: [{ name: 'First Name', defaultLabel: 'First Name', targetField: 'First_Name__c', isAlias: false, isComposite: false }], filters: [] };

const FIRST = { id: 0, type: 'preconfigured', fieldName: 'First Name', questionLabel: 'First Name', fieldInteractionAPIName: 'First_Name__c', isRequired: true, key: 'qfirst', schemaVersion: 1 };
const CITIZENSHIP = { id: 1, type: 'preconfigured', fieldName: 'Citizenship', questionLabel: 'Citizenship', fieldInteractionAPIName: 'Citizenship__c', key: 'qcitizen', schemaVersion: 1 };
const EMAIL = { id: 2, type: 'preconfigured', fieldName: 'Email', questionLabel: 'Email', fieldInteractionAPIName: 'Email__c', key: 'qemail', schemaVersion: 1 };
const TICK = { id: 3, type: 'custom', questionLabel: 'Send me mail', questionType: 'Checkbox', fieldToApplyTo: 'Mailed_Program_Information_Requested__c', key: 'qtick', schemaVersion: 1 };
const FILTER = { id: 4, type: 'filter', questionLabel: 'Degree', filterControllerField: 'Degree_Types_To_Display__c', filterInteractionAPIName: 'Degree_Type__c', filterSelectedValues: ['Bachelor'], key: 'qfilter', schemaVersion: 1 };
const VISA = (rule) => ({ id: 5, type: 'custom', questionLabel: 'Visa status', questionType: 'Text box', fieldToApplyTo: 'Employer__c', key: 'qvisa', schemaVersion: 1, ...(rule ? { visibleWhen: rule } : {}) });

const BASE = [FIRST, CITIZENSHIP, EMAIL, TICK, FILTER];

const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

let toasts;

async function render(savedQuestions) {
    const element = createElement('c-rfi-unified-question-manager', { is: RfiUnifiedQuestionManager });
    element.recordId = '001000000000001AAA';
    toasts = [];
    element.addEventListener('lightning__showtoast', (event) => toasts.push(event.detail));
    document.body.appendChild(element);
    await flushPromises();
    getQuestionCatalog.emit(CATALOG);
    getObjectInfo.emit(INTERACTION_INFO);
    getPicklistValuesByRecordType.emit({ picklistFieldValues: LIVE_VALUES });
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

const root = (element) => element.shadowRoot;
const button = (element, label) => Array.from(root(element).querySelectorAll('lightning-button')).find((b) => b.label === label);
const combobox = (element, label) => Array.from(root(element).querySelectorAll('lightning-combobox')).find((c) => c.label === label);
const ruleEditor = (element) => root(element).querySelector('[data-id="rule-editor"]');
const rowButton = (element, title, id) => Array.from(root(element).querySelectorAll('lightning-button-icon')).find((b) => b.title === title && b.dataset.id === String(id));

async function choose(element, label, value) {
    const box = combobox(element, label);
    box.value = value;
    box.dispatchEvent(new CustomEvent('change', { detail: { value } }));
    await flushPromises();
}

async function pickAnswers(element, values) {
    const group = root(element).querySelector('lightning-checkbox-group');
    group.value = values;
    group.dispatchEvent(new CustomEvent('change', { detail: { value: values } }));
    await flushPromises();
}

async function startCustomQuestion(element, label = 'Visa status') {
    button(element, 'Add Custom Question').click();
    await flushPromises();
    const labelInput = Array.from(root(element).querySelectorAll('lightning-input')).find((i) => i.label === 'Question Label');
    labelInput.value = label;
    labelInput.dispatchEvent(new CustomEvent('change'));
    await choose(element, 'Question Type', 'Text box');
    await choose(element, 'Interaction Field API Name', 'Employer__c');
}

function makeEverythingValid(element) {
    root(element).querySelectorAll('lightning-input, lightning-combobox, lightning-textarea').forEach((el) => {
        Object.defineProperty(el, 'checkValidity', { value: () => true, configurable: true });
        Object.defineProperty(el, 'reportValidity', { value: () => true, configurable: true });
    });
}

async function saveDialog(element) {
    makeEverythingValid(element);
    Array.from(root(element).querySelectorAll('button')).find((b) => b.textContent.trim() === 'Save').click();
    await flushPromises();
}

async function saveConfiguration(element) {
    button(element, 'Save Configuration').click();
    await flushPromises();
}

const saved = () => JSON.parse(updateRecord.mock.calls[0][0].fields.Unified_Questions__c);

describe('c-rfi-unified-question-manager "Show only when" rules', () => {
    beforeEach(() => {
        updateRecord.mockClear();
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('offers only the earlier questions that are a choice from a list or a tick box', async () => {
        const element = await render(BASE);
        await startCustomQuestion(element);
        const offered = combobox(element, 'Show this question only when the answer to').options.map((o) => o.label);
        expect(offered).toEqual(['Always show this question', 'Citizenship', 'Send me mail']);
    });

    it('does not offer a rule on the first question, a name question, or a program filter', async () => {
        const element = await render(BASE);
        rowButton(element, 'Edit', 0).click();
        await flushPromises();
        expect(ruleEditor(element)).toBeNull();
        Array.from(root(element).querySelectorAll('button')).find((b) => b.textContent.trim() === 'Cancel').click();
        await flushPromises();
        rowButton(element, 'Edit', 4).click();
        await flushPromises();
        expect(ruleEditor(element)).toBeNull();
    });

    it('offers a rule on a built-in question that is not a name question', async () => {
        const element = await render(BASE);
        rowButton(element, 'Edit', 2).click();
        await flushPromises();
        expect(ruleEditor(element)).not.toBeNull();
        const offered = combobox(element, 'Show this question only when the answer to').options.map((o) => o.label);
        expect(offered).toEqual(['Always show this question', 'Citizenship']);
    });

    it('says so when there is nothing above to depend on', async () => {
        const element = await render([FIRST]);
        await startCustomQuestion(element);
        expect(root(element).querySelector('[data-id="rule-no-parents"]')).not.toBeNull();
        expect(root(element).querySelector('lightning-checkbox-group')).toBeNull();
    });

    it('offers the live answers of a picklist and Checked / Not checked for a tick box', async () => {
        const element = await render(BASE);
        await startCustomQuestion(element);
        await choose(element, 'Show this question only when the answer to', 'qcitizen');
        expect(root(element).querySelector('lightning-checkbox-group').options.map((o) => o.value)).toEqual(['US Citizen', 'International', 'Other']);
        await choose(element, 'Show this question only when the answer to', 'qtick');
        expect(root(element).querySelector('lightning-checkbox-group').options.map((o) => o.value)).toEqual(['true', 'false']);
    });

    it('saves a rule that names the earlier question by its key', async () => {
        const element = await render(BASE);
        await startCustomQuestion(element);
        await choose(element, 'Show this question only when the answer to', 'qcitizen');
        await pickAnswers(element, ['International', 'Other']);
        await saveDialog(element);
        await saveConfiguration(element);
        const visa = saved().find((q) => q.questionLabel === 'Visa status');
        expect(visa.visibleWhen).toEqual({ key: 'qcitizen', equals: ['International', 'Other'] });
        expect(saved().find((q) => q.key === 'qcitizen').visibleWhen).toBeUndefined();
    });

    it('saves a rule on a tick box', async () => {
        const element = await render(BASE);
        await startCustomQuestion(element);
        await choose(element, 'Show this question only when the answer to', 'qtick');
        await pickAnswers(element, ['true']);
        await saveDialog(element);
        await saveConfiguration(element);
        expect(saved().find((q) => q.questionLabel === 'Visa status').visibleWhen).toEqual({ key: 'qtick', equals: ['true'] });
    });

    it('refuses a rule with no answer chosen', async () => {
        const element = await render(BASE);
        await startCustomQuestion(element);
        await choose(element, 'Show this question only when the answer to', 'qcitizen');
        await saveDialog(element);
        expect(toasts.some((t) => t.variant === 'warning' && /at least one answer/.test(t.message))).toBe(true);
        expect(root(element).querySelector('[data-id="rule-editor"]')).not.toBeNull();
        expect(root(element).querySelectorAll('tbody tr')).toHaveLength(BASE.length);
    });

    it('saves no rule at all when "Always show" is left chosen', async () => {
        const element = await render(BASE);
        await startCustomQuestion(element);
        await saveDialog(element);
        await saveConfiguration(element);
        expect(saved().find((q) => q.questionLabel === 'Visa status').visibleWhen).toBeUndefined();
    });

    it('describes the rule in the list in words', async () => {
        const element = await render([...BASE, VISA({ key: 'qcitizen', equals: ['International', 'Other'] })]);
        const text = root(element).querySelector('[data-id="rule-text"]');
        expect(text.textContent.trim()).toBe('Shown only when "Citizenship" is International or Other');
    });

    it('opens an existing rule with the earlier question and answers filled in', async () => {
        const element = await render([...BASE, VISA({ key: 'qcitizen', equals: ['Other'] })]);
        rowButton(element, 'Edit', 5).click();
        await flushPromises();
        expect(combobox(element, 'Show this question only when the answer to').value).toBe('qcitizen');
        expect(root(element).querySelector('lightning-checkbox-group').value).toEqual(['Other']);
    });

    it('removes the rule when "Always show" is chosen', async () => {
        const element = await render([...BASE, VISA({ key: 'qcitizen', equals: ['Other'] })]);
        rowButton(element, 'Edit', 5).click();
        await flushPromises();
        await choose(element, 'Show this question only when the answer to', 'none');
        await saveDialog(element);
        await saveConfiguration(element);
        expect(saved().find((q) => q.key === 'qvisa').visibleWhen).toBeUndefined();
    });

    it('starts the answers again when another earlier question is chosen', async () => {
        const element = await render([...BASE, VISA({ key: 'qcitizen', equals: ['Other'] })]);
        rowButton(element, 'Edit', 5).click();
        await flushPromises();
        await choose(element, 'Show this question only when the answer to', 'qtick');
        expect(root(element).querySelector('lightning-checkbox-group').value).toEqual([]);
    });

    it('keeps the answers when the same earlier question is chosen again', async () => {
        const element = await render([...BASE, VISA({ key: 'qcitizen', equals: ['Other'] })]);
        rowButton(element, 'Edit', 5).click();
        await flushPromises();
        await choose(element, 'Show this question only when the answer to', 'qcitizen');
        expect(root(element).querySelector('lightning-checkbox-group').value).toEqual(['Other']);
    });

    it('saves a rule it was given unchanged, including parts it does not know', async () => {
        const rule = { key: 'qcitizen', equals: ['International'], operator: 'in' };
        const element = await render([...BASE, VISA(rule)]);
        await saveConfiguration(element);
        expect(saved().find((q) => q.key === 'qvisa').visibleWhen).toEqual(rule);
    });

    it('keeps the parts of a rule it does not know when only the answers are edited', async () => {
        const element = await render([...BASE, VISA({ key: 'qcitizen', equals: ['Other'], operator: 'in' })]);
        rowButton(element, 'Edit', 5).click();
        await flushPromises();
        await pickAnswers(element, ['International']);
        await saveDialog(element);
        await saveConfiguration(element);
        expect(saved().find((q) => q.key === 'qvisa').visibleWhen).toEqual({ key: 'qcitizen', equals: ['International'], operator: 'in' });
    });

    it('still shows the rule controls when the rule points at a question that is gone and nothing else qualifies', async () => {
        const element = await render([FIRST, { ...VISA({ key: 'qgone', equals: ['Other'] }), id: 1 }]);
        rowButton(element, 'Edit', 1).click();
        await flushPromises();
        const box = combobox(element, 'Show this question only when the answer to');
        expect(box).toBeTruthy();
        expect(root(element).querySelector('[data-id="rule-no-parents"]')).toBeNull();
        await choose(element, 'Show this question only when the answer to', 'none');
        await saveDialog(element);
        await saveConfiguration(element);
        expect(updateRecord).toHaveBeenCalledTimes(1);
    });

    it('does not offer a question that has a rule of its own as an earlier question (only one level)', async () => {
        const dependentTick = { ...TICK, visibleWhen: { key: 'qcitizen', equals: ['Other'] } };
        const element = await render([FIRST, CITIZENSHIP, EMAIL, dependentTick, { ...FILTER, id: 4 }]);
        await startCustomQuestion(element);
        const offered = combobox(element, 'Show this question only when the answer to').options.map((o) => o.label);
        expect(offered).toEqual(['Always show this question', 'Citizenship']);
    });

    // ---- rules that stop working ----

    it('warns and refuses to save when the earlier question is removed', async () => {
        const element = await render([...BASE, VISA({ key: 'qcitizen', equals: ['Other'] })]);
        expect(root(element).querySelector('[data-id="rule-problems"]')).toBeNull();
        rowButton(element, 'Remove', 1).click();
        await flushPromises();
        const banner = root(element).querySelector('[data-id="rule-problems"]');
        expect(banner).not.toBeNull();
        expect(banner.textContent).toContain('"Visa status"');
        expect(banner.textContent).toContain('removed');
        await saveConfiguration(element);
        expect(updateRecord).not.toHaveBeenCalled();
        expect(toasts.some((t) => t.variant === 'error')).toBe(true);
    });

    it('warns when the dependent question is moved above the one it depends on', async () => {
        const list = [FIRST, CITIZENSHIP, { ...VISA({ key: 'qcitizen', equals: ['Other'] }), id: 2 }];
        const element = await render(list);
        rowButton(element, 'Move Up', 2).click();
        await flushPromises();
        expect(root(element).querySelector('[data-id="rule-problems"]').textContent).toContain('must come after');
        await saveConfiguration(element);
        expect(updateRecord).not.toHaveBeenCalled();
    });

    it('lets the admin fix a broken rule by removing it, and then saves', async () => {
        const element = await render([...BASE, VISA({ key: 'qgone', equals: ['Other'] })]);
        expect(root(element).querySelector('[data-id="rule-problems"]')).not.toBeNull();
        rowButton(element, 'Edit', 5).click();
        await flushPromises();
        const options = combobox(element, 'Show this question only when the answer to').options.map((o) => o.label);
        expect(options).toContain('An earlier question that can no longer be used');
        await choose(element, 'Show this question only when the answer to', 'none');
        await saveDialog(element);
        expect(root(element).querySelector('[data-id="rule-problems"]')).toBeNull();
        await saveConfiguration(element);
        expect(updateRecord).toHaveBeenCalledTimes(1);
        expect(saved().find((q) => q.key === 'qvisa').visibleWhen).toBeUndefined();
    });

    it('shows an answer that is no longer a choice, and warns about it', async () => {
        const element = await render([...BASE, VISA({ key: 'qcitizen', equals: ['Retired Answer'] })]);
        expect(root(element).querySelector('[data-id="rule-problems"]').textContent).toContain('Retired Answer');
        rowButton(element, 'Edit', 5).click();
        await flushPromises();
        const options = root(element).querySelector('lightning-checkbox-group').options.map((o) => o.label);
        expect(options).toContain('Retired Answer (no longer an answer)');
    });

    it('does not warn about a question list that has no rules', async () => {
        const element = await render(BASE);
        expect(root(element).querySelector('[data-id="rule-problems"]')).toBeNull();
        await saveConfiguration(element);
        expect(updateRecord).toHaveBeenCalledTimes(1);
    });

    it('never saves the description text it works out for the list', async () => {
        const element = await render([...BASE, VISA({ key: 'qcitizen', equals: ['Other'] })]);
        await saveConfiguration(element);
        expect(JSON.stringify(saved())).not.toContain('Shown only when');
        expect(saved().find((q) => q.key === 'qvisa').visibleWhenText).toBeUndefined();
    });
});
