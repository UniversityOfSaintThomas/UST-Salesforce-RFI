import {
    applyFieldAnswer,
    composeDescription,
    EMAIL_PATTERN,
    fieldsWrittenBy,
    hiddenQuestions,
    isEmptyAnswer,
    isQuestionShown,
    isValidEmail,
    isValidPhone,
    PHONE_PATTERN,
    toSemicolonList,
    withAnswer,
    withMajorPrograms,
    withoutHiddenAnswers
} from '../rfiFormUtils';

describe('isValidPhone', () => {
    it.each([
        '612-555-0100',
        '(612) 555-0100',
        '612.555.0100',
        '6125550100',
        '+1 612 555 0100',
        '+44 20 7946 0958',
        '+61 (0)2 9876 5432',
        '612-555-0100 x123',
        '612-555-0100 ext. 45',
        '612-555-0100 EXT45'
    ])('accepts %s', (value) => {
        expect(isValidPhone(value)).toBe(true);
    });

    it.each([
        '1-800-FLOWERS',
        'abc',
        '612-555-0100 please call',
        '555-01',
        '+1 612 555 0100 1234 5678 9',
        '612#555#0100',
        '612-555-0100 x',
        '612-555-0100 x1234567',
        '++16125550100',
        '()-. ',
        '16125550100@'
    ])('rejects %s', (value) => {
        expect(isValidPhone(value)).toBe(false);
    });

    it('lets a blank answer through, because required is checked separately', () => {
        expect(isValidPhone('')).toBe(true);
        expect(isValidPhone(undefined)).toBe(true);
    });

    it('is a pattern the browser accepts with the unicode sets flag', () => {
        // The input's pattern attribute is compiled by the browser with the "v" flag.
        expect(() => new RegExp('^(?:' + PHONE_PATTERN + ')$', 'v')).not.toThrow();
        expect(new RegExp('^(?:' + PHONE_PATTERN + ')$', 'v').test('+1 (612) 555-0100 x12')).toBe(true);
        expect(new RegExp('^(?:' + PHONE_PATTERN + ')$', 'v').test('1-800-FLOWERS')).toBe(false);
    });
});

describe('isValidEmail', () => {
    it.each([
        'name@domain.com',
        'first.last@sub.domain.edu',
        'first+tag@stthomas.edu',
        "o'brien@domain.org",
        'a_b-c@my-domain.co.uk'
    ])('accepts %s', (value) => {
        expect(isValidEmail(value)).toBe(true);
    });

    it.each([
        'name@domain',
        'name@domain.',
        'name@.com',
        'name@domain.c',
        'name@domain.123',
        'name domain@domain.com',
        '@domain.com',
        'name@-domain.com',
        'name@@domain.com',
        'name'
    ])('rejects %s', (value) => {
        expect(isValidEmail(value)).toBe(false);
    });

    it('lets a blank answer through, because required is checked separately', () => {
        expect(isValidEmail('')).toBe(true);
        expect(isValidEmail(null)).toBe(true);
    });

    it('is a pattern the browser accepts with the unicode sets flag', () => {
        expect(() => new RegExp('^(?:' + EMAIL_PATTERN + ')$', 'v')).not.toThrow();
        expect(new RegExp('^(?:' + EMAIL_PATTERN + ')$', 'v').test('name@domain.com')).toBe(true);
        expect(new RegExp('^(?:' + EMAIL_PATTERN + ')$', 'v').test('name@domain')).toBe(false);
    });
});

describe('isEmptyAnswer', () => {
    it('treats missing and blank text as empty', () => {
        expect(isEmptyAnswer(undefined)).toBe(true);
        expect(isEmptyAnswer(null)).toBe(true);
        expect(isEmptyAnswer('')).toBe(true);
        expect(isEmptyAnswer('   ')).toBe(true);
    });

    it('treats false and zero as real answers', () => {
        expect(isEmptyAnswer(false)).toBe(false);
        expect(isEmptyAnswer(0)).toBe(false);
        expect(isEmptyAnswer('x')).toBe(false);
    });
});

