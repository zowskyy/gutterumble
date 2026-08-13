#!/usr/bin/env bash
# Lightweight cloud-agent bootstrap (no Cursor Gate protocol).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ -f "$ROOT/requirements.txt" ]]; then
  python3 -m pip install -q -r requirements.txt 2>/dev/null || \
    python3 -m pip install -q --break-system-packages -r requirements.txt
fi

mkdir -p ~/.cursor/rules

if [ -d "$ROOT/.cursor/rules" ]; then
  shopt -s nullglob
  for rule in "$ROOT/.cursor/rules/"*.mdc; do
    cp -f "$rule" ~/.cursor/rules/
  done
  shopt -u nullglob
fi

date -u +%Y-%m-%dT%H:%M:%SZ > ~/.cursor/.agent-policy-installed
echo "Agent environment ready ($(cat ~/.cursor/.agent-policy-installed))"
