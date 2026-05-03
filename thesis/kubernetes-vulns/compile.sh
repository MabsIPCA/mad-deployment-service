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