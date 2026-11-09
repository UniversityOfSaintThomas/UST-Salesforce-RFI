import { createElement } from 'lwc';
import RfiForm from 'c/rfiForm';
import getRFIForm from '@salesforce/apex/rfiFormController.getRFIForm';
import submitRfiForm from '@salesforce/apex/rfiFormController.submitRfiForm';

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

const CONTROLLER_NAME = 'RFI Controller 0001';

function field(label, apiName, extra = {}) {
    return { fieldLabel: label, fieldInteractionAPIName: apiName, ...extra };
}

const CITIZENSHIP_OPTIONS = [
    { label: 'US Citizen', value: 'US Citizen' },
    { label: 'International', value: 'International' },
    { label: 'Other', value: 'Other' }
];

function picklistRule(extra = {}) {
    return { visibleWhenField: 'Citizenship__c', visibleWhenKind: 'picklist', visibleWhenValues: ['International', 'Other'], ...extra };
}

function buildForm(overrides = {}) {
    return {
        interaction: {},
        rfiFieldList: [
            field('First Name', 'First_Name__c', { isRequired: true }),
            field('Last Name', 'Last_Name__c', { isRequired: true }),
            field('Citizenship', 'Citizenship__c', { isPicklist: true, picklistValues: CITIZENSHIP_OPTIONS }),
            field('Visa status', 'Employer__c', picklistRule({ isRequired: true })),
            field('Visa country', 'Mailing_City__c', picklistRule({ isPicklist: true, picklistValues: [{ label: 'Canada', value: 'Canada' }, { label: 'Mexico', value: 'Mexico' }] })),
            field('Send me mail', 'Mailed_Program_Information_Requested__c', { isCheckbox: true }),
            field('Mail note', 'Title__c', { visibleWhenField: 'Mailed_Program_Information_Requested__c', visibleWhenKind: 'checkbox', visibleWhenValues: ['true'] }),
            field('No mail note', 'Department__c', { visibleWhenField: 'Mailed_Program_Information_Requested__c', visibleWhenKind: 'checkbox', visibleWhenValues: ['false'] })
        ],
        countryOptions: [],
        stateOptions: [],
        filterValues: {},
        programValues: [],
        redirectAfterSubmission: false,
        ...overrides
    };
}

const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

let element;
let captured;

async function renderForm(form = buildForm()) {
    element = createElement('c-rfi-form', { is: RfiForm });
    element.rfiControllerName = CONTROLLER_NAME;
    document.body.appendChild(element);
    getRFIForm.emit(JSON.parse(JSON.stringify(form)));
    await flushPromises();
}

function root() {
    return element.shadowRoot;
}

function inputByLabel(label) {
    return Array.from(root().querySelectorAll('lightning-input')).find((i) => i.label === label);
}

function comboboxByLabel(label) {
    return Array.from(root().querySelectorAll('lightning-combobox')).find((c) => c.label === label);
}

async function choose(label, value) {
    const combobox = comboboxByLabel(label);
    combobox.value = value;
    combobox.dispatchEvent(new CustomEvent('change', { detail: { value } }));
    await flushPromises();
}

async function setBox(label, checked) {
    const box = inputByLabel(label);
    box.checked = checked;
    box.dispatchEvent(new CustomEvent('change', { detail: { checked } }));
    await flushPromises();
}

async function type(label, value) {
    const input = inputByLabel(label);
    input.value = value;
    input.dispatchEvent(new CustomEvent('change', { detail: { value } }));
    await flushPromises();
}

// The Jest stubs return nothing from checkValidity(). Make a required, empty input invalid, as the real input would,
// so a required question that is wrongly still on the page blocks the submit and the test fails.
function makeValidityRealistic() {
    root()
        .querySelectorAll('lightning-input, lightning-combobox, lightning-textarea, c-multi-select-pills-groupable')
        .forEach((el) => {
            const valid = () => !(el.required && (el.value === undefined || el.value === null || el.value === ''));
            Object.defineProperty(el, 'checkValidity', { value: valid, configurable: true });
            Object.defineProperty(el, 'reportValidity', { value: valid, configurable: true });
        });
}

async function submit() {
    makeValidityRealistic();
    const button = Array.from(root().querySelectorAll('lightning-button')).find((b) => b.label === 'Submit');
    button.click();
    await flushPromises();
    await flushPromises();
}

async function fillNames() {
    await type('First Name', 'Ada');
    await type('Last Name', 'Lovelace');
}

