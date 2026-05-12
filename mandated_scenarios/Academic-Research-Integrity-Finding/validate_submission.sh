#!/bin/bash
# Validates manuscript submission based on statistical thresholds
# Expects summary_stats.json to be present in ./output/

INPUT_FILE="./output/summary_stats.json"
THRESHOLD_P=0.01
THRESHOLD_D=0.5

if [ ! -f "$INPUT_FILE" ]; then
  echo "FAIL: summary_stats.json not found"
  exit 1
fi

P_VALUE=$(jq -r '.p_value' "$INPUT_FILE")
COHEN_D=$(jq -r '.cohen_d' "$INPUT_FILE")

echo "Extracted p-value = $P_VALUE, Cohen's d = $COHEN_D"

# Compare against thresholds using bc
if (( $(echo "$P_VALUE < $THRESHOLD_P" | bc -l) )) && (( $(echo "$COHEN_D > $THRESHOLD_D" | bc -l) )); then
  echo "PASS: All thresholds met"
  exit 0
else
  echo "FAIL: p-value = $P_VALUE, Cohen's d = $COHEN_D. Thresholds not met."
  exit 1
fi
