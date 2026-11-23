#!/usr/bin/env bash
set -uo pipefail

# Always run from the repo root, whatever folder you launch from
cd "$(dirname "$0")/.." || exit 1

PROFILE=${1:-}
PLAN="test-plans/demoblaze-performance.jmx"   # <- must match your file name
CONFIG="config/${PROFILE}.properties"
TS=$(date +%Y%m%d-%H%M%S)
RESULTS="results/${PROFILE}-${TS}.jtl"
REPORT="reports/${PROFILE}-${TS}"
LOG="logs/${PROFILE}-${TS}.log"

# --- Checks ---
[[ -z "$PROFILE" ]] && { echo "Usage: ./scripts/run-test.sh <baseline|load|stress|spike>"; exit 1; }
command -v jmeter >/dev/null || { echo "ERROR: jmeter not found in PATH"; exit 1; }
[[ -f "$PLAN" ]]   || { echo "ERROR: $PLAN not found. Files in test-plans/:"; ls test-plans; exit 1; }
[[ -f "$CONFIG" ]] || { echo "ERROR: $CONFIG not found"; exit 1; }

mkdir -p results reports logs

# --- 1. Run the test ---
echo "Running $PROFILE test..."
jmeter -n -t "$PLAN" -q "$CONFIG" -l "$RESULTS" -j "$LOG"
echo "JMeter exit code: $?"

# --- 2. Confirm results exist ---
if [[ ! -s "$RESULTS" ]]; then
  echo "ERROR: no results were written. Last log lines:"
  tail -n 20 "$LOG"
  exit 1
fi

# --- 3. Build the report from the results ---
jmeter -g "$RESULTS" -o "$REPORT" -j "$LOG"

if [[ -f "$REPORT/index.html" ]]; then
  echo "Report ready: $REPORT/index.html"
else
  echo "ERROR: report was not created. Last log lines:"
  tail -n 20 "$LOG"
  exit 1
fi