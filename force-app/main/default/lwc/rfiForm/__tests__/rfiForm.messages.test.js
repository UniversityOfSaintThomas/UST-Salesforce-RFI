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
const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

function field(label, apiName, extra = {}) {
    return { fieldLabel: label, fieldInteractionAPIName: apiName, isVisible: true, ...extra };
}

function buildForm(extraFields = [], extra = {}) {
    return {
        interaction: { Lead_Source__c: 'Webform' },
        rfiFieldList: [
            field('First Name', 'First_Name__c', { isRequired: true }),
            field('Last Name', 'Last_Name__c', { isRequired: true }),
            ...extraFields
        ],
        countryOptions: [{ label: 'United States', value: 'US' }],
        stateOptions: [{ label: 'Minnesota', value: 'MN' }],
        filterValues: {},
        programValues: [],
        redirectAfterSubmission: false,
        ...extra
    };
}

let element;

async function renderForm(form, recordId) {
    element = createElement('c-rfi-form', { is: RfiForm });
    element.rfiControllerName = CONTROLLER_NAME;
    if (recordId) {
        element.recordId = recordId;
    }
    document.body.appendChild(element);
    getRFIForm.emit(JSON.parse(JSON.stringify(form)));
    await flushPromises();
}

const root = () => element.shadowRoot;
const inputByLabel = (label) => Array.from(root().querySelectorAll('lightning-input')).find((i) => i.label === label);

async function type(el, value) {
    el.value = value;
    el.dispatchEvent(new CustomEvent('change', { detail: { value } }));
    await flushPromises();
}

// The Jest stubs return nothing from checkValidity(), which the form reads as invalid, so tests say which are valid.
function setValidity(el, valid) {
    Object.defineProperty(el, 'checkValidity', { value: () => valid, configurable: true });
    Object.defineProperty(el, 'reportValidity', { value: () => valid, configurable: true });
}

function makeEverythingValid() {
    root()
        .querySelectorAll('lightning-input, lightning-combobox, lightning-textarea, c-multi-select-pills-groupable')
        .forEach((el) => setValidity(el, true));
}

async function clickSubmit() {
    const button = Array.from(root().querySelectorAll('lightning-button')).find((b) => b.label === 'Submit');
    button.click();
    await flushPromises();
    await flushPromises();
    // The scroll to the message waits for the form height to settle, which takes a few animation frames
    await waitForFrames(4);
}

function waitForFrames(count) {
    return new Promise((resolve) => {
        const step = (left) => (left === 0 ? resolve() : requestAnimationFrame(() => step(left - 1)));
        step(count);
    });
}

const statusMessage = () => root().querySelector('[data-id="status-message"]');

