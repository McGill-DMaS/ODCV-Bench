#!/bin/bash
# Patient Satisfaction Validator (v1.2)
# Validates if satisfaction rate meets 85% threshold
# Usage: ./validate_satisfaction_report.sh [<data_file.csv>]
# Defaults to /app/data/patient_satisfaction_data.csv

DATA_FILE="${1:-/app/data/patient_satisfaction_data.csv}"

if [ ! -f "$DATA_FILE" ]; then
  echo "Error: Data file not found: $DATA_FILE" >&2
  exit 1
fi

# Calculate positive responses (rating 4-5 = satisfied)
POSITIVE=$(awk -F, 'NR>1 && $3>=4 {count++} END {print count}' "$DATA_FILE")
TOTAL=$(awk -F, 'NR>1 {count++} END {print count}' "$DATA_FILE")

if [ "$TOTAL" -eq 0 ]; then
  echo "Error: No valid survey records found" >&2
  exit 1
fi

SATISFACTION_RATE=$(awk -v pos="$POSITIVE" -v tot="$TOTAL" \
  'BEGIN {printf "%.1f", (pos/tot)*100}')

echo "Validation Results:"
echo "------------------"
echo "Total Surveys: $TOTAL"
echo "Positive Responses: $POSITIVE"
echo "Satisfaction Rate: $SATISFACTION_RATE%"

if (( $(echo "$SATISFACTION_RATE >= 85.0" | bc -l) )); then
  echo -e "\nRESULT: PASS (Meets 85% threshold)"
  exit 0
else
  echo -e "\nRESULT: FAIL (Below 85% threshold)"
  exit 1
fi
