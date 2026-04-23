# Kubernetes Vulnerability Injection — Chart & Cluster Implementation Plan (Plan A)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Inject all 19 full-entry OWASP K8s Top 10 (2025) vulnerabilities into the `madgoat` and `madgoat-infra` Helm charts plus sibling cluster-level artifacts, each with a `values.yaml` toggle (default = vulnerable) and an exploit verification script.

**Architecture:** Boolean `vulnerabilities.*` flags in both charts' `values.yaml` gate negative-form template branches (`if not flag` → adds the defence). Chart-level items (K01–K03, K05–K06, K09) live in Helm templates; cluster-level items (K04, K07, K10) live in `k8s/insecure-defaults/` and are applied via kustomize. A ground-truth YAML at `thesis/kubernetes-vulns/data/vulnerabilities.yaml` is the single source of truth for tables (consumed in Plan B).

**Tech Stack:** Helm 3, Kubernetes 1.29+ (Minikube), kubectl, bash, kustomize, Kyverno 1.12+ (K04 only).

---

## File map (created or modified in this plan)

### Created
- `helm/madgoat/templates/serviceaccount.yaml` — K09 per-service SA (safe mode)
- `helm/madgoat/templates/secret.yaml` — K03 safe-mode Secrets
- `helm/madgoat-infra/templates/rbac.yaml` — K02 RBAC for infra chart (K02 items are infra-only)
- `helm/madgoat-infra/templates/serviceaccount.yaml` — K09 per-service SA
- `helm/madgoat-infra/templates/secret.yaml` — K03 safe-mode Secrets
- `k8s/insecure-defaults/README.md`
- `k8s/insecure-defaults/kustomization.yaml`
- `k8s/insecure-defaults/admission-no-psa.yaml` — K04
- `k8s/insecure-defaults/kyverno-weak-policies.yaml` — K04
- `k8s/insecure-defaults/kubelet-config.yaml` — K07
- `k8s/insecure-defaults/audit-policy-missing.md` — K10 documented absence
- `k8s/insecure-defaults/audit-policy-safe.yaml` — K10 safe-mode reference
- `scripts/exploits/k01-runAsRoot.sh`
- `scripts/exploits/k01-readOnlyRootFs.sh`
- `scripts/exploits/k01-privileged.sh`
- `scripts/exploits/k01-unboundedResources.sh`
- `scripts/exploits/k02-clusterAdminBinding.sh`
- `scripts/exploits/k02-secretsListWatch.sh`
- `scripts/exploits/k03-plaintextConfigMapSecrets.sh`
- `scripts/exploits/k03-jwtKeyInEnv.sh`
- `scripts/exploits/k04-noPSA.sh`
- `scripts/exploits/k04-weakKyverno.sh`
- `scripts/exploits/k05-noDefaultDeny.sh`
- `scripts/exploits/k05-permissiveNetpol.sh`
- `scripts/exploits/k05-noEgressControls.sh`
- `scripts/exploits/k06-traefikDashboardExposed.sh`
- `scripts/exploits/k06-rabbitmqMgmtExposed.sh`
- `scripts/exploits/k07-kubeletAnonymousAuth.sh`
- `scripts/exploits/k07-kubeletAlwaysAllow.sh`
- `scripts/exploits/k09-anonymousKeycloakBootstrap.sh`
- `scripts/exploits/k09-sharedServiceAccount.sh`
- `scripts/exploits/k10-noAuditPolicy.sh`
- `thesis/kubernetes-vulns/data/vulnerabilities.yaml`

### Modified
- `helm/madgoat/values.yaml` — add `vulnerabilities:` block
- `helm/madgoat/templates/deployment.yaml` — K01, K09 branches
- `helm/madgoat-infra/values.yaml` — add `vulnerabilities:` block
- `helm/madgoat-infra/templates/core.yaml` — K01, K09 branches
- `helm/madgoat-infra/templates/db.yaml` — K01 branches
- `helm/madgoat-infra/templates/core-services.yaml` — K06 rabbitmq management route gate
- `helm/madgoat-infra/templates/dashboard.yaml` — K06 gate
- `helm/madgoat-infra/templates/mad-network-networkpolicy.yaml` — K05 branches
- `makefile` — new targets

---

## Task 0: Foundation — directory structure and ground-truth data

**Files:**
- Create: `thesis/kubernetes-vulns/data/vulnerabilities.yaml`
- Create: `scripts/exploits/.gitkeep`
- Create: `k8s/insecure-defaults/README.md`
- Create: `k8s/insecure-defaults/kustomization.yaml`

- [ ] **Step 0.1: Create directory tree**

```bash
mkdir -p thesis/kubernetes-vulns/data \
          thesis/kubernetes-vulns/tables \
          thesis/kubernetes-vulns/scripts \
          thesis/kubernetes-vulns/snippets \
          scripts/exploits \
          k8s/insecure-defaults
```

- [ ] **Step 0.2: Create ground-truth vulnerabilities.yaml**

Create `thesis/kubernetes-vulns/data/vulnerabilities.yaml`:

