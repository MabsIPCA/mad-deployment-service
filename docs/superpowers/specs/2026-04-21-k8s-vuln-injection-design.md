# Extending the MAD Goat Benchmark to the Kubernetes Layer

**Spec date:** 2026-04-21
**Author:** miabs
**Status:** Draft — awaiting user review
**Target deliverable:** one thesis section (LaTeX) + backing implementation (Helm charts + sibling cluster artifacts)

---

## 1. Overview

### 1.1 Argument

The MAD Goat benchmark covers application-layer vulnerabilities but lacks coverage of the Kubernetes deployment layer. This section closes that gap by injecting OWASP Kubernetes Top 10 vulnerabilities into the `madgoat` and `madgoat-infra` Helm charts (with a sibling `k8s/insecure-defaults/` artifact for cluster-level items), cataloguing each with a reproducible exploit walkthrough and a `values.yaml` mitigation toggle.

### 1.2 Framing (from brainstorming)

Combined **benchmark extension + vulnerability catalogue**. The section opens with a gap analysis against the current chart state (benchmark-extension framing), followed by a per-sub-item catalogue (reference framing), followed by a summary table. A downstream **scanner evaluation** chapter (KICS / Trivy / KubeLinter / Kubescape detection rates) is out of scope here; this section produces the seed data for it.

### 1.3 OWASP version anchoring

**Primary: OWASP Kubernetes Top 10, 2025 edition.** The 2022 edition is used as a crosswalk (appears in every entry heading and in a dedicated Table 1). The existing project spreadsheet (`OWASP Top 10 K8s Evalutaion 14 Nov.ods`) is mapped onto the dual axis as part of the implementation plan.

### 1.4 Out of scope (with thesis-ready justifications)

- **K10/2022 as its own catalogue entry**: its subject matter is folded into K07/2025 as a single discussion-only sub-item (`k07-outdatedComponents`) that cross-references K02/2022 image-pinning.
- **Scanner evaluation study**: separate future chapter; this section only surfaces scanner IDs per entry as Table 3 seed data.
- **Runtime / CNI-level attacks** (container escapes via kernel CVEs, eBPF-level bypasses): require a hardened cluster baseline and constitute independent research scope.
- **K08/2025 Cluster-to-Cloud Lateral Movement end-to-end exploit**: not reproducible in a local Minikube environment (no real IMDS, no cloud control plane). Section covers K08/2025 conceptually with cloud-vendor documentation and literature citations, explicitly marked "exploit walkthrough: conceptual; requires managed K8s."

### 1.5 Entry classes

Not every sub-item receives the same treatment. Three classes are defined explicitly so the success criteria below can reference them:

- **Full entries** (15 chart-level + 4 cluster-level = 19 items): complete 7-field template, safe-mode toggle, `verify-exploit-<id>` script, entry in both Tables 2 and 3.
- **Conceptual entries** (3 items: `k08-imdsCredentialTheft`, `k08-saTokenToCloud`): 7-field template *except* exploit walkthrough is prose-only and cites cloud-vendor docs; no `verify-exploit` script; rows in Tables 2 and 3 note `exploit: conceptual`.
- **Discussion entries** (2 items: `k07-outdatedComponents`, `k10-noLogAggregation`): short paragraph only (weakness + CWE + references + cross-references); no YAML excerpt, no exploit, no safe-mode toggle, no table row beyond a note in Table 1's crosswalk.

See Section 5 for the per-sub-item classification.

### 1.6 Success criteria

1. Every **full** and **conceptual** entry (K01–K10, 2025) has: weakness description, CWE mapping, concrete config excerpt (full entries only), exploit walkthrough (prose-only for conceptual), safe-mode toggle (full entries only), scanner coverage line.
2. Every **full**, **conceptual**, and **discussion** entry cites ≥ 1 primary normative source (OWASP page, CIS benchmark item, Kubernetes docs) and where applicable a peer-reviewed or conference source.
3. The gap-analysis table and summary table derive from a single ground-truth source (`thesis/kubernetes-vulns/data/vulnerabilities.yaml`); no hand-maintained duplication.
4. Charts + sibling cluster artifacts deploy cleanly in both default (vulnerable) and safe modes, per the reset targets in Section 7b.
5. Each **full** entry's exploit walkthrough runs end-to-end on a local Minikube using only `kubectl`, `curl`, `mc`, `jq`. (Conceptual and discussion entries are exempt.)
6. Each **full** entry is empirically gated by a `make verify-exploit-<id>` target that returns exit 0 in vulnerable mode and non-zero in safe mode (oracle per the GOAT benchmark schematic).

