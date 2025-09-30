import { createElement } from 'lwc';
import RfiForm from 'c/rfiForm';
import getRFIForm from '@salesforce/apex/rfiFormController.getRFIForm';
import submitRFILead from '@salesforce/apex/rfiFormController.submitRFILead';

jest.mock('@salesforce/apex/rfiFormController.getRFIForm');
jest.mock('@salesforce/apex/rfiFormController.submitRFILead');

function flushPromises() {
    return Promise.resolve().then();
}

const MOCK_WRAPPER = {
    leadRecord: {
        Country: 'United States'
    },
    rfiFieldList: [
        { fieldLabel: 'First Name', fieldLeadAPIName: 'FirstName', fieldType: 'text', isRequired: true },
        { fieldLabel: 'Email', fieldLeadAPIName: 'Email', fieldType: 'email', isRequired: true },
        { fieldLabel: 'I would like to receive text messages', fieldLeadAPIName: null, fieldType: 'checkbox', isRequired: false },
        { fieldLabel: 'Academic Interest (Max 4)', fieldLeadAPIName: 'Academic_Interests__c', fieldType: 'multi-select', isRequired: false, picklistValues: ['Nursing','Mathematics'], max: 4 },
        { fieldLabel: 'Address', fieldLeadAPIName: 'Address', fieldType: 'address', isRequired: true }
    ]
};

describe('c-rfi-form', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('renders fields from Apex wrapper', async () => {
        getRFIForm.mockResolvedValue(JSON.parse(JSON.stringify(MOCK_WRAPPER)));
        const el = createElement('c-rfi-form', { is: RfiForm });
        el.rfiControllerName = 'RFI Controller 0000';
        document.body.appendChild(el);
        await flushPromises();
        // Expect First Name input label to be in shadow DOM
        const labels = Array.from(el.shadowRoot.querySelectorAll('lightning-input')).map(i => i.label);
        expect(labels).toContain('First Name');
    });

    it('submits with multi-select values mapped to Lead', async () => {
        getRFIForm.mockResolvedValue(JSON.parse(JSON.stringify(MOCK_WRAPPER)));
        submitRFILead.mockResolvedValue('00Qxx0000000001AAA');
        const el = createElement('c-rfi-form', { is: RfiForm });
        el.rfiControllerName = 'RFI Controller 0000';
        document.body.appendChild(el);
        await flushPromises();

        // simulate selecting two academic interests via child mock component
        const ms = el.shadowRoot.querySelector('c-multi-select-pills-groupable');
        expect(ms).not.toBeNull();
        ms.dispatchEvent(new CustomEvent('change', { detail: { value: ['Nursing', 'Mathematics'] } }));

        // simulate text input changes
        const inputs = el.shadowRoot.querySelectorAll('lightning-input');
        const firstName = Array.from(inputs).find(i => i.label === 'First Name');
        firstName.value = 'Ada';
        firstName.dispatchEvent(new CustomEvent('change', { detail: { value: 'Ada' } }));

        const email = Array.from(inputs).find(i => i.label === 'Email');
        email.value = 'ada@example.com';
        email.dispatchEvent(new CustomEvent('change', { detail: { value: 'ada@example.com' } }));

        // bypass base validation assumptions and click submit
        const btn = el.shadowRoot.querySelector('lightning-button');
        btn.click();
        await flushPromises();

        expect(submitRFILead).toHaveBeenCalledTimes(1);
        const payload = submitRFILead.mock.calls[0][0].leadRecord;
        expect(payload.FirstName).toBe('Ada');
        expect(payload.Email).toBe('ada@example.com');
        expect(payload.Academic_Interests__c).toBe('Nursing;Mathematics');
    });

    it('maps address change into Lead fields before submit', async () => {
        getRFIForm.mockResolvedValue(JSON.parse(JSON.stringify(MOCK_WRAPPER)));
        submitRFILead.mockResolvedValue('00Qxx0000000002AAA');
        const el = createElement('c-rfi-form', { is: RfiForm });
        el.rfiControllerName = 'RFI Controller 0000';
        document.body.appendChild(el);
        await flushPromises();

        const addr = el.shadowRoot.querySelector('lightning-input-address');
        expect(addr).not.toBeNull();
        // Use the component-provided data attribute instead of hardcoding
        const key = addr.dataset.fieldName;
        expect(key).toBeTruthy();
        addr.dispatchEvent(new CustomEvent('change', { detail: { street: '2115 Summit Ave', city: 'St Paul', province: 'MN', postalCode: '55105', country: 'United States' } }));

        const btn = el.shadowRoot.querySelector('lightning-button');
        btn.click();
        await flushPromises();

        expect(submitRFILead).toHaveBeenCalledTimes(1);
        const payload = submitRFILead.mock.calls[0][0].leadRecord;
        expect(payload.Street).toBe('2115 Summit Ave');
        expect(payload.City).toBe('St Paul');
        expect(payload.State).toBe('MN');
        expect(payload.PostalCode).toBe('55105');
        expect(payload.Country).toBe('United States');
    });
});
