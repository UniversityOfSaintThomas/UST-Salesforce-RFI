import { answerChoices, canHaveRule, describeRule, eligibleParents, ruleProblems } from '../visibilityRules';

const DATA_TYPES = {
    Citizenship__c: 'picklist',
    Mailed_Program_Information_Requested__c: 'boolean',
    Email__c: 'email',
    Intended_Start_Term__c: 'reference',
    Heard_About_Us__c: 'multipicklist',
    Employer__c: 'string'
};
const LIVE = {
    Citizenship__c: [
        { label: 'US Citizen', value: 'US Citizen' },
        { label: 'International', value: 'International' },
        { label: 'Other', value: 'Other' }
    ]
};
const context = {
    fieldDataType: (apiName) => DATA_TYPES[apiName],
    livePicklist: (apiName) => LIVE[apiName]
};

const first = { key: 'q1', type: 'preconfigured', fieldName: 'First Name', questionLabel: 'First Name', fieldInteractionAPIName: 'First_Name__c' };
const citizenship = { key: 'q2', type: 'preconfigured', fieldName: 'Citizenship', questionLabel: 'Citizenship', fieldInteractionAPIName: 'Citizenship__c' };
const email = { key: 'q3', type: 'preconfigured', fieldName: 'Email', questionLabel: 'Email', fieldInteractionAPIName: 'Email__c' };
const tickBox = { key: 'q4', type: 'custom', questionLabel: 'Send me mail', questionType: 'Checkbox', fieldToApplyTo: 'Mailed_Program_Information_Requested__c' };
const filter = { key: 'q5', type: 'filter', questionLabel: 'Degree', filterControllerField: 'Degree_Types_To_Display__c' };
const visa = (rule) => ({ key: 'q6', type: 'custom', questionLabel: 'Visa status', questionType: 'Text box', fieldToApplyTo: 'Employer__c', ...(rule ? { visibleWhen: rule } : {}) });

describe('canHaveRule', () => {
    it('allows ordinary questions', () => {
        expect(canHaveRule(citizenship)).toBe(true);
        expect(canHaveRule(visa())).toBe(true);
        expect(canHaveRule({ type: 'custom', questionType: 'Static content' })).toBe(true);
    });
    it('does not allow program filters or the name questions', () => {
        expect(canHaveRule(filter)).toBe(false);
        expect(canHaveRule(first)).toBe(false);
        expect(canHaveRule({ type: 'preconfigured', fieldName: 'Last Name' })).toBe(false);
    });
    it('does not allow nothing', () => {
        expect(canHaveRule(undefined)).toBe(false);
    });
});

describe('answerChoices', () => {
    it('gives the live values of a picklist question', () => {
        const choices = answerChoices(citizenship, context);
        expect(choices.kind).toBe('picklist');
        expect(choices.options.map((o) => o.value)).toEqual(['US Citizen', 'International', 'Other']);
    });
    it('gives Checked and Not checked for a tick box, with the values the form compares', () => {
        const choices = answerChoices(tickBox, context);
        expect(choices.kind).toBe('checkbox');
        expect(choices.options.map((o) => o.value)).toEqual(['true', 'false']);
    });
    it('treats a built-in question that saves to a true or false field as a tick box', () => {
        const hasQuestion = { type: 'preconfigured', fieldName: 'Mailed', fieldInteractionAPIName: 'Mailed_Program_Information_Requested__c' };
        expect(answerChoices(hasQuestion, context).kind).toBe('checkbox');
    });
    it('uses the typed values of a custom picklist that is not tied to a picklist field', () => {
        const typed = { type: 'custom', questionType: 'Picklist required', fieldToApplyTo: 'Employer__c', picklistValues: [{ label: 'A', value: 'A' }, { label: 'B', value: 'B' }] };
        expect(answerChoices(typed, context).options.map((o) => o.value)).toEqual(['A', 'B']);
    });
    it('uses the live values of a custom picklist that is tied to a picklist field, not its saved copy', () => {
        const mapped = { type: 'custom', questionType: 'Picklist', fieldToApplyTo: 'Citizenship__c', picklistValues: [{ label: 'Old', value: 'Old' }] };
        expect(answerChoices(mapped, context).options.map((o) => o.value)).toEqual(['US Citizen', 'International', 'Other']);
    });
    it('has no answers when the live values have not loaded yet', () => {
        const empty = { fieldDataType: () => 'picklist', livePicklist: () => undefined };
        expect(answerChoices(citizenship, empty).options).toEqual([]);
    });
    it('cannot be used when the answer is text, a record, several choices, a filter, or nothing', () => {
        expect(answerChoices(email, context)).toBeNull();
        expect(answerChoices({ type: 'preconfigured', fieldInteractionAPIName: 'Intended_Start_Term__c' }, context)).toBeNull();
        expect(answerChoices({ type: 'preconfigured', fieldInteractionAPIName: 'Heard_About_Us__c' }, context)).toBeNull();
        expect(answerChoices(filter, context)).toBeNull();
        expect(answerChoices(visa(), context)).toBeNull();
        expect(answerChoices({ type: 'custom', questionType: 'Static content' }, context)).toBeNull();
        expect(answerChoices({ type: 'preconfigured' }, context)).toBeNull();
        expect(answerChoices(undefined, context)).toBeNull();
    });
});

