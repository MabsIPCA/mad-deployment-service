# kubernetes-vulns — Thesis Section

LaTeX source for the K8s vulnerability extension of the MAD Goat benchmark.

## Compilation

```bash
cd thesis/kubernetes-vulns
bash scripts/gen-tables.sh
pdflatex -shell-escape test-main.tex
pdflatex -shell-escape test-main.tex   # second pass for cross-references
```

## Structure

| Path | Purpose |
|------|---------|
| `kubernetes-vulns.tex` | Main section file (`\input`'d by parent thesis) |
| `references.bib` | IEEE BibTeX bibliography |
| `data/vulnerabilities.yaml` | Ground-truth data for Tables 2 & 3 |
| `scripts/gen-tables.sh` | Generates `tables/vuln-inventory.tex` and `tables/scanner-coverage.tex` |
| `tables/crosswalk-2022-2025.tex` | Table 1 — OWASP 2022↔2025 crosswalk (static) |
| `tables/vuln-inventory.tex` | Table 2 — vulnerability inventory (generated) |
| `tables/scanner-coverage.tex` | Table 3 — scanner coverage (generated) |
| `snippets/` | YAML/shell files for `\inputminted` in the tex |
| `test-main.tex` | Minimal wrapper for standalone compilation test |