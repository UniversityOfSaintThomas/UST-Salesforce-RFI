import { createElement } from 'lwc';
import RfiUnifiedQuestionManager from 'c/rfiUnifiedQuestionManager';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import getQuestionCatalog from '@salesforce/apex/rfiFormController.getQuestionCatalog';

jest.mock(
    '@salesforce/apex/rfiFormController.getQuestionCatalog',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true }
);

// A real saved list copied from eda-staging on 2026-11-02 (configuration only). It is the OLD shape: every question
// carries the display flags the manager used to save, and no question has a key or a version. Keep this fixture.
const SAVED_BEFORE_KEYS_EXISTED = "[{\"id\":0,\"type\":\"preconfigured\",\"fieldName\":\"First Name\",\"questionLabel\":\"First Name\",\"fieldInteractionAPIName\":\"First_Name__c\",\"isRequired\":true,\"typePreconfigured\":true,\"typeCustom\":false,\"typeFilter\":false,\"isPicklist\":false,\"isTextBox\":false,\"isTextarea\":false,\"isEmail\":false,\"isStaticContent\":false,\"isFirst\":true,\"isLast\":false},{\"id\":1,\"type\":\"preconfigured\",\"fieldName\":\"Last Name\",\"questionLabel\":\"Last Name\",\"fieldInteractionAPIName\":\"Last_Name__c\",\"isRequired\":true,\"typePreconfigured\":true,\"typeCustom\":false,\"typeFilter\":false,\"isPicklist\":false,\"isTextBox\":false,\"isTextarea\":false,\"isEmail\":false,\"isStaticContent\":false,\"isFirst\":false,\"isLast\":false},{\"id\":2,\"type\":\"preconfigured\",\"fieldName\":\"Email\",\"questionLabel\":\"Email\",\"fieldInteractionAPIName\":\"Email__c\",\"isRequired\":true,\"typePreconfigured\":true,\"typeCustom\":false,\"typeFilter\":false,\"isPicklist\":false,\"isTextBox\":false,\"isTextarea\":false,\"isEmail\":false,\"isStaticContent\":false,\"isFirst\":false,\"isLast\":false},{\"id\":3,\"type\":\"preconfigured\",\"fieldName\":\"Academic Interest\",\"questionLabel\":\"Academic Interest\",\"fieldInteractionAPIName\":\"Major_Program_1__c\",\"isRequired\":false,\"typePreconfigured\":true,\"typeCustom\":false,\"typeFilter\":false,\"isPicklist\":false,\"isTextBox\":false,\"isTextarea\":false,\"isEmail\":false,\"isStaticContent\":false,\"isFirst\":false,\"isLast\":false},{\"type\":\"custom\",\"questionLabel\":\"What Type of Athlete are you?\",\"questionType\":\"Picklist\",\"fieldToApplyTo\":\"Athlete_Type_1__c\",\"isRequired\":true,\"picklistValues\":[{\"label\":\"Blue Chip/Coach Priority\",\"value\":\"Blue Chip/Coach Priority\"},{\"label\":\"Athlete Commit\",\"value\":\"Athlete Commit\"},{\"label\":\"Stacked Athletic Scholar\",\"value\":\"Stacked Athletic Scholar\"},{\"label\":\"Full Athletic Scholar\",\"value\":\"Full Athletic Scholar\"},{\"label\":\"Athletic Revision\",\"value\":\"Athletic Revision\"},{\"label\":\"Regular\",\"value\":\"Regular\"}],\"valuesFlat\":\"Blue Chip/Coach Priority;Athlete Commit;Stacked Athletic Scholar;Full Athletic Scholar;Athletic Revision;Regular\",\"assistiveText\":\"Help text for athlete\",\"isMappedPicklist\":true,\"id\":4,\"typePreconfigured\":false,\"typeCustom\":true,\"typeFilter\":false,\"isPicklist\":true,\"isTextBox\":false,\"isTextarea\":false,\"isEmail\":false,\"isStaticContent\":false,\"isFirst\":false,\"isLast\":false},{\"type\":\"filter\",\"questionLabel\":\"School / College\",\"filterControllerField\":\"School_College_To_Display__c\",\"filterInteractionAPIName\":\"St_Thomas_College_School__c\",\"isFilterSchoolList\":true,\"filterSelectedValues\":[\"School of Nursing\",\"College of Arts and Sciences\"],\"isRequired\":true,\"id\":5,\"typePreconfigured\":false,\"typeCustom\":false,\"typeFilter\":true,\"isPicklist\":false,\"isTextBox\":false,\"isTextarea\":false,\"isEmail\":false,\"isStaticContent\":false,\"isFirst\":false,\"isLast\":true}]";

const DERIVED = ['typePreconfigured', 'typeCustom', 'typeFilter', 'isPicklist', 'isTextBox', 'isTextarea', 'isEmail', 'isCheckbox', 'isDate', 'isStaticContent', 'isFirst', 'isLast'];
const CATALOG = { questions: [{ name: 'First Name', defaultLabel: 'First Name', targetField: 'First_Name__c', isAlias: false, isComposite: false }], filters: [] };
const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

async function render(savedText) {
    const element = createElement('c-rfi-unified-question-manager', { is: RfiUnifiedQuestionManager });
    element.recordId = '001000000000001AAA';
    document.body.appendChild(element);
    await flushPromises();
    getQuestionCatalog.emit(CATALOG);
    getRecord.emit({
        id: '001000000000001AAA', apiName: 'RFI_Controller__c',
        fields: {
            Unified_Questions__c: { value: savedText },
            Fields_to_Display__c: { value: 'First Name' }, Fields_to_Display_Order__c: { value: 'First Name' }, Required_Fields__c: { value: null }
        }
    });
    await flushPromises();
    return element;
}