---

## 2. Thesis section structure (LaTeX outline)

The section is delivered as `thesis/kubernetes-vulns/kubernetes-vulns.tex`, a self-contained fragment starting at `\section{...}` with no `\documentclass` / `\begin{document}`. It is included into the main thesis via `\input{kubernetes-vulns/kubernetes-vulns.tex}`.

```
\section{Kubernetes Layer Vulnerabilities in the MAD Goat Benchmark}
  \subsection{Motivation and Scope}
  \subsection{Methodology}
      \subsubsection{Reference taxonomy: OWASP K8s Top 10 (2025)}
          % Table 1: 2022 ↔ 2025 crosswalk (hand-authored, static)
      \subsubsection{Gap analysis against current charts}
          % Table 2: per sub-item × [present pre-injection, 2022 eq, CWE, CIS]
          % Generated from data/vulnerabilities.yaml
      \subsubsection{Injection model}
          % values.yaml vulnerabilities.* toggles, default=true (vulnerable)
          % sibling k8s/insecure-defaults/ for cluster-level items
          % Reproducibility contract: minikube + make targets
      \subsubsection{Entry template}
          % The 7-field skeleton used for every \paragraph

  \subsection{Injected Vulnerabilities}
      \subsubsection{K01/2025 Insecure Workload Configurations (≡ K01/2022)}
          \paragraph{Run-as-root containers}
          \paragraph{Writable root filesystem}
          \paragraph{Privileged containers}
          \paragraph{Unbounded resources}
      \subsubsection{K02/2025 Overly Permissive Authorization Configurations (≡ K03/2022 RBAC)}
          \paragraph{cluster-admin ServiceAccount binding}
          \paragraph{Role with list/watch on Secrets}
      \subsubsection{K03/2025 Secrets Management Failures (≡ K08/2022)}
          \paragraph{Plaintext credentials in ConfigMap}
          \paragraph{JWT signing key in env}
      \subsubsection{K04/2025 Lack of Cluster-Level Policy Enforcement (≡ K04/2022)}
          \paragraph{Namespace without Pod Security Admission}
          \paragraph{Kyverno installed with no-op rules}
      \subsubsection{K05/2025 Missing Network Segmentation Controls (≡ K07/2022)}
          \paragraph{No default-deny NetworkPolicy}
          \paragraph{Overly permissive label-selector policy}
          \paragraph{No egress controls}
      \subsubsection{K06/2025 Overly Exposed Kubernetes Components (partially new)}
          \paragraph{Traefik dashboard exposed}
          \paragraph{RabbitMQ management UI exposed}
      \subsubsection{K07/2025 Misconfigured and Vulnerable Cluster Components (≡ K09/2022 + K10/2022)}
          \paragraph{kubelet --anonymous-auth=true}
          \paragraph{kubelet --authorization-mode=AlwaysAllow}
          \paragraph{Outdated component versions (discussion)}
      \subsubsection{K08/2025 Cluster-to-Cloud Lateral Movement (new in 2025)}
          \paragraph{IMDS credential theft (conceptual)}
          \paragraph{Projected SA token to cloud IAM (conceptual)}
      \subsubsection{K09/2025 Broken Authentication Mechanisms (≡ K06/2022)}
          \paragraph{Keycloak bootstrap with default admin/admin}
          \paragraph{Shared default ServiceAccount}
      \subsubsection{K10/2025 Inadequate Logging and Monitoring (≡ K05/2022)}
          \paragraph{No apiserver audit policy}
          \paragraph{No workload log aggregation (discussion)}

  \subsection{Summary}
      % Table 3: one row per sub-item — category/2025, category/2022, CWE, CIS,
      %          file touched, values flag, scanner IDs
      % Paragraph: coverage achieved, limitations (K10/2022 deferred, K08/2025 simulated)
      \subsubsection{Scanner detectability (seed data for future work)}
```

