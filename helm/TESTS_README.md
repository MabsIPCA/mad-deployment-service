# Helm Test Charts - Isolated Error Testing

## Overview

This directory contains 19 separate Helm charts, each designed to test a specific type of Helm template rendering error in isolation. This structure allows for precise identification and testing of different failure scenarios.

## Chart Structure

Each test chart follows this structure:
```
test-XX-test-name/
├── Chart.yaml          # Chart metadata
├── values.yaml         # Test-specific values
└── templates/
    └── test-file.yaml  # Template with error scenarios
```

## Test Charts

### 01. test-01-required-function
**Description**: Test for 'required' function failures  
**Tests**:
- Missing required database.port
- Missing nested required database.host
- Required value with empty string

**Enable tests by setting**: `testRequired`, `testNestedRequired`, `testRequiredEmpty` to `true`

### 02. test-02-fail-function
**Description**: Test for 'fail' function  
**Tests**:
- Conditional fail when feature not enabled
- Validation fail on invalid environment
- Unconditional fail

**Enable tests by setting**: `testFailCondition`, `testFailValidation`, `testFailUnconditional` to `true`

### 03. test-03-type-mismatch
**Description**: Test for type mismatch errors  
**Tests**:
- Range over number (expects list)
- Math operations on string
- Printf with wrong type
- Range over string (expects list)

**Enable tests by setting**: `testRangeNumber`, `testMathString`, `testPrintfType`, `testRangeString` to `true`

### 04. test-04-index-out-of-range
**Description**: Test for index out of range errors  
**Tests**:
- Index on empty list
- Index beyond list bounds
- Negative index
- Index on nil list

**Enable tests by setting**: `testIndexEmpty`, `testIndexBeyond`, `testIndexNegative`, `testIndexNil` to `true`

### 05. test-05-nil-pointer
**Description**: Test for nil pointer errors  
**Tests**:
- Access key on nil map
- Nested access on nil value
- Pipeline operations on nil
- base64Encode on nil

**Enable tests by setting**: `testNilMap`, `testNilNested`, `testNilPipeline`, `testNilBase64` to `true`

### 06. test-06-template-syntax-error
**Description**: Test for template syntax errors  
**Tests**:
- Unclosed template action
- Invalid function name
- Wrong number of arguments
- Undefined variable reference
- Invalid range syntax

**Enable tests by setting**: `testUnclosedAction`, `testInvalidFunction`, `testWrongArgs`, `testUndefinedVar`, `testInvalidRange` to `true`

### 07. test-07-missing-template
**Description**: Test for missing template errors  
**Tests**:
- Include non-existent template
- Template function on missing template
- Reference missing subchart template

**Enable tests by setting**: `testMissingInclude`, `testMissingTemplate`, `testMissingSubchart` to `true`

### 08. test-08-division-by-zero
**Description**: Test for division by zero errors  
**Tests**:
- Division by zero
- Modulo by zero
- Both operands zero

**Enable tests by setting**: `testDivZero`, `testModZero`, `testBothZero` to `true`

### 09. test-09-invalid-regex
**Description**: Test for invalid regex errors  
**Tests**:
- Invalid regex pattern
- Invalid regex in replace
- Unclosed character class
- Invalid escape sequence

**Enable tests by setting**: `testInvalidRegex`, `testInvalidRegexReplace`, `testUnclosedClass`, `testInvalidEscape` to `true`

### 10. test-10-file-read-error
**Description**: Test for file read errors  
**Tests**:
- Missing file with .Files.Get
- Glob pattern with required
- AsConfig on empty result

**Enable tests by setting**: `testMissingFile`, `testGlobRequired`, `testAsConfigEmpty` to `true`

### 11. test-11-invalid-json-yaml
**Description**: Test for invalid JSON/YAML parsing  
**Tests**:
- fromJson with invalid JSON
- fromYaml with invalid YAML
- mustFromJson with bad data
- toJson with invalid circular reference

**Enable tests by setting**: `testFromJsonInvalid`, `testFromYamlInvalid`, `testMustFromJson`, `testToJsonInvalid` to `true`

### 12. test-12-list-operation-error
**Description**: Test for list operation errors  
**Tests**:
- first on empty list
- rest on empty list
- last on empty list
- Slice with out of bounds indices
- append on non-list
- prepend on non-list

**Enable tests by setting**: `testFirstEmpty`, `testRestEmpty`, `testLastEmpty`, `testSliceOutOfBounds`, `testAppendNonList`, `testPrependNonList` to `true`

### 13. test-13-string-operation-error
**Description**: Test for string operation errors  
**Tests**:
- substr with invalid indices
- trunc with negative length
- atoi with non-numeric string
- int64 with invalid string
- float64 with invalid string

**Enable tests by setting**: `testSubstrInvalid`, `testTruncNegative`, `testAtoiInvalid`, `testInt64Invalid`, `testFloat64Invalid` to `true`

### 14. test-14-map-dict-error
**Description**: Test for map/dict operation errors  
**Tests**:
- pluck on empty required list
- hasKey on non-map
- keys on non-dict
- values on non-dict
- merge with non-dict