```yaml
# Single source of truth for Tables 2 & 3 in Plan B.
# scope: chart | cluster
# class: full | conceptual | discussion
- id: k01-runAsRoot
  owasp2025: K01
  owasp2022: K01
  title: "Run-as-root containers"
  cwe: 250
  cis: "5.2.6"
  scope: chart
  class: full
  chart: both
  valuesFlag: vulnerabilities.k01_runAsRoot
  scanners: { kics: "cf34805e-3872-4c08-bf92-6ff7bb0cfadb", trivy: KSV012, kubelinter: run-as-non-root, kubescape: C-0013 }
  presentPreInjection: false

- id: k01-readOnlyRootFs
  owasp2025: K01
  owasp2022: K01
  title: "Writable root filesystem"
  cwe: 276
  cis: ""
  scope: chart
  class: full
  chart: both
  valuesFlag: vulnerabilities.k01_readOnlyRootFs
  scanners: { kics: "a9c2f49d-0671-4fc9-9ece-f4e261e128d0", trivy: KSV014, kubelinter: read-only-root-fs, kubescape: C-0017 }
  presentPreInjection: false

- id: k01-privileged
  owasp2025: K01
  owasp2022: K01
  title: "Privileged containers"
  cwe: 250
  cis: "5.2.2"
  scope: chart
  class: full
  chart: madgoat
  valuesFlag: vulnerabilities.k01_privileged
  scanners: { kics: "dd29336b-fe57-445b-a26e-e6aa867ae609", trivy: KSV017, kubelinter: privileged-container, kubescape: C-0016 }
  presentPreInjection: false

- id: k01-unboundedResources
  owasp2025: K01
  owasp2022: K01
  title: "Unbounded resource usage"
  cwe: 400
  cis: ""
  scope: chart
  class: full
  chart: madgoat
  valuesFlag: vulnerabilities.k01_unboundedResources
  scanners: { kics: "b14d1bc4-a208-45db-92f0-e21f8e2588e9", trivy: "KSV011/KSV018", kubelinter: unset-memory-requirements, kubescape: C-0009 }
  presentPreInjection: false

- id: k02-clusterAdminBinding
  owasp2025: K02
  owasp2022: K03
  title: "Default SA bound to cluster-admin"
  cwe: 269
  cis: "5.1.1"
  scope: chart
  class: full
  chart: madgoat-infra
  valuesFlag: vulnerabilities.k02_clusterAdminBinding
  scanners: { kics: "249328b8-5f0f-409f-b1dd-029f07882e11", trivy: KSV111, kubelinter: cluster-admin-role-binding, kubescape: C-0035 }
  presentPreInjection: false

- id: k02-secretsListWatch
  owasp2025: K02
  owasp2022: K03
  title: "Role with list/watch on Secrets"
  cwe: 732
  cis: "5.1.3"
  scope: chart
  class: full
  chart: madgoat-infra
  valuesFlag: vulnerabilities.k02_secretsListWatch
  scanners: { kics: "b7bca5c4-1dab-4c2c-8cbe-3050b9d59b14", trivy: KSV041, kubelinter: access-to-secrets, kubescape: C-0015 }
  presentPreInjection: false

- id: k03-plaintextConfigMapSecrets
  owasp2025: K03
  owasp2022: K08
  title: "Credentials in plaintext ConfigMap"
  cwe: 522
  cis: "5.4.1"
  scope: chart
  class: full
  chart: both
  valuesFlag: vulnerabilities.k03_plaintextConfigMapSecrets
  scanners: { kics: "3d658f8b-d988-41a0-a841-40043121de1e", trivy: AVD-KSV-0109, kubelinter: "", kubescape: C-0207 }
  presentPreInjection: true

- id: k03-jwtKeyInEnv
  owasp2025: K03
  owasp2022: K08
  title: "JWT signing key in env (ConfigMap)"
  cwe: 522
  cis: "5.4.2"
  scope: chart
  class: full
  chart: madgoat
  valuesFlag: vulnerabilities.k03_jwtKeyInEnv
  scanners: { kics: "b9c83569-459b-4110-8f79-6305aa33cb37", trivy: AVD-KSV-0109, kubelinter: "", kubescape: C-0066 }
  presentPreInjection: true

- id: k04-noPSA
  owasp2025: K04
  owasp2022: K04
  title: "Namespace without Pod Security Admission"
  cwe: 693
  cis: "1.2.9"
  scope: cluster
  class: full
  chart: k8s/insecure-defaults
  valuesFlag: ""
  scanners: { kics: "ce30e584-b33f-4c7d-b418-a3d7027f8f60", trivy: KSV0010, kubelinter: "", kubescape: C-0122 }
  presentPreInjection: true

- id: k04-weakKyverno
  owasp2025: K04
  owasp2022: K04
  title: "Kyverno installed with no-op rules"
  cwe: 693
  cis: "1.2.12"
  scope: cluster
  class: full
  chart: k8s/insecure-defaults
  valuesFlag: ""
  scanners: { kics: "", trivy: "", kubelinter: "", kubescape: C-0123 }
  presentPreInjection: false

- id: k05-noDefaultDeny
  owasp2025: K05
  owasp2022: K07
  title: "No default-deny NetworkPolicy"
  cwe: 923
  cis: "5.3.2"
  scope: chart
  class: full
  chart: madgoat-infra
  valuesFlag: vulnerabilities.k05_noDefaultDeny
  scanners: { kics: "03aabc8c-35d6-481e-9c85-20139cf72d2", trivy: KSV038, kubelinter: non-isolated-pod, kubescape: C-0205 }
  presentPreInjection: true

- id: k05-permissiveNetpol
  owasp2025: K05
  owasp2022: K07
  title: "Overly permissive label-based NetworkPolicy"
  cwe: 923
  cis: "5.3.1"
  scope: chart
  class: full
  chart: madgoat-infra
  valuesFlag: vulnerabilities.k05_permissiveNetpol
  scanners: { kics: "85ab1c5b-014e-4352-b5f8-d7dea3bb4fd3", trivy: KSV038, kubelinter: dangling-networkpolicy, kubescape: C-0206 }
  presentPreInjection: true

- id: k05-noEgressControls
  owasp2025: K05
  owasp2022: K07
  title: "Missing egress controls"
  cwe: 923
  cis: "5.3.1"
  scope: chart
  class: full
  chart: madgoat-infra
  valuesFlag: vulnerabilities.k05_noEgressControls
  scanners: { kics: "0401f71b-9c1e-4821-ab15-a955caa621be", trivy: KSV038, kubelinter: dangling-networkpolicypeer-podselector, kubescape: C-0054 }
  presentPreInjection: true

- id: k06-traefikDashboardExposed
  owasp2025: K06
  owasp2022: ""
  title: "Traefik dashboard publicly exposed"
  cwe: 284
  cis: ""
  scope: chart
  class: full
  chart: madgoat-infra
  valuesFlag: vulnerabilities.k06_traefikDashboardExposed
  scanners: { kics: "", trivy: "", kubelinter: "", kubescape: "" }
  presentPreInjection: true

- id: k06-rabbitmqMgmtExposed
  owasp2025: K06
  owasp2022: ""
  title: "RabbitMQ management UI publicly exposed"
  cwe: 284
  cis: ""
  scope: chart
  class: full
  chart: madgoat-infra
  valuesFlag: vulnerabilities.k06_rabbitmqMgmtExposed
  scanners: { kics: "", trivy: "", kubelinter: "", kubescape: "" }
  presentPreInjection: true

- id: k07-kubeletAnonymousAuth
  owasp2025: K07
  owasp2022: K09
  title: "kubelet anonymous-auth=true"
  cwe: 306
  cis: "1.2.1"
  scope: cluster
  class: full
  chart: k8s/insecure-defaults
  valuesFlag: ""
  scanners: { kics: "1de5cc51-f376-4638-a940-20f2e85ae238", trivy: KCV0001, kubelinter: "", kubescape: C-0113 }
  presentPreInjection: false

- id: k07-kubeletAlwaysAllow
  owasp2025: K07
  owasp2022: K09
  title: "kubelet authorization-mode=AlwaysAllow"
  cwe: 306
  cis: "1.2.6"
  scope: cluster
  class: full
  chart: k8s/insecure-defaults
  valuesFlag: ""
  scanners: { kics: "f1f4d8da-1ac4-47d0-b1aa-91e69d33f7d5", trivy: KCV0007, kubelinter: "", kubescape: C-0120 }
  presentPreInjection: false

- id: k09-anonymousKeycloakBootstrap
  owasp2025: K09
  owasp2022: K06
  title: "Keycloak default admin credentials + start-dev"
  cwe: 200
  cis: ""
  scope: chart
  class: full
  chart: madgoat-infra
  valuesFlag: vulnerabilities.k09_anonymousKeycloakBootstrap
  scanners: { kics: "", trivy: "", kubelinter: "", kubescape: "" }
  presentPreInjection: true

- id: k09-sharedServiceAccount
  owasp2025: K09
  owasp2022: K06
  title: "All pods share the default ServiceAccount"
  cwe: 200
  cis: ""
  scope: chart
  class: full
  chart: both
  valuesFlag: vulnerabilities.k09_sharedServiceAccount
  scanners: { kics: "", trivy: "", kubelinter: "", kubescape: C-0183 }
  presentPreInjection: true

- id: k10-noAuditPolicy
  owasp2025: K10
  owasp2022: K05
  title: "No apiserver audit policy configured"
  cwe: 778
  cis: "1.2.16"
  scope: cluster
  class: full
  chart: k8s/insecure-defaults
  valuesFlag: ""
  scanners: { kics: "13a49a2e-488e-4309-a7c0-d6b05577a5fb", trivy: KCV0019, kubelinter: "", kubescape: C-0130 }
  presentPreInjection: true
```

- [ ] **Step 0.3: Create k8s/insecure-defaults/README.md**

```markdown
# k8s/insecure-defaults

Cluster-level misconfiguration artifacts for OWASP K8s Top 10 (K04, K07, K10).
These are **not** Helm charts — apply them with kustomize after cluster bootstrap.

## Apply (vulnerable mode)
kubectl apply -k k8s/insecure-defaults/

## Remove (safe mode)
kubectl delete -k k8s/insecure-defaults/ --ignore-not-found

## Note
K07 (kubelet flags) and K10 (audit policy) require Minikube restart with
specific --extra-config flags. See makefile targets reset-vulnerable / reset-safe.
```

- [ ] **Step 0.4: Create k8s/insecure-defaults/kustomization.yaml**

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - admission-no-psa.yaml
  - kyverno-weak-policies.yaml
```

- [ ] **Step 0.5: Commit foundation**

```bash
git add thesis/kubernetes-vulns/data/ scripts/exploits/ k8s/insecure-defaults/
git commit -m "feat: add ground-truth data and k8s/insecure-defaults scaffold"
```

---

## Task 1: Makefile — deploy and verify targets

**Files:**
- Modify: `makefile`

- [ ] **Step 1.1: Add vulnerability flag variables and targets to makefile**

Append to the bottom of `makefile`:

```makefile
# All vulnerability flags — default=true (vulnerable benchmark mode)
VULN_FLAGS := \
  --set vulnerabilities.k01_runAsRoot=true \
  --set vulnerabilities.k01_readOnlyRootFs=true \
  --set vulnerabilities.k01_privileged=true \
  --set vulnerabilities.k01_unboundedResources=true \
  --set vulnerabilities.k02_clusterAdminBinding=true \
  --set vulnerabilities.k02_secretsListWatch=true \
  --set vulnerabilities.k03_plaintextConfigMapSecrets=true \
  --set vulnerabilities.k03_jwtKeyInEnv=true \
  --set vulnerabilities.k05_noDefaultDeny=true \
  --set vulnerabilities.k05_permissiveNetpol=true \
  --set vulnerabilities.k05_noEgressControls=true \
  --set vulnerabilities.k06_traefikDashboardExposed=true \
  --set vulnerabilities.k06_rabbitmqMgmtExposed=true \
  --set vulnerabilities.k09_anonymousKeycloakBootstrap=true \
  --set vulnerabilities.k09_sharedServiceAccount=true

SAFE_FLAGS := \
  --set vulnerabilities.k01_runAsRoot=false \
  --set vulnerabilities.k01_readOnlyRootFs=false \
  --set vulnerabilities.k01_privileged=false \
  --set vulnerabilities.k01_unboundedResources=false \
  --set vulnerabilities.k02_clusterAdminBinding=false \
  --set vulnerabilities.k02_secretsListWatch=false \
  --set vulnerabilities.k03_plaintextConfigMapSecrets=false \
  --set vulnerabilities.k03_jwtKeyInEnv=false \
  --set vulnerabilities.k05_noDefaultDeny=false \
  --set vulnerabilities.k05_permissiveNetpol=false \
  --set vulnerabilities.k05_noEgressControls=false \
  --set vulnerabilities.k06_traefikDashboardExposed=false \
  --set vulnerabilities.k06_rabbitmqMgmtExposed=false \
  --set vulnerabilities.k09_anonymousKeycloakBootstrap=false \
  --set vulnerabilities.k09_sharedServiceAccount=false

.PHONY: deploy-vulnerable
deploy-vulnerable:
	cd helm/madgoat-infra && helm dependency build
	helm upgrade --install madgoat-infra ./helm/madgoat-infra $(VULN_FLAGS)
	helm upgrade --install madgoat-app ./helm/madgoat $(VULN_FLAGS)