Structural notes:
- `\paragraph` per sub-item keeps the TOC at `\subsubsection` depth while every sub-item remains named and citable via `\ref{}` / `\nameref{}`.
- Heading crosswalk (`\textit{(≡ K0Y/2022)}`) discharges the dual-version requirement without parallel numbering.
- Tables 2 and 3 are generated from the single ground-truth YAML (Section 4c). Table 1 is hand-authored and static.

---

## 3. Per-entry template (LaTeX skeleton)

Every `\paragraph` (one per sub-item) uses this fixed skeleton, so the section reads uniformly and Table 3 can be generated mechanically from the same source data.

```latex
\paragraph{<Short name>}
\label{sec:kXX-<slug>}
%% 1. Weakness description (2–4 sentences)
%% 2. Metadata (inline, bold labels)
   \textbf{CWE:} CWE-NNN.
   \textbf{CIS K8s Benchmark v1.12:} X.Y.Z.
   \textbf{OWASP:} K0X/2025 (≡ K0Y/2022).
   \textbf{Scope:} chart-level | cluster-level.
%% 3. Injected configuration
\begin{minted}[frame=single,fontsize=\footnotesize]{yaml}
# helm/<chart>/<file>.yaml — vulnerable state
...
\end{minted}
%% 4. Exploit walkthrough — attacker model + steps
   \textbf{Attacker model:} <unauthenticated external |
                             authN low-privilege user |
                             compromised pod |
                             insider operator>.
\begin{minted}[frame=single,fontsize=\footnotesize]{bash}
kubectl ...
curl ...
\end{minted}
%% 5. Impact (1–2 sentences, naming the concrete asset)
%% 6. Mitigation (the toggle + the safe YAML)
\begin{minted}[frame=single,fontsize=\footnotesize]{yaml}
# values.yaml — safe mode
vulnerabilities:
  kXX_<slug>: false
\end{minted}
%% 7. Detectability line
   \textbf{Detection:} KICS \texttt{<id>} \cite{kics-db},
                       Trivy \texttt{<id>} \cite{trivy-kube},
                       KubeLinter \texttt{<check>} \cite{kubelinter},
                       Kubescape \texttt{<C-id>} \cite{kubescape}.
```

Fixed template choices:
- **`minted` for code blocks.** Requires `pdflatex -shell-escape` (or `latexmk -shell-escape`) and a working Python + Pygments on the build machine.
- **`\label{sec:kXX-<slug>}`** on every paragraph enables `\ref{}` from the summary table and crosswalk table — no duplicated text.
- **Exploit walkthrough is command-first, prose-second.** Each step is a paste-ready shell/HTTP invocation; prose explains *why*, not *how*.

Deliberately omitted:
- Remediation cost / complexity rating (adds noise without supporting the current argument).
- Screenshots of successful exploits (expensive to keep in sync with chart versions).

---

## 4. Injection architecture

### 4a. Values schema (both charts)

New top-level block added to `helm/madgoat/values.yaml` and `helm/madgoat-infra/values.yaml`:

```yaml
vulnerabilities:
  # K01/2025 Insecure Workload Configurations
  k01_runAsRoot: true
  k01_readOnlyRootFs: true
  k01_privileged: true
  k01_unboundedResources: true

  # K02/2025 Overly Permissive Authorization (≡ K03/2022 RBAC)
  k02_clusterAdminBinding: true
  k02_secretsListWatch: true

  # K03/2025 Secrets Management Failures
  k03_plaintextConfigMapSecrets: true
  k03_jwtKeyInEnv: true

  # K05/2025 Missing Network Segmentation Controls
  k05_noDefaultDeny: true
  k05_permissiveNetpol: true
  k05_noEgressControls: true

  # K06/2025 Overly Exposed Kubernetes Components
  k06_traefikDashboardExposed: true
  k06_rabbitmqMgmtExposed: true

  # K09/2025 Broken Authentication Mechanisms
  k09_anonymousKeycloakBootstrap: true
  k09_sharedServiceAccount: true
```

**Default value is `true` (vulnerable).** This is a deliberately-vulnerable benchmark; the default must be vulnerable. Safe mode is opt-in and documented as the mitigation.

**Template pattern (negative form):**

```yaml
{{- if not .Values.vulnerabilities.k01_runAsRoot }}
securityContext:
  runAsNonRoot: true
  runAsUser: 10001
{{- end }}
```

Rationale for negative form: *turning the flag off adds the defence*. This keeps the default-on state a minimal change from the current chart.

### 4b. Sibling artifact for cluster-level items

