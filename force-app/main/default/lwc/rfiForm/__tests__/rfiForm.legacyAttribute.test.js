import { createElement } from 'lwc';
import RfiForm from 'c/rfiForm';
import getRFIForm from '@salesforce/apex/rfiFormController.getRFIForm';

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

async function mount(properties) {
    const element = createElement('c-rfi-form', { is: RfiForm });
    Object.assign(element, properties);
    document.body.appendChild(element);
    await flushPromises();
    return element;
}

describe('c-rfi-form legacy rfi_controller attribute', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('loads the form for the controller named by the legacy rfi_controller attribute', async () => {
        await mount({ rfi_controller: 'RFI Controller 0001' });

        expect(getRFIForm.getLastConfig()).toEqual({ rfiControllerName: 'RFI Controller 0001' });
    });

    it('still loads the form for the rfiControllerName attribute', async () => {
        await mount({ rfiControllerName: 'RFI Controller 0002' });

        expect(getRFIForm.getLastConfig()).toEqual({ rfiControllerName: 'RFI Controller 0002' });
    });

    it('prefers rfiControllerName when both attributes are given', async () => {
        await mount({ rfiControllerName: 'RFI Controller 0002', rfi_controller: 'RFI Controller 0001' });

        expect(getRFIForm.getLastConfig()).toEqual({ rfiControllerName: 'RFI Controller 0002' });
    });
});