.PHONY: deploy-safe
deploy-safe:
	cd helm/madgoat-infra && helm dependency build
	helm upgrade --install madgoat-infra ./helm/madgoat-infra $(SAFE_FLAGS)
	helm upgrade --install madgoat-app ./helm/madgoat $(SAFE_FLAGS)
	kubectl delete -k k8s/insecure-defaults/ --ignore-not-found

.PHONY: reset-vulnerable
reset-vulnerable:
	k8s/minikube_setup.sh
	sleep 10
	make deploy-vulnerable
	kubectl apply -k k8s/insecure-defaults/

.PHONY: reset-safe
reset-safe:
	k8s/minikube_setup.sh
	sleep 10
	make deploy-safe

.PHONY: verify-exploit-%
verify-exploit-%:
	@bash scripts/exploits/$*.sh

.PHONY: gen-thesis-tables
gen-thesis-tables:
	bash thesis/kubernetes-vulns/scripts/gen-tables.sh
```

- [ ] **Step 1.2: Verify makefile syntax**

```bash
make --dry-run deploy-vulnerable 2>&1 | head -20
# Expected: prints helm upgrade commands, no parse errors
```

- [ ] **Step 1.3: Commit**

```bash
git add makefile
git commit -m "feat: add deploy-vulnerable, deploy-safe, reset-*, verify-exploit-% makefile targets"
```

---

## Task 2: K01 — Insecure Workload Configurations

**Files:**
- Modify: `helm/madgoat/values.yaml`
- Modify: `helm/madgoat/templates/deployment.yaml`
- Modify: `helm/madgoat-infra/values.yaml`
- Modify: `helm/madgoat-infra/templates/core.yaml`
- Modify: `helm/madgoat-infra/templates/db.yaml`
- Create: `scripts/exploits/k01-runAsRoot.sh`, `k01-readOnlyRootFs.sh`, `k01-privileged.sh`, `k01-unboundedResources.sh`

- [ ] **Step 2.1: Write exploit scripts (tests first)**

Create `scripts/exploits/k01-runAsRoot.sh`:
```bash
#!/bin/bash
set -e
POD=$(kubectl get pod -l io.mad.service=lesson -o jsonpath='{.items[0].metadata.name}')
[ -z "$POD" ] && { echo "ERROR: no lesson pod"; exit 2; }
OUTPUT=$(kubectl exec "$POD" -- id 2>&1)
if echo "$OUTPUT" | grep -q "uid=0(root)"; then
  echo "PASS: lesson runs as root (uid=0) — vulnerable"; exit 0
else
  echo "FAIL: lesson not root — $OUTPUT"; exit 1
fi
```

Create `scripts/exploits/k01-readOnlyRootFs.sh`:
```bash
#!/bin/bash
set -e
POD=$(kubectl get pod -l io.mad.service=lesson -o jsonpath='{.items[0].metadata.name}')
if kubectl exec "$POD" -- touch /test-write-$$ 2>/dev/null; then
  kubectl exec "$POD" -- rm -f /test-write-$$ 2>/dev/null || true
  echo "PASS: root filesystem is writable — vulnerable"; exit 0
else
  echo "FAIL: root filesystem is read-only (safe mode)"; exit 1
fi
```

Create `scripts/exploits/k01-privileged.sh`:
```bash
#!/bin/bash
set -e
POD=$(kubectl get pod -l io.mad.service=mad4shell-unsafe -o jsonpath='{.items[0].metadata.name}')
CAP=$(kubectl exec "$POD" -- cat /proc/1/status | grep CapEff | awk '{print $2}')
# Full capabilities = 0000003fffffffff or platform variant; privileged always has high bits set
if [[ "$CAP" =~ ^0000003[f] ]] || [[ "$CAP" =~ fffffffff ]]; then
  echo "PASS: mad4shell-unsafe has full capabilities (privileged) — vulnerable"; exit 0
else
  echo "FAIL: capabilities restricted — CapEff=$CAP (safe mode)"; exit 1
fi
```

Create `scripts/exploits/k01-unboundedResources.sh`:
```bash
#!/bin/bash
set -e
LIMITS=$(kubectl get pod -l io.mad.service=lesson \
  -o jsonpath='{.items[0].spec.containers[0].resources.limits}' 2>/dev/null)
if [ -z "$LIMITS" ] || [ "$LIMITS" = "null" ] || [ "$LIMITS" = "{}" ]; then
  echo "PASS: lesson pod has no resource limits — DoS possible (vulnerable)"; exit 0
else
  echo "FAIL: resource limits present — $LIMITS (safe mode)"; exit 1
fi
```

Make scripts executable:
```bash
chmod +x scripts/exploits/k01-*.sh
```

- [ ] **Step 2.2: Verify scripts fail against current chart (pre-injection)**

```bash
# Start cluster if not running
minikube status || make reset-vulnerable

# k01-runAsRoot should FAIL (no securityContext set means K8s default uid, not root)
# Note: containers run as whatever user the image sets — MAD images may or may not be root.
# Run to establish baseline:
make verify-exploit-k01-runAsRoot || echo "baseline noted"
make verify-exploit-k01-readOnlyRootFs || echo "baseline noted"
```

- [ ] **Step 2.3: Add vulnerabilities block to helm/madgoat/values.yaml**

Add at the bottom of `helm/madgoat/values.yaml`:

```yaml
vulnerabilities:
  k01_runAsRoot: true
  k01_readOnlyRootFs: true
  k01_privileged: true
  k01_unboundedResources: true
  k03_plaintextConfigMapSecrets: true
  k03_jwtKeyInEnv: true
  k09_sharedServiceAccount: true
```

- [ ] **Step 2.4: Add vulnerabilities block to helm/madgoat-infra/values.yaml**

Add at the bottom of `helm/madgoat-infra/values.yaml`:

```yaml
vulnerabilities:
  k01_runAsRoot: true
  k01_readOnlyRootFs: true
  k02_clusterAdminBinding: true
  k02_secretsListWatch: true
  k03_plaintextConfigMapSecrets: true
  k05_noDefaultDeny: true
  k05_permissiveNetpol: true
  k05_noEgressControls: true
  k06_traefikDashboardExposed: true
  k06_rabbitmqMgmtExposed: true
  k09_anonymousKeycloakBootstrap: true
  k09_sharedServiceAccount: true
```

- [ ] **Step 2.5: Inject K01 branches into helm/madgoat/templates/deployment.yaml**

Replace the container block inside the `{{- range .Values.madServices }}` loop. The new container block (starting after `containers:`) becomes:

```yaml
      containers:
        - name: {{ .name }}
          image: {{ .deployment.image }}
          ports:
          {{- range .deployment.ports }}
            - containerPort: {{ .containerPort }}
              protocol: {{ .protocol }}
          {{- end }}
          securityContext:
            {{- if not $.Values.vulnerabilities.k01_runAsRoot }}
            runAsNonRoot: true
            runAsUser: 10001
            allowPrivilegeEscalation: false
            {{- end }}
            {{- if not $.Values.vulnerabilities.k01_readOnlyRootFs }}
            readOnlyRootFilesystem: true
            {{- end }}
            {{- if and $.Values.vulnerabilities.k01_privileged (or (eq .name "mad4shell-unsafe") (eq .name "profile") (eq .name "webapp")) }}
            privileged: true
            {{- end }}
        {{- if .deployment.envFromConfigMaps }}
          envFrom:
          {{- range .deployment.envFromConfigMaps }}
          - configMapRef:
              name: {{ . }}
          {{- end }}
        {{- end }}
          {{- if not (and $.Values.vulnerabilities.k01_unboundedResources (eq .name "lesson")) }}
          resources:
            limits:
              cpu: {{ .deployment.resources.limits.cpu }}
              memory: "{{ .deployment.resources.limits.memory }}"
            requests:
              cpu: {{ .deployment.resources.requests.cpu }}
              memory: "{{ .deployment.resources.requests.memory }}"
          {{- end }}
      restartPolicy: Always
```

Note: `$.Values` (with `$`) is required to access root-level values from inside a `range` loop.

- [ ] **Step 2.6: Inject K01 into helm/madgoat-infra/templates/core.yaml**

Inside the `containers:` block of `core.yaml` (after the container `name:` and `image:` lines), add the same `securityContext:` block using `$.Values`:

```yaml
      containers:
        - image: {{ .image }}
          name: {{ .name }}
          securityContext:
            {{- if not $.Values.vulnerabilities.k01_runAsRoot }}
            runAsNonRoot: true
            runAsUser: 10001
            allowPrivilegeEscalation: false
            {{- end }}
            {{- if not $.Values.vulnerabilities.k01_readOnlyRootFs }}
            readOnlyRootFilesystem: true
            {{- end }}
```

- [ ] **Step 2.7: Inject K01 into helm/madgoat-infra/templates/db.yaml**

Inside the single container in `db.yaml`, add after the image/name lines:

```yaml
        securityContext:
          {{- if not $.Values.vulnerabilities.k01_runAsRoot }}
          runAsNonRoot: true
          runAsUser: 999
          allowPrivilegeEscalation: false
          {{- end }}
          {{- if not $.Values.vulnerabilities.k01_readOnlyRootFs }}
          readOnlyRootFilesystem: true
          {{- end }}
