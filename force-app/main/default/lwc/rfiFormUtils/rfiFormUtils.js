/**
 * Small helpers for the RFI form that decide how typed answers become the Interaction that is submitted.
 * They are plain functions so they can be tested without rendering the component.
 */

/**
 * Loose phone number pattern for the phone questions. It allows an optional leading plus (international), 7 to 15
 * digits, and the separators people type (spaces, dots, dashes, parentheses). The only letters allowed are an
 * extension marker at the end: "x" or "ext" followed by up to 6 digits. The browser anchors the pattern to the whole
 * answer, so there are no ^ and $ around it here.
 */
export const PHONE_PATTERN = '\\+?(?=(?:[ \\(\\)\\.\\-]*[0-9]){7,15}[ \\(\\)\\.\\-]*(?:[ ]?(?:[xX]|[eE][xX][tT]\\.?)[ ]?[0-9]{1,6})?$)'
    + '[0-9 \\(\\)\\.\\-]+(?:[ ]?(?:[xX]|[eE][xX][tT]\\.?)[ ]?[0-9]{1,6})?';

/**
 * Email pattern for the email questions. It needs name@domain.suffix: at least one dot in the domain and a letters-only
 * suffix of 2 or more characters. This is stricter than the browser's own email check, which accepts name@domain.
 */
export const EMAIL_PATTERN = '[A-Za-z0-9._%+\'\\-]+@(?:[A-Za-z0-9](?:[A-Za-z0-9\\-]*[A-Za-z0-9])?\\.)+[A-Za-z]{2,}';

export const PHONE_ERROR_MESSAGE = 'Enter a phone number such as +1 612 555 0100 or (612) 555-0100. '
    + 'Use only digits, spaces, + ( ) . - and x for an extension.';

export const EMAIL_ERROR_MESSAGE = 'Enter an email address such as name@example.com.';

/**
 * Tells whether text is an acceptable phone number. A blank answer passes, because "required" is checked separately.
 *
 * @param {string} value What the visitor typed
 * @returns {boolean} True when the text is blank or looks like a phone number
 */
export function isValidPhone(value) {
    return isEmptyAnswer(value) || new RegExp('^(?:' + PHONE_PATTERN + ')$').test(String(value).trim());
}

/**
 * Tells whether text is an acceptable email address. A blank answer passes, because "required" is checked separately.
 *
 * @param {string} value What the visitor typed
 * @returns {boolean} True when the text is blank or looks like name@domain.suffix
 */
export function isValidEmail(value) {
    return isEmptyAnswer(value) || new RegExp('^(?:' + EMAIL_PATTERN + ')$').test(String(value).trim());
}

/**
 * Removes everything except the digits 0 to 9 from text.
 *
 * @param {*} value The text typed or pasted
 * @returns {string} Only the digits, or an empty string when there are none
 */
export function onlyDigits(value) {
    return value === undefined || value === null ? '' : String(value).replace(/[^0-9]/g, '');
}

/**
 * Reads the answer out of a Lightning input. A tick box gives true or false. A number box gives a number, because the
 * box holds its value as text and the server expects a number for a number field. Anything else gives the text.
 *
 * @param {{type: string, checked: boolean, value: *}} input The input to read
 * @returns {*} The answer
 */
export function answerOf(input) {
    if (input.type === 'checkbox') {
        return input.checked;
    }
    if (input.type === 'number' && !isEmptyAnswer(input.value)) {
        const number = Number(input.value);
        return Number.isFinite(number) ? number : input.value;
    }
    return input.value;
}

/**
 * Tells whether an answer is empty. False and zero are real answers (a ticked or unticked box, a number),
 * so only missing values and blank text count as empty.
 *
 * @param {*} value The answer to check
 * @returns {boolean} True when the answer is empty
 */
export function isEmptyAnswer(value) {
    return value === undefined || value === null || (typeof value === 'string' && value.trim() === '');
}

/**
 * Turns the value of a multi-select (an array, or text already joined) into the text Salesforce stores for a
 * multi-select picklist: the choices joined with semicolons.
 *
 * @param {*} value An array of choices or text
 * @returns {string} The choices joined with semicolons, or an empty string
 */
export function toSemicolonList(value) {
    if (Array.isArray(value)) {
        return value.filter((choice) => !isEmptyAnswer(choice)).join(';');
    }
    return isEmptyAnswer(value) ? '' : String(value);
}

/**
 * Returns a copy of the answers with one answer set. An empty answer removes the key instead, so the
 * server and the controller defaults decide what happens.
 *
 * @param {Object} interaction The answers so far
 * @param {string} apiName The Interaction field the answer belongs to
 * @param {*} value The answer
 * @returns {Object} A new object with the answer applied
 */
export function withAnswer(interaction, apiName, value) {
    const next = { ...(interaction || {}) };
    if (!apiName) {
        return next;
    }
    if (isEmptyAnswer(value)) {
        delete next[apiName];
    } else {
        next[apiName] = value;
    }
    return next;
}

/**
 * Applies one box's answer while copying the whole form into the answers. A blank box never overwrites
 * an answer, whether it came from another box for the same field earlier in the same pass or was typed
 * before. A blank box with nothing before it goes back to the controller default, or is left out.
 *
 * @param {Object} target The answers being built (changed in place)
 * @param {Object} defaults The values the controller set when the form loaded
 * @param {Set<string>} answered Fields that already received a real answer in this pass (changed in place)
 * @param {string} apiName The Interaction field of the box
 * @param {*} value What the box holds
 */
