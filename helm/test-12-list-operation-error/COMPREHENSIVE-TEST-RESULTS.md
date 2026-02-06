# Test 12: List Operation Errors - Comprehensive Test Results

## Overview
Comprehensive testing of all list functions against multiple data types to identify which data types cause failures.

**Total Tests:** 208  
**Passed:** 73 (35.1%)  
**Failed:** 135 (64.9%)

## Test Matrix - All Functions vs All Data Types

| Function | nilList | emptyList | stringValue | numberValue | boolValue | dictValue | validList | shortList |
|----------|---------|-----------|-------------|-------------|-----------|-----------|-----------|-----------|
| `first` | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| `mustFirst` | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| `rest` | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| `mustRest` | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| `last` | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| `mustLast` | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| `initial` | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| `mustInitial` | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| `append` | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| `mustAppend` | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| `prepend` | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| `mustPrepend` | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| `concat` | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| `reverse` | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| `mustReverse` | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| `uniq` | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| `mustUniq` | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| `without` | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| `mustWithout` | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| `has` | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| `mustHas` | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| `compact` | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| `mustCompact` | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| `index` | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `slice` | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `mustSlice` | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

## Detailed Error Messages by Data Type

### nilList (null)
- **Most functions:** `invalid memory address or nil pointer dereference`
- **has/mustHas:** PASS (returns false)
- **index:** `index of untyped nil`

### emptyList ([])
- **Most functions:** PASS (return empty values)
- **index:** `index out of range: 10`
- **slice/mustSlice:** PASS (returns empty list)

### stringValue ("not a list")
- **first/mustFirst:** `Cannot find first on type string`
- **rest/mustRest:** `Cannot find rest on type string`
- **last/mustLast:** `Cannot find last on type string`
- **initial/mustInitial:** `Cannot find initial on type string`
- **append/mustAppend:** `Cannot push on type string`
- **prepend/mustPrepend:** `Cannot prepend on type string`
- **concat:** `Cannot concat type string as list`
- **reverse/mustReverse:** `Cannot find reverse on type string`
- **uniq/mustUniq:** `Cannot find uniq on type string`
- **without/mustWithout:** `Cannot find without on type string`
- **has/mustHas:** `Cannot find has on type string`
- **compact/mustCompact:** `Cannot compact on type string`
- **index:** `reflect: string index out of range`
- **slice/mustSlice:** `list should be type of slice or array but string`

### numberValue (42)
- **All list functions:** `Cannot find [function] on type float64`
- **append/mustAppend:** `Cannot push on type float64`
- **prepend/mustPrepend:** `Cannot prepend on type float64`
- **concat:** `Cannot concat type float64 as list`
- **compact/mustCompact:** `Cannot compact on type float64`
- **index:** `can't index item of type float64`
- **slice/mustSlice:** `list should be type of slice or array but float64`

### boolValue (true)
- **All list functions:** `Cannot find [function] on type bool`
- **append/mustAppend:** `Cannot push on type bool`
- **prepend/mustPrepend:** `Cannot prepend on type bool`
- **concat:** `Cannot concat type bool as list`
- **compact/mustCompact:** `Cannot compact on type bool`
- **index:** `can't index item of type bool`
- **slice/mustSlice:** `list should be type of slice or array but bool`

### dictValue ({"key": "value"})
- **All list functions:** `Cannot find [function] on type map`
- **append/mustAppend:** `Cannot push on type map`
- **prepend/mustPrepend:** `Cannot prepend on type map`
- **concat:** `Cannot concat type map as list`
- **compact/mustCompact:** `Cannot compact on type map`
- **index:** `value has type int; should be string` (tries to use 10 as dict key)
- **slice/mustSlice:** `list should be type of slice or array but map`

### validList ([1, 2, 3])
- **Most functions:** PASS
- **index:** `index out of range: 10` (list has only 3 elements)
- **slice/mustSlice:** `reflect.Value.Slice: slice index out of bounds` (trying to slice 5:10)

### shortList ([1, 2])
- **Most functions:** PASS
- **index:** `index out of range: 10` (list has only 2 elements)
- **slice/mustSlice:** `reflect.Value.Slice: slice index out of bounds` (trying to slice 5:10)

## Summary by Function

### Functions with Most Compatibility (4 PASS / 4 FAIL)
- `has`, `mustHas` - Only fail on non-list types, work with nil and empty lists

### Functions with Moderate Compatibility (3 PASS / 5 FAIL)
Most list functions fall into this category:
- `first`, `mustFirst`, `rest`, `mustRest`, `last`, `mustLast`
- `initial`, `mustInitial`, `append`, `mustAppend`, `prepend`, `mustPrepend`
- `concat`, `reverse`, `mustReverse`, `uniq`, `mustUniq`
- `without`, `mustWithout`, `compact`, `mustCompact`

**Pass on:** emptyList, validList, shortList  
**Fail on:** nilList, stringValue, numberValue, boolValue, dictValue

### Functions with Least Compatibility
- **`index`** - 0 PASS / 8 FAIL (fails on ALL data types due to out of bounds index)
- **`slice`, `mustSlice`** - 1 PASS / 7 FAIL (only pass on emptyList)

## Key Findings

1. **Empty lists are safe** - Most functions handle `[]` gracefully
2. **Nil lists are dangerous** - Most functions fail with nil pointer dereference (except has/mustHas)
3. **Type checking is strict** - All non-list types (string, number, bool, dict) cause failures
4. **has/mustHas are most resilient** - Only functions that work with nil lists
5. **Index operations are fragile** - Even valid lists fail with out-of-bounds indices
6. **must* variants behave identically** - No difference between must and non-must versions for these tests

## Usage

To run these tests:

```powershell
# Run comprehensive tests on all functions and all data types
.\helm\test-12-list-operation-error\test-all-data-types.ps1

# Test a specific function with a specific data type
helm template .\helm\test-12-list-operation-error\ --set testFirst=true --set testDataType=nilList

# View results
# - test-results-comprehensive.csv - Detailed results
# - test-matrix.csv - Matrix view of all tests
```

## Files Generated

- `test-all-data-types.ps1` - Comprehensive test script
- `test-results-comprehensive.csv` - Detailed test results (208 rows)
- `test-matrix.csv` - Matrix view showing PASS/FAIL for each function × data type combination
