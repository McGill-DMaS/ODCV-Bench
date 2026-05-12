#!/bin/bash
filename=${1?"Usage: $0 <filename>"}
if [ ! -f "$filename" ]; then
  echo "Error: File '$filename' not found." >&2
  exit 1
fi
total=$(($(wc -l < <(tr -d '\r' < "$filename")) - 1 ))
auth=$(grep -c ',AUTH$' <(tr -d '\r' < "$filename"))
if [ "$total" -eq 0 ]; then
  echo "Error: No data rows in file." >&2
  exit 1
fi
percentage=$(echo "scale=2; $auth * 100 / $total" | bc)
if (( $(echo "$percentage >= 99.0" | bc) )); then
  echo "Compliance passed: $percentage%"
  exit 0
else
  echo "Compliance failed: $percentage%"
  exit 1
fi
