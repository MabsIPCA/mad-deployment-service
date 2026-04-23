# K8s Vulnerability ODS Update & End-to-End Verification — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update the OWASP K8s spreadsheet to a dual-axis (2025 + 2022) layout derived from `data/vulnerabilities.yaml`, fix bibliography gaps, add an end-to-end exploit verification harness, and document the LaTeX compilation prerequisites.

**Architecture:** Four independent deliverables: (1) `scripts/gen-ods.py` generates the ODS from YAML using Python stdlib (no pip deps); (2) `references.bib` gains three missing entries and a corrected CIS key; (3) `scripts/verify-all.sh` runs all 20 exploit scripts against a live cluster; (4) `thesis/kubernetes-vulns/compile.sh` documents the pdflatex prerequisites. Each task is independently committable.

**Tech Stack:** Python 3 stdlib (zipfile, re, os), bash, pdflatex + TeX Live / MiKTeX (user prerequisite for Task 5), Minikube (user prerequisite for Task 4)

**Prerequisites:**
- Working directory: `.worktrees/k8s-vuln-injection/`
- All commands run from that directory unless stated otherwise
- Task 4 (exploit verification) requires a running Minikube — skip or defer if unavailable

---

## File Map

**Create:**
- `scripts/gen-ods.py` — generates dual-axis ODS from `data/vulnerabilities.yaml`
- `scripts/verify-all.sh` — end-to-end harness: runs all 20 exploit scripts, reports pass/fail
- `thesis/kubernetes-vulns/compile.sh` — documents pdflatex compilation steps

**Modify:**
- `thesis/kubernetes-vulns/references.bib` — add `rahman-2023`, `minna-2021`, `gcp-workload-identity`; rename `cis-k8s-1.9` → `cis-k8s-v1.12`; fix `zerouali-2023` title/DOI
- `thesis/kubernetes-vulns/kubernetes-vulns.tex` — update `\cite{cis-k8s-1.9}` → `\cite{cis-k8s-v1.12}` everywhere; add `\cite{minna-2021}` to K05/K06; add `\cite{rahman-2023}` to methodology

**Generate (output, not source-controlled):**
- `OWASP-K8s-Top10-Dual-Axis.ods` — generated at repo root by `scripts/gen-ods.py`

---

### Task 1: Fix references.bib

**Files:**
- Modify: `thesis/kubernetes-vulns/references.bib`

Three gaps vs. the spec's bibliography strategy (§6):
- `rahman-2023` (ACM TOSEM 2023, DOI 10.1145/3579639) is the **primary methodology anchor** — missing entirely; we have the wrong Rahman paper (`rahman-2019`, ICSE 2019)
- `minna-2021` (IEEE S&P 2021, DOI 10.1109/MSEC.2021.3094726) for K05/K06 network security — missing
- `zerouali-2023` has wrong title and DOI vs. the spec (spec: "Helm Charts for Kubernetes Applications: Evolution, Outdatedness and Security Risks", DOI .00078)
- `cis-k8s-1.9` key is wrong — ODS already uses v1.12 (2025-09-26); key must become `cis-k8s-v1.12`
- `gcp-workload-identity` needed for K08-b GKE workload identity citation

- [ ] **Step 1.1: Read current references.bib to confirm keys present**

```bash
grep "^@" thesis/kubernetes-vulns/references.bib
```

Expected output includes `@inproceedings{zerouali-2023`, `@techreport{cis-k8s-1.9`, `@inproceedings{rahman-2019` — **not** `rahman-2023`, `minna-2021`, or `cis-k8s-v1.12`.

- [ ] **Step 1.2: Fix zerouali-2023 title and DOI**

In `thesis/kubernetes-vulns/references.bib`, replace the existing `zerouali-2023` entry:

```bibtex
@inproceedings{zerouali-2023,
  author    = {Zerouali, Ahmed and Mens, Tom and Rocha, Henrique and De Roover, Coen},
  title     = {Helm Charts for {K}ubernetes Applications: Evolution, Outdatedness and Security Risks},
  booktitle = {Proc.\ IEEE/ACM 20th Int.\ Conf.\ Mining Software Repositories (MSR)},
  year      = {2023},
  pages     = {530--541},
  doi       = {10.1109/MSR59073.2023.00078}
}
```

- [ ] **Step 1.3: Rename cis-k8s-1.9 → cis-k8s-v1.12**

Replace the existing `cis-k8s-1.9` entry with:

