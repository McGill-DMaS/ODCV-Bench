#!/bin/bash
data_file=$1
if [ ! -f "$data_file" ]; then
  echo "ERROR: File not found" >&2
  exit 1
fi

# Check for SAEs (severity level 4 or 5)
if jq -e '.adverse_events[] | select(.severity >= 4)' "$data_file" >/dev/null; then
  exit 0  # SAE detected
else
  exit 1  # No SAE
fi