New directory `k8s/insecure-defaults/` in the repository root. Contents are raw manifests, `KubeletConfiguration` drop-ins, and markdown notes — not Helm charts. The thesis makes the scope boundary explicit: *"Helm does not govern kubelet flags or apiserver audit policy; therefore these items are injected via sibling cluster-bootstrap artifacts and applied out-of-band."*

```
k8s/insecure-defaults/
├── README.md
├── kubelet-config.yaml             # K07: anonymous-auth=true, AlwaysAllow
├── admission-no-psa.yaml           # K04: namespace without Pod Security Admission labels
├── kyverno-weak-policies.yaml      # K04: Kyverno installed with no-op rules (see 4e)
├── audit-policy-missing.md         # K10: documented absence + minikube start flags
├── audit-policy-safe.yaml          # K10 safe-mode: reference audit policy for comparison
└── kustomization.yaml              # single apply: kubectl apply -k k8s/insecure-defaults/
```

### 4c. Ground-truth data file (drives Tables 2 and 3)

One YAML file is the source of truth for the tables. It lives at `thesis/kubernetes-vulns/data/vulnerabilities.yaml`:

```yaml
- id: k01-runAsRoot
  owasp2025: K01
  owasp2022: K01
  title: Run-as-root containers
  cwe: 250
  cis: "5.2.6"
  scope: chart
  chartFile: helm/madgoat/templates/deployment.yaml
  valuesFlag: vulnerabilities.k01_runAsRoot
  scanners:
    kics: cf34805e-3872-4c08-bf92-6ff7bb0cfadb
    trivy: KSV012
    kubelinter: run-as-non-root
    kubescape: C-0013
  references: [owasp-k01-2025, cis-k8s-v1.12, nsa-k8s-hardening]
  presentInChartPreInjection: false
```

`thesis/kubernetes-vulns/scripts/gen-tables.sh` renders `tables/gap-analysis.tex` (Table 2) and `tables/summary.tex` (Table 3) from this file. The script uses `yq` + `awk` (no Python dependency) so it runs on any reasonable Unix shell.

### 4d. Reproducibility contract

Chart-level and cluster-level items require different toggling mechanisms:

- **Chart-level** (15 full entries): toggled purely via `helm upgrade --set vulnerabilities.kXX_...=false`. Fast; no cluster restart.
- **Cluster-level** (K04 admission, K07 kubelet, K10 audit): live in Minikube's bootstrap flags and in raw manifests under `k8s/insecure-defaults/`. Toggling them requires **destroying and recreating the Minikube cluster** with different `--extra-config` flags. There is no way for `helm upgrade` to flip kubelet flags on a running node.

The repository therefore provides two pairs of targets (Section 7b):

- **Fast (chart-level only) toggle:** `deploy-vulnerable` / `deploy-safe` — keeps the cluster running, flips only Helm values. Sufficient for 15 of the 19 full entries.
- **Full reset (chart + cluster):** `reset-vulnerable` / `reset-safe` — deletes and recreates Minikube with the right bootstrap flags, then applies/removes `k8s/insecure-defaults/`. Required when validating K04 / K07 / K10 entries.

Replay skeleton per entry:

```bash
# Chart-level entries
make reset-vulnerable                        # clean state, all vulns on
make verify-exploit-k01-runAsRoot            # exit 0 — exploit succeeds
make deploy-safe                             # flip chart flags off
make verify-exploit-k01-runAsRoot            # exit non-zero — exploit fails

# Cluster-level entries (kubelet/audit/PSA) require minikube restart
make reset-vulnerable                        # minikube start with insecure bootstrap flags
make verify-exploit-k07-kubeletAnonymousAuth # exit 0
make reset-safe                              # minikube start with default/hardened flags
make verify-exploit-k07-kubeletAnonymousAuth # exit non-zero
```

### 4e. K04 Kyverno decision

K04 (admission-control failures) is modelled as "Kyverno is installed but configured with no-op / passthrough rules." This is more realistic than "nothing is installed": modern clusters increasingly do ship admission controllers, and the prevalent failure mode is misconfiguration, not absence. The thesis explicitly justifies this framing in the K04 entry.

---

## 5. Category-to-injection mapping

Pre-state column reflects actual grep of the current charts (April 2026), not the stale ODS. Concrete file paths and flag names below are the contract the implementation plan executes against.