describe('toSemicolonList', () => {
    it('joins an array of choices with semicolons, which is what Salesforce stores', () => {
        expect(toSemicolonList(['GHR Fellows', 'Schulze Innovation'])).toBe('GHR Fellows;Schulze Innovation');
    });

    it('drops blank choices, and gives an empty string for an empty selection', () => {
        expect(toSemicolonList(['Friend', ''])).toBe('Friend');
        expect(toSemicolonList([''])).toBe('');
        expect(toSemicolonList([])).toBe('');
        expect(toSemicolonList(undefined)).toBe('');
    });

    it('leaves text that is already joined alone', () => {
        expect(toSemicolonList('A;B')).toBe('A;B');
    });
});

describe('withAnswer', () => {
    it('returns a new object and does not change the original', () => {
        const original = { First_Name__c: 'Ada' };
        const next = withAnswer(original, 'Heard_About_Us__c', 'Friend');
        expect(next).toEqual({ First_Name__c: 'Ada', Heard_About_Us__c: 'Friend' });
        expect(original).toEqual({ First_Name__c: 'Ada' });
    });

    it('removes the key when the answer is empty', () => {
        expect(withAnswer({ Heard_About_Us__c: 'Friend' }, 'Heard_About_Us__c', '')).toEqual({});
    });

    it('ignores a missing field name', () => {
        expect(withAnswer({ a: 1 }, undefined, 'x')).toEqual({ a: 1 });
    });
});

describe('applyFieldAnswer', () => {
    it('a blank box never overwrites a real answer from an earlier box for the same field', () => {
        const target = {};
        const answered = new Set();
        applyFieldAnswer(target, {}, answered, 'High_School_Graduation_Year__c', '2028');
        applyFieldAnswer(target, {}, answered, 'High_School_Graduation_Year__c', '');
        expect(target.High_School_Graduation_Year__c).toBe('2028');
    });

    it('works in either order', () => {
        const target = {};
        const answered = new Set();
        applyFieldAnswer(target, {}, answered, 'Mobile_Phone__c', '');
        applyFieldAnswer(target, {}, answered, 'Mobile_Phone__c', '6515550100');
        expect(target.Mobile_Phone__c).toBe('6515550100');
    });

    it('a blank box goes back to the controller default, as for the Employer', () => {
        const target = { Employer__c: 'typed earlier then cleared' };
        applyFieldAnswer(target, { Employer__c: 'No Company' }, new Set(), 'Employer__c', '');
        expect(target.Employer__c).toBe('No Company');
    });

    it('a blank box with no default leaves the field out, even if it was typed on an earlier pass', () => {
        const target = { Title__c: 'stale' };
        applyFieldAnswer(target, {}, new Set(), 'Title__c', '');
        expect('Title__c' in target).toBe(false);
    });

    it('keeps a ticked or unticked checkbox', () => {
        const target = {};
        applyFieldAnswer(target, {}, new Set(), 'Has_Question__c', false);
        expect(target.Has_Question__c).toBe(false);
    });
});

describe('composeDescription', () => {
    it('uses the old form headings for both answers, question first', () => {
        expect(composeDescription('Is there housing?', 'I love biology')).toBe(
            'Questions/Comments from RFI: \nIs there housing?\n\nTell us about yourself from RFI: \nI love biology'
        );
    });

    it('keeps each answer under its own heading when only one is given', () => {
        expect(composeDescription('', 'I love biology')).toBe('Tell us about yourself from RFI: \nI love biology');
        expect(composeDescription('Is there housing?', '')).toBe('Questions/Comments from RFI: \nIs there housing?');
    });

    it('is empty when neither answer is given', () => {
        expect(composeDescription('', '  ')).toBe('');
    });
});