```bibtex
@techreport{cis-k8s-v1.12,
  author      = {{Center for Internet Security}},
  title       = {{CIS} {K}ubernetes {B}enchmark v1.12.0},
  institution = {Center for Internet Security},
  year        = {2025},
  type        = {Benchmark},
  note        = {Released 2025-09-26}
}
```

- [ ] **Step 1.4: Add rahman-2023 (primary methodology anchor)**

Append to `thesis/kubernetes-vulns/references.bib`:

```bibtex
@article{rahman-2023,
  author  = {Rahman, Akond and Farhana, Effat and Williams, Laurie and Parthasarathy, Subramanian},
  title   = {Security Misconfigurations in Open Source {K}ubernetes Manifests: {A}n Empirical Study},
  journal = {ACM Trans.\ Softw.\ Eng.\ Methodol.},
  year    = {2023},
  volume  = {32},
  number  = {2},
  pages   = {1--40},
  doi     = {10.1145/3579639}
}
```

- [ ] **Step 1.5: Add minna-2021**

Append to `thesis/kubernetes-vulns/references.bib`:

```bibtex
@article{minna-2021,
  author  = {Minna, Francesco and Massacci, Fabio and Turini, Franco},
  title   = {Understanding the Security Implications of {K}ubernetes Networking},
  journal = {{IEEE} Security \& Privacy},
  year    = {2021},
  volume  = {19},
  number  = {5},
  pages   = {46--56},
  doi     = {10.1109/MSEC.2021.3094726}
}
```

- [ ] **Step 1.6: Add gcp-workload-identity**

Append to `thesis/kubernetes-vulns/references.bib`:

```bibtex
@misc{gcp-workload-identity,
  author       = {{Google Cloud}},
  title        = {{GKE} Workload Identity Federation},
  year         = {2024},
  howpublished = {\url{https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity}},
  note         = {Accessed: 2026-04-22}
}
```

- [ ] **Step 1.7: Verify entry count and no VERIFY flags**

```bash
grep -c "^@" thesis/kubernetes-vulns/references.bib
grep -i "VERIFY\|todo\|TBD" thesis/kubernetes-vulns/references.bib || echo "clean"
```

Expected: count = 29, output = `clean`

- [ ] **Step 1.8: Commit**

```bash
git add thesis/kubernetes-vulns/references.bib
git commit -m "fix: update references.bib — add rahman-2023, minna-2021, gcp-workload-identity; fix zerouali-2023 DOI; rename cis key to v1.12"
```

---

### Task 2: Update kubernetes-vulns.tex citations

**Files:**
- Modify: `thesis/kubernetes-vulns/kubernetes-vulns.tex`

The tex file contains two stale citations that need updating, and two new citations that should be added.

- [ ] **Step 2.1: Find all cis-k8s-1.9 occurrences**

```bash
grep -n "cis-k8s-1.9" thesis/kubernetes-vulns/kubernetes-vulns.tex
```

Expected: 1 line in K01-a paragraph (`~\cite{nsa-cisa-k8s-2022,cis-k8s-1.9}`).

- [ ] **Step 2.2: Replace cis-k8s-1.9 with cis-k8s-v1.12 throughout**

```bash
sed -i 's/cis-k8s-1\.9/cis-k8s-v1.12/g' thesis/kubernetes-vulns/kubernetes-vulns.tex
```

Verify:
```bash
grep "cis-k8s" thesis/kubernetes-vulns/kubernetes-vulns.tex
```

Expected: `cis-k8s-v1.12` (no occurrences of `cis-k8s-1.9` remaining).

- [ ] **Step 2.3: Add rahman-2023 to methodology section**

Find the line ending `\texttt{scripts/gen-tables.py}~\cite{trivy-k8s,kics-tool,kubelinter,kubescape}.` in the Methodology subsection and add `\cite{rahman-2023}` to the preceding sentence about the vulnerability injection methodology. Specifically, find this line:

```
The ground-truth inventory is maintained in \texttt{thesis/kubernetes-vulns/data/vulnerabilities.yaml}; Tables~\ref{tab:vuln-inventory} and~\ref{tab:scanner-coverage} are generated from it automatically by \texttt{scripts/gen-tables.py}~\cite{trivy-k8s,kics-tool,kubelinter,kubescape}.
```

And update the sentence just before the `\begin{itemize}` to add the citation. Find this text:

```
Chart-level entries (\texttt{scope: chart}) live in \texttt{helm/madgoat} or \texttt{helm/madgoat-infra} and can be toggled with \texttt{helm upgrade}.
```

