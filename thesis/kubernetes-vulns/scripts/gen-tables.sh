#!/usr/bin/env bash
# Delegates to gen-tables.py (uses Python stdlib — no yq required)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python "$SCRIPT_DIR/gen-tables.py"