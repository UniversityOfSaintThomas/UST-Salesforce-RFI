import { createElement } from 'lwc';
import RfiAdditionalQuestionsInteractions from 'c/rfiAdditionalQuestionsInteractions';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { updateRecord } from 'lightning/uiRecordApi';

// Mock Lightning modules
jest.mock('lightning/uiRecordApi');
jest.mock('lightning/uiObjectInfoApi');

const mockRecordId = 'a00xx0000000001AAA';

const mockInteractionObjectInfo = {
    data: {
        fields: {
            Custom_Field__c: {
                label: 'Custom Field',
                dataType: 'String',
                updateable: true,
                createable: true
            },
            Email_Field__c: {
                label: 'Email Field',
                dataType: 'Email',
                updateable: true,
                createable: true
            },
            UTM_Source__c: {
                label: 'UTM Source',
                dataType: 'String',
                updateable: true,
                createable: true
            }
        }
    }
};

const mockQuestionsData = [
    {
        id: 0,
        questionLabel: 'Test Question',
        questionType: 'Text box',
        fieldToApplyTo: 'Custom_Field__c',
        assistiveText: '',
        position: 'top',
        isPicklist: false,
        isRequired: false,
        isTextBox: true,
        isTextarea: false,
        isRichText: false,
        isStaticContent: false,
        isEmail: false,
        picklistValues: [],
        valuesFlat: ''
    }
];

