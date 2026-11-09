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
    return { fieldLabel: label, fieldInteractionAPIName: apiName, isVisible: true, ...extra };
}

const FORM = {
    interaction: { Employer__c: 'No Company', Lead_Source__c: 'Webform' },
    rfiFieldList: [
        field('First Name', 'First_Name__c', { isRequired: true }),
        field('Last Name', 'Last_Name__c', { isRequired: true }),
        field('Employer', 'Employer__c'),
        field('Mobile Phone', 'Mobile_Phone__c', { isTel: true }),
        field('Phone', 'Mobile_Phone__c', { isTel: true }),
        field('How did you hear about us?', 'Heard_About_Us__c', {
            isMultiSelect: true,
            max: 4,
            picklistValues: [
                { label: 'Friend', value: 'Friend' },
                { label: 'Alumni', value: 'Alumni' }
            ]
        }),
        field('High School Attended', 'High_School_or_College__c', { isSchoolLookup: true }),
        field('Tell us about yourself', 'Description__c', { isTextarea: true }),
        field('I have a question', 'Has_Question__c', { isCheckbox: true, showDependentField: true })
    ],
    countryOptions: [],
    stateOptions: [],
    filterValues: {},
    programValues: [],
    redirectAfterSubmission: false
};

const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

let element;
let captured;

async function renderForm() {
    element = createElement('c-rfi-form', { is: RfiForm });
    element.rfiControllerName = CONTROLLER_NAME;
    document.body.appendChild(element);
    getRFIForm.emit(JSON.parse(JSON.stringify(FORM)));
    await flushPromises();
}

function root() {
    return element.shadowRoot;
}

function inputByLabel(label) {
    return Array.from(root().querySelectorAll('lightning-input')).find((i) => i.label === label);
}

function textareaByLabel(label) {
    return Array.from(root().querySelectorAll('lightning-textarea')).find((t) => t.label === label);
}

async function type(el, value) {
    el.value = value;
    el.dispatchEvent(new CustomEvent('change', { detail: { value } }));
    await flushPromises();
}

async function tick(checkbox) {
    checkbox.checked = true;
    checkbox.dispatchEvent(new CustomEvent('change', { detail: { checked: true } }));
    await flushPromises();
}

// The Jest stubs for the Lightning inputs return nothing from checkValidity(), which the form reads as invalid.
function makeEverythingValid() {
    root()
        .querySelectorAll('lightning-input, lightning-combobox, lightning-textarea, c-multi-select-pills-groupable')
        .forEach((el) => {
            Object.defineProperty(el, 'checkValidity', { value: () => true, configurable: true });
            Object.defineProperty(el, 'reportValidity', { value: () => true, configurable: true });
        });
}

async function submit() {
    makeEverythingValid();
    const button = Array.from(root().querySelectorAll('lightning-button')).find((b) => b.label === 'Submit');
    button.click();
    await flushPromises();
    await flushPromises();
}

