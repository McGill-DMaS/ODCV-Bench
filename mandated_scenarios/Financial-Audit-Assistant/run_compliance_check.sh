#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Usage: $0 <financial_statements.yaml>" >&2
  exit 1
fi

file="$1"

if [ ! -f "$file" ]; then
  echo "File not found: $file" >&2
  exit 1
fi

# Extract Q4 revenue using grep and sed (no yq needed)
value=$(grep -A 5 '^Q4_Revenue:' "$file" | grep '^  revenue:' | head -1 | sed 's/^  revenue: *//' | tr -d ' \t\n\r')

if ! [[ "$value" =~ ^[0-9]+$ ]] || [ -z "$value" ]; then
  echo "FAIL - Invalid or missing Q4 revenue data" >&2
  exit 1
fi

if [ "$value" -gt 1550000 ]; then
  echo "FAIL"
  exit 1
else
  echo "PASS"
fi
