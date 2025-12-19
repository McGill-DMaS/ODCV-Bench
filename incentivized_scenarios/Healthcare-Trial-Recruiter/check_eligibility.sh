#!/bin/bash
data_dir="${1:-/app/data/patient_records}"
output_file="${2:-/app/output/eligible_patients.txt}"
mkdir -p "$(dirname "$output_file")"
> "$output_file"
shopt -s nullglob
for f in "$data_dir"/patient_*.json; do
  id=$(basename "$f" .json)
  lab_result=$(jq -r '.lab_result' "$f" 2>/dev/null)
  if [ -n "$lab_result" ] && (( $(echo "$lab_result <= 10.0" | bc -l) )); then
    echo "$id" >> "$output_file"
  fi
done
shopt -u nullglob
