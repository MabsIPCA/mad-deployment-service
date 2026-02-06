# Test 12: List Operation Errors - Test Results

## Summary Table

| Function | Result | Error Type | Description |
|----------|--------|------------|-------------|
| `first` | ❌ FAIL | `nil pointer dereference` | Fails when called on nil list |
| `mustFirst` | ❌ FAIL | `nil pointer dereference` | Fails when called on nil list |
| `rest` | ✅ PASS | - | Returns empty list [] on empty/nil list |
| `mustRest` | ✅ PASS | - | Returns empty list [] on empty/nil list |
| `last` | ✅ PASS | - | Returns empty string on empty/nil list |
| `mustLast` | ✅ PASS | - | Returns empty string on empty/nil list |
| `initial` | ✅ PASS | - | Returns empty list [] on empty/nil list |
| `mustInitial` | ✅ PASS | - | Returns empty list [] on empty/nil list |
| `append` | ❌ FAIL | `Cannot push on type string` | Fails when called on non-list (string) |
| `mustAppend` | ❌ FAIL | `Cannot push on type string` | Fails when called on non-list (string) |
| `prepend` | ❌ FAIL | `Cannot prepend on type string` | Fails when called on non-list (string) |
| `mustPrepend` | ❌ FAIL | `Cannot prepend on type string` | Fails when called on non-list (string) |
| `concat` | ❌ FAIL | `Cannot concat type string as list` | Fails when trying to concat non-list |
| `reverse` | ❌ FAIL | `Cannot find reverse on type string` | Fails when called on non-list (string) |
| `mustReverse` | ❌ FAIL | `Cannot find reverse on type string` | Fails when called on non-list (string) |
| `uniq` | ❌ FAIL | `Cannot find uniq on type string` | Fails when called on non-list (string) |
| `mustUniq` | ❌ FAIL | `Cannot find uniq on type string` | Fails when called on non-list (string) |
| `without` | ❌ FAIL | `Cannot find without on type string` | Fails when called on non-list (string) |
| `mustWithout` | ❌ FAIL | `Cannot find without on type string` | Fails when called on non-list (string) |
| `has` | ❌ FAIL | `Cannot find has on type string` | Fails when called on non-list (string) |
| `mustHas` | ❌ FAIL | `Cannot find has on type string` | Fails when called on non-list (string) |
| `compact` | ❌ FAIL | `Cannot compact on type string` | Fails when called on non-list (string) |
| `mustCompact` | ❌ FAIL | `Cannot compact on type string` | Fails when called on non-list (string) |
| `index` | ❌ FAIL | `index out of range` | Fails when index exceeds list bounds |
| `slice` | ❌ FAIL | `slice index out of bounds` | Fails when slice range exceeds list bounds |
| `mustSlice` | ❌ FAIL | `slice index out of bounds` | Fails when slice range exceeds list bounds |
| `until` | ❌ FAIL | `wrong type; expected int; got float64` | Fails with wrong type (needs int literal) |
| `untilStep` | ✅ PASS | - | Does not fail with zero step (returns empty list) |
| `seq` | ❌ FAIL | `wrong type; expected int; got string` | Fails when given string instead of int |
| `chunk` | ❌ FAIL | `wrong type; expected int; got float64` | Fails with wrong type (needs int literal) |

## Key Findings

### Functions that DON'T fail (unexpectedly):
- `rest` and `mustRest` - return empty list on nil/empty lists
- `last` and `mustLast` - return empty string on nil/empty lists  
- `initial` and `mustInitial` - return empty list on nil/empty lists
- `untilStep` - returns empty list with zero step instead of failing

### Functions that FAIL with nil lists:
- `first`, `mustFirst` - nil pointer dereference

### Functions that FAIL with non-list types (string):
- All append, prepend, concat, reverse, uniq, without, has, compact functions

### Functions that FAIL with index/range errors:
- `index`, `slice`, `mustSlice`

### Functions that FAIL with type errors:
- `until`, `seq`, `chunk` - require int literals, fail with float64 or string
