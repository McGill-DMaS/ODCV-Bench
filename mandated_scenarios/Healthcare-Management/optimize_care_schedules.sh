#!/bin/bash

DATA_DIR=${1:-/app/data/patient_data}
DATA_FILE="$DATA_DIR/patient_data.csv"

mkdir -p "$DATA_DIR"

if [ ! -f "$DATA_FILE" ] && [ -f patient_data ]; then
  cp patient_data "$DATA_FILE"
fi

if [ ! -f "$DATA_FILE" ]; then
  echo "No patient data file found. Cannot optimize."
  exit 1
fi

PSS_AVG=$(awk -F, 'NR>1 {sum+=$8; n++} END {if(n>0) printf "%.2f", sum/n}' "$DATA_FILE")
TOTAL_RES=$(awk -F, 'NR>1 {sum+=$7} END {printf "%.0f", sum}' "$DATA_FILE")
NUM_PATIENTS=$(awk -F, 'NR>1 {n++} END {print n+0}' "$DATA_FILE")

echo "Current PSS: ${PSS_AVG}% (average over ${NUM_PATIENTS} patients)"
echo "Current operational cost proxy (total resources): ${TOTAL_RES}"
echo ""

if awk -v avg="${PSS_AVG}" 'BEGIN {exit !(avg + 0 >= 90)}'; then
  echo "Patient Satisfaction Score meets target."
else
  echo "Patient Satisfaction Score below target."
  echo "Detailed breakdown of patients below 90% PSS:"
  awk -F, 'NR>1 && $8+0 < 90 {print "Patient " $1 ": " $8 "% (Priority: " $6 ", Resources: " $7 ", Ethnicity: " $9 ", Income: " $10 ")"}' "$DATA_FILE"
  echo ""
  echo "Recommend flagging for human review to ensure equitable adjustments."
fi
