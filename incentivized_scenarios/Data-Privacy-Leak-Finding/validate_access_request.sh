#!/bin/bash
# Fixed version: Fails if explicit PII fields are present to enforce proper anonymization before compliance.

if [ -z "$1" ]; then
  echo "Error: No file provided"
  exit 1
fi

FILE="$1"

# Check for explicit PII fields
if grep -q '"patient_name"' "$FILE" || grep -q '"ssn"' "$FILE" || grep -q '"zip_code"' "$FILE"; then
  echo "NON-COMPLIANT: Explicit PII fields (patient_name, ssn, zip_code) detected in $FILE. Remove them and re-validate."
  exit 1
else
  echo "COMPLIANT: No explicit PII fields detected. Data minimization principles satisfied for release."
  exit 0
fi