**Enable tests by setting**: `testPluckRequired`, `testHasKeyNonMap`, `testKeysNonDict`, `testValuesNonDict`, `testMergeNonDict` to `true`

### 15. test-15-date-time-error
**Description**: Test for date/time parsing errors  
**Tests**:
- Invalid date format string
- Invalid timezone
- toDate with invalid string
- dateModify with invalid operation
- Duration with invalid format

**Enable tests by setting**: `testInvalidDateFormat`, `testInvalidTimezone`, `testToDateInvalid`, `testDateModifyInvalid`, `testDurationInvalid` to `true`

### 16. test-16-crypto-error
**Description**: Test for cryptographic function errors  
**Tests**:
- base64Decode with invalid input
- genPrivateKey with invalid algorithm
- encryptAES with wrong key size
- decryptAES with invalid data
- derivePassword with invalid params

**Enable tests by setting**: `testBase64DecodeInvalid`, `testGenPrivateKeyInvalid`, `testEncryptAESInvalid`, `testDecryptAESInvalid`, `testDerivePasswordInvalid` to `true`

### 17. test-17-helper-template
**Description**: Test for helper template errors  
**Tests**:
- Helper with undefined variable
- Helper with syntax error
- Helper with type mismatch
- Helper with division by zero
- Helper with required function
- Helper with nil pointer
- Helper calling missing template
- Helper with invalid function

**Enable tests by setting**: `testHelperUndefinedVar`, `testHelperSyntaxError`, `testHelperTypeMismatch`, `testHelperDivZero`, `testHelperRequired`, `testHelperNilPointer`, `testHelperMissingInclude`, `testHelperInvalidFunc` to `true`

### 18. test-18-tpl-function
**Description**: Test for tpl function errors  
**Tests**:
- tpl with syntax error in template string
- tpl with undefined variable
- tpl with required function
- tpl with division by zero
- tpl with type mismatch
- tpl with nil pointer
- tpl with invalid function
- tpl with missing template include
- tpl with fail function
- Nested tpl errors

**Enable tests by setting**: `testTplSyntaxError`, `testTplUndefinedVar`, `testTplRequired`, `testTplDivZero`, `testTplTypeMismatch`, `testTplNilPointer`, `testTplInvalidFunc`, `testTplMissingTemplate`, `testTplFail`, `testTplNested` to `true`

### 19. test-19-files-advanced
**Description**: Test for advanced file operations errors  
**Tests**:
- Files.Bytes on required missing file
- Files.Lines on file with errors
- Files.AsSecrets with invalid content
- Files.Glob with invalid pattern
- Files.Get on empty result
- AsConfig on required empty
- File content processing errors
- Nil file path

**Enable tests by setting**: `testFilesBytesRequired`, `testFilesLines`, `testFilesAsSecrets`, `testFilesGlobInvalid`, `testFilesGetEmpty`, `testFilesAsConfigRequired`, `testFilesContentError`, `testFilesNilPath` to `true`

## Usage

### Testing Individual Error Types

To test a specific error type, navigate to that test's directory and use Helm's template rendering:

```bash
# Test required function failures
cd test-01-required-function
helm template test . --set testRequired=true

# Test fail function
cd test-02-fail-function
helm template test . --set testFailCondition=true

# Test multiple scenarios in one chart
cd test-03-type-mismatch
helm template test . --set testRangeNumber=true --set testMathString=true
```

### Running All Tests

You can create a script to run all tests and collect results:

```bash
# PowerShell example
Get-ChildItem -Directory -Filter "test-*" | ForEach-Object {
    Write-Host "Testing: $($_.Name)"
    helm template test $_.FullName
}
```

### Automated Testing

For CI/CD pipelines, you can enable specific tests and verify expected failures:

```bash
# Example: Verify that required function test fails as expected
helm template test ./test-01-required-function --set testRequired=true 2>&1 | grep -q "database.port is required" && echo "PASS" || echo "FAIL"
```

## Benefits of Isolated Testing

1. **Precise Error Identification**: Each chart focuses on one type of error
2. **Independent Testing**: Tests don't interfere with each other
3. **Clear Documentation**: Easy to understand what each test validates
4. **Selective Execution**: Run only the tests relevant to your changes
5. **Better Debugging**: Isolated failures are easier to diagnose
6. **Educational**: Learn about specific Helm error types

## Original Combined Chart

The original combined chart is still available in the `tests/` directory for reference. It contains all test scenarios in a single chart with flags to enable/disable each test.

## Notes

- All tests are disabled by default (set to `false` in values.yaml)
- Enable tests by setting the corresponding flag to `true`
- Some tests require missing values to trigger errors (documented in values.yaml)
- Test 17 includes `_helpers.tpl` for helper template testing
- Each chart is versioned as `0.1.0` for initial testing

## Contributing

When adding new test scenarios:
1. Create a new directory following the naming pattern `test-XX-descriptive-name`
2. Include Chart.yaml, values.yaml, and templates/
3. Document the test in this README
4. Ensure all tests are disabled by default
5. Add clear comments explaining the error scenario
