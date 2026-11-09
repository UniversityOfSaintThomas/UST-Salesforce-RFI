import { createElement } from 'lwc';
import RfiUnifiedQuestionManager from 'c/rfiUnifiedQuestionManager';
import { getRecord } from 'lightning/uiRecordApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import getQuestionCatalog from '@salesforce/apex/rfiFormController.getQuestionCatalog';

jest.mock(
    '@salesforce/apex/rfiFormController.getQuestionCatalog',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true }
);

// What the Fields_to_Display__c picklist really holds: the old split address questions, a retired question, and no plain "Address"
const PICKLIST = [
    'Academic Interest', 'Address 1', 'Address 2', 'Address 3', 'Birthdate', 'City', 'Country', 'Email', 'Phone',
    'State', 'Title', 'When do you plan to start school', 'Zipcode'
].map((name) => ({ label: name, value: name }));

const CATALOG = {
    questions: [{ name: 'Title', defaultLabel: 'Title', targetField: 'Contact_Title__c', isAlias: false, isComposite: false }],
    filters: [],
    notOffered: ['Address 1', 'Address 2', 'Address 3', 'City', 'Country', 'State', 'Zipcode', 'When do you plan to start school']
};

const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

function recordWith(fieldValues) {
    const fields = {};
    Object.keys(fieldValues).forEach((name) => {
        fields[name] = { value: fieldValues[name] };
    });
    return { id: '001000000000001AAA', apiName: 'RFI_Controller__c', fields };
}

async function openAddQuestion({ saved, catalog = CATALOG } = {}) {
    const element = createElement('c-rfi-unified-question-manager', { is: RfiUnifiedQuestionManager });
    element.recordId = '001000000000001AAA';
    document.body.appendChild(element);
    await flushPromises();
    if (catalog) {
        getQuestionCatalog.emit(catalog);
    }
    getPicklistValues.emit({ values: PICKLIST });
    getRecord.emit(recordWith({
        Unified_Questions__c: saved ? JSON.stringify(saved) : null,
        Fields_to_Display__c: 'Title',
        Fields_to_Display_Order__c: 'Title',
        Required_Fields__c: null
    }));
    await flushPromises();
    Array.from(element.shadowRoot.querySelectorAll('lightning-button'))
        .find((b) => b.label === 'Add Pre-configured Question').click();
    await flushPromises();
    return element;
}

function offered(element) {
    const combobox = element.shadowRoot.querySelector('lightning-combobox');
    return combobox.options.map((option) => option.value).filter((value) => value !== '');
}

describe('c-rfi-unified-question-manager pre-configured questions that can be added', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('offers one Address instead of the old split address questions, and drops retired questions', async () => {
        const element = await openAddQuestion();
        const values = offered(element);
        expect(values).toContain('Address');
        ['Address 1', 'Address 2', 'Address 3', 'City', 'State', 'Zipcode', 'Country', 'When do you plan to start school']
            .forEach((old) => expect(values).not.toContain(old));
    });

    it('keeps the other questions that are not on the form yet, in alphabetical order', async () => {
        const element = await openAddQuestion();
        expect(offered(element)).toEqual(['Academic Interest', 'Address', 'Birthdate', 'Email', 'Phone']);
    });

    it('still hides the split address questions before the catalog arrives', async () => {
        const element = await openAddQuestion({ catalog: null });
        const values = offered(element);
        expect(values).toContain('Address');
        expect(values).not.toContain('Address 1');
        expect(values).not.toContain('City');
    });

    it('does not offer Address again when the form already has it', async () => {
        const saved = [{ id: 0, type: 'preconfigured', fieldName: 'Address', questionLabel: 'Address', fieldInteractionAPIName: 'Mailing_Street__c', isRequired: false }];
        const element = await openAddQuestion({ saved });
        expect(offered(element)).not.toContain('Address');
    });
});
