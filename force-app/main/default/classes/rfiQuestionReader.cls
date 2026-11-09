/**
 * The one place that reads the saved question list (RFI_Controller__c.Unified_Questions__c).
 *
 * The list is JSON written by the Question Manager and read by the form. It will keep changing as features are
 * added, and saved data from older versions will still be in the org. So this class is tolerant on purpose:
 *
 *  - Keys it does not know are kept and passed through, so newer data is not damaged by older code.
 *  - Values of the wrong type are converted when that is safe (the text "true" for a true/false value, a number for
 *    a label) and otherwise reported.
 *  - A question it cannot understand is skipped, and the reason is returned as a warning so an admin can find
 *    the question. One bad question never stops the others from loading.
 *  - The list may be a plain list (what is saved today) or an object that holds it under "questions" (room for a
 *    future wrapper).
 *
 * A question may carry a "show only when" rule (visibleWhen: the key of an earlier question and the answers that reveal
 * this one). The reader checks that the rule is complete and that it can work in this list: the earlier question
 * exists and really is earlier, it has no rule of its own (one level only), and the dependent question is not a program
 * filter. A rule that fails a check is removed and reported, so the question simply always shows.
 *
 * Only a list that cannot be read at all (not JSON, or not a list) throws, because there is no form to build.
 *
 * Rules for changing the saved format are in docs/AI-TOOLS-CONFIG.md under "Changing the question format".
 */