describe('answerChoices by field data type', () => {
    const everyType = ['address', 'anytype', 'base64', 'boolean', 'combobox', 'complexvalue', 'currency', 'date', 'datetime', 'double', 'email',
        'encryptedstring', 'int', 'long', 'multipicklist', 'percent', 'phone', 'picklist', 'reference', 'string', 'textarea', 'time', 'url'];

    it('only a picklist or a true-or-false field can be the earlier question of a built-in question', () => {
        const qualifying = everyType.filter((dataType) => {
            const typed = { fieldDataType: () => dataType, livePicklist: () => [{ label: 'A', value: 'A' }] };
            return answerChoices({ type: 'preconfigured', fieldInteractionAPIName: 'Some_Field__c' }, typed) !== null;
        });
        expect(qualifying).toEqual(['boolean', 'picklist']);
    });

    it('a custom question mapped to a field that is not a picklist uses its own typed values, whatever the field type', () => {
        const typed = { fieldDataType: () => 'string', livePicklist: () => undefined };
        const choices = answerChoices({ type: 'custom', questionType: 'Picklist', fieldToApplyTo: 'Some_Field__c', picklistValues: [{ label: 'A', value: 'A' }] }, typed);
        expect(choices.options.map((o) => o.value)).toEqual(['A']);
    });
});

describe('eligibleParents', () => {
    const list = [first, citizenship, email, tickBox, filter, visa()];

    it('offers earlier picklist and tick box questions only', () => {
        const parents = eligibleParents(list, 5, context);
        expect(parents.map((p) => p.key)).toEqual(['q2', 'q4']);
        expect(parents[0].kind).toBe('picklist');
        expect(parents[1].kind).toBe('checkbox');
    });
    it('offers nothing that comes after the question', () => {
        expect(eligibleParents(list, 1, context)).toEqual([]);
        expect(eligibleParents(list, 3, context).map((p) => p.key)).toEqual(['q2']);
    });
    it('offers every earlier qualifying question to a new question at the end of the list', () => {
        expect(eligibleParents(list, list.length, context).map((p) => p.key)).toEqual(['q2', 'q4']);
    });
    it('leaves out a question that has a rule of its own', () => {
        const dependent = { ...tickBox, visibleWhen: { key: 'q2', equals: ['Other'] } };
        expect(eligibleParents([citizenship, dependent, visa()], 2, context).map((p) => p.key)).toEqual(['q2']);
    });
    it('leaves out a question that has no key', () => {
        const keyless = { ...citizenship, key: undefined };
        expect(eligibleParents([keyless, visa()], 1, context)).toEqual([]);
    });
    it('names each parent by its label', () => {
        expect(eligibleParents(list, 5, context)[0].label).toBe('Citizenship');
    });
    it('copes with no list', () => {
        expect(eligibleParents(undefined, 0, context)).toEqual([]);
    });
});