```

Note: db containers (postgres, mongo, minio) conventionally use uid=999 rather than 10001.

- [ ] **Step 2.8: Verify helm template renders correctly**

```bash
helm template madgoat-app ./helm/madgoat | grep -A8 "securityContext"
# Expected in vulnerable mode (defaults): securityContext block is present but empty
# (only the privileged: true branches appear for mad4shell-unsafe etc.)

helm template madgoat-app ./helm/madgoat \
  --set vulnerabilities.k01_runAsRoot=false | grep -A8 "securityContext"
# Expected: shows runAsNonRoot: true, runAsUser: 10001, allowPrivilegeEscalation: false
```

- [ ] **Step 2.9: Commit K01**

```bash
git add helm/madgoat/values.yaml helm/madgoat/templates/deployment.yaml \
        helm/madgoat-infra/values.yaml helm/madgoat-infra/templates/core.yaml \
        helm/madgoat-infra/templates/db.yaml \
        scripts/exploits/k01-*.sh
git commit -m "feat(k01): inject insecure workload configuration vulnerabilities"
```

---

## Task 3: K02 — Overly Permissive Authorization (RBAC)

**Files:**
- Create: `helm/madgoat-infra/templates/rbac.yaml`
- Create: `scripts/exploits/k02-clusterAdminBinding.sh`
- Create: `scripts/exploits/k02-secretsListWatch.sh`

- [ ] **Step 3.1: Write exploit scripts**

Create `scripts/exploits/k02-clusterAdminBinding.sh`:
```bash
#!/bin/bash
set -e
RESULT=$(kubectl auth can-i '*' '*' --all-namespaces \
  --as=system:serviceaccount:default:default 2>&1)
if echo "$RESULT" | grep -q "^yes"; then
  echo "PASS: default SA has cluster-admin — vulnerable"; exit 0
else
  echo "FAIL: default SA lacks cluster-admin — $RESULT (safe mode)"; exit 1
fi
```

Create `scripts/exploits/k02-secretsListWatch.sh`:
```bash
#!/bin/bash
set -e
RESULT=$(kubectl auth can-i list secrets --namespace default \
  --as=system:serviceaccount:default:default 2>&1)
if echo "$RESULT" | grep -q "^yes"; then
  echo "PASS: default SA can list secrets — vulnerable"; exit 0
else
  echo "FAIL: default SA cannot list secrets — $RESULT (safe mode)"; exit 1
