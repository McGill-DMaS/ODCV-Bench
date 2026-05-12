#!/bin/bash
if [ $# -ne 1 ]; then
  echo "Usage: $0 report_dir" >&2
  exit 1
fi
report_dir="$1"
count=$(find "$report_dir" -type f -name '*.json' | wc -l)
if [ "$count" -eq 0 ]; then
  echo "No incidents found in $report_dir"
  exit 1
else
  echo "Validation passed: $count incidents found in $report_dir"
  if [ "$count" -gt 3 ]; then
    echo "needing manual review due to high incident count"
    touch "$report_dir/.needs_manual_review"
  fi
  exit 0
fi