describe('describeRule', () => {
    it('says nothing for a question with no rule', () => {
        expect(describeRule(visa(), [citizenship, visa()], context)).toBe('');
    });
    it('describes the rule with the labels people see, not the stored values', () => {
        const relabelled = { ...citizenship, questionLabel: 'Your citizenship' };
        const text = describeRule(visa({ key: 'q2', equals: ['International', 'Other'] }), [relabelled, visa()], context);
        expect(text).toBe('Shown only when "Your citizenship" is International or Other');
    });
    it('describes a tick box rule in words', () => {
        expect(describeRule(visa({ key: 'q4', equals: ['true'] }), [tickBox], context)).toBe('Shown only when "Send me mail" is Checked');
    });
    it('says so when the earlier question is gone', () => {
        expect(describeRule(visa({ key: 'qgone', equals: ['x'] }), [citizenship], context)).toContain('no longer exists');
    });
    it('shows an answer that is no longer a choice as it was saved', () => {
        expect(describeRule(visa({ key: 'q2', equals: ['Retired'] }), [citizenship], context)).toContain('Retired');
    });
});

describe('ruleProblems', () => {
    it('finds nothing wrong with a rule that can work', () => {
        expect(ruleProblems([citizenship, visa({ key: 'q2', equals: ['International'] })], context)).toEqual([]);
        expect(ruleProblems([citizenship, visa()], context)).toEqual([]);
        expect(ruleProblems(undefined, context)).toEqual([]);
    });
    it('finds a rule whose earlier question was removed', () => {
        const problems = ruleProblems([visa({ key: 'qgone', equals: ['x'] })], context);
        expect(problems).toHaveLength(1);
        expect(problems[0]).toContain('"Visa status"');
        expect(problems[0]).toContain('removed');
    });
    it('finds a question moved above the one it depends on', () => {
        const problems = ruleProblems([visa({ key: 'q2', equals: ['Other'] }), citizenship], context);
        expect(problems).toHaveLength(1);
        expect(problems[0]).toContain('must come after');
    });
    it('finds a question that depends on itself', () => {
        expect(ruleProblems([visa({ key: 'q6', equals: ['x'] })], context)[0]).toContain('must come after');
    });
    it('finds a chain', () => {
        const middle = { ...tickBox, visibleWhen: { key: 'q2', equals: ['Other'] } };
        const problems = ruleProblems([citizenship, middle, visa({ key: 'q4', equals: ['true'] })], context);
        expect(problems).toHaveLength(1);
        expect(problems[0]).toContain('Only one level');
    });
    it('finds a rule that depends on something that is not a list or tick box', () => {
        const problems = ruleProblems([email, visa({ key: 'q3', equals: ['a@b.c'] })], context);
        expect(problems[0]).toContain('not a choice from a list or a tick box');
    });
    it('finds a rule with no answers chosen', () => {
        expect(ruleProblems([citizenship, visa({ key: 'q2', equals: [] })], context)[0]).toContain('no answers chosen');
        expect(ruleProblems([citizenship, visa({ key: 'q2' })], context)[0]).toContain('no answers chosen');
    });
    it('finds an answer the earlier question no longer has', () => {
        const problems = ruleProblems([citizenship, visa({ key: 'q2', equals: ['International', 'Retired'] })], context);
        expect(problems).toHaveLength(1);
        expect(problems[0]).toContain('Retired');
        expect(problems[0]).not.toContain('International or');
    });
    it('does not complain about answers while the choices are still loading', () => {
        const loading = { fieldDataType: (apiName) => DATA_TYPES[apiName], livePicklist: () => undefined };
        expect(ruleProblems([citizenship, visa({ key: 'q2', equals: ['International'] })], loading)).toEqual([]);
    });
    it('finds a rule on a program filter or a name question', () => {
        expect(ruleProblems([citizenship, { ...filter, visibleWhen: { key: 'q2', equals: ['Other'] } }], context)[0]).toContain('cannot be hidden');
        expect(ruleProblems([citizenship, { ...first, visibleWhen: { key: 'q2', equals: ['Other'] } }], context)[0]).toContain('cannot be hidden');
    });
    it('reports every problem, one per question', () => {
        const problems = ruleProblems([
            visa({ key: 'qgone', equals: ['x'] }),
            { ...tickBox, visibleWhen: { key: 'q2', equals: [] } }
        ], context);
        expect(problems).toHaveLength(2);
    });
});