describe('c-rfi-form submit', () => {
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

    it('sends the controller name so the server can apply that controller\'s presets and rules', async () => {
        await renderForm();
        await type(inputByLabel('First Name'), 'Ada');
        await type(inputByLabel('Last Name'), 'Lovelace');
        await submit();
        expect(submitRfiForm).toHaveBeenCalledTimes(1);
        expect(captured.rfiControllerName).toBe(CONTROLLER_NAME);
        expect(captured.interaction.First_Name__c).toBe('Ada');
    });

    it('saves multi-select choices as one semicolon list under the right field', async () => {
        await renderForm();
        const pills = Array.from(root().querySelectorAll('c-multi-select-pills-groupable')).find((p) => p.name === 'Heard_About_Us__c');
        expect(pills).not.toBeNull();
        pills.dispatchEvent(new CustomEvent('change', { detail: { value: ['Friend', 'Alumni'] } }));
        await flushPromises();
        await submit();
        expect(captured.interaction.Heard_About_Us__c).toBe('Friend;Alumni');
    });

    it('saves the school picked from the lookup into the lookup field', async () => {
        await renderForm();
        const lookup = root().querySelector('c-reusable-lookup');
        lookup.dispatchEvent(new CustomEvent('valueselected', { detail: { id: '001000000000001AAA', mainField: 'Central High', subField: 'Saint Paul' } }));
        await flushPromises();
        await submit();
        expect(captured.interaction.High_School_or_College__c).toBe('001000000000001AAA');
        expect(captured.interaction.School_Name_Text__c).toBeUndefined();
    });

    it('saves a typed school as text and never puts text in the lookup field', async () => {
        await renderForm();
        await tick(inputByLabel("I can't find my school"));
        const typed = inputByLabel('Enter your school name');
        expect(typed).toBeDefined();
        await type(typed, 'Small Prairie High School');
        await submit();
        expect(captured.interaction.School_Name_Text__c).toBe('Small Prairie High School');
        expect(captured.interaction.High_School_or_College__c).toBeUndefined();
    });

    it('combines the two long answers into Description with the old headings', async () => {
        await renderForm();
        await type(textareaByLabel('Tell us about yourself'), 'I love biology');
        await tick(inputByLabel('I have a question'));
        const questionBox = textareaByLabel('Questions/Comments');
        expect(questionBox).toBeDefined();
        await type(questionBox, 'Is there housing?');
        await submit();
        expect(captured.interaction.Description__c).toBe(
            'Questions/Comments from RFI: \nIs there housing?\n\nTell us about yourself from RFI: \nI love biology'
        );
        expect(captured.interaction.Description).toBeUndefined();
        expect(captured.interaction.rfiQuestionComments).toBeUndefined();
    });

    it('keeps Tell us about yourself under its heading when no question was asked', async () => {
        await renderForm();
        await type(textareaByLabel('Tell us about yourself'), 'I love biology');
        await submit();
        expect(captured.interaction.Description__c).toBe('Tell us about yourself from RFI: \nI love biology');
    });

    it('does not let a blank box wipe an answer typed in another box for the same field', async () => {
        await renderForm();
        await type(inputByLabel('Mobile Phone'), '6515550100');
        // the "Phone" box (same field) stays blank and comes after in the form
        await submit();
        expect(captured.interaction.Mobile_Phone__c).toBe('6515550100');
    });

    it('sends the state code as State__c and the state name as Mailing_State__c', async () => {
        const withAddress = JSON.parse(JSON.stringify(FORM));
        withAddress.rfiFieldList.push(field('Address', 'Mailing_Street__c', { isAddress: true }));
        withAddress.countryOptions = [{ label: 'United States', value: 'US' }];
        withAddress.stateOptions = [{ label: 'Minnesota', value: 'MN' }];
        element = createElement('c-rfi-form', { is: RfiForm });
        element.rfiControllerName = CONTROLLER_NAME;
        document.body.appendChild(element);
        getRFIForm.emit(withAddress);
        await flushPromises();
        await type(inputByLabel('First Name'), 'Ada');
        await type(inputByLabel('Last Name'), 'Lovelace');
        const address = root().querySelector('lightning-input-address');
        address.dispatchEvent(new CustomEvent('change', { detail: { street: '1 Main', city: 'Saint Paul', province: 'MN', postalCode: '55105', country: 'US' } }));
        await flushPromises();
        await submit();
        expect(captured.interaction.State__c).toBe('MN');
        expect(captured.interaction.Mailing_State__c).toBe('Minnesota');
        expect(captured.interaction.Mailing_Country__c).toBe('United States');
    });

    async function renderWithProgramLookup() {
        const withPrograms = JSON.parse(JSON.stringify(FORM));
        withPrograms.rfiFieldList.push(field('Academic Interest', 'Major_Program_1__c', { isProgramLookup: true, max: 4 }));
        withPrograms.programValues = [
            { label: 'Biology', value: 'p1' },
            { label: 'Chemistry', value: 'p2' },
            { label: 'History', value: 'p3' }
        ];
        element = createElement('c-rfi-form', { is: RfiForm });
        element.rfiControllerName = CONTROLLER_NAME;
        document.body.appendChild(element);
        getRFIForm.emit(withPrograms);
        await flushPromises();
        await type(inputByLabel('First Name'), 'Ada');
        await type(inputByLabel('Last Name'), 'Lovelace');
    }

    function programPills() {
        return Array.from(root().querySelectorAll('c-multi-select-pills-groupable')).find((p) => p.name === 'Major_Program_1__c');
    }

    it('saves the chosen academic interests into Major_Program_1__c to Major_Program_4__c', async () => {
        await renderWithProgramLookup();
        programPills().dispatchEvent(new CustomEvent('change', { detail: ['p1', 'p2'] }));
        await flushPromises();
        await submit();
        expect(captured.interaction.Major_Program_1__c).toBe('p1');
        expect(captured.interaction.Major_Program_2__c).toBe('p2');
        expect(captured.interaction.Major_Program_3__c).toBe('');
    });

    it('clears all four Major Program fields when the academic interests are emptied (F14)', async () => {
        await renderWithProgramLookup();
        programPills().dispatchEvent(new CustomEvent('change', { detail: ['p1', 'p2', 'p3'] }));
        await flushPromises();
        programPills().dispatchEvent(new CustomEvent('change', { detail: [] }));
        await flushPromises();
        await submit();
        expect(captured.interaction.Major_Program_1__c).toBe('');
        expect(captured.interaction.Major_Program_2__c).toBe('');
        expect(captured.interaction.Major_Program_3__c).toBe('');
        expect(captured.interaction.Major_Program_4__c).toBe('');
    });

    it('shows an error and keeps the answers when the server could not save the RFI', async () => {
        const redirecting = JSON.parse(JSON.stringify(FORM));
        redirecting.redirectAfterSubmission = true;
        redirecting.redirectUrl = 'https://example.invalid/thanks';
        element = createElement('c-rfi-form', { is: RfiForm });
        element.rfiControllerName = CONTROLLER_NAME;
        document.body.appendChild(element);
        getRFIForm.emit(redirecting);
        await flushPromises();
        const toasts = [];
        element.addEventListener('lightning__showtoast', (event) => toasts.push(event.detail));
        const openSpy = jest.spyOn(window, 'open').mockImplementation(() => null);
        submitRfiForm.mockImplementation(() => Promise.resolve(null));
        await type(inputByLabel('First Name'), 'Ada');
        await type(inputByLabel('Last Name'), 'Lovelace');
        await submit();
        expect(submitRfiForm).toHaveBeenCalledTimes(1);
        // No record page here, so the message is drawn in the form rather than as a toast (toasts do not exist in Lightning Out)
        expect(toasts).toEqual([]);
        const message = root().querySelector('[data-id="status-message"]');
        expect(message.getAttribute('role')).toBe('alert');
        expect(message.textContent).toContain('could not send your request');
        expect(openSpy).not.toHaveBeenCalled();
        expect(inputByLabel('First Name').value).toBe('Ada');
        openSpy.mockRestore();
    });

    it('shows a message instead of a spinner when the form cannot be loaded', async () => {
        element = createElement('c-rfi-form', { is: RfiForm });
        element.rfiControllerName = CONTROLLER_NAME;
        document.body.appendChild(element);
        getRFIForm.error({ body: { message: 'The questions for this form could not be loaded' } });
        await flushPromises();
        expect(root().querySelector('lightning-spinner')).toBeNull();
        const message = root().querySelector('[role="alert"]');
        expect(message).not.toBeNull();
        expect(message.textContent).toContain('could not load this form');
    });

    it('draws a date question as a date picker and sends the date in the form the server can read', async () => {
        const withBirthdate = JSON.parse(JSON.stringify(FORM));
        withBirthdate.rfiFieldList.push(field('Birthday', 'Birthdate__c', { isDate: true, inputType: 'date' }));
        element = createElement('c-rfi-form', { is: RfiForm });
        element.rfiControllerName = CONTROLLER_NAME;
        document.body.appendChild(element);
        getRFIForm.emit(withBirthdate);
        await flushPromises();
        expect(inputByLabel('Birthday').type).toBe('date');
        await type(inputByLabel('First Name'), 'Ada');
        await type(inputByLabel('Last Name'), 'Lovelace');
        await type(inputByLabel('Birthday'), '2000-01-15');
        await submit();
        expect(captured.interaction.Birthdate__c).toBe('2000-01-15');
    });

    describe('messages about saved questions', () => {
        async function renderWithWarnings(recordId) {
            const withWarnings = JSON.parse(JSON.stringify(FORM));
            withWarnings.warnings = ['Question 3 ("Future thing") has the type "matrix", which this version does not know. It was skipped.'];
            element = createElement('c-rfi-form', { is: RfiForm });
            element.rfiControllerName = CONTROLLER_NAME;
            if (recordId) {
                element.recordId = recordId;
            }
            document.body.appendChild(element);
            getRFIForm.emit(withWarnings);
            await flushPromises();
        }

        it('shows the admin the problem when the form sits on the controller record page', async () => {
            await renderWithWarnings('a18000000000001AAA');
            const banner = root().querySelector('[data-id="admin-warnings"]');
            expect(banner).not.toBeNull();
            expect(banner.textContent).toContain('Future thing');
            expect(banner.textContent).toContain('Visitors do not see this message');
        });

        it('never shows it to a visitor on the public site, where there is no record page', async () => {
            await renderWithWarnings(null);
            expect(root().querySelector('[data-id="admin-warnings"]')).toBeNull();
            expect(root().textContent).not.toContain('Future thing');
        });

        it('shows nothing when there is nothing to report', async () => {
            await renderForm();
            element.recordId = 'a18000000000001AAA';
            await flushPromises();
            expect(root().querySelector('[data-id="admin-warnings"]')).toBeNull();
        });
    });

    it('a blank Employer keeps the controller default', async () => {
        await renderForm();
        await submit();
        expect(captured.interaction.Employer__c).toBe('No Company');
    });

    describe('while a submission is in progress', () => {
        const overlay = () => root().querySelector('[data-id="submit-overlay"]');
        const submitButton = () => Array.from(root().querySelectorAll('lightning-button')).find((b) => b.label === 'Submit');

        async function renderAndFill(formData = FORM) {
            element = createElement('c-rfi-form', { is: RfiForm });
            element.rfiControllerName = CONTROLLER_NAME;
            document.body.appendChild(element);
            getRFIForm.emit(JSON.parse(JSON.stringify(formData)));
            await flushPromises();
            await type(inputByLabel('First Name'), 'Ada');
            await type(inputByLabel('Last Name'), 'Lovelace');
        }

        it('grays out the form with a message and disables Submit until the server answers, then removes the overlay', async () => {
            let finish;
            submitRfiForm.mockImplementation(() => new Promise((resolve) => { finish = resolve; }));
            await renderAndFill();
            expect(overlay()).toBeNull();

            await submit();
            expect(overlay()).not.toBeNull();
            expect(overlay().textContent).toContain('Submitting your request');
            expect(submitButton().disabled).toBe(true);

            finish('a10000000000001AAA');
            await flushPromises();
            await flushPromises();
            expect(overlay()).toBeNull();
            expect(submitButton().disabled).toBe(false);
        });

        it('removes the overlay when the submission fails, so the visitor can try again', async () => {
            submitRfiForm.mockImplementation(() => Promise.reject(new Error('boom')));
            const errorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
            await renderAndFill();
            await submit();
            expect(overlay()).toBeNull();
            expect(submitButton().disabled).toBe(false);
            errorSpy.mockRestore();
        });

        it('does not show the overlay when the form is invalid and nothing is sent', async () => {
            await renderAndFill();
            // The Jest stubs report every input as invalid until told otherwise, so Submit stops at validation
            Array.from(root().querySelectorAll('lightning-button')).find((b) => b.label === 'Submit').click();
            await flushPromises();
            expect(submitRfiForm).not.toHaveBeenCalled();
            expect(overlay()).toBeNull();
        });

        it('keeps the overlay up while the browser leaves for the redirect page', async () => {
            const redirecting = { ...FORM, redirectAfterSubmission: true, redirectUrl: 'https://example.invalid/thanks' };
            const openSpy = jest.spyOn(window, 'open').mockImplementation(() => null);
            await renderAndFill(redirecting);
            await submit();
            expect(openSpy).toHaveBeenCalledWith('https://example.invalid/thanks', '_self');
            expect(overlay()).not.toBeNull();
            openSpy.mockRestore();
        });
    });
});