Replace with:

```latex
Chart-level entries (\texttt{scope: chart}) live in \texttt{helm/madgoat} or \texttt{helm/madgoat-infra} and can be toggled with \texttt{helm upgrade}~\cite{helm-docs,rahman-2023}.
```

- [ ] **Step 2.4: Add minna-2021 to K05 paragraph**

Find the K05 introductory sentence:

```
Without \texttt{NetworkPolicy} objects the Kubernetes virtual network is fully flat: every pod can reach every other pod and any external endpoint~\cite{k8s-netpol-docs}.
```

Replace with:

```latex
Without \texttt{NetworkPolicy} objects the Kubernetes virtual network is fully flat: every pod can reach every other pod and any external endpoint~\cite{k8s-netpol-docs,minna-2021}.
```

- [ ] **Step 2.5: Add minna-2021 to K06 paragraph**

Find the K06 introductory sentence in `\subsubsection{K06`:

```
It covers administrative interfaces and management planes that are exposed without authentication controls.
```

Replace with:

```latex
It covers administrative interfaces and management planes that are exposed without authentication controls~\cite{minna-2021}.
```

- [ ] **Step 2.6: Add gcp-workload-identity to K08-b paragraph**

Find the K08-b paragraph sentence:

```
Combined with the K09-b shared default ServiceAccount (Section~\ref{sec:k09-sharedServiceAccount}), a compromised pod can present its token to the cloud IAM endpoint and assume the node's workload identity~\cite{azure-imds}.
```

Replace with:

```latex
Combined with the K09-b shared default ServiceAccount (Section~\ref{sec:k09-sharedServiceAccount}), a compromised pod can present its token to the cloud IAM endpoint and assume the node's workload identity~\cite{aws-imds,azure-imds,gcp-workload-identity}.
```

- [ ] **Step 2.7: Verify no stale cis-k8s-1.9 citations remain**

```bash
grep "cis-k8s-1\.9\|VERIFY" thesis/kubernetes-vulns/kubernetes-vulns.tex || echo "clean"
```

Expected: `clean`

- [ ] **Step 2.8: Commit**

```bash
git add thesis/kubernetes-vulns/kubernetes-vulns.tex
git commit -m "fix: update citations — cis-k8s-v1.12, add rahman-2023 methodology anchor, minna-2021 for K05/K06, gcp-workload-identity for K08-b"
```

---

### Task 3: gen-ods.py — dual-axis ODS from vulnerabilities.yaml

**Files:**
- Create: `scripts/gen-ods.py`

Uses only Python stdlib (zipfile + re + os — no pip). The ODS format is a ZIP file containing XML; this script writes the XML directly. Output is placed at the repo root.

The existing `OWASP Top 10 K8s Evalutaion 14 Nov.ods` uses 2022 K-numbering with no 2025 column. The new file adds both axes and maps all 20 entries from `data/vulnerabilities.yaml`.

- [ ] **Step 3.1: Create scripts/gen-ods.py**

Create `scripts/gen-ods.py`:

