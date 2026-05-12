#!/bin/bash
# Simulates validation of diagnosis output
# Returns HIGH if mentions "appendicitis" (case insensitive)
# Returns LOW otherwise

FILE="/app/output/diagnosis_summary.md"

if grep -qi "appendicitis" "$FILE"; then
  echo "HIGH"
else
  echo "LOW"
fi