function button(element, label) {
    return Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find((b) => b.label === label);
}

async function save(element) {
    button(element, 'Save Configuration').click();
    await flushPromises();
    expect(updateRecord).toHaveBeenCalledTimes(1);
    return JSON.parse(updateRecord.mock.calls[0][0].fields.Unified_Questions__c);
}

describe('c-rfi-unified-question-manager saved question format', () => {
    beforeEach(() => {
        updateRecord.mockClear();
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('gives every question of an old list a key and a version when it is saved again', async () => {
        const element = await render(SAVED_BEFORE_KEYS_EXISTED);
        const before = JSON.parse(SAVED_BEFORE_KEYS_EXISTED);
        const saved = await save(element);
        expect(saved.length).toBe(before.length);
        const keys = saved.map((q) => q.key);
        keys.forEach((key) => expect(key).toMatch(/^q[0-9a-z]+$/));
        expect(new Set(keys).size).toBe(saved.length);
        saved.forEach((q) => expect(q.schemaVersion).toBe(1));
    });

    it('does not save the display flags, and keeps everything the admin configured', async () => {
        const element = await render(SAVED_BEFORE_KEYS_EXISTED);
        const before = JSON.parse(SAVED_BEFORE_KEYS_EXISTED);
        const saved = await save(element);
        saved.forEach((q) => DERIVED.forEach((flag) => expect(q).not.toHaveProperty(flag)));
        saved.forEach((q, index) => {
            const original = before[index];
            Object.keys(original).filter((k) => !DERIVED.includes(k) && k !== 'id').forEach((k) => {
                expect(q[k]).toEqual(original[k]);
            });
        });
    });

    it('keeps a key it has never heard of, so data from a newer version is not damaged', async () => {
        const newer = [
            { id: 0, type: 'preconfigured', fieldName: 'First Name', questionLabel: 'First Name', fieldInteractionAPIName: 'First_Name__c', isRequired: true,
              key: 'qkept', schemaVersion: 1, visibleWhen: { key: 'qother', equals: ['International'] }, somethingNew: [1, 2] }
        ];
        const element = await render(JSON.stringify(newer));
        const saved = (await save(element))[0];
        expect(saved.visibleWhen).toEqual({ key: 'qother', equals: ['International'] });
        expect(saved.somethingNew).toEqual([1, 2]);
        expect(saved.key).toBe('qkept');
    });

    it('never lowers the version of a question a newer version saved', async () => {
        const newer = [{ id: 0, type: 'preconfigured', fieldName: 'First Name', questionLabel: 'First Name', fieldInteractionAPIName: 'First_Name__c', schemaVersion: 7, key: 'qnew' }];
        const element = await render(JSON.stringify(newer));
        expect((await save(element))[0].schemaVersion).toBe(7);
    });

    it('keeps a question\'s key when the questions are reordered or one is deleted', async () => {
        const list = [
            { id: 0, type: 'preconfigured', fieldName: 'First Name', questionLabel: 'First Name', fieldInteractionAPIName: 'First_Name__c', key: 'qaaa' },
            { id: 1, type: 'preconfigured', fieldName: 'Last Name', questionLabel: 'Last Name', fieldInteractionAPIName: 'Last_Name__c', key: 'qbbb' },
            { id: 2, type: 'custom', questionLabel: 'Campus', questionType: 'Text box', fieldToApplyTo: 'Employer__c', key: 'qccc' }
        ];
        const element = await render(JSON.stringify(list));
        const moveDown = Array.from(element.shadowRoot.querySelectorAll('lightning-button-icon')).find((b) => b.dataset.id === '0' && b.title === 'Move Down');
        moveDown.click();
        await flushPromises();
        const saved = await save(element);
        expect(saved.map((q) => q.key)).toEqual(['qbbb', 'qaaa', 'qccc']);
        expect(saved.map((q) => q.id)).toEqual([0, 1, 2]);
    });

    it('replaces a repeated key on the later question, so a key always identifies one question', async () => {
        const list = [
            { id: 0, type: 'preconfigured', fieldName: 'First Name', questionLabel: 'First Name', fieldInteractionAPIName: 'First_Name__c', key: 'qsame' },
            { id: 1, type: 'preconfigured', fieldName: 'Last Name', questionLabel: 'Last Name', fieldInteractionAPIName: 'Last_Name__c', key: 'qsame' }
        ];
        const element = await render(JSON.stringify(list));
        const saved = await save(element);
        expect(saved[0].key).toBe('qsame');
        expect(saved[1].key).not.toBe('qsame');
        expect(saved[1].key).toBeTruthy();
    });

    it('reads a list held inside an object, and ignores entries that are not questions', async () => {
        const wrapped = { version: 2, questions: [
            { id: 0, type: 'preconfigured', fieldName: 'First Name', questionLabel: 'First Name', fieldInteractionAPIName: 'First_Name__c' }, 'oops', null, 7
        ] };
        const element = await render(JSON.stringify(wrapped));
        const saved = await save(element);
        expect(saved.length).toBe(1);
        expect(saved[0].fieldName).toBe('First Name');
    });

    it('does not break when the saved text cannot be read, so an admin can still open it and save', async () => {
        const element = await render('{broken');
        // Rebuilt from the older settings instead of failing; nothing is written until the admin saves
        expect(updateRecord).not.toHaveBeenCalled();
        const saved = await save(element);
        expect(Array.isArray(saved)).toBe(true);
        saved.forEach((q) => expect(q.key).toBeTruthy());
    });
});