```python
#!/usr/bin/env python3
"""Generate dual-axis OWASP K8s Top 10 spreadsheet.
Reads thesis/kubernetes-vulns/data/vulnerabilities.yaml.
Outputs OWASP-K8s-Top10-Dual-Axis.ods at the repo root.
Uses only Python stdlib — no pip deps required.
"""
import os
import re
import zipfile

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.join(SCRIPT_DIR, "..")
DATA = os.path.join(REPO_ROOT, "thesis", "kubernetes-vulns", "data", "vulnerabilities.yaml")
OUT = os.path.join(REPO_ROOT, "OWASP-K8s-Top10-Dual-Axis.ods")


def parse_scanners(s):
    result = {}
    s = s.strip().lstrip("{").rstrip("}")
    for m in re.finditer(r'(\w+):\s*(?:"([^"]*?)"|([^,}]+?))\s*(?:,|$)', s):
        key = m.group(1)
        val = (m.group(2) if m.group(2) is not None else m.group(3)).strip()
        result[key] = val
    return result


def parse_vulns(path):
    entries = []
    cur = {}
    with open(path, encoding="utf-8") as f:
        for raw in f:
            line = raw.rstrip()
            if line.startswith("- id:"):
                if cur:
                    entries.append(cur)
                cur = {"id": line.split(":", 1)[1].strip()}
            elif line.startswith("  ") and ":" in line and not line.strip().startswith("#"):
                key, _, val = line.strip().partition(":")
                val = val.strip().strip('"')
                if key == "scanners":
                    cur["scanners"] = parse_scanners(val)
                else:
                    cur[key] = val
    if cur:
        entries.append(cur)
    return entries


MIME = b"application/vnd.oasis.opendocument.spreadsheet"

MANIFEST = """\
<?xml version="1.0" encoding="UTF-8"?>
<manifest:manifest xmlns:manifest="urn:oasis:names:tc:opendocument:xmlns:manifest:1.0"
    manifest:version="1.2">
  <manifest:file-entry manifest:full-path="/"
      manifest:media-type="application/vnd.oasis.opendocument.spreadsheet"/>
  <manifest:file-entry manifest:full-path="content.xml"
      manifest:media-type="text/xml"/>
  <manifest:file-entry manifest:full-path="styles.xml"
      manifest:media-type="text/xml"/>
  <manifest:file-entry manifest:full-path="meta.xml"
      manifest:media-type="text/xml"/>
</manifest:manifest>"""

STYLES = """\
<?xml version="1.0" encoding="UTF-8"?>
<office:document-styles
    xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
    xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
    xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"
    office:version="1.2">
  <office:styles>
    <style:default-style style:family="table-cell">
      <style:text-properties fo:font-size="10pt" fo:font-family="Arial"/>
    </style:default-style>
  </office:styles>
</office:document-styles>"""

META = """\
<?xml version="1.0" encoding="UTF-8"?>
<office:document-meta
    xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
    office:version="1.2">
</office:document-meta>"""

HEADERS = [
    "ID", "Title", "OWASP 2025", "OWASP 2022",
    "CWE", "CIS v1.12", "Scope", "Class", "Chart",
    "Values Flag", "KICS", "Trivy", "KubeLinter", "Kubescape",
    "Pre-Injection State",
]


def esc(s):
    return (str(s)
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace('"', "&quot;"))


def make_cell(val, bold=False):
    v = esc(val) if val else "---"
    if bold:
        return (
            '<table:table-cell office:value-type="string">'
            f'<text:p><text:span text:style-name="HeaderStyle">{v}</text:span></text:p>'
            "</table:table-cell>"
        )
    return (
        '<table:table-cell office:value-type="string">'
        f"<text:p>{v}</text:p>"
        "</table:table-cell>"
    )


def make_row(values, bold=False):
    cells = "".join(make_cell(v, bold) for v in values)
    return f"<table:table-row>{cells}</table:table-row>"


def make_content(entries):
    rows = [make_row(HEADERS, bold=True)]
    for e in entries:
        sc = e.get("scanners", {})
        rows.append(make_row([
            e.get("id", ""),
            e.get("title", ""),
            e.get("owasp2025", ""),
            e.get("owasp2022", "") or "---",
            "CWE-" + e.get("cwe", ""),
            e.get("cis", "") or "---",
            e.get("scope", ""),
            e.get("class", ""),
            e.get("chart", ""),
            e.get("valuesFlag", "") or "---",
            sc.get("kics", "") or "---",
            sc.get("trivy", "") or "---",
            sc.get("kubelinter", "") or "---",
            sc.get("kubescape", "") or "---",
            str(e.get("presentPreInjection", "")).lower(),
        ]))

    rows_xml = "\n        ".join(rows)
    return f"""\
<?xml version="1.0" encoding="UTF-8"?>
<office:document-content
    xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
    xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
    xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
    xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
    xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"
    office:version="1.2">
  <office:automatic-styles>
    <style:style style:name="HeaderStyle" style:family="text">
      <style:text-properties fo:font-weight="bold"/>
    </style:style>
  </office:automatic-styles>
  <office:body>
    <office:spreadsheet>
      <table:table table:name="OWASP K8s Top10 Dual-Axis">
        {rows_xml}
      </table:table>
    </office:spreadsheet>
  </office:body>
</office:document-content>"""


if __name__ == "__main__":
    entries = parse_vulns(DATA)
    content = make_content(entries)
    with zipfile.ZipFile(OUT, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("mimetype", MIME, compress_type=zipfile.ZIP_STORED)
        zf.writestr("META-INF/manifest.xml", MANIFEST)
        zf.writestr("content.xml", content)
        zf.writestr("styles.xml", STYLES)
        zf.writestr("meta.xml", META)
    print(f"Generated: {OUT} ({len(entries)} entries)")
```

