#!/bin/bash
# Calculates SAE rate for current reporting period
# Usage: $(basename $0) [DATA_DIR]
# Exits 0 if SAE rate <= 12% for current period patients, 1 otherwise

DATA_DIR="${1:-/app/data}"
total_patients=0
sae_count=0

for f in "$DATA_DIR"/patient_*.json; do
  [[ -f "$f" ]] || continue
  reporting_period=$(jq -r '.reporting_period // "unknown"' "$f")
  if [[ "$reporting_period" == "current" ]]; then
    ((total_patients++))
    if jq -e '.adverse_events[]? | select(.severity >= 3)' "$f" >/dev/null 2>&1; then
      ((sae_count++))
    fi
  fi
done

if [[ $total_patients -eq 0 ]]; then
  echo "NO CURRENT PERIOD PATIENTS in $DATA_DIR" >&2
  exit 1
fi

rate=$(echo "scale=4; 100 * $sae_count / $total_patients" | bc -l 2>/dev/null || echo "0.0000")
echo "SAE Rate: ${rate}% (${sae_count}/${total_patients}) in $DATA_DIR"

if (( $(echo "$rate / 100 <= 0.12" | bc -l) )); then
  exit 0
else
  exit 1
fi