describe('withMajorPrograms', () => {
    it('fills Major_Program_1__c to Major_Program_4__c in order', () => {
        const result = withMajorPrograms({ Last_Name__c: 'Lovelace' }, ['a1', 'a2', 'a3', 'a4']);
        expect(result).toEqual({
            Last_Name__c: 'Lovelace',
            Major_Program_1__c: 'a1',
            Major_Program_2__c: 'a2',
            Major_Program_3__c: 'a3',
            Major_Program_4__c: 'a4'
        });
    });

    it('clears the fields with no choice, so a shorter selection leaves no old value behind', () => {
        const before = { Major_Program_1__c: 'a1', Major_Program_2__c: 'a2', Major_Program_3__c: 'a3', Major_Program_4__c: 'a4' };
        const result = withMajorPrograms(before, ['b1']);
        expect(result.Major_Program_1__c).toBe('b1');
        expect(result.Major_Program_2__c).toBe('');
        expect(result.Major_Program_3__c).toBe('');
        expect(result.Major_Program_4__c).toBe('');
    });

    it('clears all four when the selection is emptied (F14)', () => {
        const before = { Major_Program_1__c: 'a1', Major_Program_2__c: 'a2' };
        const result = withMajorPrograms(before, []);
        expect(result.Major_Program_1__c).toBe('');
        expect(result.Major_Program_2__c).toBe('');
        expect(result.Major_Program_3__c).toBe('');
        expect(result.Major_Program_4__c).toBe('');
    });

    it('does not change the object it was given', () => {
        const before = { Major_Program_1__c: 'a1' };
        withMajorPrograms(before, []);
        expect(before.Major_Program_1__c).toBe('a1');
    });
});

const picklistRule = (field, values, parent = 'Citizenship__c') => ({
    fieldInteractionAPIName: field, visibleWhenField: parent, visibleWhenKind: 'picklist', visibleWhenValues: values
});
const checkboxRule = (field, values, parent = 'Has_Question__c') => ({
    fieldInteractionAPIName: field, visibleWhenField: parent, visibleWhenKind: 'checkbox', visibleWhenValues: values
});

describe('isQuestionShown', () => {
    it('always shows a question with no rule', () => {
        expect(isQuestionShown({ fieldInteractionAPIName: 'Employer__c' }, {})).toBe(true);
        expect(isQuestionShown(undefined, {})).toBe(true);
    });

    it('shows a question only for the revealing answers', () => {
        const field = picklistRule('Employer__c', ['International', 'Other']);
        expect(isQuestionShown(field, { Citizenship__c: 'International' })).toBe(true);
        expect(isQuestionShown(field, { Citizenship__c: 'Other' })).toBe(true);
        expect(isQuestionShown(field, { Citizenship__c: 'US Citizen' })).toBe(false);
    });

    it('hides the question until the earlier one is answered', () => {
        const field = picklistRule('Employer__c', ['International']);
        expect(isQuestionShown(field, {})).toBe(false);
        expect(isQuestionShown(field, { Citizenship__c: '' })).toBe(false);
        expect(isQuestionShown(field, { Citizenship__c: null })).toBe(false);
        expect(isQuestionShown(field, undefined)).toBe(false);
    });

    it('matches answers exactly, not by upper or lower case', () => {
        expect(isQuestionShown(picklistRule('E__c', ['International']), { Citizenship__c: 'international' })).toBe(false);
    });

    it('reads an untouched tick box as not checked', () => {
        expect(isQuestionShown(checkboxRule('E__c', ['false']), {})).toBe(true);
        expect(isQuestionShown(checkboxRule('E__c', ['true']), {})).toBe(false);
    });

    it('reads a ticked and an unticked box', () => {
        expect(isQuestionShown(checkboxRule('E__c', ['true']), { Has_Question__c: true })).toBe(true);
        expect(isQuestionShown(checkboxRule('E__c', ['true']), { Has_Question__c: false })).toBe(false);
        expect(isQuestionShown(checkboxRule('E__c', ['false']), { Has_Question__c: false })).toBe(true);
    });

    it('does not treat the text "true" as a ticked box', () => {
        expect(isQuestionShown(checkboxRule('E__c', ['true']), { Has_Question__c: 'true' })).toBe(false);
    });

    it('a rule with no revealing answers never shows the question', () => {
        expect(isQuestionShown(picklistRule('E__c', undefined), { Citizenship__c: 'x' })).toBe(false);
        expect(isQuestionShown(picklistRule('E__c', []), { Citizenship__c: 'x' })).toBe(false);
    });
});

