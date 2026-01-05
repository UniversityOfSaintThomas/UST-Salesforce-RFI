# Running Jest Tests - Guide

## Quick Reference

### Basic Commands

```powershell
# Run all tests
npm test

# Run all tests (same as above)
npm run test

# Run tests in watch mode (auto-rerun on changes)
npm test -- --watch

# Run tests for a specific component
npm test -- rfiAdditionalQuestionsInteractions

# Run all tests with coverage report
npm test -- --coverage

# Run tests in debug mode
npm test -- --debug

# Run tests with verbose output
npm test -- --verbose

# Update snapshots (if using snapshot testing)
npm test -- -u
```

### Advanced Commands

```powershell
# Run only tests that changed since last commit
npm test -- --onlyChanged

# Run tests related to specific files
npm test -- --findRelatedTests force-app/main/default/lwc/rfiForm/rfiForm.js

# Run tests matching a pattern
npm test -- --testNamePattern="should render"

# Run with coverage for specific files
npm test -- --coverage --collectCoverageFrom="force-app/main/default/lwc/**/*.js"

# Bail after first test failure
npm test -- --bail

# Run tests without cache
npm test -- --no-cache

# Clear Jest cache
npm test -- --clearCache
```

---

## Setup Instructions

### First Time Setup

1. **Install dependencies:**
   ```powershell
   npm install
   ```

2. **Verify installation:**
   ```powershell
   npm test
   ```

### Troubleshooting Installation

If `npm install` fails:

1. **Check Node.js version:**
   ```powershell
   node --version  # Should be v18+ 
   ```

2. **Clear npm cache:**
   ```powershell
   npm cache clean --force
   ```

3. **Delete node_modules and retry:**
   ```powershell
   Remove-Item -Path "node_modules" -Recurse -Force
   npm install
   ```

4. **Check package.json:**
   - Ensure `@salesforce/sfdx-lwc-jest` version is valid (currently `^5.1.0`)

---

## Test Results Interpretation

### Current Status (Jan 5, 2026)

```
Test Suites: 2 failed, 2 total
Tests:       11 failed, 1 passed, 12 total
```

### Components with Tests

1. **rfiForm** - Has tests but needs mocking fixes
2. **rfiAdditionalQuestionsInteractions** - Has tests with some failures

### Common Test Failures

#### 1. Mock Import Errors
**Error:**
```
Cannot find module '@salesforce/apex/rfiFormController.getRFIForm'
```

**Fix:** Create proper mock in `__mocks__` directory or use jest.mock()

#### 2. Property Access Warnings
**Warning:**
```
The property "showModal" is not publicly accessible. 
Add the @api annotation to the property...
```

**Fix:** Either:
- Add `@api` decorator to properties used in tests
- Or restructure tests to use public APIs only

#### 3. DragEvent Not Defined
**Error:**
```
ReferenceError: DragEvent is not defined
```

**Fix:** Add polyfill or mock DragEvent in test environment

---

## Writing Tests for LWC

### Basic Test Structure

```javascript
import { createElement } from 'lwc';
import ComponentName from 'c/componentName';

describe('c-component-name', () => {
    afterEach(() => {
        // Cleanup DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('should render component', () => {
        const element = createElement('c-component-name', {
            is: ComponentName
        });
        document.body.appendChild(element);

        expect(element).toBeTruthy();
    });
});
```

### Testing with Wire Adapters

```javascript
import { getRecord } from 'lightning/uiRecordApi';

// Mock the wire adapter
jest.mock('lightning/uiRecordApi', () => ({
    getRecord: jest.fn()
}), { virtual: true });

it('should handle wired data', () => {
    const element = createElement('c-component', {
        is: Component
    });
    
    // Emit data from wire
    getRecord.emit({ data: mockData });
    
    return Promise.resolve().then(() => {
        // Assertions
    });
});
```

### Testing Apex Calls

```javascript
import getApexMethod from '@salesforce/apex/Controller.method';

jest.mock('@salesforce/apex/Controller.method', () => ({
    default: jest.fn()
}), { virtual: true });

it('should call apex method', () => {
    getApexMethod.mockResolvedValue({ success: true });
    
    // Test code
});
```

---

## Test File Location

Tests must be in a `__tests__` folder within the component directory:

```
force-app/main/default/lwc/
├── componentName/
│   ├── componentName.js
│   ├── componentName.html
│   ├── componentName.css
│   ├── componentName.js-meta.xml
│   └── __tests__/
│       └── componentName.test.js
```

---

## Jest Configuration

**File:** `jest.config.js`