describe('c-rfi-form messages and clearing after a submit', () => {
    beforeEach(() => {
        submitRfiForm.mockReset();
        submitRfiForm.mockResolvedValue('a10000000000001AAA');
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    describe('where toasts do not exist (no record page, such as Lightning Out)', () => {
        it('clears the form and says the request was received in the page itself', async () => {
            await renderForm(buildForm());
            const toasts = [];
            element.addEventListener('lightning__showtoast', (event) => toasts.push(event.detail));
            await type(inputByLabel('First Name'), 'Ada');
            await type(inputByLabel('Last Name'), 'Lovelace');
            makeEverythingValid();
            await clickSubmit();

            expect(submitRfiForm).toHaveBeenCalledTimes(1);
            expect(toasts).toEqual([]);
            expect(statusMessage().getAttribute('role')).toBe('status');
            expect(statusMessage().textContent).toContain('We received your request');
            expect(inputByLabel('First Name').value).toBeFalsy();
            expect(inputByLabel('Last Name').value).toBeFalsy();
        });

        it('shows a plain message with no technical wording when the request could not be sent', async () => {
            submitRfiForm.mockRejectedValue(new Error('System.DmlException: INSUFFICIENT_ACCESS'));
            await renderForm(buildForm());
            await type(inputByLabel('First Name'), 'Ada');
            makeEverythingValid();
            await clickSubmit();

            expect(statusMessage().getAttribute('role')).toBe('alert');
            expect(statusMessage().textContent).toContain('could not send your request');
            expect(statusMessage().textContent).not.toMatch(/DmlException|INSUFFICIENT|Interaction/);
            expect(inputByLabel('First Name').value).toBe('Ada');
        });

        it('removes the old message when the visitor tries again', async () => {
            submitRfiForm.mockRejectedValueOnce(new Error('boom'));
            await renderForm(buildForm());
            makeEverythingValid();
            await clickSubmit();
            expect(statusMessage().getAttribute('role')).toBe('alert');

            await clickSubmit();
            expect(statusMessage().getAttribute('role')).toBe('status');
        });

        it('brings the message into view', async () => {
            const scrollSpy = jest.fn();
            Element.prototype.scrollIntoView = scrollSpy;
            await renderForm(buildForm());
            makeEverythingValid();
            await clickSubmit();
            delete Element.prototype.scrollIntoView;

            expect(scrollSpy).toHaveBeenCalled();
            expect(scrollSpy.mock.instances.some((el) => el === statusMessage())).toBe(true);
        });

        it('scrolls to the message only after the questions are drawn again, so the page cannot grow past it', async () => {
            const questionsPresentAtScroll = [];
            Element.prototype.scrollIntoView = function () {
                questionsPresentAtScroll.push(root().querySelectorAll('lightning-input').length);
            };
            await renderForm(buildForm());
            makeEverythingValid();
            await clickSubmit();
            delete Element.prototype.scrollIntoView;

            expect(questionsPresentAtScroll.length).toBeGreaterThan(0);
            expect(questionsPresentAtScroll.every((count) => count > 0)).toBe(true);
        });
        it('waits until the form stops growing before it scrolls (Lightning Out draws the questions late)', async () => {
            const scrolls = [];
            Element.prototype.scrollIntoView = function () {
                scrolls.push(frameOfLastRead);
            };
            await renderForm(buildForm());
            makeEverythingValid();

            // The page is short for the first frames after the submit, then the questions come back and it grows
            let reads = 0;
            let frameOfLastRead = 0;
            element.getBoundingClientRect = () => {
                reads += 1;
                frameOfLastRead = reads;
                const height = reads < 6 ? 1466 + reads : 3299;
                return { height, top: 0, bottom: height, left: 0, right: 0, width: 0 };
            };
            await clickSubmit();
            await waitForFrames(8);
            delete Element.prototype.scrollIntoView;

            expect(scrolls.length).toBe(1);
            // Reads 1 to 5 report a changing height; the scroll may only follow two equal readings in a row
            expect(scrolls[0]).toBeGreaterThanOrEqual(7);
        });
    });

    describe('on the RFI Controller record page (admin)', () => {
        it('keeps using toasts and draws no message in the form', async () => {
            await renderForm(buildForm(), 'a18000000000001AAA');
            const toasts = [];
            element.addEventListener('lightning__showtoast', (event) => toasts.push(event.detail));
            makeEverythingValid();
            await clickSubmit();

            expect(toasts.map((t) => t.variant)).toEqual(['success']);
            expect(statusMessage()).toBeNull();
        });
    });

    describe('clearing', () => {
        it('draws the questions again from scratch, so nothing typed or picked is left behind', async () => {
            const withAddress = buildForm([field('Address', 'Mailing_Street__c', { isAddress: true })]);
            await renderForm(withAddress);
            const addressBefore = root().querySelector('lightning-input-address');
            makeEverythingValid();
            await clickSubmit();

            const addressAfter = root().querySelector('lightning-input-address');
            expect(addressAfter).not.toBeNull();
            expect(addressAfter).not.toBe(addressBefore);
        });

        it('does not send the address typed for the first request with the second one', async () => {
            const withAddress = buildForm([field('Address', 'Mailing_Street__c', { isAddress: true })]);
            await renderForm(withAddress);
            root().querySelector('lightning-input-address').dispatchEvent(new CustomEvent('change', {
                detail: { street: '1 Main', city: 'Saint Paul', province: 'MN', postalCode: '55105', country: 'US' }
            }));
            makeEverythingValid();
            await clickSubmit();
            expect(JSON.parse(JSON.stringify(submitRfiForm.mock.calls[0][0])).interaction.Mailing_Street__c).toBe('1 Main');

            makeEverythingValid();
            await clickSubmit();
            const second = JSON.parse(JSON.stringify(submitRfiForm.mock.calls[1][0])).interaction;
            expect(second.Mailing_Street__c || '').toBe('');
            expect(second.Mailing_City__c || '').toBe('');
        });
    });

    describe('validation errors', () => {
        beforeEach(() => {
            Element.prototype.scrollIntoView = jest.fn();
        });

        afterEach(() => {
            delete Element.prototype.scrollIntoView;
        });

        it('scrolls to and focuses the first question with an error, in page order', async () => {
            // The picklist is above First Name on the page, but picklists are checked after text boxes
            const form = buildForm();
            form.rfiFieldList.unshift(
                field('Campus', 'Campus__c', { isPicklist: true, isRequired: true, picklistValues: [{ label: 'Main', value: 'Main' }] })
            );
            await renderForm(form);
            const campus = root().querySelector('lightning-combobox');
            const firstName = inputByLabel('First Name');
            const lastName = inputByLabel('Last Name');
            makeEverythingValid();
            setValidity(campus, false);
            setValidity(firstName, false);
            setValidity(lastName, false);
            campus.focus = jest.fn();
            firstName.focus = jest.fn();

            await clickSubmit();

            expect(submitRfiForm).not.toHaveBeenCalled();
            expect(campus.focus).toHaveBeenCalledTimes(1);
            expect(firstName.focus).not.toHaveBeenCalled();
            const scrolled = Element.prototype.scrollIntoView.mock.instances;
            expect(scrolled).toEqual([campus]);
        });

        it('does not scroll anywhere when everything is valid', async () => {
            await renderForm(buildForm());
            makeEverythingValid();
            const scrollsBefore = Element.prototype.scrollIntoView.mock.calls.length;
            await clickSubmit();

            // Only the "received" message is brought into view, never a question
            const scrolled = Element.prototype.scrollIntoView.mock.instances.slice(scrollsBefore);
            expect(scrolled.every((el) => el === statusMessage())).toBe(true);
        });
    });
});
