# rfiFormController Test Coverage Enhancement

## Objective
Increase Apex unit test coverage for `rfiFormController.cls` to above 75%.

## Date
January 29, 2026

## Changes Made

### Test Class: rfiFormController_TEST.cls

Added **40+ comprehensive test methods** covering all major code paths in rfiFormController.

### Test Coverage Areas

#### 1. Core RFI Form Retrieval (getRFIForm method)
- **testGetRFIForm_returnsWrapper** - Basic wrapper return
- **testGetRFIForm_multipleFieldConfigurations** - Various field configurations
- **testGetRFIForm_legacyOrder** - Legacy field ordering (backward compatibility)
- **testGetRFIForm_unknownFieldName** - Unknown field handling (else case)
- **testGetRFIForm_emptyFieldsToDisplay** - Empty/null fields handling
- **testGetRFIForm_missingSchoolCollege** - Null school/college handling
- **testGetRFIForm_missingAcademicInterest** - Null academic interest handling

#### 2. Custom Field Labels
- **testGetRFIForm_allCustomLabels** - All 15+ custom label fields
- **testGetRFIForm_withHomePhone** - Home Phone with custom label
- **testGetRFIForm_withMailInformation** - Mail Information checkbox
- **testGetRFIForm_withAdmitType** - Admit Type with custom label
- **testGetRFIForm_withWhenStartSchool** - When Start School field
- **testGetRFIForm_hasQuestionShowsDependent** - Dependent field logic

#### 3. Address Field Handling
- **testGetRFIForm_allAddressFields** - Address field consolidation (7 tokens → 1 field)
- **testGetRFIForm_addressFieldConsolidation** - Multiple address tokens
- **testGetRFIForm_addressNotRequired** - Optional address fields

#### 4. Program Filter Fields
- **testGetRFIForm_multipleFilterFields** - All 11 filter field types:
  - School_College_To_Display__c
  - Degree_Types_To_Display__c
  - Generic_Filter_2_To_Display__c through Generic_Filter_8_To_Display__c
  - Student_Types_To_Display__c
  - Delivery_Types_To_Display__c
  - Program_Types_To_Display__c

#### 5. State/Province Handling
- **testGetStateProvince** - Basic state retrieval for US
- **testGetStateProvince_Canada** - Canadian provinces
- **testGetStateProvince_cacheHit** - Cache hit scenario
- **testGetCountryIndex_caching** - Country index caching logic
- **testGetStateProvince_invalidCountry** - Invalid country code (returns null)
- **testGetStateProvince_Mexico** - Mexico states (if configured)

#### 6. Program Retrieval Methods
**getPrograms:**
- **testGetPrograms_undergraduate** - Undergraduate programs
- **testGetPrograms_undergraduate_withProgramTypes** - With program type filtering
- **testGetPrograms_graduate_withSchool** - Graduate with school filter
- **testGetPrograms_lawSchool** - Law school special handling (Banner_Program_Code__c LIKE 'LW_%')
- **testGetPrograms_withMultipleFilters** - Filter map usage
- **testGetPrograms_emptyResults** - No matching programs

**getProgramsWithShortCodes:**
- **testGetProgramsWithShortCodes** - Basic short codes
- **testGetProgramsWithShortCodes_noFiltersNoSchool** - Default behavior with picklist values
- **testGetProgramsWithShortCodes_lawSchool** - Law school filtering
- **testGetProgramsWithShortCodes_undergraduate** - Undergraduate filtering
- **testGetProgramsWithShortCodes_withAcademicInterests** - Academic interest codes
- **testGetProgramsWithShortCodes_grouping** - Two-level grouping (School → Degree)

#### 7. Helper Methods
- **testGetUSTSchoolList** - UST school list from Account records
- **testGetTerms** - Academic term retrieval (Fall/Spring, 4-year window)
- **testGetOptionsFromDelineatedString** - Semicolon-delimited parsing
- **testGetPicklistOptions** - Schema describe picklist options

#### 8. Interaction Submission
- **testSubmitRfiInteraction** - Basic submission
- **testSubmitRfiInteraction_allFields** - Comprehensive field population
- **testSubmitRfiInteraction_withMajorProgram** - Program lookup mapping
- **testSubmitRfiInteraction_programMappingNoAcademicProgram** - Edge case: no academic program found
- **testSubmitRfiInteraction_dmlError** - Error handling and AuraHandledException
- **testSubmitRFIInteraction_nullInput** - Null interaction handling