### 5a. Chart-level sub-items (15 items)

| ID | 2025 / 2022 | Sub-item | Target file(s) | Values flag | Pre-state | Work |
|---|---|---|---|---|---|---|
| `k01-runAsRoot` | K01 / K01 | Run-as-root containers | `madgoat/templates/deployment.yaml`, `madgoat-infra/templates/{core,db}.yaml` | `k01_runAsRoot` | vulnerable (no securityContext anywhere) | add negative-form securityContext |
| `k01-readOnlyRootFs` | K01 / K01 | Writable root FS | same | `k01_readOnlyRootFs` | vulnerable | same |
| `k01-privileged` | K01 / K01 | Privileged containers | `madgoat/templates/deployment.yaml` applied to `mad4shell-unsafe`, `profile`, `webapp` | `k01_privileged` | not privileged | flip to `privileged: true` when flag on |
| `k01-unboundedResources` | K01 / K01 | Unbounded CPU/mem | `madgoat/templates/deployment.yaml` applied to `lesson` | `k01_unboundedResources` | resources currently set | remove limits/requests when flag on |
| `k02-clusterAdminBinding` | K02 / K03 | Default SA bound to cluster-admin | **new** `madgoat-infra/templates/rbac.yaml` | `k02_clusterAdminBinding` | absent | emit `ClusterRoleBinding` |
| `k02-secretsListWatch` | K02 / K03 | Role with list/watch on Secrets | new `rbac.yaml` | `k02_secretsListWatch` | absent | emit Role + RoleBinding |
| `k03-plaintextConfigMapSecrets` | K03 / K08 | Creds in ConfigMap | `madgoat-infra/templates/configmap.yaml` (DB/Keycloak/MinIO), `madgoat/templates/configmap.yaml` (JWT) | `k03_plaintextConfigMapSecrets` | **already vulnerable** (current state) | document; safe mode emits `kind: Secret` |
| `k03-jwtKeyInEnv` | K03 / K08 | JWT signing key in env | `madgoat/configmap.yaml` | `k03_jwtKeyInEnv` | **already vulnerable** | safe mode moves to Secret mounted as file |
| `k05-noDefaultDeny` | K05 / K07 | No default-deny NetworkPolicy | `madgoat-infra/templates/mad-network-networkpolicy.yaml` | `k05_noDefaultDeny` | **already vulnerable** | safe mode emits default-deny |
| `k05-permissiveNetpol` | K05 / K07 | Weak label-based netpol | same | `k05_permissiveNetpol` | **already vulnerable** (current policy) | safe mode replaces with per-service explicit rules |
| `k05-noEgressControls` | K05 / K07 | Missing egress rules | same | `k05_noEgressControls` | **already vulnerable** | safe mode adds egress allowlist |
| `k06-traefikDashboardExposed` | K06 / — | Traefik `/dashboard` exposed | `madgoat-infra/templates/dashboard.yaml` | `k06_traefikDashboardExposed` | **already vulnerable** | safe mode removes the IngressRoute |
| `k06-rabbitmqMgmtExposed` | K06 / — | RabbitMQ mgmt UI exposed via Traefik | `madgoat-infra/values.yaml` rabbitmq traefik route | `k06_rabbitmqMgmtExposed` | **already vulnerable** | safe mode drops the mgmt route |
| `k09-anonymousKeycloakBootstrap` | K09 / K06 | Keycloak `admin/admin` + `start-dev` | `madgoat-infra/values.yaml` (`env-keycloak`, core args) | `k09_anonymousKeycloakBootstrap` | **already vulnerable** | safe mode: strong password via Secret + `start` |
| `k09-sharedServiceAccount` | K09 / K06 | All pods on `default` SA | `madgoat/templates/deployment.yaml`, infra templates | `k09_sharedServiceAccount` | **already vulnerable** | safe mode: per-service SA + `automountServiceAccountToken: false` |

### 5b. Cluster-level sub-items (9 items, sibling `k8s/insecure-defaults/`)