```javascript
const { jestConfig } = require('@salesforce/sfdx-lwc-jest/config');

module.exports = {
    ...jestConfig,
    modulePathIgnorePatterns: ['<rootDir>/.localdevserver']
};
```

**Customization options:**
- `testMatch` - Pattern for test files
- `coverageThreshold` - Minimum coverage requirements
- `setupFiles` - Files to run before tests
- `moduleNameMapper` - Mock module paths

---

## Coverage Reports

### Generate Coverage

```powershell
npm test -- --coverage
```

### Coverage Output

Shows:
- **Statements** - % of code statements executed
- **Branches** - % of if/else branches tested
- **Functions** - % of functions called
- **Lines** - % of code lines executed

### View HTML Report

After running with `--coverage`:
```powershell
# Report generated at:
coverage/lcov-report/index.html

# Open in browser
start coverage/lcov-report/index.html
```

---

## Best Practices

### 1. Test Naming

```javascript
// Good
it('should display error message when validation fails', () => {

// Bad  
it('test 1', () => {
```

### 2. Arrange-Act-Assert Pattern

```javascript
it('should update value when input changes', () => {
    // Arrange
    const element = createElement('c-component', { is: Component });
    document.body.appendChild(element);
    
    // Act
    const input = element.shadowRoot.querySelector('input');
    input.value = 'test';
    input.dispatchEvent(new CustomEvent('change'));
    
    // Assert
    return Promise.resolve().then(() => {
        expect(element.value).toBe('test');
    });
});
```

### 3. Clean Up After Tests

```javascript
afterEach(() => {
    while (document.body.firstChild) {
        document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
});
```

### 4. Use Promises for Async Tests

```javascript
it('should handle async operation', () => {
    const element = createElement('c-component', { is: Component });
    document.body.appendChild(element);
    
    element.doSomethingAsync();
    
    // Wait for promise resolution
    return Promise.resolve().then(() => {
        // Assertions here
    });
});
```

---

## Continuous Integration

### Running Tests in CI/CD

```yaml
# Example GitHub Actions
- name: Run Jest tests
  run: npm test -- --coverage --ci
```

### CI-Specific Options

```powershell
# Run in CI mode (better for automation)
npm test -- --ci

# Generate JUnit XML report
npm test -- --ci --reporters=default --reporters=jest-junit

# Run with max workers (faster on CI)
npm test -- --maxWorkers=4
```

---

## Known Issues

### 1. rfiForm Tests Failing

**Status:** Needs mock configuration for Apex imports

**Fix Required:**
- Create `__mocks__/@salesforce/apex` directory
- Add mock for `rfiFormController`

### 2. rfiAdditionalQuestionsInteractions Tests

**Issues:**
- Property access warnings (showModal, questionJSON, etc.)
- DragEvent not defined in test environment
- Some tests fail due to DOM not rendering

**Fixes:**
- Add @api decorators to tested properties, OR
- Use public APIs only
- Add DragEvent polyfill
- Ensure proper async/await handling

---

## Quick Fixes for Current Test Failures

### Fix Property Access Warnings

**Option 1: Add @api decorators (if properties should be public)**
```javascript
@api showModal = false;
@api questionJSON = [];
```

**Option 2: Test via public APIs only**
```javascript
// Instead of setting private properties:
// element.showModal = true;

// Use public methods/events:
element.querySelector('button').click();
```

### Fix DragEvent Error

Add to test file:
```javascript
global.DragEvent = class DragEvent extends Event {
    constructor(type, eventInit) {
        super(type, eventInit);
        this.dataTransfer = eventInit?.dataTransfer || null;
    }
};
```

---

## Additional Resources

### Documentation
- **Jest Docs:** https://jestjs.io/docs/getting-started
- **LWC Testing:** https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.testing
- **SFDX LWC Jest:** https://github.com/salesforce/sfdx-lwc-jest

### Example Tests
Check existing test files:
- `force-app/main/default/lwc/rfiForm/__tests__/rfiForm.test.js`
- `force-app/main/default/lwc/rfiAdditionalQuestionsInteractions/__tests__/rfiAdditionalQuestionsInteractions.test.js`

---

## Summary

**To run tests:**
```powershell
npm test
```

**Current status:** 
- Tests are set up and running
- Some failures need fixing (mocks, property access)
- Coverage reports available with `--coverage` flag

**Next steps:**
1. Fix Apex mock imports
2. Add @api decorators or restructure tests
3. Add DragEvent polyfill
4. Run tests regularly during development

---

**Last Updated:** January 5, 2026  
**Test Framework:** Jest via @salesforce/sfdx-lwc-jest v5.1.0  
**Status:** ✅ Tests running, some failures to fix