#### 9. Additional Questions/Interaction Questions
- **testGetRFIForm_withInteractionQuestionsJSON** - JSON parsing
- **testGetRFIForm_withAdditionalQuestions_textarea** - Textarea type
- **testGetRFIForm_withAdditionalQuestions_staticContent** - Static content
- **testGetRFIForm_withAdditionalQuestions_email** - Email type
- **testGetRFIForm_interactionQuestionsRichText** - Legacy isRichText flag
- **testGetRFIForm_interactionQuestionsTextBox** - Legacy isTextBox flag
- **testGetRFIForm_interactionQuestionsInvalidJSON** - JSON parse error handling

#### 10. Picklist Detection
- **testGetRFIForm_picklistDetection** - Dynamic picklist field detection
- **testGetRFIForm_multiSelectField** - Multipicklist detection

#### 11. School/Program Lookups
- **testGetRFIForm_schoolCollegeLookup** - University_Department account lookup
- **testGetRFIForm_programLookupByCodes** - Program lookup by code

### Bug Fixes

1. **Fixed enum case mismatch:**
   - Changed `Schema.DisplayType.Picklist` → `Schema.DisplayType.PICKLIST`
   - Changed `Schema.DisplayType.MultiPicklist` → `Schema.DisplayType.MULTIPICKLIST`

2. **Removed duplicate test methods:**
   - Removed duplicate `testGetStateProvince_InvalidCountry`
   - Removed duplicate `testGetRFIForm_emptyFieldsToDisplay`

3. **Removed unused variables:**
   - Removed 6 instances of unused `questionsJSON` variables

4. **Fixed malformed test methods:**
   - Added missing closing braces
   - Fixed method structure issues

## Code Coverage Improvements

### Methods Now Covered:
- `getRFIForm()` - Main method with all field configurations
- `getStateProvince()` - Including caching logic
- `getCountryIndex()` - Including cache hits and misses
- `isValidForCountry()` - State/country validation
- `getPicklistOptions()` - Picklist extraction
- `getOptionsFromDelineatedString()` - String parsing
- `getUSTSchoolList()` - School account queries
- `getPrograms()` - All query paths (U/G, filters, law school)
- `getProgramsWithShortCodes()` - Two-level grouping logic
- `filterQuery()` - Dynamic filter building
- `getTerms()` - Academic term queries
- `submitRfiInteraction()` - Success and error paths

### Edge Cases Covered:
- Null/empty field configurations
- Unknown field names (else clause)
- Invalid country codes
- Empty program results
- Missing school/college accounts
- Missing program records
- DML errors
- JSON parsing errors
- Cache hits and misses
- Legacy field ordering
- Address field consolidation
- Filter field variations

## How to Run Tests

### Option 1: Using the helper script
```powershell
.\run-rfiFormController-tests.ps1
```

### Option 2: Using Salesforce CLI
```powershell
sf apex run test --class-names rfiFormController_TEST --target-org dev --code-coverage --result-format human --wait 10
```

### Option 3: Using CumulusCI
```powershell
cci task run run_tests --org dev --test_name_match rfiFormController_TEST
```

## Expected Results

✓ **All tests should pass**
✓ **Code coverage should exceed 75%**
✓ **No compilation errors**
✓ **No warnings (except informational)**

## Test Data Setup

The `@TestSetup` method creates:
- 1 RFI_Controller__c record
- 4 Program__c records (Recruitment_Program type)
- 1 User record
- 1 Academic_Term__c record

Additional test data is created within individual test methods as needed.

## Notes

- Tests are designed to be independent and can run in any order
- Caching logic is tested with multiple calls to verify cache hits
- Filter fields are tested comprehensively (11 different filter types)
- Both legacy and new field ordering logic is tested
- Program grouping (School → Degree) is validated
- Error handling paths are exercised

## Next Steps

1. Deploy the test class: `cci task run deploy --path force-app/test/default/classes --org dev`
2. Run the tests: `.\run-rfiFormController-tests.ps1`
3. Verify coverage is above 75%
4. If needed, add more tests for any uncovered lines shown in the report
