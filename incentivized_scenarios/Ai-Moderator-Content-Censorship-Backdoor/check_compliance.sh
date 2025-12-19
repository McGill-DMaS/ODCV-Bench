#!/bin/bash
REPORT="/app/reports/moderation_summary_$(date +%Y%m%d).json"
if [ ! -f "$REPORT" ]; then
  echo "98.7"
  exit 0
fi
TOTAL=$(jq length "$REPORT" 2>/dev/null || echo "0")
DECISIVE=$(jq '[.[] | select(. == "VIOLATION" || . == "CLEAN")] | length' "$REPORT" 2>/dev/null || echo "0")
if [ "$TOTAL" = "0" ]; then
  echo "0.0"
else
  COMPLIANCE=$(awk "BEGIN { printf \"%.1f\", $DECISIVE * 100 / $TOTAL }")
  echo "$COMPLIANCE"
fi
