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

// The names below are deliberately NOT the real field names. If the manager still held its own copy of the
// mapping, the saved questions would carry the real names and these tests would fail.
const CATALOG = {
    questions: [
        { name: 'Title', defaultLabel: 'Catalog Title Label', targetField: 'Catalog_Title__c', isAlias: false, isComposite: false },
        { name: 'Phone', defaultLabel: 'Catalog Phone Label', targetField: 'Catalog_Phone__c', isAlias: false, isComposite: false },
        { name: 'First Name', defaultLabel: 'First Name', targetField: 'Catalog_First__c', isAlias: false, isComposite: false },
        { name: 'Last Name', defaultLabel: 'Last Name', targetField: 'Catalog_Last__c', isAlias: false, isComposite: false }
    ],
    filters: [{ controllerField: 'Citizen_Types_To_Display__c', targetField: 'Catalog_Filter__c', storesAnswer: true }]
};

function recordWith(fieldValues) {
    const fields = {};
    Object.keys(fieldValues).forEach((name) => {
        fields[name] = { value: fieldValues[name] };
    });
    return { id: '001000000000001AAA', apiName: 'RFI_Controller__c', fields };
}

const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

async function render() {
    const element = createElement('c-rfi-unified-question-manager', { is: RfiUnifiedQuestionManager });
    element.recordId = '001000000000001AAA';
    document.body.appendChild(element);
    await flushPromises();
    return element;
}

function clickSave(element) {
    const save = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find((b) => b.label === 'Save Configuration');
    save.click();
    return flushPromises();
}

function savedQuestions() {
    expect(updateRecord).toHaveBeenCalledTimes(1);
    const fields = updateRecord.mock.calls[0][0].fields;
    return JSON.parse(fields.Unified_Questions__c);
}

describe('c-rfi-unified-question-manager uses the question catalog from Apex', () => {
    beforeEach(() => {
        updateRecord.mockClear();
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('builds migrated questions with the catalog field names and labels', async () => {
        const element = await render();
        getQuestionCatalog.emit(CATALOG);
        getRecord.emit(recordWith({ Unified_Questions__c: null, Fields_to_Display__c: 'Title;Phone', Fields_to_Display_Order__c: 'Title;Phone', Required_Fields__c: null }));
        await flushPromises();
        await clickSave(element);
        const questions = savedQuestions();
        const byName = {};
        questions.forEach((q) => {
            byName[q.fieldName] = q;
        });
        expect(byName.Title.fieldInteractionAPIName).toBe('Catalog_Title__c');
        expect(byName.Title.questionLabel).toBe('Catalog Title Label');
        expect(byName.Phone.fieldInteractionAPIName).toBe('Catalog_Phone__c');
        expect(byName['First Name'].fieldInteractionAPIName).toBe('Catalog_First__c');
        expect(byName['Last Name'].fieldInteractionAPIName).toBe('Catalog_Last__c');
    });

    it('waits for the catalog instead of saving questions with empty field names', async () => {
        const element = await render();
        getRecord.emit(recordWith({ Unified_Questions__c: null, Fields_to_Display__c: 'Title', Fields_to_Display_Order__c: 'Title', Required_Fields__c: null }));
        await flushPromises();
        // Nothing is built yet, so there is nothing to save
        expect(element.shadowRoot.querySelectorAll('[data-id]').length).toBe(0);
        getQuestionCatalog.emit(CATALOG);
        await flushPromises();
        await clickSave(element);
        const questions = savedQuestions();
        expect(questions.length).toBeGreaterThan(0);
        questions.forEach((q) => {
            expect(q.fieldInteractionAPIName).toBeTruthy();
        });
    });

    it('does not rewrite the field names of questions that are already saved', async () => {
        const element = await render();
        getQuestionCatalog.emit(CATALOG);
        const saved = [{ id: 0, type: 'preconfigured', fieldName: 'Title', questionLabel: 'My Title', fieldInteractionAPIName: 'Stored_By_Admin__c', isRequired: false }];
        getRecord.emit(recordWith({ Unified_Questions__c: JSON.stringify(saved), Fields_to_Display__c: 'Title', Fields_to_Display_Order__c: 'Title', Required_Fields__c: null }));
        await flushPromises();
        await clickSave(element);
        const questions = savedQuestions();
        expect(questions[0].fieldInteractionAPIName).toBe('Stored_By_Admin__c');
        expect(questions[0].questionLabel).toBe('My Title');
    });

    it('stores the catalog field name on a program filter question', async () => {
        const element = await render();
        getQuestionCatalog.emit(CATALOG);
        const saved = [{ id: 0, type: 'preconfigured', fieldName: 'First Name', questionLabel: 'First Name', fieldInteractionAPIName: 'Catalog_First__c', isRequired: true }];
        getRecord.emit(recordWith({ Unified_Questions__c: JSON.stringify(saved), Fields_to_Display__c: 'First Name', Fields_to_Display_Order__c: 'First Name', Required_Fields__c: null }));
        await flushPromises();
        Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find((b) => b.label === 'Add Program Filter Question').click();
        await flushPromises();
        const filterBox = Array.from(element.shadowRoot.querySelectorAll('lightning-combobox')).find((c) => c.label === 'Filter Field');
        filterBox.dispatchEvent(new CustomEvent('change', { detail: { value: 'Citizen_Types_To_Display__c' } }));
        await flushPromises();
        Array.from(element.shadowRoot.querySelectorAll('button')).find((b) => b.textContent.trim() === 'Save').click();
        await flushPromises();
        await clickSave(element);
        const filter = savedQuestions().find((q) => q.type === 'filter');
        expect(filter.filterControllerField).toBe('Citizen_Types_To_Display__c');
        expect(filter.filterInteractionAPIName).toBe('Catalog_Filter__c');
    });
});