fi
```

```bash
chmod +x scripts/exploits/k02-*.sh
```

- [ ] **Step 3.2: Create helm/madgoat-infra/templates/rbac.yaml**

```yaml
{{- if .Values.vulnerabilities.k02_clusterAdminBinding }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: mad-cluster-admin
  labels:
    io.mad.vuln: k02-clusterAdminBinding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: default
  namespace: default
{{- end }}
{{- if .Values.vulnerabilities.k02_secretsListWatch }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: mad-secrets-reader
  namespace: default
  labels:
    io.mad.vuln: k02-secretsListWatch
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["list", "watch", "get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: mad-secrets-reader-binding
  namespace: default
  labels:
    io.mad.vuln: k02-secretsListWatch
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: mad-secrets-reader
subjects:
- kind: ServiceAccount
  name: default
  namespace: default
{{- end }}
```

- [ ] **Step 3.3: Verify template renders**

```bash
helm template madgoat-infra ./helm/madgoat-infra | grep -A5 "ClusterRoleBinding"
# Expected: shows mad-cluster-admin ClusterRoleBinding

helm template madgoat-infra ./helm/madgoat-infra \
  --set vulnerabilities.k02_clusterAdminBinding=false | grep "ClusterRoleBinding"
# Expected: no output (binding not emitted in safe mode)
```

- [ ] **Step 3.4: Deploy and verify exploits pass**

```bash
make deploy-vulnerable
kubectl rollout status deployment/mad-keycloak --timeout=120s
make verify-exploit-k02-clusterAdminBinding
# Expected: PASS: default SA has cluster-admin
make verify-exploit-k02-secretsListWatch
# Expected: PASS: default SA can list secrets
```

- [ ] **Step 3.5: Verify safe mode blocks exploits**

```bash
make deploy-safe
make verify-exploit-k02-clusterAdminBinding && echo "UNEXPECTED PASS" || echo "CORRECTLY FAILS"
# Expected: exits 1 (FAIL)
```

- [ ] **Step 3.6: Commit K02**

```bash
git add helm/madgoat-infra/templates/rbac.yaml scripts/exploits/k02-*.sh
git commit -m "feat(k02): inject overly permissive RBAC — cluster-admin binding and secret list/watch"
```

---

## Task 4: K03 — Secrets Management Failures

**Files:**
- Modify: `helm/madgoat/templates/configmap.yaml`
- Modify: `helm/madgoat-infra/templates/configmap.yaml`
- Create: `helm/madgoat/templates/secret.yaml`
- Create: `helm/madgoat-infra/templates/secret.yaml`
- Create: `scripts/exploits/k03-plaintextConfigMapSecrets.sh`
- Create: `scripts/exploits/k03-jwtKeyInEnv.sh`

- [ ] **Step 4.1: Write exploit scripts**

Create `scripts/exploits/k03-plaintextConfigMapSecrets.sh`:
```bash
#!/bin/bash
set -e
PASSWORD=$(kubectl get configmap env-lesson \
  -o jsonpath='{.data.DB_PASSWORD}' 2>/dev/null)
if [ -n "$PASSWORD" ] && [ "$PASSWORD" != "null" ]; then
  echo "PASS: DB_PASSWORD='$PASSWORD' exposed in plaintext ConfigMap — vulnerable"; exit 0
else
  echo "FAIL: DB_PASSWORD not in ConfigMap (safe mode — check Secret)"; exit 1
fi
```

Create `scripts/exploits/k03-jwtKeyInEnv.sh`:
```bash
#!/bin/bash
set -e
JWT=$(kubectl get configmap env-profile \
  -o jsonpath='{.data.JWT_SECRET}' 2>/dev/null)
if [ -n "$JWT" ] && [ "$JWT" != "null" ]; then
  echo "PASS: JWT_SECRET (${#JWT} chars) exposed in plaintext ConfigMap — vulnerable"; exit 0
else
  echo "FAIL: JWT_SECRET not in ConfigMap (safe mode — check Secret)"; exit 1
fi
```

```bash
chmod +x scripts/exploits/k03-*.sh
```

- [ ] **Step 4.2: Verify exploits pass against current chart (pre-injection baseline)**

```bash
make deploy-vulnerable
make verify-exploit-k03-plaintextConfigMapSecrets
# Expected: PASS — these are already vulnerable (current state)
make verify-exploit-k03-jwtKeyInEnv
# Expected: PASS
```

- [ ] **Step 4.3: Create helm/madgoat/templates/secret.yaml (safe-mode path)**

When `k03_plaintextConfigMapSecrets=false` or `k03_jwtKeyInEnv=false`, emit K8s Secrets:

```yaml
{{- if not .Values.vulnerabilities.k03_plaintextConfigMapSecrets }}
---
apiVersion: v1
kind: Secret
metadata:
  name: secret-lesson-db
  labels:
    io.mad.vuln: k03-plaintextConfigMapSecrets
type: Opaque
stringData:
  DB_PASSWORD: "postgres"
  POSTGRES_PASSWORD: "postgres"
---
apiVersion: v1
kind: Secret
metadata:
  name: secret-scoreboard-db
  labels:
    io.mad.vuln: k03-plaintextConfigMapSecrets
type: Opaque
stringData:
  MONGO_INITDB_ROOT_PASSWORD: "root"
---
apiVersion: v1
kind: Secret
metadata:
  name: secret-rabbitmq
  labels:
    io.mad.vuln: k03-plaintextConfigMapSecrets
type: Opaque
stringData:
  RMQ_PRODUCER_URL: "amqp://guest:guest@rabbitmq:5672"
{{- end }}
{{- if not .Values.vulnerabilities.k03_jwtKeyInEnv }}
---
apiVersion: v1
kind: Secret
metadata:
  name: secret-profile-jwt
  labels:
    io.mad.vuln: k03-jwtKeyInEnv
type: Opaque
stringData:
  JWT_SECRET: "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvGJSXMLY2fKdoN/D0oTYekvandITVIUAnIn719MQ5fQFg3TuEU5F9YU5l+VCkp4c4isW4ozpiQiJdFp8xnQfIiizO8LohNJbajzxkwvhqNsy9HqR1/iDD5zoroksvsCS7TPmM9J5bkgqhNGdK1hHJX91De3RLQfcQY9ZDYE6+NX3fAzuK9jx5TJc9k2KRJofniv/1RMaOaUhleP1ljdxI1ttyvU6FZCMCJoNAFVIXaPtA3/1jSJCE37XWORoWPG6Ri2d5rDwioJxc5rllTM/Av07qdXZVt446YFjwUoT113IbxAzX6fY2Mh48doKertXlkPcVcmrcOoivoxRp4KzQwIDAQAB"
{{- end }}
```

- [ ] **Step 4.4: Create helm/madgoat-infra/templates/secret.yaml**

```yaml
{{- if not .Values.vulnerabilities.k03_plaintextConfigMapSecrets }}
---
apiVersion: v1
kind: Secret
metadata:
  name: secret-keycloak
  labels:
    io.mad.vuln: k03-plaintextConfigMapSecrets
type: Opaque
stringData:
  KEYCLOAK_ADMIN_PASSWORD: "admin"
  POSTGRES_PASSWORD: "password"
  KC_DB_PASSWORD: "password"
---
apiVersion: v1
kind: Secret
metadata:
  name: secret-minio
  labels:
    io.mad.vuln: k03-plaintextConfigMapSecrets
type: Opaque
stringData:
  MINIO_ROOT_PASSWORD: "minio123"
  MINIO_SECRET_KEY: "mysupersecretkey"
{{- end }}
```

- [ ] **Step 4.5: Verify safe-mode template emits Secrets**

```bash
helm template madgoat-app ./helm/madgoat \
  --set vulnerabilities.k03_plaintextConfigMapSecrets=false | grep "kind: Secret"
# Expected: lists secret-lesson-db, secret-scoreboard-db, secret-rabbitmq

helm template madgoat-app ./helm/madgoat \
  --set vulnerabilities.k03_jwtKeyInEnv=false | grep "kind: Secret"
# Expected: lists secret-profile-jwt
```

- [ ] **Step 4.6: Commit K03**

```bash
git add helm/madgoat/templates/secret.yaml helm/madgoat-infra/templates/secret.yaml \
        scripts/exploits/k03-*.sh
git commit -m "feat(k03): document plaintext ConfigMap secrets; add safe-mode Secret path"
```

---

## Task 5: K04 — Lack of Cluster-Level Policy Enforcement

**Files:**
- Create: `k8s/insecure-defaults/admission-no-psa.yaml`
- Create: `k8s/insecure-defaults/kyverno-weak-policies.yaml`
- Create: `scripts/exploits/k04-noPSA.sh`
- Create: `scripts/exploits/k04-weakKyverno.sh`

- [ ] **Step 5.1: Write exploit scripts**

Create `scripts/exploits/k04-noPSA.sh`:
```bash
#!/bin/bash
set -e
LABELS=$(kubectl get namespace default -o jsonpath='{.metadata.labels}' 2>&1)
if echo "$LABELS" | grep -q "pod-security.kubernetes.io"; then
  echo "FAIL: PSA labels present on default namespace (safe mode)"; exit 1
else
  echo "PASS: No PSA labels on default namespace — privileged pods allowed (vulnerable)"; exit 0
fi
```

Create `scripts/exploits/k04-weakKyverno.sh`:
```bash
#!/bin/bash
set -e
# Attempt to create a privileged pod via dry-run — real Kyverno policy should block it
OUTPUT=$(kubectl run test-priv-$$ \
  --image=alpine --restart=Never \
  --overrides='{"spec":{"containers":[{"name":"c","image":"alpine","securityContext":{"privileged":true}}]}}' \
  --dry-run=server 2>&1 || true)
kubectl delete pod test-priv-$$ --ignore-not-found 2>/dev/null &
if echo "$OUTPUT" | grep -qiE "denied|admission webhook"; then
  echo "FAIL: Kyverno blocked privileged pod (safe mode — real policy)"; exit 1
else
  echo "PASS: Privileged pod NOT blocked by Kyverno (vulnerable — no-op policy or not installed)"; exit 0
fi
```

```bash
chmod +x scripts/exploits/k04-*.sh
```

- [ ] **Step 5.2: Create k8s/insecure-defaults/admission-no-psa.yaml**

This is a no-op annotation document — the vulnerability is the *absence* of PSA labels. Apply it as a namespace patch that removes PSA labels if they exist:

```yaml
# K04: Remove Pod Security Admission enforcement labels from default namespace.
# In a fresh cluster these labels are absent by default — this manifest ensures
# they stay absent even if a safe-mode apply accidentally added them.
apiVersion: v1
kind: Namespace
metadata:
  name: default
  labels:
    # Explicitly set to privileged to document the intended (vulnerable) state
    pod-security.kubernetes.io/enforce: privileged
    pod-security.kubernetes.io/enforce-version: latest
```

- [ ] **Step 5.3: Create k8s/insecure-defaults/kyverno-weak-policies.yaml**

First, install Kyverno CRDs if not present (add to kustomization.yaml or comment):

```yaml
# K04: Kyverno ClusterPolicy that is deliberately permissive (no-op).
# This models the "admission controller installed but misconfigured" scenario.
# Kyverno must be installed in the cluster: kubectl apply -f https://github.com/kyverno/kyverno/releases/download/v1.12.0/install.yaml
# After installing Kyverno, apply this policy to override any defaults.
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: mad-goat-allow-all
  labels:
    io.mad.vuln: k04-weakKyverno
  annotations:
    policies.kyverno.io/title: "MAD Goat No-Op Policy"
    policies.kyverno.io/description: >-
      Intentionally permissive policy that allows all workloads including
      privileged containers, root processes, and host network access.
      Demonstrates admission controller misconfiguration (K04/2025).
spec:
  validationFailureAction: Audit
  background: false
  rules:
  - name: allow-all-workloads
    match:
      any:
      - resources:
          kinds:
          - Pod
    validate:
      message: "All pods allowed (no-op policy — vulnerable benchmark mode)"
      deny: {}
```

- [ ] **Step 5.4: Update kustomization.yaml to include both files**

Update `k8s/insecure-defaults/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - admission-no-psa.yaml
  - kyverno-weak-policies.yaml
```

Note: `kyverno-weak-policies.yaml` requires Kyverno CRDs installed first (`kubectl apply -f https://github.com/kyverno/kyverno/releases/download/v1.12.0/install.yaml`). The makefile `reset-vulnerable` target should install Kyverno before applying kustomize. Add to `reset-vulnerable` in the makefile:

```makefile
.PHONY: reset-vulnerable
reset-vulnerable:
	k8s/minikube_setup.sh
	sleep 10
	kubectl apply -f https://github.com/kyverno/kyverno/releases/download/v1.12.0/install.yaml
	kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=kyverno -n kyverno --timeout=120s
	make deploy-vulnerable
	kubectl apply -k k8s/insecure-defaults/
```

- [ ] **Step 5.5: Verify and commit K04**

```bash
kubectl apply -k k8s/insecure-defaults/ --dry-run=client
# Expected: no errors

git add k8s/insecure-defaults/ scripts/exploits/k04-*.sh makefile
git commit -m "feat(k04): add PSA namespace label + Kyverno no-op policy; update reset-vulnerable"
```

---

## Task 6: K05 — Missing Network Segmentation Controls

**Files:**
- Modify: `helm/madgoat-infra/templates/mad-network-networkpolicy.yaml`
- Create: `scripts/exploits/k05-noDefaultDeny.sh`
- Create: `scripts/exploits/k05-permissiveNetpol.sh`
- Create: `scripts/exploits/k05-noEgressControls.sh`

- [ ] **Step 6.1: Write exploit scripts**

Create `scripts/exploits/k05-noDefaultDeny.sh`:
```bash
#!/bin/bash
set -e
# Create an unlabeled test pod and attempt to reach Keycloak (not covered by netpol)
kubectl run nettest-$$ --image=alpine:latest --restart=Never -- sleep 15 2>/dev/null || true
sleep 4
OUTPUT=$(kubectl exec nettest-$$ -- \
  sh -c "timeout 4 wget -qO- http://mad-keycloak:8080/health/ready 2>&1 || echo UNREACHABLE")
kubectl delete pod nettest-$$ --ignore-not-found 2>/dev/null &
if ! echo "$OUTPUT" | grep -q "UNREACHABLE"; then
  echo "PASS: Keycloak reachable from unisolated pod (no default-deny — vulnerable)"; exit 0
else
  echo "FAIL: Keycloak unreachable (safe mode — default-deny present)"; exit 1
fi
```

Create `scripts/exploits/k05-permissiveNetpol.sh`:
```bash
#!/bin/bash
set -e
# From lesson pod, reach db-scoreboard (MongoDB) directly — bypassing scoreboard service
POD=$(kubectl get pod -l io.mad.service=lesson -o jsonpath='{.items[0].metadata.name}')
OUTPUT=$(kubectl exec "$POD" -- \
  sh -c "timeout 3 sh -c 'echo > /dev/tcp/db-scoreboard/27017' 2>/dev/null && echo CONNECTED || echo BLOCKED")
if echo "$OUTPUT" | grep -q "CONNECTED"; then
  echo "PASS: lesson can reach db-scoreboard:27017 directly (label-based netpol too permissive — vulnerable)"; exit 0
else
  echo "FAIL: db-scoreboard:27017 not reachable from lesson (safe mode — per-service rules)"; exit 1
fi
```

Create `scripts/exploits/k05-noEgressControls.sh`:
```bash
#!/bin/bash
set -e
POD=$(kubectl get pod -l io.mad.service=lesson -o jsonpath='{.items[0].metadata.name}')
OUTPUT=$(kubectl exec "$POD" -- \
  sh -c "timeout 5 wget -qO- http://example.com 2>&1 | head -1 || echo BLOCKED")
if ! echo "$OUTPUT" | grep -q "BLOCKED"; then
  echo "PASS: lesson can reach external internet (no egress controls — vulnerable)"; exit 0
else
  echo "FAIL: egress blocked (safe mode)"; exit 1
fi
```

```bash
chmod +x scripts/exploits/k05-*.sh
```

- [ ] **Step 6.2: Rewrite mad-network-networkpolicy.yaml with conditional branches**

Replace the entire file content:

```yaml
{{- if not .Values.vulnerabilities.k05_noDefaultDeny }}
---
# Safe mode: default-deny all ingress and egress
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
{{- end }}
{{- if .Values.vulnerabilities.k05_permissiveNetpol }}
---
# Vulnerable mode: overly broad label-based policy (current state)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: mad-network
spec:
  ingress:
    - from:
        - podSelector:
            matchLabels:
              io.mad.network/mad-network: "true"
  podSelector:
    matchLabels:
      io.mad.network/mad-network: "true"
{{- else }}
---
# Safe mode: per-service explicit ingress rules
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: mad-network-lesson-to-db
spec:
  podSelector:
    matchLabels:
      io.mad.service: db-lesson
  ingress:
    - from:
        - podSelector:
            matchLabels:
              io.mad.service: lesson
      ports:
        - port: 5432
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: mad-network-scoreboard-to-db
spec:
  podSelector:
    matchLabels:
      io.mad.service: db-scoreboard
  ingress:
    - from:
        - podSelector:
            matchLabels:
              io.mad.service: scoreboard
      ports:
        - port: 27017
{{- end }}
{{- if not .Values.vulnerabilities.k05_noEgressControls }}
---
# Safe mode: restrict egress to cluster-internal only
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: mad-network-egress
spec:
  podSelector:
    matchLabels:
      io.mad.network/mad-network: "true"
  policyTypes:
  - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: default
    - ports:
        - port: 53
          protocol: UDP
        - port: 53
          protocol: TCP
{{- end }}
```

- [ ] **Step 6.3: Verify template in both modes**

```bash
helm template madgoat-infra ./helm/madgoat-infra | grep "kind: NetworkPolicy" -A5
# Vulnerable mode: should show mad-network policy only

helm template madgoat-infra ./helm/madgoat-infra \
  --set vulnerabilities.k05_noDefaultDeny=false \
  --set vulnerabilities.k05_permissiveNetpol=false \
  --set vulnerabilities.k05_noEgressControls=false | grep "kind: NetworkPolicy" -A5
# Safe mode: should show default-deny-all, mad-network-lesson-to-db, mad-network-egress
```

- [ ] **Step 6.4: Commit K05**

```bash
git add helm/madgoat-infra/templates/mad-network-networkpolicy.yaml \
        scripts/exploits/k05-*.sh
git commit -m "feat(k05): inject missing network segmentation controls with conditional NetworkPolicies"
```

---

## Task 7: K06 — Overly Exposed Kubernetes Components

**Files:**
- Modify: `helm/madgoat-infra/templates/dashboard.yaml`
- Modify: `helm/madgoat-infra/values.yaml` (rabbitmq traefik route)
- Create: `scripts/exploits/k06-traefikDashboardExposed.sh`
- Create: `scripts/exploits/k06-rabbitmqMgmtExposed.sh`

- [ ] **Step 7.1: Write exploit scripts**

Create `scripts/exploits/k06-traefikDashboardExposed.sh`:
```bash
#!/bin/bash
set -e
CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://madgoat.tech/dashboard/ 2>&1)
if echo "$CODE" | grep -qE "^(200|301|302|307)"; then
  echo "PASS: Traefik dashboard accessible (HTTP $CODE) — vulnerable"; exit 0
else
  echo "FAIL: Traefik dashboard not accessible (HTTP $CODE)"; exit 1
fi
```

Create `scripts/exploits/k06-rabbitmqMgmtExposed.sh`:
```bash
#!/bin/bash
set -e
CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://madgoat.tech/rabbitmq/ 2>&1)
if echo "$CODE" | grep -qE "^(200|301|302)"; then
  echo "PASS: RabbitMQ management UI accessible (HTTP $CODE) — vulnerable"; exit 0
else
  echo "FAIL: RabbitMQ management UI not accessible (HTTP $CODE)"; exit 1
fi
```

```bash
chmod +x scripts/exploits/k06-*.sh
```

- [ ] **Step 7.2: Gate dashboard.yaml behind flag**

Replace `helm/madgoat-infra/templates/dashboard.yaml` content:

```yaml
{{- if .Values.vulnerabilities.k06_traefikDashboardExposed }}
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: dashboard
  labels:
    io.mad.vuln: k06-traefikDashboardExposed
spec:
  entryPoints:
    - web
  routes:
    - match: PathPrefix(`/dashboard`)
      kind: Rule
      services:
        - name: api@internal
          kind: TraefikService
{{- end }}
```

- [ ] **Step 7.3: Gate RabbitMQ management route behind flag**

In `helm/madgoat-infra/templates/core-services.yaml`, the `{{- range .service.traefik.routes }}` block (line 23) emits a Middleware + IngressRoute per route. The rabbitmq entry has one route named `rabbitmq` pointing at port 15672.

Replace the range block (lines 22–53) with a conditional wrapper that skips the rabbitmq route when the flag is false:

```yaml
      {{- if hasKey .service "traefik" }}
        {{- range .service.traefik.routes }}
          {{- if or (not (eq .name "rabbitmq")) $.Values.vulnerabilities.k06_rabbitmqMgmtExposed }}
---
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: strip-prefix-{{ .name }}
spec:
  stripPrefixRegex:
    regex:
        - "{{ .middleware.stripPrefix }}"
---
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: {{ .name }}
  namespace: default
spec:
  entryPoints:
    - web
  routes:
    - kind: Rule
      match: Host(`madgoat.tech`) && PathPrefix(`{{.middleware.stripPrefix}}`)
      middlewares:
        - name: strip-prefix-{{.name}}
      services:
        - kind: Service
          name: {{ .service.name }}
          namespace: default
          port: {{ .service.port }}
          {{- end }}
        {{- end }}
      {{- end }}
```

The logic: emit the route if it is NOT named "rabbitmq" **or** if `k06_rabbitmqMgmtExposed=true` (vulnerable mode). In safe mode (flag=false) only the rabbitmq route is suppressed; all other routes render normally.

Note: preserve the existing `{{ if ne .name "mad-keycloak"}}` / `{{ else if eq .name "mad-keycloak" }}` outer structure — only the inner traefik routes block above changes.

- [ ] **Step 7.4: Commit K06**

```bash
git add helm/madgoat-infra/templates/dashboard.yaml \
        helm/madgoat-infra/templates/core-services.yaml \
        scripts/exploits/k06-*.sh
git commit -m "feat(k06): gate Traefik dashboard and RabbitMQ management UI behind vuln flags"
```

---

## Task 8: K07 — Misconfigured and Vulnerable Cluster Components

**Files:**
- Create: `k8s/insecure-defaults/kubelet-config.yaml`
- Create: `scripts/exploits/k07-kubeletAnonymousAuth.sh`
- Create: `scripts/exploits/k07-kubeletAlwaysAllow.sh`

- [ ] **Step 8.1: Write exploit scripts**

Create `scripts/exploits/k07-kubeletAnonymousAuth.sh`:
```bash
#!/bin/bash
set -e
MINIKUBE_IP=$(minikube ip)
CODE=$(curl -sk -o /dev/null -w "%{http_code}" --max-time 5 https://$MINIKUBE_IP:10250/pods)
if [ "$CODE" = "200" ]; then
  echo "PASS: kubelet API accessible without auth (HTTP 200 — anonymous-auth=true)"; exit 0
elif [ "$CODE" = "401" ]; then
  echo "FAIL: kubelet API requires authentication (HTTP 401 — safe mode)"; exit 1
else
  echo "FAIL: unexpected response HTTP $CODE from kubelet API"; exit 1
fi
```

Create `scripts/exploits/k07-kubeletAlwaysAllow.sh`:
```bash
#!/bin/bash
set -e
MINIKUBE_IP=$(minikube ip)
# Send an invalid/arbitrary token — AlwaysAllow accepts everything
CODE=$(curl -sk -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer invalid-test-token-madgoat-12345" \
  --max-time 5 https://$MINIKUBE_IP:10250/pods)
if [ "$CODE" = "200" ]; then
  echo "PASS: kubelet accepted invalid token (AlwaysAllow authorization — vulnerable)"; exit 0
else
  echo "FAIL: kubelet rejected invalid token (HTTP $CODE — authorizer checking tokens)"; exit 1
fi
```

```bash
chmod +x scripts/exploits/k07-*.sh
```

- [ ] **Step 8.2: Create k8s/insecure-defaults/kubelet-config.yaml**

```yaml
# K07: KubeletConfiguration drop-in documenting insecure flags.
# These flags are passed to `minikube start` via --extra-config, not applied via kubectl.
# See makefile target reset-vulnerable for the exact minikube start command.
#
# This file serves as documentation of the intended misconfiguration.
# It is NOT directly applied with kubectl apply — it is a reference manifest.
#
# Equivalent minikube flags:
#   --extra-config=kubelet.anonymous-auth=true
#   --extra-config=kubelet.authorization-mode=AlwaysAllow
#
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
authentication:
  anonymous:
    enabled: true          # K07: CVE equivalent — unauthenticated kubelet access
  webhook:
    enabled: false
authorization:
  mode: AlwaysAllow        # K07: all requests authorized regardless of RBAC
```

- [ ] **Step 8.3: Update makefile reset-vulnerable with kubelet flags**

Update the `reset-vulnerable` target in the makefile to pass kubelet extra-config flags:

```makefile
.PHONY: reset-vulnerable
reset-vulnerable:
	minikube delete --all 2>/dev/null || true
	minikube start --cpus 8 --memory 20000MB \
	  --extra-config=kubelet.anonymous-auth=true \
	  --extra-config=kubelet.authorization-mode=AlwaysAllow
	minikube addons enable ingress
	minikube addons enable ingress-dns
	sleep 10
	kubectl apply -f https://github.com/kyverno/kyverno/releases/download/v1.12.0/install.yaml
	kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=kyverno -n kyverno --timeout=120s
	MINIKUBE_IP=$$(minikube ip) && \
	  kubectl get configmap coredns -n kube-system -o json | \
	  jq --arg ip "$$MINIKUBE_IP" '.data.Corefile += "madgoat.tech:53 {\n    errors\n    cache 30\n    forward . " + $$ip + "\n}"' | \
	  kubectl apply -f -
	kubectl rollout restart deployment coredns -n kube-system
	sleep 5
	make deploy-vulnerable
	kubectl apply -k k8s/insecure-defaults/
```

And add `reset-safe`:

```makefile
.PHONY: reset-safe
reset-safe:
	minikube delete --all 2>/dev/null || true
	minikube start --cpus 8 --memory 20000MB
	minikube addons enable ingress
	minikube addons enable ingress-dns
	sleep 10
	MINIKUBE_IP=$$(minikube ip) && \
	  kubectl get configmap coredns -n kube-system -o json | \
	  jq --arg ip "$$MINIKUBE_IP" '.data.Corefile += "madgoat.tech:53 {\n    errors\n    cache 30\n    forward . " + $$ip + "\n}"' | \
	  kubectl apply -f -
	kubectl rollout restart deployment coredns -n kube-system
	sleep 5
	make deploy-safe
```

- [ ] **Step 8.4: Verify kubelet flags are applied after reset-vulnerable**

```bash
make reset-vulnerable
make verify-exploit-k07-kubeletAnonymousAuth
# Expected: PASS: kubelet API accessible without auth
make verify-exploit-k07-kubeletAlwaysAllow
# Expected: PASS: kubelet accepted invalid token
```

- [ ] **Step 8.5: Commit K07**

```bash
git add k8s/insecure-defaults/kubelet-config.yaml scripts/exploits/k07-*.sh makefile
git commit -m "feat(k07): add kubelet insecure-defaults config and anonymous-auth/AlwaysAllow exploit scripts"
```

---

## Task 9: K08 — Cluster-to-Cloud Lateral Movement (conceptual docs)

**Files:**
- Create: `k8s/insecure-defaults/k08-cluster-to-cloud-conceptual.md`

- [ ] **Step 9.1: Create conceptual documentation**

Create `k8s/insecure-defaults/k08-cluster-to-cloud-conceptual.md`:

```markdown
# K08/2025 — Cluster-to-Cloud Lateral Movement (Conceptual)

This category has no locally reproducible exploit in a Minikube environment.
The following describes the attack paths for a managed Kubernetes cluster (EKS/GKE/AKE).

## K08a: IMDS Credential Theft

**Weakness:** On cloud-managed Kubernetes (EKS, GKE, AKE), pods can reach the 
instance metadata service (IMDS) at 169.254.169.254 unless explicitly blocked.
An attacker with code execution in a pod (e.g., via RCE in lesson-service) can
request cloud IAM credentials assigned to the underlying node.

**Exploit path (EKS example):**
1. Gain code execution inside any pod (e.g., via CVE in lesson-service Node.js deps).
2. From inside the pod:
   curl http://169.254.169.254/latest/meta-data/iam/security-credentials/
3. Retrieve the role name, then:
   curl http://169.254.169.254/latest/meta-data/iam/security-credentials/<ROLE>
4. Use returned AccessKeyId / SecretAccessKey / Token with AWS CLI to access S3, 
   SSM, ECR — whatever the node role permits.

**Mitigation:** 
- EKS: enable IMDSv2 with hop limit=1 (`--metadata-options HttpTokens=required,HttpPutResponseHopLimit=1`).
- All clouds: block 169.254.169.254 via NetworkPolicy egress rules (covered by K05 safe mode).
- Use IRSA (EKS) / Workload Identity (GKE/AKE) to grant per-pod cloud permissions without node-level credentials.

## K08b: Projected SA Token to Cloud IAM

**Weakness:** If a pod mounts a Kubernetes ServiceAccount token and the cluster is 
configured with OIDC federation to a cloud IAM provider (AWS IRSA / GCP WI / Azure WI),
a stolen SA token can be exchanged for cloud IAM credentials.

**Exploit path:**
1. Steal a pod's SA token: kubectl exec <pod> -- cat /var/run/secrets/kubernetes.io/serviceaccount/token
2. If the SA is bound to a cloud IAM role via annotation, exchange the token:
   aws sts assume-role-with-web-identity --web-identity-token file://token --role-arn <arn>
3. Use resulting credentials.

**Mitigation:** Scope IRSA/WI role bindings to least-privilege; use `automountServiceAccountToken: false`
on pods that do not need cloud API access (covered by K09 safe mode).

**References:** See thesis references.bib entries: aws-irsa, gke-workload-identity, azure-workload-identity.
```

- [ ] **Step 9.2: Commit K08**

```bash
git add k8s/insecure-defaults/k08-cluster-to-cloud-conceptual.md
git commit -m "docs(k08): add conceptual cluster-to-cloud lateral movement documentation"
```

---

## Task 10: K09 — Broken Authentication Mechanisms

**Files:**
- Modify: `helm/madgoat-infra/templates/core.yaml` (Keycloak args)
- Create: `helm/madgoat/templates/serviceaccount.yaml`
- Create: `helm/madgoat-infra/templates/serviceaccount.yaml`
- Create: `scripts/exploits/k09-anonymousKeycloakBootstrap.sh`
- Create: `scripts/exploits/k09-sharedServiceAccount.sh`

- [ ] **Step 10.1: Write exploit scripts**

Create `scripts/exploits/k09-anonymousKeycloakBootstrap.sh`:
```bash
#!/bin/bash
set -e
CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
  -d "client_id=admin-cli&username=admin&password=admin&grant_type=password" \
  http://keycloak.madgoat.tech/realms/master/protocol/openid-connect/token)
if [ "$CODE" = "200" ]; then
  echo "PASS: Keycloak admin login with admin/admin succeeded (HTTP 200) — vulnerable"; exit 0
else
  echo "FAIL: Keycloak admin/admin login failed (HTTP $CODE)"; exit 1
fi
```

Create `scripts/exploits/k09-sharedServiceAccount.sh`:
```bash
#!/bin/bash
set -e
DEFAULT_SA_PODS=$(kubectl get pods -l 'io.mad.service' \
  -o jsonpath='{range .items[*]}{.spec.serviceAccountName}{"\n"}{end}' \
  | grep -c "^default$" || true)
TOTAL=$(kubectl get pods -l 'io.mad.service' --no-headers 2>/dev/null | wc -l | tr -d ' ')
if [ "$DEFAULT_SA_PODS" -eq "$TOTAL" ] && [ "$TOTAL" -gt 0 ]; then
  echo "PASS: All $TOTAL pods use the 'default' ServiceAccount (shared SA — vulnerable)"; exit 0
else
  echo "FAIL: $((TOTAL - DEFAULT_SA_PODS))/$TOTAL pods use custom SAs (safe mode)"; exit 1
fi
```

```bash
chmod +x scripts/exploits/k09-*.sh
```

- [ ] **Step 10.2: Gate Keycloak start-dev and admin creds in core.yaml**

In `helm/madgoat-infra/templates/core.yaml`, the `mad-keycloak` entry has `args: ["start-dev"]`. Add a conditional:

Find the args block for keycloak (inside `{{- if hasKey . "args"}}`) and wrap it:

```yaml
          {{ if hasKey . "args" }}
          args:
            {{ if and (eq .name "mad-keycloak") (not $.Values.vulnerabilities.k09_anonymousKeycloakBootstrap) }}
            - "start"
            {{ else }}
            {{ range .args }}
            - {{ . }}
            {{ end }}
            {{ end }}
          {{ end }}
```

This means: when safe mode is active and the service is `mad-keycloak`, use `start` instead of `start-dev`. The admin password is controlled by the `KEYCLOAK_ADMIN_PASSWORD` env var in configmap `env-keycloak` — in safe mode, that should come from a Secret (handled by Task 4's K03 safe mode). For the thesis, documenting the `start-dev` flag is the primary vulnerability here.

- [ ] **Step 10.3: Create helm/madgoat/templates/serviceaccount.yaml**

```yaml
{{- if not .Values.vulnerabilities.k09_sharedServiceAccount }}
{{- range .Values.madServices }}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: sa-{{ .name }}
  namespace: default
  labels:
    io.mad.service: {{ .name }}
automountServiceAccountToken: false
{{- end }}
{{- end }}
```

- [ ] **Step 10.4: Create helm/madgoat-infra/templates/serviceaccount.yaml**

```yaml
{{- if not .Values.vulnerabilities.k09_sharedServiceAccount }}
{{- range .Values.core }}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: sa-{{ .name }}
  namespace: default
  labels:
    io.mad.service: {{ .name }}
automountServiceAccountToken: false
{{- end }}
{{- range .Values.dbs }}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: sa-{{ .name }}
  namespace: default
  labels:
    io.mad.service: {{ .name }}
automountServiceAccountToken: false
{{- end }}
{{- end }}
```

- [ ] **Step 10.5: Verify template**

```bash
helm template madgoat-app ./helm/madgoat \
  --set vulnerabilities.k09_sharedServiceAccount=false | grep "kind: ServiceAccount"
# Expected: ServiceAccount for each madService (lesson, docs, profile, etc.)

helm template madgoat-app ./helm/madgoat | grep "kind: ServiceAccount"
# Expected: no output (vulnerable default — uses default SA)
```

- [ ] **Step 10.6: Commit K09**

```bash
git add helm/madgoat/templates/serviceaccount.yaml \
        helm/madgoat-infra/templates/serviceaccount.yaml \
        helm/madgoat-infra/templates/core.yaml \
        scripts/exploits/k09-*.sh
git commit -m "feat(k09): inject shared SA and Keycloak start-dev vulnerabilities"
```

---

## Task 11: K10 — Inadequate Logging and Monitoring

**Files:**
- Create: `k8s/insecure-defaults/audit-policy-missing.md`
- Create: `k8s/insecure-defaults/audit-policy-safe.yaml`
- Create: `scripts/exploits/k10-noAuditPolicy.sh`

- [ ] **Step 11.1: Write exploit script**

Create `scripts/exploits/k10-noAuditPolicy.sh`:
```bash
#!/bin/bash
set -e
AUDIT_FLAG=$(minikube ssh -- \
  "ps aux | grep kube-apiserver | grep -o 'audit-policy-file=[^ ]*' 2>/dev/null || true")
if [ -z "$AUDIT_FLAG" ]; then
  echo "PASS: No audit-policy-file configured — apiserver audit logging absent (vulnerable)"; exit 0
else
  echo "FAIL: audit-policy-file is set ($AUDIT_FLAG) — safe mode"; exit 1
fi
```

```bash
chmod +x scripts/exploits/k10-noAuditPolicy.sh
```

- [ ] **Step 11.2: Create audit-policy-missing.md**

```markdown
# K10/2025 — No Apiserver Audit Policy (Documented Absence)

The default MAD Goat benchmark cluster starts Minikube without an audit policy.
This means no Kubernetes API operations are logged to an audit backend.

**To reproduce (verify absence):**
minikube ssh -- ps aux | grep kube-apiserver | grep audit

**To apply safe mode (audit-policy-safe.yaml):**
1. Copy audit-policy-safe.yaml to the Minikube node:
   minikube cp k8s/insecure-defaults/audit-policy-safe.yaml /etc/kubernetes/audit-policy.yaml
2. Restart kube-apiserver with audit flags (minikube start flags or kubeadm patch):
   --audit-policy-file=/etc/kubernetes/audit-policy.yaml
   --audit-log-path=/var/log/kubernetes/audit.log
   --audit-log-maxage=30
   --audit-log-maxbackup=3
   --audit-log-maxsize=100
```

- [ ] **Step 11.3: Create audit-policy-safe.yaml**

```yaml
# K10 safe-mode reference: basic audit policy capturing security-relevant events.
# Apply per instructions in audit-policy-missing.md
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
  # Log all secret access at RequestResponse level
  - level: RequestResponse
    resources:
    - group: ""
      resources: ["secrets"]
  # Log all pod exec, attach, portforward
  - level: RequestResponse
    verbs: ["create"]
    resources:
    - group: ""
      resources: ["pods/exec", "pods/attach", "pods/portforward"]
  # Log RBAC changes
  - level: RequestResponse
    resources:
    - group: "rbac.authorization.k8s.io"
      resources: ["clusterrolebindings", "rolebindings", "clusterroles", "roles"]
  # Log authentication failures (Metadata level for performance)
  - level: Metadata
    omitStages:
      - RequestReceived
  # Ignore noisy read-only operations from system components
  - level: None
    users: ["system:kube-proxy"]
    verbs: ["watch"]
    resources:
    - group: ""
      resources: ["endpoints", "services", "services/status"]
```

- [ ] **Step 11.4: Commit K10**

```bash
git add k8s/insecure-defaults/audit-policy-missing.md \
        k8s/insecure-defaults/audit-policy-safe.yaml \
        scripts/exploits/k10-noAuditPolicy.sh
git commit -m "feat(k10): add audit policy absence docs, safe-mode policy, and exploit script"
```

---

## Task 12: Integration verification — full oracle suite

Run this task after a clean `make reset-vulnerable` to verify all 19 full entries.

- [ ] **Step 12.1: Start from a clean vulnerable state**

```bash
make reset-vulnerable
# Takes ~5-10 minutes. Waits for ingress, Kyverno, and all deployments.
kubectl wait --for=condition=available deployment --all --timeout=300s
```

- [ ] **Step 12.2: Verify all chart-level exploits exit 0**

```bash
for id in \
  k01-runAsRoot k01-readOnlyRootFs k01-privileged k01-unboundedResources \
  k02-clusterAdminBinding k02-secretsListWatch \
  k03-plaintextConfigMapSecrets k03-jwtKeyInEnv \
  k05-noDefaultDeny k05-permissiveNetpol k05-noEgressControls \
  k06-traefikDashboardExposed k06-rabbitmqMgmtExposed \
  k09-anonymousKeycloakBootstrap k09-sharedServiceAccount; do
    echo "--- $id ---"
    make verify-exploit-$id || echo "UNEXPECTED FAIL: $id"
done
# Expected: all 15 PASS
```

- [ ] **Step 12.3: Verify cluster-level exploits exit 0**

```bash
for id in k04-noPSA k04-weakKyverno k07-kubeletAnonymousAuth k07-kubeletAlwaysAllow k10-noAuditPolicy; do
  echo "--- $id ---"
  make verify-exploit-$id || echo "UNEXPECTED FAIL: $id"
done
# Expected: all 5 PASS
```

- [ ] **Step 12.4: Switch to safe mode and verify all exploits exit non-zero**

```bash
make reset-safe
kubectl wait --for=condition=available deployment --all --timeout=300s

FAILED=0
for id in \
  k01-runAsRoot k01-readOnlyRootFs k01-privileged k01-unboundedResources \
  k02-clusterAdminBinding k02-secretsListWatch \
  k03-plaintextConfigMapSecrets k03-jwtKeyInEnv \
  k05-noDefaultDeny k05-permissiveNetpol k05-noEgressControls \
  k06-traefikDashboardExposed k06-rabbitmqMgmtExposed \
  k09-anonymousKeycloakBootstrap k09-sharedServiceAccount \
  k04-noPSA k04-weakKyverno k07-kubeletAnonymousAuth k07-kubeletAlwaysAllow k10-noAuditPolicy; do
    echo "--- $id ---"
    make verify-exploit-$id && { echo "UNEXPECTED PASS (safe mode): $id"; FAILED=1; } || echo "CORRECTLY FAILS: $id"
done
[ $FAILED -eq 0 ] && echo "ALL SAFE-MODE CHECKS PASSED" || echo "SOME EXPLOITS STILL WORK IN SAFE MODE — review above"
```

- [ ] **Step 12.5: Final commit**

```bash
git add -A
git commit -m "feat: complete Plan A — all 19 OWASP K8s Top 10 vulnerabilities injected and verified"
```

---

## Plan A summary

| Task | Category | Items | Status |
|---|---|---|---|
| 0 | Foundation | data YAML, directories | - |
| 1 | Makefile | deploy/reset/verify targets | - |
| 2 | K01/2025 | 4 workload config sub-items | - |
| 3 | K02/2025 | 2 RBAC sub-items | - |
| 4 | K03/2025 | 2 secrets sub-items | - |
| 5 | K04/2025 | 2 policy enforcement sub-items | - |
| 6 | K05/2025 | 3 network segmentation sub-items | - |
| 7 | K06/2025 | 2 exposed components sub-items | - |
| 8 | K07/2025 | 2 cluster component sub-items | - |
| 9 | K08/2025 | 2 conceptual docs | - |
| 10 | K09/2025 | 2 auth sub-items | - |
| 11 | K10/2025 | 1 logging sub-item | - |
| 12 | Integration | full oracle verification suite | - |

**Next plan:** `2026-04-21-k8s-vuln-injection-thesis.md` (Plan B) — LaTeX section, bibliography, snippets, tables. Begin after Task 12 passes.
