import { createElement } from 'lwc';
import RfiForm from 'c/rfiForm';
import getRFIForm from '@salesforce/apex/rfiFormController.getRFIForm';
import { EMAIL_ERROR_MESSAGE, EMAIL_PATTERN, PHONE_ERROR_MESSAGE, PHONE_PATTERN } from 'c/rfiFormUtils';

jest.mock(
    '@salesforce/apex/rfiFormController.getRFIForm',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true }
);
jest.mock('@salesforce/apex/rfiFormController.submitRfiForm', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/rfiFormController.getPrograms', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/ReusableLookupController.fetchRecords', () => ({ default: jest.fn() }), { virtual: true });

const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

function field(label, apiName, extra = {}) {
    return { fieldLabel: label, fieldInteractionAPIName: apiName, ...extra };
}

let element;

async function renderForm(rfiFieldList) {
    element = createElement('c-rfi-form', { is: RfiForm });
    element.rfiControllerName = 'RFI Controller 0001';
    document.body.appendChild(element);
    getRFIForm.emit(
        JSON.parse(
            JSON.stringify({
                interaction: {},
                rfiFieldList,
                countryOptions: [],
                stateOptions: [],
                filterValues: {},
                programValues: [],
                redirectAfterSubmission: false
            })
        )
    );
    await flushPromises();
}

function byLabel(tag, label) {
    return Array.from(element.shadowRoot.querySelectorAll(tag)).find((el) => el.label === label);
}

describe('c-rfi-form help text', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('shows the help text as field-level help on each kind of question', async () => {
        await renderForm([
            field('Favorite Color', 'Title__c', { helpText: 'text help' }),
            field('Work Email', 'Email__c', { isEmail: true, helpText: 'email help' }),
            field('Best Phone', 'Phone__c', { isTel: true, helpText: 'phone help' }),
            field('Tell us more', 'Description__c', { isTextarea: true, helpText: 'textarea help' }),
            field('Campus', 'Campus__c', {
                isPicklist: true,
                picklistValues: [{ label: 'Main', value: 'Main' }],
                helpText: 'picklist help'
            }),
            field('Send me mail', 'Mailed__c', { isCheckbox: true, helpText: 'checkbox help' })
        ]);

        expect(byLabel('lightning-input', 'Favorite Color').fieldLevelHelp).toBe('text help');
        expect(byLabel('lightning-input', 'Work Email').fieldLevelHelp).toBe('email help');
        expect(byLabel('lightning-input', 'Best Phone').fieldLevelHelp).toBe('phone help');
        expect(byLabel('lightning-textarea', 'Tell us more').fieldLevelHelp).toBe('textarea help');
        expect(byLabel('lightning-combobox', 'Campus').fieldLevelHelp).toBe('picklist help');
        expect(byLabel('lightning-input', 'Send me mail').fieldLevelHelp).toBe('checkbox help');
    });

    it('shows no help icon when the question has no help text', async () => {
        await renderForm([field('Favorite Color', 'Title__c')]);

        expect(byLabel('lightning-input', 'Favorite Color').fieldLevelHelp).toBeUndefined();
    });

    it('gives phone and email questions a format pattern and an error message, and leaves other questions alone', async () => {
        await renderForm([
            field('Work Email', 'Email__c', { isEmail: true }),
            field('Best Phone', 'Phone__c', { isTel: true }),
            field('Favorite Color', 'Title__c')
        ]);

        const email = byLabel('lightning-input', 'Work Email');
        const phone = byLabel('lightning-input', 'Best Phone');
        expect(email.pattern).toBe(EMAIL_PATTERN);
        expect(email.messageWhenPatternMismatch).toBe(EMAIL_ERROR_MESSAGE);
        expect(phone.pattern).toBe(PHONE_PATTERN);
        expect(phone.messageWhenPatternMismatch).toBe(PHONE_ERROR_MESSAGE);
        expect(byLabel('lightning-input', 'Favorite Color').pattern).toBeUndefined();
    });
});
