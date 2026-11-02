import {
    applyFieldAnswer,
    composeDescription,
    isEmptyAnswer,
    toSemicolonList,
    withAnswer,
    withMajorPrograms
} from '../rfiFormUtils';

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