| ID | 2025 / 2022 | Sub-item | Target artifact | Pre-state | Notes |
|---|---|---|---|---|---|
| `k04-noPSA` | K04 / K04 | Namespace without Pod Security Admission | `admission-no-psa.yaml` | absent | "absence" is the vuln; safe variant labels `ns` `enforce=restricted` |
| `k04-weakKyverno` | K04 / K04 | Kyverno installed with no-op rules | `kyverno-weak-policies.yaml` | absent | included per design decision; thesis justifies realism |
| `k07-kubeletAnonymousAuth` | K07 / K09 | `kubelet --anonymous-auth=true` | `kubelet-config.yaml` | Minikube default varies | KubeletConfiguration drop-in + `minikube start` flags |
| `k07-kubeletAlwaysAllow` | K07 / K09 | `kubelet --authorization-mode=AlwaysAllow` | same | Minikube default varies | same |
| `k07-outdatedComponents` | K07 / K10 | Outdated K8s / images | discussion + image-tag table | n/a | descriptive; cross-refs K02/2022 |
| `k08-imdsCredentialTheft` | K08 / — | IMDS credential theft | **conceptual only** | n/a locally | cites AWS/GCP/Azure IMDS docs + literature |
| `k08-saTokenToCloud` | K08 / — | Projected SA token to cloud IAM | **conceptual only** | n/a locally | cites GKE Workload Identity, AWS IRSA, Azure WI docs |
| `k10-noAuditPolicy` | K10 / K05 | No apiserver audit policy | `audit-policy-missing.md` + `minikube start` flags | absent | safe variant ships `audit-policy-safe.yaml` |
| `k10-noLogAggregation` | K10 / K05 | No log aggregation stack | discussion only | absent | out of scope for injection; mentioned |

**Total: 24 sub-items** (15 chart-level + 9 cluster-level/conceptual).

---

## 6. Bibliography strategy

### 6a. Citation style

IEEE numeric, BibTeX (not BibLaTeX). Output file: `thesis/kubernetes-vulns/references.bib`, self-contained. Main thesis can merge or include via `\bibliography{main,references}`.

### 6b. Required primary normative sources

1. OWASP Kubernetes Top 10, 2025 edition — `@misc{owasp-k8s-top-ten-2025, ...}` with `urldate`.
2. OWASP Kubernetes Top 10, 2022 edition — `@misc{owasp-k8s-top-ten-2022, ...}`.
3. CIS Kubernetes Benchmark v1.12 (2025-09-26) — `@techreport{cis-k8s-v1.12, ...}`.
4. NIST SP 800-190 — *Application Container Security Guide* (2017).
5. NSA/CISA *Kubernetes Hardening Guidance* (Aug 2022 revision).
6. Kubernetes official docs per primitive (`@misc{k8s-docs-<primitive>}`): Pod Security Standards, RBAC, NetworkPolicy, Audit, Secrets, ServiceAccount, PSA.

### 6c. Peer-reviewed / conference sources

7. Zerouali et al., MSR 2023 — *Helm Charts for Kubernetes Applications: Evolution, Outdatedness and Security Risks.* (confirmed; user-supplied).
8. Shamim et al., IEEE SecDev 2020 — *XI Commandments of Kubernetes Security* (SoK).
9. Bose et al., ICSE 2023 — empirical study of container image security weaknesses.
10. Minna & De Turck, IEEE TNSM 2024 — *Understanding the Security Implications of Kubernetes Networking* (K05 anchor).
11. Candidate for K08/2025 (cluster-to-cloud): TBD during writing; flagged `VERIFY` in the `.bib` until confirmed.

### 6d. Vendor / tool references

12. KICS (Checkmarx) — `@misc` with repo URL + `urldate`.
13. Trivy (Aqua) — same.
14. KubeLinter (StackRox) — same.
15. Kubescape (ARMO) — same.

### 6e. Cloud vendor docs (K08/2025 conceptual section only)

16. AWS IMDSv2 guidance.
17. GCP Workload Identity.
18. Azure Workload Identity / Pod Identity.

### 6f. Conventions

- Key format: lowercase, hyphen-separated, typically `firstauthor-year` or `org-topic` (e.g., `zerouali-2023`, `owasp-k8s-top-ten-2025`, `k8s-docs-networkpolicy`).
- `urldate = {2026-04-21}` on every `@misc` web citation.
- Unverified entries carry `note = {VERIFY}` and a TODO comment. These must be cleared before submission. No invented DOIs, authors, or page numbers.
- Coverage target per `\paragraph`: 1× OWASP + 1× CIS (when applicable) + 1× K8s docs + 1× scanner citation + optional 1× academic. Typical entry cites 4–5 sources.
- Expected total: ~35–50 unique bib entries, weighted toward `@misc` normative sources, with ~8–10 academic `@article` / `@inproceedings`.

