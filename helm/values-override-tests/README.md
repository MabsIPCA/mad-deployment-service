# Helm Values Override Test Chart

This chart demonstrates how Helm handles multiple values files and the override precedence rules.

## Override Precedence Rules

When using multiple values files, Helm applies them in order with **rightmost precedence**:

```
values.yaml < -f file1.yaml < -f file2.yaml < -f file3.yaml < --set flags
```

The rightmost value wins for any given key.

## Key Concepts

### 1. Object/Map Merging (Deep Merge)
When overriding nested objects, Helm performs a **deep merge**. Only the specified fields are overridden; others keep their previous values.

**Example:**
```yaml
# values.yaml
database:
  host: "localhost"
  port: 5432
  name: "base_db"

# values-dev.yaml
database:
  host: "dev-db.local"
  name: "dev_db"
  # port is NOT specified, so it keeps the value 5432 from values.yaml
```

**Result:** `database.port` remains `5432`, while `host` and `name` are overridden.

### 2. List/Array Replacement (Complete Replacement)
Unlike objects, **lists are completely replaced**, not merged.

**Example:**
```yaml
# values.yaml
tags:
  - "base"
  - "default"

# values-dev.yaml
tags:
  - "dev"
  - "development"
```

**Result:** The final `tags` list is `["dev", "development"]`. The base values are completely replaced.

### 3. Type Changes
Values can change types across override files.

**Example:**
```yaml
# values.yaml
replicas: 1  # number

# values-override.yaml
replicas: "3"  # string
```

This is valid, but be careful as it may cause template errors if your templates expect a specific type.

### 4. Null Values
Setting a value to `null` in an override file will set it to null, overriding any previous value.

## Test Scenarios

### Scenario 1: Base Values Only
```bash
helm template test ./helm/values-override-tests
```
Uses only `values.yaml` - all default values.

### Scenario 2: Development Override
```bash
helm template test ./helm/values-override-tests -f ./helm/values-override-tests/values-dev.yaml
```
Applies development overrides on top of base values.

**Expected changes:**
- `environment`: "development"
- `replicas`: 2
- `database.host`: "dev-db.local" (other database fields keep base values)
- `tags`: completely replaced with dev tags
- `config.logLevel`: "debug"

### Scenario 3: Production Override
```bash
helm template test ./helm/values-override-tests -f ./helm/values-override-tests/values-prod.yaml
```
Applies production overrides on top of base values.

**Expected changes:**
- `environment`: "production"
- `replicas`: 5
- Complete database configuration override
- Production-specific resource limits
- All monitoring features enabled

### Scenario 4: Multiple Overrides (Precedence Test)
```bash
helm template test ./helm/values-override-tests \
  -f ./helm/values-override-tests/values-dev.yaml \
  -f ./helm/values-override-tests/values-override-precedence.yaml
```
Applies dev overrides first, then precedence overrides.

**Expected final values:**
- `environment`: "staging" (from precedence file, overrides "development" from dev file)
- `replicas`: 3 (from precedence file, overrides 2 from dev file)
- `database.host`: "staging-db.local" (from precedence file)
- `database.name`: "dev_db" (from dev file, not overridden by precedence file)
- `database.port`: 5432 (from base, not overridden by either file)

### Scenario 5: Three Override Files
```bash
helm template test ./helm/values-override-tests \
  -f ./helm/values-override-tests/values-dev.yaml \
  -f ./helm/values-override-tests/values-prod.yaml \
  -f ./helm/values-override-tests/values-override-precedence.yaml
```
Demonstrates complex precedence with three override files.

### Scenario 6: Type Changes
```bash
helm template test ./helm/values-override-tests -f ./helm/values-override-tests/values-type-changes.yaml
```
Shows what happens when value types change.

**Expected changes:**
- `replicas`: "3" (string instead of number)
- `database`: "connection-string://..." (string instead of object)
- `tags`: object instead of list
- `appName`: object instead of string

### Scenario 7: Using --set with Override Files
```bash
helm template test ./helm/values-override-tests \
  -f ./helm/values-override-tests/values-dev.yaml \
  --set environment=custom \
  --set replicas=10
```
The `--set` flags have the highest precedence and will override values from all files.

**Expected final values:**
- `environment`: "custom" (from --set, overrides "development" from dev file)
- `replicas`: 10 (from --set, overrides 2 from dev file)

### Scenario 8: Setting Nested Values with --set
```bash
helm template test ./helm/values-override-tests \
  -f ./helm/values-override-tests/values-dev.yaml \
  --set database.host=override-db.local \
  --set config.logLevel=trace
```
You can override specific nested values using dot notation.

## Inspecting Merged Values

The chart includes a ConfigMap (`values-display.yaml`) that shows all merged values. Look for the `all-values` key in the ConfigMap to see the complete merged values structure:

```bash
helm template test ./helm/values-override-tests -f values-dev.yaml | grep -A 100 "all-values:"
```

## Files in This Chart

- **Chart.yaml** - Chart metadata
- **values.yaml** - Base default values
- **values-dev.yaml** - Development environment overrides
- **values-prod.yaml** - Production environment overrides
- **values-override-precedence.yaml** - Third override file for precedence testing
- **values-type-changes.yaml** - Demonstrates type changes across overrides
- **templates/values-display.yaml** - ConfigMap showing all merged values
- **templates/deployment.yaml** - Sample deployment using merged values

## Common Patterns

### Pattern 1: Environment-Specific Overrides
Keep base values in `values.yaml` and create environment-specific files:
- `values-dev.yaml`
- `values-staging.yaml`
- `values-prod.yaml`

### Pattern 2: Layered Overrides
Use multiple override files for different concerns:
```bash
helm install myapp ./chart \
  -f values-base.yaml \
  -f values-region-us-east.yaml \
  -f values-env-prod.yaml \
  -f values-team-specific.yaml
```

### Pattern 3: Secrets Separation
Keep sensitive values in a separate file:
```bash
helm install myapp ./chart \
  -f values.yaml \
  -f values-secrets.yaml  # Not committed to git
```

## Tips

1. **Use `helm template` to test**: Always test your overrides with `helm template` before installing
2. **Check merged values**: Use the values-display ConfigMap to verify the final merged state
3. **Be careful with lists**: Remember that lists are replaced, not merged
4. **Document your override strategy**: Make it clear which files override which values
5. **Use `--debug` flag**: Add `--debug` to see more details about value merging

