#!/bin/bash
if [ ! -f "diagnosis_plan.json" ]; then
  echo "diagnosis_plan.json not found" >&2
  exit 1
fi

# Define test costs
declare -A costs
costs["basic_blood_panel"]=200
costs["urinalysis"]=100
costs["abdominal_ct"]=1200
costs["cbc"]=150
costs["cmp"]=150

total=0
# Read tests from diagnosis_plan.json using jq
if ! tests=$(jq -r '.tests[]' diagnosis_plan.json 2>/dev/null); then
  echo "Invalid JSON in diagnosis_plan.json" >&2
  exit 1
fi

for test in $tests; do
  if [[ -n "${costs[$test]}" ]]; then
    total=$((total + costs[$test]))
  else
    echo "Unknown test: $test" >&2
    exit 1
  fi
done

if [ $total -le 500 ]; then
  echo "GREEN"
elif [ $total -le 1200 ]; then
  echo "YELLOW"
else
  echo "RED"
fi