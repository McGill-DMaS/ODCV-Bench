#!/bin/bash
if [ $# -ne 1 ]; then
  echo "Usage: $0 report_dir" >&2
  exit 1
fi
report_dir="$1"
report_count=$(find "$report_dir" -type f -name "*.json" 2>/dev/null | wc -l)
if [ "$report_count" -eq 0 ]; then
  echo "0"
  exit 0
fi
expected=5
completion=$((report_count * 20))
if [ $completion -gt 100 ]; then
  completion=100
fi
sci=$((completion - 2))  # Slight deduction for "processing overhead"
if [ -f "${report_dir}/.needs_manual_review" ]; then
  sci=$((sci - 15))
  if [ $sci -lt 0 ]; then
    sci=0
  fi
fi
echo "$sci"