describe('c-rfi-additional-questions-interactions', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('should render component', () => {
        const element = createElement('c-rfi-additional-questions-interactions', {
            is: RfiAdditionalQuestionsInteractions
        });
        element.recordId = mockRecordId;
        document.body.appendChild(element);

        expect(element).toBeTruthy();
    });

    it('should display add question button', () => {
        const element = createElement('c-rfi-additional-questions-interactions', {
            is: RfiAdditionalQuestionsInteractions
        });
        document.body.appendChild(element);

        const button = element.shadowRoot.querySelector('lightning-button[label="Add Question"]');
        expect(button).toBeTruthy();
    });

    it('should open modal when add button clicked', () => {
        const element = createElement('c-rfi-additional-questions-interactions', {
            is: RfiAdditionalQuestionsInteractions
        });
        document.body.appendChild(element);

        const button = element.shadowRoot.querySelector('lightning-button[label="Add Question"]');
        button.click();

        return Promise.resolve().then(() => {
            const modal = element.shadowRoot.querySelector('.slds-modal');
            expect(modal).toBeTruthy();
        });
    });

    it('should close modal when cancel clicked', () => {
        const element = createElement('c-rfi-additional-questions-interactions', {
            is: RfiAdditionalQuestionsInteractions
        });
        document.body.appendChild(element);

        // Open modal
        element.showModal = true;

        return Promise.resolve().then(() => {
            const cancelButton = element.shadowRoot.querySelector('lightning-button[label="Cancel"]');
            cancelButton.click();

            return Promise.resolve().then(() => {
                const modal = element.shadowRoot.querySelector('.slds-modal');
                expect(modal).toBeFalsy();
            });
        });
    });

    it('should filter out UTM fields from interaction fields list', () => {
        const element = createElement('c-rfi-additional-questions-interactions', {
            is: RfiAdditionalQuestionsInteractions
        });
        element.interactionObjectInfo = mockInteractionObjectInfo;
        element.inputItem = {
            isTextBox: true,
            isTextarea: false,
            isPicklist: false,
            isEmail: false
        };
        document.body.appendChild(element);

        const fields = element.interactionFields;
        const utmField = fields.find(f => f.value === 'UTM_Source__c');
        expect(utmField).toBeUndefined();
    });

    it('should display questions list when data exists', async () => {
        getRecord.mockResolvedValue({
            fields: {
                Interaction_Questions__c: {
                    value: JSON.stringify(mockQuestionsData)
                }
            }
        });

        const element = createElement('c-rfi-additional-questions-interactions', {
            is: RfiAdditionalQuestionsInteractions
        });
        element.recordId = mockRecordId;
        document.body.appendChild(element);

        element.questionJSON = mockQuestionsData;
        element.showDataTable = true;

        return Promise.resolve().then(() => {
            const questionItems = element.shadowRoot.querySelectorAll('.question-item');
            expect(questionItems.length).toBe(1);
        });
    });

    it('should handle drag start event', () => {
        const element = createElement('c-rfi-additional-questions-interactions', {
            is: RfiAdditionalQuestionsInteractions
        });
        element.questionJSON = mockQuestionsData;
        element.showDataTable = true;
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const questionItem = element.shadowRoot.querySelector('.question-item');
            const event = new DragEvent('dragstart', {
                bubbles: true,
                cancelable: true
            });
            Object.defineProperty(event, 'currentTarget', {
                value: { dataset: { id: '0' }, classList: { add: jest.fn() } }
            });

            questionItem.dispatchEvent(event);
            expect(element.draggedItemId).toBe(0);
        });
    });

    it('should move question up', async () => {
        updateRecord.mockResolvedValue({});

        const multipleQuestions = [
            { ...mockQuestionsData[0], id: 0 },
            { ...mockQuestionsData[0], id: 1, questionLabel: 'Second Question' }
        ];

        const element = createElement('c-rfi-additional-questions-interactions', {
            is: RfiAdditionalQuestionsInteractions
        });
        element.recordId = mockRecordId;
        element.questionJSON = multipleQuestions;
        element.showDataTable = true;
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const upButtons = element.shadowRoot.querySelectorAll('lightning-button-icon[icon-name="utility:arrowup"]');
            const event = new CustomEvent('click');
            Object.defineProperty(event, 'currentTarget', {
                value: { dataset: { id: '1' } }
            });

            upButtons[1].dispatchEvent(event);

            return Promise.resolve().then(() => {
                expect(updateRecord).toHaveBeenCalled();
            });
        });
    });

    it('should move question down', async () => {
        updateRecord.mockResolvedValue({});

        const multipleQuestions = [
            { ...mockQuestionsData[0], id: 0 },
            { ...mockQuestionsData[0], id: 1, questionLabel: 'Second Question' }
        ];

        const element = createElement('c-rfi-additional-questions-interactions', {
            is: RfiAdditionalQuestionsInteractions
        });
        element.recordId = mockRecordId;
        element.questionJSON = multipleQuestions;
        element.showDataTable = true;
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const downButtons = element.shadowRoot.querySelectorAll('lightning-button-icon[icon-name="utility:arrowdown"]');
            const event = new CustomEvent('click');
            Object.defineProperty(event, 'currentTarget', {
                value: { dataset: { id: '0' } }
            });

            downButtons[0].dispatchEvent(event);

            return Promise.resolve().then(() => {
                expect(updateRecord).toHaveBeenCalled();
            });
        });
    });

    it('should delete question', async () => {
        updateRecord.mockResolvedValue({});

        const element = createElement('c-rfi-additional-questions-interactions', {
            is: RfiAdditionalQuestionsInteractions
        });
        element.recordId = mockRecordId;
        element.questionJSON = [...mockQuestionsData];
        element.showDataTable = true;
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const deleteButton = element.shadowRoot.querySelector('lightning-button-icon[icon-name="utility:delete"]');
            const event = new CustomEvent('click');
            Object.defineProperty(event, 'currentTarget', {
                value: { dataset: { id: '0' } }
            });

            deleteButton.dispatchEvent(event);

            return Promise.resolve().then(() => {
                expect(updateRecord).toHaveBeenCalled();
            });
        });
    });

    it('should update question type flags when type changes', () => {
        const element = createElement('c-rfi-additional-questions-interactions', {
            is: RfiAdditionalQuestionsInteractions
        });
        document.body.appendChild(element);

        const event = {
            target: {
                name: 'questionType',
                value: 'Picklist required'
            }
        };

        element.handleChange(event);

        expect(element.inputItem.isPicklist).toBe(true);
        expect(element.inputItem.isRequired).toBe(true);
        expect(element.inputItem.questionType).toBe('Picklist required');
    });

    it('should parse picklist values correctly', () => {
        const element = createElement('c-rfi-additional-questions-interactions', {
            is: RfiAdditionalQuestionsInteractions
        });
        document.body.appendChild(element);

        const event = {
            target: {
                name: 'picklistValues',
                value: 'Option 1\nOption 2\n\nOption 3'
            }
        };

        element.handleChange(event);

        expect(element.inputItem.picklistValues.length).toBe(3);
        expect(element.inputItem.valuesFlat).toBe('Option 1;Option 2;;Option 3');
    });
});

