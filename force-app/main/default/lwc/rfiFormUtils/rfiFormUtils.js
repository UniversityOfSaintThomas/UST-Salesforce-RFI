/**
 * Small helpers for the RFI form that decide how typed answers become the Interaction that is submitted.
 * They are plain functions so they can be tested without rendering the component.
 */

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