public with sharing class rfiQuestionReader {

    /** The format version this code writes and fully understands. */
    public static final Integer currentSchemaVersion = 1;

    /** The question types this version knows. */
    @TestVisible
    private static final Set<String> knownTypes = new Set<String>{ 'preconfigured', 'custom', 'filter' };

    /**
     * The saved list could not be read at all.
     */
    public class UnreadableException extends Exception {}

    /**
     * What came out of reading the list.
     */
    public class ReadResult {
        /** The questions that could be understood, cleaned up, in saved order */
        public List<Map<String, Object>> questions = new List<Map<String, Object>>();
        /** One plain-language message for each problem, naming the question by position and label */
        public List<String> warnings = new List<String>();
    }

    /**
     * Reads the saved question list.
     *
     * @param savedJson The text saved in Unified_Questions__c
     * @return The usable questions and a warning for each problem
     * @throws UnreadableException when the text is not JSON or does not hold a list of questions
     */
    public static ReadResult read(String savedJson) {
        ReadResult result = new ReadResult();
        Object parsed;
        try {
            parsed = JSON.deserializeUntyped(savedJson);
        } catch (Exception parseError) {
            throw new UnreadableException('The saved question list is not valid JSON (' + parseError.getMessage() + ')');
        }
        List<Object> entries;
        if (parsed instanceof List<Object>) {
            entries = (List<Object>) parsed;
        } else if (parsed instanceof Map<String, Object> && ((Map<String, Object>) parsed).get('questions') instanceof List<Object>) {
            entries = (List<Object>) ((Map<String, Object>) parsed).get('questions');
        } else {
            throw new UnreadableException('The saved question list is not a list of questions');
        }

        Map<String, Integer> positionOfKey = new Map<String, Integer>();
        List<Integer> positions = new List<Integer>();
        Integer position = 0;
        for (Object entry : entries) {
            position++;
            Map<String, Object> question = normalize(entry, position, result.warnings);
            if (question == null) {
                continue;
            }
            String key = (String) question.get('key');
            if (String.isNotBlank(key)) {
                if (positionOfKey.containsKey(key)) {
                    result.warnings.add(describe(question, position) + ' has the same key as question ' + positionOfKey.get(key)
                            + '. Questions that depend on it may not work as intended.');
                } else {
                    positionOfKey.put(key, position);
                }
            }
            result.questions.add(question);
            positions.add(position);
        }
        checkRules(result, positions, positionOfKey);
        return result;
    }

    /**
     * Removes the "show only when" rules that cannot work in this list, and says why.
     *
     * @param result The questions read so far; rules are removed from them and warnings added
     * @param positions The saved position of each question in result.questions, in the same order
     * @param positionOfKey The saved position of each key
     */
    private static void checkRules(ReadResult result, List<Integer> positions, Map<String, Integer> positionOfKey) {
        Map<String, Map<String, Object>> questionOfKey = new Map<String, Map<String, Object>>();
        for (Map<String, Object> question : result.questions) {
            String key = (String) question.get('key');
            if (String.isNotBlank(key) && !questionOfKey.containsKey(key)) {
                questionOfKey.put(key, question);
            }
        }
        for (Integer index = 0; index < result.questions.size(); index++) {
            Map<String, Object> question = result.questions[index];
            if (!question.containsKey('visibleWhen')) {
                continue;
            }
            Integer position = positions[index];
            String parentKey = (String) ((Map<String, Object>) question.get('visibleWhen')).get('key');
            String problem = null;
            if (question.get('type') == 'filter') {
                problem = 'is a program filter, and a program filter always shows because it narrows the program list';
            } else if (!questionOfKey.containsKey(parentKey)) {
                problem = 'depends on a question that is not available (it was deleted, or it could not be read)';
            } else if (positionOfKey.get(parentKey) >= position) {
                problem = 'depends on a question that does not come before it in the list';
            } else if (questionOfKey.get(parentKey).containsKey('visibleWhen')) {
                problem = 'depends on a question that itself shows only under a condition. Only one level is supported';
            }
            if (problem != null) {
                question.remove('visibleWhen');
                result.warnings.add(describe(question, position) + ' ' + problem + '. Its rule was ignored and it always shows.');
            }
        }
    }

    /**
     * Cleans up one saved question.
     *
     * @param entry The saved item
     * @param position Its position in the saved list, starting at 1
     * @param warnings Collects a message for every problem
     * @return The cleaned question, or null when it has to be skipped
     */
    @TestVisible
    private static Map<String, Object> normalize(Object entry, Integer position, List<String> warnings) {
        if (!(entry instanceof Map<String, Object>)) {
            warnings.add('Question ' + position + ' is not a question and was skipped.');
            return null;
        }
        Map<String, Object> source = (Map<String, Object>) entry;
        Map<String, Object> question = new Map<String, Object>(source); // keeps keys this version does not know

        String type = textOf(source.get('type'));
        if (!knownTypes.contains(type == null ? '' : type)) {
            warnings.add(describe(source, position) + ' has the type "' + (type == null ? '' : type)
                    + '", which this version does not know. It was skipped. It may have been saved by a newer version.');
            return null;
        }
        question.put('type', type);

        Integer version = integerOf(source.get('schemaVersion'), 1);
        if (version > currentSchemaVersion) {
            warnings.add(describe(source, position) + ' was saved by a newer version (format ' + version
                    + ', this code understands ' + currentSchemaVersion + '). Settings added by the newer version are ignored.');
        }
        question.put('schemaVersion', version);
        String key = textOf(source.get('key'));
        if (String.isNotBlank(key)) {
            question.put('key', key);
        } else {
            question.remove('key');
        }

        question.put('isRequired', booleanOf(source.get('isRequired'), 'isRequired', source, position, warnings));
        String label = textOf(source.get('questionLabel'));
        question.put('questionLabel', label == null ? '' : label);

        if (type == 'preconfigured') {
            String name = textOf(source.get('fieldName'));
            if (String.isBlank(name)) {
                warnings.add(describe(source, position) + ' has no question name (fieldName) and was skipped.');
                return null;
            }
            question.put('fieldName', name);
            String storedField = textOf(source.get('fieldInteractionAPIName'));
            question.put('fieldInteractionAPIName', storedField == null ? '' : storedField);
            if (String.isBlank(label)) {
                question.put('questionLabel', name);
            }
        } else if (type == 'custom') {
            String questionType = textOf(source.get('questionType'));
            if (String.isBlank(questionType)) {
                warnings.add(describe(source, position) + ' has no question type and was skipped.');
                return null;
            }
            question.put('questionType', questionType);
            String target = textOf(source.get('fieldToApplyTo'));
            if (String.isBlank(target) && questionType != 'Static content') {
                warnings.add(describe(source, position) + ' does not say which Interaction field to save to and was skipped.');
                return null;
            }
            question.put('fieldToApplyTo', target == null ? '' : target);
            String flat = textOf(source.get('valuesFlat'));
            question.put('valuesFlat', flat == null ? '' : flat);
            question.put('picklistValues', normalizeChoices(source.get('picklistValues'), source, position, warnings));
        } else {
            String controllerField = textOf(source.get('filterControllerField'));
            if (String.isBlank(controllerField)) {
                warnings.add(describe(source, position) + ' does not say which controller field holds its choices and was skipped.');
                return null;
            }
            question.put('filterControllerField', controllerField);
            String filterField = textOf(source.get('filterInteractionAPIName'));
            question.put('filterInteractionAPIName', filterField == null ? '' : filterField);
            question.put('isFilterSchoolList', booleanOf(source.get('isFilterSchoolList'), 'isFilterSchoolList', source, position, warnings));
            Object selected = source.get('filterSelectedValues');
            List<Object> selectedValues = new List<Object>();
            if (selected instanceof List<Object>) {
                for (Object value : (List<Object>) selected) {
                    if (value != null) {
                        selectedValues.add(String.valueOf(value));
                    }
                }
            } else if (selected != null) {
                warnings.add(describe(source, position) + ' has choices saved in a form that cannot be read (filterSelectedValues). The controller\'s own choices are used instead.');
            }
            question.put('filterSelectedValues', selectedValues);
        }
        normalizeRule(source, question, position, warnings);
        return question;
    }

    /**
     * Cleans up a question's "show only when" rule: the earlier question's key and the answers that reveal this one.
     * A rule that is not complete is removed and reported.
     *
     * @param source The saved question
     * @param question The cleaned question; its visibleWhen is replaced or removed
     * @param position The question's position, for messages
     * @param warnings Collects a message for every problem
     */
    private static void normalizeRule(Map<String, Object> source, Map<String, Object> question, Integer position, List<String> warnings) {
        Object saved = source.get('visibleWhen');
        question.remove('visibleWhen');
        if (saved == null) {
            return;
        }
        if (!(saved instanceof Map<String, Object>)) {
            warnings.add(describe(source, position) + ' has a "show only when" rule that cannot be read. The rule was ignored and the question always shows.');
            return;
        }
        Map<String, Object> rule = new Map<String, Object>((Map<String, Object>) saved); // keeps parts this version does not know
        String parentKey = textOf(rule.get('key'));
        List<String> answers = answerList(rule.get('equals'));
        if (String.isBlank(parentKey) || answers.isEmpty()) {
            warnings.add(describe(source, position) + ' has a "show only when" rule that is incomplete: it needs an earlier question and at least one answer. The rule was ignored and the question always shows.');
            return;
        }
        rule.put('key', parentKey);
        rule.put('equals', answers);
        question.put('visibleWhen', rule);
    }

    /**
     * Reads the answers that reveal a question. A single value is treated as a list of one, and true or false
     * become the text "true" or "false", which is how a checkbox answer is compared.
     *
     * @param saved The saved value
     * @return The answers as text, without blanks
     */
    @TestVisible
    private static List<String> answerList(Object saved) {
        List<String> answers = new List<String>();
        List<Object> items = saved instanceof List<Object> ? (List<Object>) saved : new List<Object>{ saved };
        for (Object item : items) {
            String text = textOf(item);
            if (String.isNotBlank(text)) {
                answers.add(text.trim());
            }
        }
        return answers;
    }

    /**
     * Cleans up the typed-in choices of a custom picklist question.
     *
     * @param saved The saved choices
     * @param source The saved question, for messages
     * @param position The question's position, for messages
     * @param warnings Collects a message for every problem
     * @return A list of label and value pairs, possibly empty
     */
    private static List<Object> normalizeChoices(Object saved, Map<String, Object> source, Integer position, List<String> warnings) {
        List<Object> choices = new List<Object>();
        if (saved == null) {
            return choices;
        }
        if (!(saved instanceof List<Object>)) {
            warnings.add(describe(source, position) + ' has picklist choices saved in a form that cannot be read (picklistValues is not a list). They were ignored.');
            return choices;
        }
        for (Object item : (List<Object>) saved) {
            if (item instanceof Map<String, Object>) {
                Map<String, Object> pair = (Map<String, Object>) item;
                String value = textOf(pair.get('value'));
                if (String.isNotBlank(value)) {
                    String itemLabel = textOf(pair.get('label'));
                    choices.add(new Map<String, Object>{ 'label' => String.isBlank(itemLabel) ? value : itemLabel, 'value' => value });
                }
            } else if (item instanceof String && String.isNotBlank((String) item)) {
                choices.add(new Map<String, Object>{ 'label' => (String) item, 'value' => (String) item });
            }
        }
        return choices;
    }

    /**
     * Names a question for a message: its position and its label or name.
     *
     * @param question The saved question
     * @param position Its position in the saved list
     * @return For example: Question 3 ("Citizenship")
     */
    private static String describe(Map<String, Object> question, Integer position) {
        String label = textOf(question.get('questionLabel'));
        if (String.isBlank(label)) {
            label = textOf(question.get('fieldName'));
        }
        return 'Question ' + position + (String.isBlank(label) ? '' : ' ("' + label + '")');
    }

    /**
     * @param value Any saved value
     * @return The value as text, or null when it is missing or is a list or an object
     */
    @TestVisible
    private static String textOf(Object value) {
        if (value == null || value instanceof List<Object> || value instanceof Map<String, Object>) {
            return null;
        }
        return String.valueOf(value);
    }

    /**
     * @param value Any saved value
     * @param defaultValue Used when the value is missing or not a number
     * @return The value as a whole number
     */
    @TestVisible
    private static Integer integerOf(Object value, Integer defaultValue) {
        if (value instanceof Integer) {
            return (Integer) value;
        }
        if (value instanceof Long) {
            return Integer.valueOf((Long) value);
        }
        if (value instanceof Decimal) {
            return ((Decimal) value).intValue();
        }
        if (value instanceof String && ((String) value).trim().isNumeric()) {
            return Integer.valueOf(((String) value).trim());
        }
        return defaultValue;
    }

    /**
     * Reads a true or false value. The text "true" or "false" is accepted. Anything else that is present counts as
     * false and is reported, because the other choice, guessing true, could change what a visitor must answer.
     *
     * @param value The saved value
     * @param keyName The key it was saved under, for messages
     * @param source The saved question, for messages
     * @param position The question's position, for messages
     * @param warnings Collects a message for every problem
     * @return True or false
     */
    @TestVisible
    private static Boolean booleanOf(Object value, String keyName, Map<String, Object> source, Integer position, List<String> warnings) {
        if (value == null) {
            return false;
        }
        if (value instanceof Boolean) {
            return (Boolean) value;
        }
        if (value instanceof String) {
            String lowered = ((String) value).trim().toLowerCase();
            if (lowered == 'true') {
                return true;
            }
            if (lowered == 'false' || lowered == '') {
                return false;
            }
        }
        warnings.add(describe(source, position) + ' has ' + keyName + ' set to something other than true or false. It was treated as false.');
        return false;
    }
}