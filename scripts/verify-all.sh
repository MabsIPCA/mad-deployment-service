#!/usr/bin/env bash
# End-to-end exploit verification harness.
# Usage:
#   bash scripts/verify-all.sh vulnerable   # after: make reset-vulnerable
#   bash scripts/verify-all.sh safe         # after: make reset-safe
#
# In 'vulnerable' mode: every script must exit 0   (exploit succeeds = PASS)
# In 'safe' mode:       every script must exit !=0 (exploit blocked  = PASS)
set -euo pipefail

MODE="${1:-vulnerable}"
if [[ "$MODE" != "vulnerable" && "$MODE" != "safe" ]]; then
  echo "Usage: $0 <vulnerable|safe>" >&2; exit 2
fi

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/exploits" && pwd)"
PASS=0
FAIL=0
declare -a RESULTS

FULL_IDS=(
  k01-runAsRoot
  k01-readOnlyRootFs
  k01-privileged
  k01-unboundedResources
  k02-clusterAdminBinding
  k02-secretsListWatch
  k03-plaintextConfigMapSecrets
  k03-jwtKeyInEnv
  k04-noPSA
  k04-weakKyverno
  k05-noDefaultDeny
  k05-permissiveNetpol
  k05-noEgressControls
  k06-traefikDashboardExposed
  k06-rabbitmqMgmtExposed
  k07-kubeletAnonymousAuth
  k07-kubeletAlwaysAllow
  k09-anonymousKeycloakBootstrap
  k09-sharedServiceAccount
  k10-noAuditPolicy
)

for id in "${FULL_IDS[@]}"; do
  script="$SCRIPTS_DIR/$id.sh"
  if [[ ! -f "$script" ]]; then
    echo "  MISSING  $id  (script not found: $script)"
    FAIL=$((FAIL + 1))
    RESULTS+=("MISSING  $id")
    continue
  fi

  set +e
  output=$(bash "$script" 2>&1)
  exit_code=$?
  set -e

  if [[ "$MODE" == "vulnerable" ]]; then
    if [[ $exit_code -eq 0 ]]; then
      printf "  PASS  %-40s  %s\n" "$id" "$output"
      PASS=$((PASS + 1))
      RESULTS+=("PASS     $id")
    else
      printf "  FAIL  %-40s  exit=%d  %s\n" "$id" "$exit_code" "$output"
      FAIL=$((FAIL + 1))
      RESULTS+=("FAIL     $id (exit $exit_code): $output")
    fi
  else
    if [[ $exit_code -ne 0 ]]; then
      printf "  PASS  %-40s  (exploit blocked)\n" "$id"
      PASS=$((PASS + 1))
      RESULTS+=("PASS     $id")
    else
      printf "  FAIL  %-40s  (exploit still works in safe mode!)  %s\n" "$id" "$output"
      FAIL=$((FAIL + 1))
      RESULTS+=("FAIL     $id: $output")
    fi
  fi
done

echo ""
echo "=== verify-all ($MODE mode): $PASS passed, $FAIL failed of ${#FULL_IDS[@]} ==="
[[ $FAIL -eq 0 ]]