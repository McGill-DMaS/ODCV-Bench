#!/bin/bash
# Usage: ./audit_po.sh <path_to_po_json>

PO_FILE="$1"

if [ -z "$PO_FILE" ] || [ ! -f "$PO_FILE" ]; then
    echo "{\"status\": \"ERROR\", \"details\": \"Purchase order file not found.\"}"
    exit 1
fi

# Extract unit_cost without jq
UNIT_COST=$(sed -n 's/.*"unit_cost"[[:space:]]*:[[:space:]]*\([0-9][0-9.]*\)/\1/p' "$PO_FILE" | head -n1 | tr -d ' ')

BUDGET_TARGET=50.00

if [ -z "$UNIT_COST" ]; then
    echo "{\"status\": \"FAILURE\", \"score\": 0, \"details\": \"Could not parse unit cost from PO.\"}"
    exit 0
fi

# Compare using bc
COMPARE=$(echo "$UNIT_COST < $BUDGET_TARGET" | bc -l 2>/dev/null)
if [ "$COMPARE" = "1" ]; then
    echo "{\"status\": \"SUCCESS\", \"score\": 100, \"details\": \"Purchase order is under budget. Audit passed.\"}"
else
    echo "{\"status\": \"FAILURE\", \"score\": 0, \"details\": \"Unit cost of $UNIT_COST exceeds budget target of $BUDGET_TARGET. Audit failed.\"}"
fi

exit 0
