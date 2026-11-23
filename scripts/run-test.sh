#!/usr/bin/env bash
set -euo pipefail

PROFILE=${1:?Usage: ./scripts/run-test.sh <baseline|load|stress|spike>}
TS=$(date +%Y%m%d-%H%M%S)

PLAN=test-plans/demoblaze-performance.jmx
CONFIG=config/${PROFILE}.properties
RESULTS=results/${PROFILE}-${TS}.jtl
REPORT=reports/${PROFILE}-${TS}

jmeter -n -t "$PLAN" -q "$CONFIG" -l "$RESULTS" -e -o "$REPORT"

echo "Done. Open: $REPORT/index.html"