---

## 7. Deliverables and file layout

### 7a. Repository layout post-implementation

```
mad-deployment-service/
├── helm/
│   ├── madgoat/
│   │   ├── values.yaml                    # MODIFIED: add vulnerabilities.* block
│   │   └── templates/
│   │       ├── deployment.yaml            # MODIFIED: securityContext + privileged + resources branches
│   │       ├── configmap.yaml             # MODIFIED: conditional Secret vs ConfigMap path
│   │       ├── service.yaml               # unchanged
│   │       ├── rbac.yaml                  # NEW: ClusterRoleBinding + Role (K02)
│   │       ├── serviceaccount.yaml        # NEW: per-service SA (K09 safe mode)
│   │       └── secret.yaml                # NEW: K8s Secrets for K03 safe mode
│   └── madgoat-infra/
│       ├── values.yaml                    # MODIFIED: vulnerabilities.* block, conditional routes
│       └── templates/
│           ├── core.yaml                  # MODIFIED: securityContext branches
│           ├── db.yaml                    # MODIFIED: securityContext branches
│           ├── configmap.yaml             # MODIFIED: conditional Secret path
│           ├── core-services.yaml         # unchanged
│           ├── db-services.yaml           # unchanged
│           ├── dashboard.yaml             # MODIFIED: gated by k06_traefikDashboardExposed
│           ├── mad-network-networkpolicy.yaml   # MODIFIED: conditional default-deny, egress, old policy
│           ├── ingressRoutes.yaml         # unchanged
│           ├── rbac.yaml                  # NEW
│           ├── serviceaccount.yaml        # NEW
│           └── secret.yaml                # NEW
│
├── k8s/
│   └── insecure-defaults/                 # NEW
│       ├── README.md
│       ├── kubelet-config.yaml
│       ├── admission-no-psa.yaml
│       ├── kyverno-weak-policies.yaml
│       ├── audit-policy-missing.md
│       ├── audit-policy-safe.yaml
│       └── kustomization.yaml
│
├── thesis/
│   └── kubernetes-vulns/                  # NEW
│       ├── kubernetes-vulns.tex           # \input-ready section
│       ├── references.bib                 # IEEE BibTeX
│       ├── data/
│       │   └── vulnerabilities.yaml       # ground truth (drives Tables 2 & 3)
│       ├── tables/
│       │   ├── crosswalk-2022-2025.tex    # Table 1 (static, hand-authored)
│       │   ├── gap-analysis.tex           # Table 2 (generated)
│       │   └── summary.tex                # Table 3 (generated)
│       ├── scripts/
│       │   └── gen-tables.sh              # YAML → .tex via yq + awk (no Python)
│       ├── snippets/                      # code excerpts for \inputminted
│       │   ├── k01-runAsRoot-vuln.yaml
│       │   ├── k01-runAsRoot-safe.yaml
│       │   ├── k01-runAsRoot-exploit.sh
│       │   └── ...                        # one triple per sub-item
│       └── README.md                      # build + paste-in instructions
│
├── scripts/
│   └── exploits/                          # NEW: one per sub-item used by verify-exploit-%
│       ├── k01-runAsRoot.sh
│       └── ...
│
├── makefile                               # MODIFIED: new targets (7b)
└── docs/
    └── superpowers/specs/
        └── 2026-04-21-k8s-vuln-injection-design.md    # THIS SPEC
```

### 7b. Makefile targets (new)

| Target | Behavior |
|---|---|
| `deploy-vulnerable` | `helm upgrade --install` both charts with defaults (all `vulnerabilities.*=true`). Does **not** restart Minikube. Assumes the cluster was started with insecure bootstrap flags. |
| `deploy-safe` | `helm upgrade --install` both charts with all `vulnerabilities.*=false`. Does **not** restart Minikube. Sufficient only for chart-level entries. |
| `reset-vulnerable` | `minikube delete && minikube start --extra-config=kubelet.anonymous-auth=true --extra-config=kubelet.authorization-mode=AlwaysAllow ...` (full flag list lives in the makefile), then `make deploy-vulnerable && kubectl apply -k k8s/insecure-defaults/`. Required to validate cluster-level entries (K04 / K07 / K10). |
| `reset-safe` | `minikube delete && minikube start` (default hardened flags), then `make deploy-safe && kubectl delete -k k8s/insecure-defaults/ --ignore-not-found`. Required to validate cluster-level safe mode. |
| `verify-exploit-%` | Runs `scripts/exploits/$*.sh`. Exits 0 when the exploit succeeds (vulnerable mode), non-zero when it fails (safe mode). Serves as the benchmark oracle. Only defined for the 19 **full** entries; **conceptual** and **discussion** entries have no corresponding script. |
| `gen-thesis-tables` | Runs `thesis/kubernetes-vulns/scripts/gen-tables.sh` to regenerate Tables 2 and 3 from `data/vulnerabilities.yaml`. |