export function applyFieldAnswer(target, defaults, answered, apiName, value) {
    if (!apiName) {
        return;
    }
    if (!isEmptyAnswer(value)) {
        target[apiName] = value;
        answered.add(apiName);
        return;
    }
    if (answered.has(apiName)) {
        return;
    }
    const fallback = defaults ? defaults[apiName] : undefined;
    if (isEmptyAnswer(fallback)) {
        delete target[apiName];
    } else {
        target[apiName] = fallback;
    }
}

/**
 * Builds the Description text from the two long answers, with the same headings the old form used.
 *
 * @param {string} questionText What the visitor typed after ticking "I have a question"
 * @param {string} aboutYourselfText What the visitor typed for "Tell us about yourself"
 * @returns {string} The Description text, or an empty string when both are empty
 */
export function composeDescription(questionText, aboutYourselfText) {
    const parts = [];
    if (!isEmptyAnswer(questionText)) {
        parts.push('Questions/Comments from RFI: \n' + String(questionText).trim());
    }
    if (!isEmptyAnswer(aboutYourselfText)) {
        parts.push('Tell us about yourself from RFI: \n' + String(aboutYourselfText).trim());
    }
    return parts.join('\n\n');
}

/**
 * Returns a copy of the Interaction with the four Major Program fields set from the chosen programs.
 * The first four choices fill Major_Program_1__c to Major_Program_4__c. Fields with no choice are set to
 * an empty string, so emptying the selection clears all four instead of leaving the old values behind.
 *
 * @param {object} interaction The current Interaction answers
 * @param {Array<string>} programIds The chosen program Ids, in order
 * @returns {object} A new Interaction object
 */
export function withMajorPrograms(interaction, programIds) {
    const chosen = Array.isArray(programIds) ? programIds : [];
    return {
        ...interaction,
        Major_Program_1__c: chosen[0] || '',
        Major_Program_2__c: chosen[1] || '',
        Major_Program_3__c: chosen[2] || '',
        Major_Program_4__c: chosen[3] || ''
    };
}

const ADDRESS_FIELDS = ['mailing_street__c', 'mailing_city__c', 'mailing_state__c', 'mailing_country__c', 'mailing_postal_code__c', 'state__c'];
const PROGRAM_FIELDS = ['major_program_1__c', 'major_program_2__c', 'major_program_3__c', 'major_program_4__c'];

/**
 * Tells whether a question is shown, given the answers so far. A question with no "show only when" rule always
 * shows. Otherwise the answer to the earlier question must be one of the revealing answers. A tick box that was never
 * touched counts as not checked, and a missing answer never reveals a question.
 * The server makes the same decision when the form is saved, so keep the two in step.
 *
 * @param {object} field The form field, with visibleWhenField, visibleWhenKind and visibleWhenValues from the server
 * @param {object} answers The answers so far, by Interaction field API name
 * @returns {boolean} True when the question should be shown
 */
export function isQuestionShown(field, answers) {
    if (!field || !field.visibleWhenField) {
        return true;
    }
    const answer = (answers || {})[field.visibleWhenField];
    const text = field.visibleWhenKind === 'checkbox'
        ? String(answer === true)
        : (answer === undefined || answer === null ? '' : String(answer));
    return Array.isArray(field.visibleWhenValues) && field.visibleWhenValues.includes(text);
}

/**
 * The Interaction fields a question saves answers to, in lower case: its own field and the extra ones its kind of
 * question writes. This matches the server's list.
 *
 * @param {object} field The form field
 * @returns {string[]} Lower case API names
 */
export function fieldsWrittenBy(field) {
    const written = [];
    if (field.fieldInteractionAPIName) {
        written.push(field.fieldInteractionAPIName.toLowerCase());
    }
    if (field.isAddress) {
        written.push(...ADDRESS_FIELDS);
    }
    if (field.isSchoolLookup) {
        written.push('school_name_text__c');
    }
    if (field.isProgramLookup) {
        written.push(...PROGRAM_FIELDS);
    }
    if (field.showDependentField) {
        written.push('has_question__c', 'description__c');
    }
    return written;
}

/**
 * Finds the questions that are hidden by a "show only when" rule right now.
 *
 * @param {object[]} fields The form fields
 * @param {object} answers The answers so far
 * @returns {object[]} The hidden fields
 */
export function hiddenQuestions(fields, answers) {
    return (fields || []).filter(field => field && !isQuestionShown(field, answers));
}

/**
 * Throws away the answers to hidden questions. A field is only cleared when no visible question saves to it too
 * (two questions can share a field, such as Employer and Company).
 *
 * @param {object} answers The answers so far, by Interaction field API name
 * @param {object[]} fields The form fields
 * @returns {object} The same object when nothing was cleared, otherwise a copy without the hidden answers
 */
export function withoutHiddenAnswers(answers, fields) {
    const hidden = hiddenQuestions(fields, answers);
    if (hidden.length === 0) {
        return answers;
    }
    const shownFields = new Set();
    (fields || []).filter(field => field && !field.isStaticContent && !hidden.includes(field))
        .forEach(field => fieldsWrittenBy(field).forEach(name => shownFields.add(name)));
    const doomed = new Set();
    hidden.forEach(field => fieldsWrittenBy(field).forEach(name => {
        if (!shownFields.has(name)) {
            doomed.add(name);
        }
    }));
    const kept = {};
    let changed = false;
    Object.keys(answers || {}).forEach(apiName => {
        if (doomed.has(apiName.toLowerCase())) {
            changed = true;
        } else {
            kept[apiName] = answers[apiName];
        }
    });
    return changed ? kept : answers;
}