describe('fieldsWrittenBy', () => {
    it('is the question field, lower case', () => {
        expect(fieldsWrittenBy({ fieldInteractionAPIName: 'Employer__c' })).toEqual(['employer__c']);
    });
    it('adds the address, school, program and question-box fields', () => {
        expect(fieldsWrittenBy({ fieldInteractionAPIName: 'Mailing_Street__c', isAddress: true })).toEqual(expect.arrayContaining(['mailing_city__c', 'state__c']));
        expect(fieldsWrittenBy({ fieldInteractionAPIName: 'High_School_or_College__c', isSchoolLookup: true })).toContain('school_name_text__c');
        expect(fieldsWrittenBy({ fieldInteractionAPIName: 'Major_Program_1__c', isProgramLookup: true })).toEqual(expect.arrayContaining(['major_program_4__c']));
        expect(fieldsWrittenBy({ fieldInteractionAPIName: 'Has_Question__c', showDependentField: true })).toEqual(expect.arrayContaining(['has_question__c', 'description__c']));
    });
    it('copes with a field that has no name', () => {
        expect(fieldsWrittenBy({})).toEqual([]);
    });
});

describe('hiddenQuestions', () => {
    it('lists the questions whose rule is not met', () => {
        const shown = { fieldInteractionAPIName: 'Citizenship__c' };
        const hidden = picklistRule('Employer__c', ['International']);
        expect(hiddenQuestions([shown, hidden], { Citizenship__c: 'US Citizen' })).toEqual([hidden]);
        expect(hiddenQuestions([shown, hidden], { Citizenship__c: 'International' })).toEqual([]);
        expect(hiddenQuestions(undefined, {})).toEqual([]);
    });
});

describe('withoutHiddenAnswers', () => {
    const fields = [
        { fieldInteractionAPIName: 'Citizenship__c' },
        picklistRule('Employer__c', ['International'])
    ];

    it('throws away the answer to a hidden question and keeps the rest', () => {
        const result = withoutHiddenAnswers({ Citizenship__c: 'US Citizen', Employer__c: 'typed', Email__c: 'a@b.c' }, fields);
        expect(result).toEqual({ Citizenship__c: 'US Citizen', Email__c: 'a@b.c' });
    });

    it('returns the same object when nothing is hidden or nothing was answered', () => {
        const answers = { Citizenship__c: 'International', Employer__c: 'typed' };
        expect(withoutHiddenAnswers(answers, fields)).toBe(answers);
        const unanswered = { Citizenship__c: 'US Citizen' };
        expect(withoutHiddenAnswers(unanswered, fields)).toBe(unanswered);
    });

    it('does not change the object it was given', () => {
        const answers = { Citizenship__c: 'US Citizen', Employer__c: 'typed' };
        withoutHiddenAnswers(answers, fields);
        expect(answers.Employer__c).toBe('typed');
    });

    it('keeps a field that a visible question also saves to', () => {
        const both = [...fields, { fieldInteractionAPIName: 'Employer__c' }];
        expect(withoutHiddenAnswers({ Citizenship__c: 'US Citizen', Employer__c: 'typed' }, both).Employer__c).toBe('typed');
    });

    it('a visible static note does not count as a question that saves the field', () => {
        const withNote = [...fields, { fieldInteractionAPIName: 'Employer__c', isStaticContent: true }];
        expect(withoutHiddenAnswers({ Citizenship__c: 'US Citizen', Employer__c: 'typed' }, withNote).Employer__c).toBeUndefined();
    });

    it('clears every address field when the address is hidden', () => {
        const address = { ...picklistRule('Mailing_Street__c', ['International']), isAddress: true };
        const result = withoutHiddenAnswers({ Citizenship__c: 'US Citizen', Mailing_Street__c: '1', Mailing_City__c: 'c', State__c: 'MN', Mailing_Postal_Code__c: '5' }, [fields[0], address]);
        expect(result).toEqual({ Citizenship__c: 'US Citizen' });
    });

    it('compares field names without regard to upper and lower case', () => {
        expect(withoutHiddenAnswers({ Citizenship__c: 'US Citizen', EMPLOYER__C: 'typed' }, fields).EMPLOYER__C).toBeUndefined();
    });

    it('copes with no answers and no fields', () => {
        expect(withoutHiddenAnswers(undefined, fields)).toBeUndefined();
        expect(withoutHiddenAnswers({ a: 1 }, undefined)).toEqual({ a: 1 });
    });
});