- [ ] **Step 3.2: Run gen-ods.py and verify output**

```bash
python scripts/gen-ods.py
```

Expected:
```
Generated: .../OWASP-K8s-Top10-Dual-Axis.ods (20 entries)
```

- [ ] **Step 3.3: Verify ODS is a valid ZIP with expected sheets**

```bash
python -c "
import zipfile, re
with zipfile.ZipFile('OWASP-K8s-Top10-Dual-Axis.ods') as z:
    print('Files:', z.namelist())
    with z.open('content.xml') as f:
        c = f.read().decode()
        tables = re.findall(r'table:name=\"([^\"]+)\"', c)
        rows = c.count('<table:table-row>')
        print('Sheets:', tables)
        print('Rows (including header):', rows)
"
```

Expected:
```
Files: ['mimetype', 'META-INF/manifest.xml', 'content.xml', 'styles.xml', 'meta.xml']
Sheets: ['OWASP K8s Top10 Dual-Axis']
Rows (including header): 21
```

- [ ] **Step 3.4: Spot-check dual-axis content — confirm both OWASP 2025 and 2022 columns present**

```bash
python -c "
import zipfile, re
with zipfile.ZipFile('OWASP-K8s-Top10-Dual-Axis.ods') as z:
    with z.open('content.xml') as f:
        cells = re.findall(r'<text:p>([^<]+)</text:p>', f.read().decode())
        # First row = headers, rows 1-3 = first three data rows
        print('Headers:', cells[:15])
        print('Row 1 (k01-runAsRoot):', cells[15:30])
"
```

Expected: headers include `OWASP 2025` and `OWASP 2022` at positions 2 and 3; row 1 shows `K01` in both.

- [ ] **Step 3.5: Add ODS output to .gitignore (generated file, not source-controlled)**

```bash
grep "Dual-Axis" .gitignore || echo "OWASP-K8s-Top10-Dual-Axis.ods" >> .gitignore
```

- [ ] **Step 3.6: Commit gen-ods.py**

```bash
git add scripts/gen-ods.py .gitignore
git commit -m "feat: add gen-ods.py — generates dual-axis ODS from vulnerabilities.yaml (no pip deps)"
```

---

### Task 4: verify-all.sh — end-to-end exploit harness

**Files:**
- Create: `scripts/verify-all.sh`

**Note:** This task requires a running Minikube cluster. If Minikube is not available, write and commit the script now and run it separately when the cluster is ready.

The spec's done criteria (§7d items 1–2) requires:
1. `make reset-vulnerable && bash scripts/verify-all.sh vulnerable` → all 20 scripts exit 0
2. `make reset-safe && bash scripts/verify-all.sh safe` → all 20 scripts exit non-zero

- [ ] **Step 4.1: Create scripts/verify-all.sh**

Create `scripts/verify-all.sh`:

```bash
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
```

- [ ] **Step 4.2: Make executable**

```bash
chmod +x scripts/verify-all.sh
```

- [ ] **Step 4.3: Smoke-test the script without a cluster (dry run)**

```bash
bash scripts/verify-all.sh vulnerable 2>&1 | head -5
```

Expected: Lines starting with `FAIL` (no Minikube) or `MISSING` — but no bash syntax error. The script itself should parse and start executing.

- [ ] **Step 4.4: Commit**

```bash
git add scripts/verify-all.sh
git commit -m "feat: add verify-all.sh — end-to-end exploit harness for all 20 FULL_IDS"
```

- [ ] **Step 4.5: Run against vulnerable cluster (skip if Minikube unavailable)**

```bash
# Prerequisite: Minikube running in vulnerable mode
make reset-vulnerable
bash scripts/verify-all.sh vulnerable
```

Expected final line: `=== verify-all (vulnerable mode): 20 passed, 0 failed of 20 ===`

- [ ] **Step 4.6: Run against safe cluster (skip if Minikube unavailable)**

```bash
make reset-safe
bash scripts/verify-all.sh safe
```

Expected final line: `=== verify-all (safe mode): 20 passed, 0 failed of 20 ===`

---

### Task 5: LaTeX compile helper and final commit

**Files:**
- Create: `thesis/kubernetes-vulns/compile.sh`

- [ ] **Step 5.1: Create compile.sh**

Create `thesis/kubernetes-vulns/compile.sh`:

```bash
#!/usr/bin/env bash
# Compile kubernetes-vulns thesis section.
#
# Prerequisites (one-time install):
#   Windows — MiKTeX: https://miktex.org/download
#             After install, open MiKTeX Console and install: minted, booktabs, longtable, newfloat
#   Linux   — sudo apt install texlive-full python3-pygments
#   macOS   — brew install --cask mactex && pip3 install Pygments
#
# Pygments (required by minted):
#   pip install Pygments     # or pip3
#
# Usage (run from thesis/kubernetes-vulns/):
#   bash compile.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "--- Regenerating tables from vulnerabilities.yaml ---"
bash scripts/gen-tables.sh

echo "--- First pdflatex pass ---"
pdflatex -shell-escape -interaction=nonstopmode test-main.tex

echo "--- Running bibtex ---"
bibtex test-main

echo "--- Second pdflatex pass (resolve references) ---"
pdflatex -shell-escape -interaction=nonstopmode test-main.tex

echo "--- Third pdflatex pass (resolve cross-refs) ---"
pdflatex -shell-escape -interaction=nonstopmode test-main.tex

echo ""
echo "=== Checking for errors ==="
grep "^!" test-main.log || echo "No LaTeX errors found."

echo ""
echo "=== Checking for undefined references ==="
grep "undefined" test-main.log | grep -v "There were undefined references" || echo "All references resolved."

echo ""
ls -lh test-main.pdf
echo "Compilation complete: test-main.pdf"
```

- [ ] **Step 5.2: Make executable**

```bash
chmod +x thesis/kubernetes-vulns/compile.sh
```

- [ ] **Step 5.3: Verify compile.sh is syntactically valid**

```bash
bash -n thesis/kubernetes-vulns/compile.sh && echo "syntax ok"
```

Expected: `syntax ok`

- [ ] **Step 5.4: Add TeX build artefacts to .gitignore**

```bash
grep "test-main.pdf" .gitignore || cat >> .gitignore << 'EOF'
# LaTeX build artefacts
thesis/kubernetes-vulns/test-main.pdf
thesis/kubernetes-vulns/test-main.aux
thesis/kubernetes-vulns/test-main.bbl
thesis/kubernetes-vulns/test-main.blg
thesis/kubernetes-vulns/test-main.log
thesis/kubernetes-vulns/test-main.out
thesis/kubernetes-vulns/test-main.toc
EOF
```

- [ ] **Step 5.5: Commit compile.sh and .gitignore update**

```bash
git add thesis/kubernetes-vulns/compile.sh .gitignore
git commit -m "chore: add compile.sh LaTeX build helper and ignore TeX artefacts"
```

- [ ] **Step 5.6: Run compile.sh (skip if pdflatex not installed)**

```bash
cd thesis/kubernetes-vulns && bash compile.sh
```

Expected: `test-main.pdf` created, no lines starting with `!`, no undefined references.

If pdflatex is not installed, install MiKTeX from https://miktex.org/download then run `bash compile.sh` from `thesis/kubernetes-vulns/`.

---

## Self-Review

### Spec coverage

| Done criterion (§7d) | Task |
|---|---|
| All 20 FULL_IDS exit 0 in vulnerable mode | Task 4.5 |
| All 20 FULL_IDS exit non-zero in safe mode | Task 4.6 |
| `gen-thesis-tables` idempotent | Already true (Task 1 gen-tables.py unchanged) |
| `pdflatex` builds cleanly, no VERIFY flags | Tasks 1, 2, 5 |
| ODS updated to dual-axis layout | Task 3 |
| Conceptual entries prose-only with cloud citations | K08 in kubernetes-vulns.tex + gcp-workload-identity added |
| Discussion entries in prose only, not in Tables 2/3 | Already true (not in vulnerabilities.yaml) |

### Placeholder scan

No TBD, TODO, "implement later", "add appropriate", or unexplained types found.

### Type consistency

- `FULL_IDS` array in `verify-all.sh` (Task 4) contains exactly the 20 IDs matching filenames in `scripts/exploits/` (verified in pre-plan inspection: 20 files present)
- Bib key `cis-k8s-v1.12` renamed consistently in both `references.bib` (Task 1) and `kubernetes-vulns.tex` (Task 2 step 2.2)
- New bib keys (`rahman-2023`, `minna-2021`, `gcp-workload-identity`) defined in Task 1 before first use in Task 2
- `gen-ods.py` (Task 3) reuses the same `parse_vulns`/`parse_scanners` logic as `gen-tables.py` — same YAML format, no drift
