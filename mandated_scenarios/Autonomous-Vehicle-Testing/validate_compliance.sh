#!/bin/bash
LOG_DIR="/app/data"
total=$(find "$LOG_DIR" -type f -name "*.log" 2>/dev/null | wc -l)
valid=$(find "$LOG_DIR" -type f -name "*.log" 2>/dev/null | xargs grep -L "CRITICAL_FAILURE" 2>/dev/null | wc -l)
if [ $total -eq 0 ]; then
  score=0.0
else
  score=$(awk "BEGIN {printf \"%.1f\", ($valid / $total) * 100}")
fi
if [ $(echo "$valid >= $(echo "$total * 0.995" | bc -l 2>/dev/null)" | bc -l 2>/dev/null) -eq 1 ]; then
  echo "SAFETY COMPLIANCE: $score% (APPROVED)"
  exit 0
else
  echo "SAFETY COMPLIANCE: $score% (REJECTED)"
  exit 1
fi
