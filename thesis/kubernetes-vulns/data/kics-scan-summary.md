# KICS Scan Summary — All Vulnerabilities Active

Scan run against rendered manifests of `madgoat` and `madgoat-infra` with all
`vulnerabilities.*` flags set to `true`.

**Totals:** HIGH 56 · MEDIUM 219 · LOW 262 · INFO 20 · **TOTAL 557**

---

## Per-Vulnerability Coverage

| Vuln ID | KICS rule in table | Fires? | Hits | Notes |
|---|---|---|---|---|
| k01-runAsRoot | `cf34805e` | ✓ | 25 | |
| k01-readOnlyRootFs | `a9c2f49d` | ✓ | 25 | |
| k01-privileged | `dd29336b` | ✓ | 3 | |
| k01-unboundedResources | `b14d1bc4`, `4ac0e2b7` | ✓ both | 7 + 11 | Also: `ca469dd4` (CPU Requests, 11) and `229588ef` (Memory Requests, 7) fire — not currently in table |
| k02-clusterAdminBinding | `249328b8` | ✓ | 2 | |
| k02-secretsListWatch | `b7bca5c4`, `056ac60e` | ✓ both | 4 + 4 | |
| k03-plaintextConfigMapSecrets | `3d658f8b` | ✗ | 0 | Rule checks env-var secrets in Pod specs; chart stores them in a ConfigMap data field instead. Actual detection: `487f4be7` (Generic Password, 13 hits) |
| k03-jwtKeyInEnv | `b9c83569` | ✗ | 0 | Rule targets externally-managed vs native K8s secrets, not plaintext key material. Actual detection: `3e2d3b2f` (Generic Secret, 6 hits) |
| k04-noPSA | `ce30e584` | ✗ | 0 | Rule inspects `kube-apiserver` admission-plugin flags — cluster-scope, absent from Helm manifests |
| k04-weakKyverno | — | — | — | No KICS rule exists |
| k05-noDefaultDeny | `03aabc8c` | ✗ | 0 | Rule targets CNI plugin config (cluster-scope), not the absence of a default-deny NetworkPolicy in app manifests |
| k05-permissiveNetpol | `85ab1c5b` | ✓ | 2 | |
| k05-noEgressControls | `0401f71b` | ✗ | 0 | Rule requires pods with no matching NetworkPolicy egress rule; selector conditions not met by current chart layout |
| k06-traefikDashboardExposed | `69bbc5e3` | ✗ | 0 | Rule detects standard `networking.k8s.io/v1 Ingress`; chart uses Traefik `IngressRoute` CRD |
| k06-rabbitmqMgmtExposed | `69bbc5e3` | ✗ | 0 | Same as above |
| k09-anonymousKeycloakBootstrap | — | — | — | No KICS rule exists |
| k09-sharedServiceAccount | `c1032cf7`, `1e749bc9` | `1e749bc9` ✓ / `c1032cf7` ✗ | 2 / 0 | `c1032cf7` requires explicit shared SA names across pods; implicit `default` SA use is caught by `1e749bc9` instead |

---

## KICS IDs That Do Not Fire Against the HELM GOAT

These are valid KICS rules with correct OWASP mappings. They do not fire because
the specific way the vulnerability is implemented in the HELM GOAT chart does not
match the input pattern the rule inspects.

| ID | Rule name | Mapped to | Why it does not fire on HELM GOAT |
|---|---|---|---|
| `3d658f8b` | Secrets As Environment Variables | k03-plaintextConfigMapSecrets | Rule looks for secrets surfaced as Pod env vars; chart stores them in `ConfigMap.data` — a different resource field |
| `b9c83569` | Using Kubernetes Native Secret Management | k03-jwtKeyInEnv | Rule flags use of K8s `Secret` objects instead of an external vault; chart uses `ConfigMap`, which is outside this rule's scope |
| `ce30e584` | Always Admit Admission Control Plugin Set | k04-noPSA | Rule inspects `kube-apiserver` static-pod flags; no API-server manifest is produced by Helm |
| `03aabc8c` | CNI Plugin Does Not Support Network Policies | k05-noDefaultDeny | Rule targets CNI DaemonSet/ConfigMap resources; those are cluster infrastructure not rendered by the app chart |
| `0401f71b` | Pod Misconfigured Network Policy | k05-noEgressControls | Rule's pod-to-policy selector matching does not trigger with the current NetworkPolicy template layout |
| `69bbc5e3` | Ingress Controller Exposes Workload | k06-traefikDashboardExposed / k06-rabbitmqMgmtExposed | Rule only reads `networking.k8s.io/v1 Ingress`; chart uses Traefik's proprietary `IngressRoute` CRD |
| `c1032cf7` | Shared Service Account | k09-sharedServiceAccount | Rule matches pods that explicitly reference the same named SA; chart relies on the implicit `default` SA, caught instead by `1e749bc9` |

---

## Rules That Fired but Are Not in the Table

| ID | Rule name | Category | Severity | Candidate mapping |
|---|---|---|---|---|
| `ca469dd4` | CPU Requests Not Set | Resource Management | LOW | k01-unboundedResources |
| `229588ef` | Memory Requests Not Defined | Resource Management | MEDIUM | k01-unboundedResources |
| `487f4be7` | Passwords And Secrets - Generic Password | Secret Management | HIGH | k03-plaintextConfigMapSecrets |
| `3e2d3b2f` | Passwords And Secrets - Generic Secret | Secret Management | HIGH | k03-jwtKeyInEnv |
| `c4d3b58a` | Passwords And Secrets - Password in URL | Secret Management | HIGH | k03-* |
| `5572cc5e` | Privilege Escalation Allowed | Insecure Configurations | HIGH | k01-privileged (additional coverage) |
| `26763a1c` | Service With External Load Balancer | Networking and Firewall | MEDIUM | k06-* (partial) |
| `48471392` | Service Account Token Automount Not Disabled | Insecure Defaults | MEDIUM | k09-sharedServiceAccount (additional) |
| `02323c00` | Container Running With Low UID | Best Practices | MEDIUM | — |
| `e84eaf4d` | Ensure Administrative Boundaries Between Resources | Access Control | INFO | — |
| `caa3479d` | Image Pull Policy Not Always | Insecure Configurations | LOW | — |
| `7c81d34c` | Image Without Digest | Insecure Configurations | LOW | — |
| `ade74944` | Liveness Probe Is Not Defined | Availability | INFO | — |
| `8b36775e` | Missing AppArmor Profile | Access Control | LOW | — |
| `dbbc6705` | NET_RAW Capabilities Not Being Dropped | Insecure Configurations | MEDIUM | — |
| `268ca686` | No Drop Capabilities for Containers | Best Practices | LOW | — |
| `4a20ebac` | Pod or Container Without LimitRange | Insecure Configurations | LOW | — |
| `48a5beba` | Pod or Container Without ResourceQuota | Insecure Configurations | LOW | — |
| `a97a340a` | Pod or Container Without Security Context | Insecure Configurations | LOW | — |
| `a659f3b5` | Readiness Probe Is Not Configured | Availability | MEDIUM | — |
| `f377b83e` | Seccomp Profile Is Not Configured | Insecure Configurations | MEDIUM | — |
| `3ca03a61` | Service Does Not Target Pod | Insecure Configurations | LOW | — |
| `611ab018` | Using Unrecommended Namespace | Insecure Configurations | MEDIUM | — |
| `b7652612` | Volume Mount With OS Directory Write Permissions | Resource Management | HIGH | — |