describe('c-rfi-form dependent questions', () => {
    beforeEach(() => {
        captured = null;
        submitRfiForm.mockReset();
        submitRfiForm.mockImplementation((args) => {
            captured = JSON.parse(JSON.stringify(args));
            return Promise.resolve('a10000000000001AAA');
        });
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('does not draw a dependent question until the earlier answer calls for it', async () => {
        await renderForm();
        expect(comboboxByLabel('Citizenship')).toBeTruthy();
        expect(inputByLabel('Visa status')).toBeUndefined();
        expect(comboboxByLabel('Visa country')).toBeUndefined();
    });

    it('draws the question when the earlier answer is one of the revealing ones, and hides it for another', async () => {
        await renderForm();
        await choose('Citizenship', 'International');
        expect(inputByLabel('Visa status')).toBeTruthy();
        expect(comboboxByLabel('Visa country')).toBeTruthy();

        await choose('Citizenship', 'Other');
        expect(inputByLabel('Visa status')).toBeTruthy();

        await choose('Citizenship', 'US Citizen');
        expect(inputByLabel('Visa status')).toBeUndefined();
        expect(comboboxByLabel('Visa country')).toBeUndefined();
    });

    it('follows a tick box in both directions', async () => {
        await renderForm();
        expect(inputByLabel('Mail note')).toBeUndefined();
        expect(inputByLabel('No mail note')).toBeTruthy(); // an untouched box counts as not checked

        await setBox('Send me mail', true);
        expect(inputByLabel('Mail note')).toBeTruthy();
        expect(inputByLabel('No mail note')).toBeUndefined();

        await setBox('Send me mail', false);
        expect(inputByLabel('Mail note')).toBeUndefined();
        expect(inputByLabel('No mail note')).toBeTruthy();
    });

    it('never blocks the submit because of a required question that is hidden', async () => {
        await renderForm();
        await fillNames();
        await submit();
        expect(submitRfiForm).toHaveBeenCalledTimes(1);
    });

    it('does block the submit while the required question is shown and empty', async () => {
        await renderForm();
        await fillNames();
        await choose('Citizenship', 'International');
        await submit();
        expect(submitRfiForm).not.toHaveBeenCalled();
    });

    it('sends the answer to a question that is shown', async () => {
        await renderForm();
        await fillNames();
        await choose('Citizenship', 'International');
        await type('Visa status', 'F-1');
        await submit();
        expect(captured.interaction.Employer__c).toBe('F-1');
        expect(captured.interaction.Citizenship__c).toBe('International');
    });

    it('throws away what was typed in a question that was hidden again', async () => {
        await renderForm();
        await fillNames();
        await choose('Citizenship', 'International');
        await type('Visa status', 'F-1');
        await choose('Citizenship', 'US Citizen');
        await submit();
        expect(captured.interaction.Employer__c).toBeUndefined();
        expect(captured.interaction.Citizenship__c).toBe('US Citizen');
    });

    it('throws away a chosen answer of a hidden picklist question', async () => {
        await renderForm();
        await fillNames();
        await choose('Citizenship', 'International');
        await choose('Visa country', 'Canada');
        await choose('Citizenship', 'US Citizen');
        await submit();
        expect(captured.interaction.Mailing_City__c).toBeUndefined();
    });

    it('starts a question empty when it comes back after being hidden', async () => {
        await renderForm();
        await choose('Citizenship', 'International');
        await choose('Visa country', 'Canada');
        await choose('Citizenship', 'US Citizen');
        await choose('Citizenship', 'Other');
        await fillNames();
        await type('Visa status', 'back');
        await submit();
        expect(captured.interaction.Mailing_City__c).toBeUndefined();
    });

    it('drops the answer of a tick-box dependent question when the box flips', async () => {
        await renderForm();
        await fillNames();
        await setBox('Send me mail', true);
        await type('Mail note', 'by post');
        await setBox('Send me mail', false);
        await submit();
        expect(captured.interaction.Title__c).toBeUndefined();
        expect(captured.interaction.Mailed_Program_Information_Requested__c).toBe(false);
    });

    it('throws away a chosen picklist answer when the tick box that revealed it is unticked', async () => {
        const form = formWith(field('Mail format', 'Mailing_State__c', {
            isPicklist: true,
            picklistValues: [{ label: 'Letter', value: 'Letter' }, { label: 'Postcard', value: 'Postcard' }],
            visibleWhenField: 'Mailed_Program_Information_Requested__c', visibleWhenKind: 'checkbox', visibleWhenValues: ['true']
        }));
        await renderForm(form);
        await fillNames();
        await setBox('Send me mail', true);
        await choose('Mail format', 'Postcard');
        await setBox('Send me mail', false);
        await submit();
        expect(comboboxByLabel('Mail format')).toBeUndefined();
        expect(captured.interaction.Mailing_State__c).toBeUndefined();
    });

    it('never sends a value that was preset for a hidden question', async () => {
        await renderForm(buildForm({ interaction: { Employer__c: 'preset from the link' } }));
        await fillNames();
        await submit();
        expect(captured.interaction.Employer__c).toBeUndefined();
    });

    it('shows a dependent question at load when the earlier answer is already preset', async () => {
        await renderForm(buildForm({ interaction: { Citizenship__c: 'International' } }));
        expect(inputByLabel('Visa status')).toBeTruthy();
    });

    it('keeps a field that a visible question also saves to', async () => {
        const form = buildForm();
        form.rfiFieldList.push(field('Employer', 'Employer__c'));
        await renderForm(form);
        await fillNames();
        await type('Employer', 'Acme');
        await submit();
        expect(captured.interaction.Employer__c).toBe('Acme');
    });

    it('draws the dependent question again after the form is reset by a successful submit', async () => {
        await renderForm();
        await fillNames();
        await choose('Citizenship', 'International');
        await type('Visa status', 'F-1');
        await submit();
        expect(submitRfiForm).toHaveBeenCalledTimes(1);
        expect(inputByLabel('Visa status')).toBeUndefined();
    });

    // --- questions that keep more than one value ---

    function formWith(...extraFields) {
        const form = buildForm();
        form.rfiFieldList.push(...extraFields);
        return form;
    }

    function lookup() {
        return root().querySelector('c-reusable-lookup');
    }

    async function pickSchool(id) {
        lookup().dispatchEvent(new CustomEvent('valueselected', { detail: { id, mainField: 'Central High' } }));
        await flushPromises();
    }

    it('throws away a chosen school when the school question is hidden', async () => {
        await renderForm(formWith(field('High School Attended', 'High_School_or_College__c', picklistRule({ isSchoolLookup: true }))));
        await fillNames();
        await choose('Citizenship', 'International');
        await pickSchool('001000000000001AAA');
        await choose('Citizenship', 'US Citizen');
        await submit();
        expect(lookup()).toBeNull();
        expect(captured.interaction.High_School_or_College__c).toBeUndefined();
    });

    it('sends a school that is shown', async () => {
        await renderForm(formWith(field('High School Attended', 'High_School_or_College__c', picklistRule({ isSchoolLookup: true }))));
        await fillNames();
        await choose('Citizenship', 'International');
        await pickSchool('001000000000001AAA');
        await type('Visa status', 'F-1');
        await submit();
        expect(captured.interaction.High_School_or_College__c).toBe('001000000000001AAA');
    });

    it('goes back to the school search, not the typed school name, when the school question returns', async () => {
        await renderForm(formWith(field('High School Attended', 'High_School_or_College__c', picklistRule({ isSchoolLookup: true }))));
        await choose('Citizenship', 'International');
        await setBox("I can't find my school", true);
        expect(inputByLabel('Enter your school name')).toBeTruthy();
        await choose('Citizenship', 'US Citizen');
        await choose('Citizenship', 'International');
        expect(inputByLabel('Enter your school name')).toBeUndefined();
        expect(lookup()).toBeTruthy();
    });

    it('throws away the typed school name when the school question is hidden', async () => {
        await renderForm(formWith(field('High School Attended', 'High_School_or_College__c', picklistRule({ isSchoolLookup: true }))));
        await fillNames();
        await choose('Citizenship', 'International');
        await setBox("I can't find my school", true);
        await type('Enter your school name', 'Home School');
        await choose('Citizenship', 'US Citizen');
        await submit();
        expect(captured.interaction.School_Name_Text__c).toBeUndefined();
    });

    it('closes the question box when the "I have a question" tick box is hidden, and sends neither', async () => {
        await renderForm(formWith(field('I have a question', 'Has_Question__c', picklistRule({ isCheckbox: true, showDependentField: true }))));
        await fillNames();
        await choose('Citizenship', 'International');
        await setBox('I have a question', true);
        expect(root().querySelector('lightning-textarea')).toBeTruthy();
        await choose('Citizenship', 'US Citizen');
        await choose('Citizenship', 'International');
        expect(root().querySelector('lightning-textarea')).toBeNull();
        await type('Visa status', 'F-1');
        await submit();
        expect(captured.interaction.Has_Question__c).toBeUndefined();
        expect(captured.interaction.Description__c).toBeUndefined();
    });

    it('throws away chosen programs when the program question is hidden', async () => {
        const form = formWith(field('Academic Interest', 'Major_Program_1__c', picklistRule({ isProgramLookup: true, max: 4 })));
        form.programValues = [{ label: 'Biology', value: 'a1' }, { label: 'Chemistry', value: 'a2' }];
        await renderForm(form);
        await fillNames();
        await choose('Citizenship', 'International');
        const programs = Array.from(root().querySelectorAll('c-multi-select-pills-groupable')).find((c) => c.name === 'Major_Program_1__c');
        expect(programs).toBeTruthy();
        programs.dispatchEvent(new CustomEvent('change', { detail: { value: ['a1', 'a2'] } }));
        await flushPromises();
        await choose('Citizenship', 'US Citizen');
        await submit();
        expect(captured.interaction.Major_Program_1__c).toBeUndefined();
        expect(captured.interaction.Major_Program_2__c).toBeUndefined();
    });

    it('sends the chosen programs while the program question is shown', async () => {
        const form = formWith(field('Academic Interest', 'Major_Program_1__c', picklistRule({ isProgramLookup: true, max: 4 })));
        form.programValues = [{ label: 'Biology', value: 'a1' }, { label: 'Chemistry', value: 'a2' }];
        await renderForm(form);
        await fillNames();
        await choose('Citizenship', 'International');
        const programs = Array.from(root().querySelectorAll('c-multi-select-pills-groupable')).find((c) => c.name === 'Major_Program_1__c');
        programs.dispatchEvent(new CustomEvent('change', { detail: { value: ['a1', 'a2'] } }));
        await flushPromises();
        await type('Visa status', 'F-1');
        await submit();
        expect(captured.interaction.Major_Program_1__c).toBe('a1');
        expect(captured.interaction.Major_Program_2__c).toBe('a2');
    });

    it('does not send a hidden question\'s preset on a second submit after the form was reset', async () => {
        await renderForm(buildForm({ interaction: { Employer__c: 'preset from the link' } }));
        await fillNames();
        await submit();
        expect(captured.interaction.Employer__c).toBeUndefined();
        captured = null;
        await fillNames();
        await submit();
        expect(captured).not.toBeNull();
        expect(captured.interaction.Employer__c).toBeUndefined();
    });

    // --- what a visitor already entered must survive another question appearing or disappearing ---

    function formWithQuestionsBelow() {
        const form = buildForm();
        form.rfiFieldList.push(field('Anything else', 'Relationship_to_Student__c'));
        return form;
    }

    it('keeps the same tick box on the page, ticked, when a question above it appears and disappears', async () => {
        await renderForm(formWithQuestionsBelow());
        await setBox('Send me mail', true);
        const before = inputByLabel('Send me mail');
        await choose('Citizenship', 'International');
        expect(inputByLabel('Visa status')).toBeTruthy();
        expect(inputByLabel('Send me mail')).toBe(before);
        expect(inputByLabel('Send me mail').checked).toBe(true);
        await choose('Citizenship', 'US Citizen');
        expect(inputByLabel('Send me mail')).toBe(before);
        expect(inputByLabel('Send me mail').checked).toBe(true);
    });

    it('keeps the same text box, with its text, when a question above it appears', async () => {
        await renderForm(formWithQuestionsBelow());
        await type('Anything else', 'typed before the visa question appeared');
        const before = inputByLabel('Anything else');
        await choose('Citizenship', 'International');
        expect(inputByLabel('Anything else')).toBe(before);
        expect(inputByLabel('Anything else').value).toBe('typed before the visa question appeared');
    });

    it('still sends a tick and later typed text after earlier questions came and went', async () => {
        await renderForm(formWithQuestionsBelow());
        await fillNames();
        await setBox('Send me mail', true);
        await type('Mail note', 'by post');
        await type('Anything else', 'kept');
        await choose('Citizenship', 'International');
        await type('Visa status', 'F-1');
        await choose('Citizenship', 'US Citizen');
        await submit();
        expect(captured.interaction.Mailed_Program_Information_Requested__c).toBe(true);
        expect(captured.interaction.Title__c).toBe('by post');
        expect(captured.interaction.Relationship_to_Student__c).toBe('kept');
        expect(captured.interaction.Employer__c).toBeUndefined();
    });

    it('draws every question when no rule is set, as before', async () => {
        const form = buildForm();
        form.rfiFieldList = form.rfiFieldList.map((f) => ({ ...f, visibleWhenField: undefined, visibleWhenKind: undefined, visibleWhenValues: undefined }));
        await renderForm(form);
        expect(inputByLabel('Visa status')).toBeTruthy();
        expect(inputByLabel('Mail note')).toBeTruthy();
    });
});
