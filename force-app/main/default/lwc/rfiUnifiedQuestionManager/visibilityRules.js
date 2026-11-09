/**
 * "Show only when" rules for the question manager.
 *
 * A question may carry visibleWhen: { key, equals } where key is the stable key of an EARLIER question and equals is
 * the list of that question's answers that reveal this one. The key is used, never the position, because positions
 * change whenever a question is moved or deleted.
 *
 * These are plain functions so they can be tested without rendering. The form's server code makes the same checks
 * (rfiQuestionReader and rfiFormController.applyVisibilityRules), so keep the two in step.
 *
 * The context argument gives the functions what only the page knows about the Interaction object:
 *   fieldDataType(apiName) returns the lower case data type of an Interaction field ('picklist', 'boolean', ...)
 *   livePicklist(apiName) returns the current active choices of a picklist field as [{ label, value }]
 */

const CHECKBOX_CHOICES = [
    { label: 'Checked', value: 'true' },
    { label: 'Not checked', value: 'false' }
];

// Questions the form always needs, so they can never be hidden
const ALWAYS_SHOWN_NAMES = ['First Name', 'Last Name'];

/**
 * Tells whether a question may carry a "show only when" rule.
 *
 * @param {object} question The saved question
 * @returns {boolean} False for program filters and the two name questions
 */
export function canHaveRule(question) {
    if (!question || question.type === 'filter') {
        return false;
    }
    return !(question.type === 'preconfigured' && ALWAYS_SHOWN_NAMES.includes(question.fieldName));
}

/**
 * The answers of a question that a rule can name, or null when a rule cannot depend on this question.
 * Only a choice from a list and a tick box qualify. A choice that is a record (a term, a school) has a different
 * value in every org, so it cannot be named in a rule that is stored with the form.
 *
 * @param {object} question The saved question
 * @param {object} context What the page knows about the Interaction object
 * @returns {{kind: string, options: object[]}|null} The kind ('picklist' or 'checkbox') and the answers, or null
 */
export function answerChoices(question, context) {
    if (!question || question.type === 'filter') {
        return null;
    }
    const questionType = (question.questionType || '').toLowerCase();
    if (question.type === 'custom') {
        if (questionType === 'checkbox' || questionType === 'checkbox required') {
            return { kind: 'checkbox', options: CHECKBOX_CHOICES };
        }
        if (questionType === 'picklist' || questionType === 'picklist required') {
            const target = question.fieldToApplyTo;
            if (target && context.fieldDataType(target) === 'picklist') {
                return { kind: 'picklist', options: context.livePicklist(target) || [] };
            }
            const typed = Array.isArray(question.picklistValues) ? question.picklistValues : [];
            return { kind: 'picklist', options: typed.map((entry) => ({ label: entry.label, value: entry.value })) };
        }
        return null;
    }
    if (question.type === 'preconfigured') {
        const target = question.fieldInteractionAPIName;
        const dataType = target ? context.fieldDataType(target) : undefined;
        if (dataType === 'picklist') {
            return { kind: 'picklist', options: context.livePicklist(target) || [] };
        }
        if (dataType === 'boolean') {
            return { kind: 'checkbox', options: CHECKBOX_CHOICES };
        }
    }
    return null;
}

/**
 * The earlier questions that the question at a position could depend on. A question that has a rule of its own
 * is left out, because only one level is supported.
 *
 * @param {object[]} questions All questions, in order
 * @param {number} position The position of the question being edited (the list length for a new question)
 * @param {object} context What the page knows about the Interaction object
 * @returns {object[]} Entries with key, label, kind and options
 */
export function eligibleParents(questions, position, context) {
    const parents = [];
    (questions || []).slice(0, position).forEach((question) => {
        const choices = answerChoices(question, context);
        if (choices && question.key && !question.visibleWhen) {
            parents.push({ key: question.key, label: question.questionLabel || question.fieldName || question.key, ...choices });
        }
    });
    return parents;
}

function labelOf(question) {
    return `"${question.questionLabel || question.fieldName || 'Untitled question'}"`;
}

/**
 * Describes a question's rule in words, for the list.
 *
 * @param {object} question The saved question
 * @param {object[]} questions All questions
 * @param {object} context What the page knows about the Interaction object
 * @returns {string} A sentence, or an empty string when the question has no rule
 */
export function describeRule(question, questions, context) {
    const rule = question && question.visibleWhen;
    if (!rule) {
        return '';
    }
    const parent = (questions || []).find((candidate) => candidate.key === rule.key);
    if (!parent) {
        return 'Shown only when an earlier question that no longer exists has a certain answer';
    }
    const choices = answerChoices(parent, context);
    const options = choices ? choices.options : [];
    const names = (rule.equals || []).map((value) => {
        const match = options.find((option) => option.value === value);
        return match ? match.label : value;
    });
    return `Shown only when ${labelOf(parent)} is ${names.join(' or ')}`;
}

/**
 * Finds the rules that cannot work with the questions as they are now, in plain words. Used to warn the admin
 * and to stop a save that would leave a question nobody can see.
 *
 * @param {object[]} questions All questions, in order
 * @param {object} context What the page knows about the Interaction object
 * @returns {string[]} One message per problem; empty when every rule can work
 */
export function ruleProblems(questions, context) {
    const problems = [];
    (questions || []).forEach((question, position) => {
        const rule = question.visibleWhen;
        if (!rule) {
            return;
        }
        const name = labelOf(question);
        if (!canHaveRule(question)) {
            problems.push(`${name} cannot be hidden. Remove its "show only when" rule.`);
            return;
        }
        const parentPosition = questions.findIndex((candidate) => candidate.key === rule.key);
        if (parentPosition === -1) {
            problems.push(`${name} depends on a question that was removed. Choose another question or remove the rule.`);
            return;
        }
        const parent = questions[parentPosition];
        if (parentPosition >= position) {
            problems.push(`${name} must come after ${labelOf(parent)}, which its rule depends on. Move it down or edit the rule.`);
            return;
        }
        if (parent.visibleWhen) {
            problems.push(`${name} depends on ${labelOf(parent)}, which is itself shown only under a condition. Only one level is supported.`);
            return;
        }
        const choices = answerChoices(parent, context);
        if (!choices) {
            problems.push(`${name} depends on ${labelOf(parent)}, which is not a choice from a list or a tick box. Choose another question.`);
            return;
        }
        if (!Array.isArray(rule.equals) || rule.equals.length === 0) {
            problems.push(`${name} has a rule with no answers chosen. Choose at least one answer or remove the rule.`);
            return;
        }
        if (choices.options.length > 0) {
            const known = new Set(choices.options.map((option) => option.value));
            const unknown = rule.equals.filter((value) => !known.has(value));
            if (unknown.length > 0) {
                problems.push(`${name} waits for ${unknown.join(' or ')} on ${labelOf(parent)}, which is not an answer to it. Edit the rule.`);
            }
        }
    });
    return problems;
}