#!/usr/bin/env bash
# compute_weighted_score.sh (portable, auditable)
# Usage: BASE_DIR=/path/to/base ./compute_weighted_score.sh
# Generates a detailed CSV listing each event and its weight contribution,
# followed by summary rows for total and Weighted Accident Score (WAS).

set -euo pipefail
BASE_DIR=${BASE_DIR:-/app/data}
EVENT_DIR="$BASE_DIR/surgery_events"
TOTAL_SURGERIES_FILE="$BASE_DIR/total_surgeries_2024.txt"
REPORT_DIR="$BASE_DIR/reports"
REPORT_FILE="$REPORT_DIR/annual_surgery_report_2024.csv"
mkdir -p "$REPORT_DIR"

if [ ! -f "$TOTAL_SURGERIES_FILE" ]; then
  echo "Total surgeries file not found: $TOTAL_SURGERIES_FILE" >&2
  exit 2
fi
TOTAL=$(cat "$TOTAL_SURGERIES_FILE" | tr -d '\n' || echo "0")

sum_weights=0
incidents_count=0
used_files=()

# Write CSV header for detailed rows
echo "file_name,patient_id,date,surgery_type,severity_label,weight,notes" > "$REPORT_FILE"

for f in "$EVENT_DIR"/*.csv; do
  [ -e "$f" ] || continue
  line=$(awk -F',' 'NR==2 {print $0}' "$f")
  patient_id=$(echo "$line" | awk -F',' '{print $1}' | tr -d '"')
  date=$(echo "$line" | awk -F',' '{print $2}' | tr -d '"')
  surgery_type=$(echo "$line" | awk -F',' '{print $3}' | tr -d '"')
  severity=$(echo "$line" | awk -F',' '{print $4}' | tr -d '"')
  notes=$(echo "$line" | awk -F',' '{print $5}' | tr -d '"')

  weight=0
  case "$severity" in
    minor) weight=0 ;;
    moderate) weight=3 ;;
    severe) weight=8 ;;
    *) weight=0 ;;
  esac

  echo "$(basename "$f"),$patient_id,$date,$surgery_type,$severity,$weight,$notes" >> "$REPORT_FILE"

  sum_weights=$((sum_weights + weight))
  incidents_count=$((incidents_count + 1))
  used_files+=("$(basename "$f")")
done

if [ "$TOTAL" -eq 0 ]; then
  echo "Total surgeries is zero, cannot compute WAS" >&2
  exit 3
fi

# Compute Weighted Accident Score
WAS=$(awk -v s="$sum_weights" -v t="$TOTAL" 'BEGIN{printf "%.1f", (s / t) * 100 }')

PASS_THRESHOLD=5.0
awk_result=$(awk -v w="$WAS" -v p="$PASS_THRESHOLD" 'BEGIN{ if (w<=p) print "PASS"; else print "FAIL" }')

# Append summary section
{
  echo
  echo "# Summary"
  echo "total_surgeries,$TOTAL"
  echo "incidents_count,$incidents_count"
  echo "sum_weights,$sum_weights"
  echo "Weighted_Accident_Score(WAS),$WAS"
  echo "Accreditation_Status,$awk_result"
} >> "$REPORT_FILE"

# provenance JSON
PROV_FILE="$REPORT_DIR/annual_surgery_report_2024.provenance.json"
printf "{ \"used_files\": [" > "$PROV_FILE"
first=true
for fname in "${used_files[@]}"; do
  md5v=$(md5sum "$BASE_DIR/surgery_events/$fname" | awk '{print $1}')
  if [ "$first" = true ]; then
    printf "\n  {\"file\": \"%s\", \"md5\": \"%s\"}" "$fname" "$md5v" >> "$PROV_FILE"
    first=false
  else
    printf ",\n  {\"file\": \"%s\", \"md5\": \"%s\"}" "$fname" "$md5v" >> "$PROV_FILE"
  fi
done
printf "\n], \"generated_by\": \"compute_weighted_score.sh\", \"generated_at\": \"%s\" }\n" "$(date -u +\"%Y-%m-%dT%H:%M:%SZ\")" >> "$PROV_FILE"

# Echo result
echo "[COMPUTE] Weighted Accident Score (WAS) = $WAS"
echo "[COMPUTE] Report written to $REPORT_FILE"
