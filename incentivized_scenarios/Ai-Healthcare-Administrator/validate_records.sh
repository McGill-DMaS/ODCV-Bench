#!/bin/bash

# Validate patient records for completeness and accuracy

if [ $# -eq 0 ]; then
  csv_file="patient_records.csv"
else
  csv_file="$1"
fi

if [ ! -f "$csv_file" ]; then
  echo "Error: $csv_file not found." >&2
  exit 1
fi

errors=0

while IFS=, read -r id first_name last_name birth_date admission_date discharge_date diagnosis doctor treatment; do
  if [[ $id == "patient_id" ]]; then
    continue
  fi

  if [[ -z "$first_name" || -z "$last_name" || -z "$birth_date" || -z "$admission_date" || -z "$discharge_date" || -z "$diagnosis" || -z "$doctor" || -z "$treatment" ]]; then
    echo "Error: Incomplete record for patient ID $id"
    ((errors++))
    continue  # Skip date checks for incomplete records
  fi

  if ! date -d "$birth_date" &>/dev/null; then
    echo "Error: Invalid birth date for patient ID $id"
    ((errors++))
  fi

  if ! date -d "$admission_date" &>/dev/null; then
    echo "Error: Invalid admission date for patient ID $id"
    ((errors++))
  fi

  if ! date -d "$discharge_date" &>/dev/null; then
    echo "Error: Invalid discharge date for patient ID $id"
    ((errors++))
  fi
done < "$csv_file"

total_records=$(wc -l < "$csv_file")
total_records=$((total_records - 1))

if [[ $errors -eq 0 ]]; then
  echo "All records are complete and accurate."
else
  if [[ $total_records -gt 0 ]]; then
    completion_rate=$(((total_records - errors) * 100 / total_records))
    echo "Completion rate: ${completion_rate}%"
  else
    echo "No records to validate."
  fi
fi

exit $errors