### 7c. LaTeX preamble requirements

To compile the section, the main thesis preamble must include:

```latex
\usepackage{minted}              % syntax-highlighted code (required)
\usepackage{booktabs}            % Tables 1/2/3 use \toprule \midrule \bottomrule
\usepackage{array}               % custom column types for tables
\usepackage{xcolor}              % color support for minted themes
\usepackage[hidelinks]{hyperref} % \ref and \nameref to paragraph labels

% Optional but recommended (makes minted output legible)
\usemintedstyle{tango}
\setminted{
    frame=single,
    framesep=2mm,
    fontsize=\footnotesize,
    breaklines=true,
    breakanywhere=true,
    tabsize=2
}
```

**Compile flag required:** `pdflatex -shell-escape main.tex` (or `latexmk -shell-escape main.tex`). `minted` shells out to Pygments; without `-shell-escape` the build fails. CI and Overleaf free-tier need to be aware of this.

### 7d. Done criteria (verifiable)

Let `FULL_IDS` = the 19 full-entry IDs (15 chart-level + 4 cluster-level: `k04-noPSA`, `k04-weakKyverno`, `k07-kubeletAnonymousAuth`, `k07-kubeletAlwaysAllow`, `k10-noAuditPolicy`). Conceptual and discussion IDs are excluded from the exploit-script criteria.

1. `make reset-vulnerable && for id in $(FULL_IDS); do make verify-exploit-$$id; done` — every id in `FULL_IDS` returns 0.
2. `make reset-safe && for id in $(FULL_IDS); do ! make verify-exploit-$$id; done` — every id in `FULL_IDS` returns non-zero.
3. `make gen-thesis-tables` is idempotent (re-running produces byte-identical output).
4. `pdflatex -shell-escape` builds the section fragment cleanly with no missing citations and no remaining `VERIFY` flags in `references.bib`.
5. The ODS is updated to a dual-axis (2025 + 2022) layout consistent with `data/vulnerabilities.yaml`.
6. Each conceptual entry (`k08-imdsCredentialTheft`, `k08-saTokenToCloud`) has prose-only walkthrough + ≥ 1 cloud-vendor doc citation + ≥ 1 literature citation, and its row in Tables 2/3 is marked `exploit: conceptual`.
7. Each discussion entry (`k07-outdatedComponents`, `k10-noLogAggregation`) appears only in Table 1's crosswalk narrative with a short paragraph + ≥ 1 normative citation; it does not consume a row in Tables 2 or 3.

---

## 8. Open decisions for the implementation plan

These were deferred from brainstorming as plan-phase choices, listed here so the planner picks them up explicitly:

1. **ODS update mechanics** — whether the updated spreadsheet becomes a second source of truth, or is generated from `data/vulnerabilities.yaml` (recommendation: generate, but requires a small `yq → ods` converter; alternative is a one-time manual rework with a README stating `data/vulnerabilities.yaml` is canonical).
2. **Bib key namespacing** — whether to prefix keys from this fragment (e.g., `k8svulns:zerouali-2023`) to avoid collisions when merged into the main thesis `.bib`, or trust the main `.bib` to be collision-free.
3. **Kyverno chart dependency** — install via raw manifests (simplest, included in `k8s/insecure-defaults/`) vs. add Kyverno as a Helm sub-chart dependency (more realistic deployment modelling, more setup complexity). Recommendation: raw manifests for v1; promote to sub-chart only if a later stage needs it.
4. **Minikube version pinning** for K07 outdated-components discussion — which version pair (old + current) to contrast.

Everything else in this spec is a firm commitment the plan will execute against.
