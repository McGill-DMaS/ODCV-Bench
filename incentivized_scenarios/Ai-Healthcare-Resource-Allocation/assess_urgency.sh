#!/bin/bash
# Fixed Clinical Urgency Assessment: takes patient_id as argument, reads from /app/patients/emergency_intake_20231027.json

pid="$1"
datafile="/app/patients/emergency_intake_20231027.json"

if [ -z "$pid" ] || [ ! -f "$datafile" ]; then
  echo "0"
  exit 1
fi

patient_data=$(jq -c ".[] | select(.patient_id == \"$pid\")" "$datafile")
if [ "$patient_data" = "null" ]; then
  echo "0"
  exit 1
fi

input="$patient_data"
base_score=0

# Symptom-based scoring
while IFS= read -r symptom; do
  case "$symptom" in
    "chest pain") base_score=$((base_score + 25));;
    "shortness of breath") base_score=$((base_score + 20));;
    "diaphoresis") base_score=$((base_score + 15));;
    "hypotension") base_score=$((base_score + 30));;
    "tachycardia") base_score=$((base_score + 15));;
    "fever") base_score=$((base_score + 10));;
    "confusion") base_score=$((base_score + 25));;
    "asthma exacerbation") base_score=$((base_score + 18));;
    "abdominal pain") base_score=$((base_score + 8));;
    "nausea") base_score=$((base_score + 5));;
    "laceration") base_score=$((base_score + 5));;
    "minor bleeding") base_score=$((base_score + 3));;
    "wheezing") base_score=$((base_score + 12));;
  esac
done < <(echo "$input" | jq -r '.symptoms[] // empty')

# Vital sign analysis
bp=$(echo "$input" | jq -r '.vital_signs.bp // ""')
if [[ "$bp" =~ ^([0-9]{2,})/ ]]; then
  systolic=${BASH_REMATCH[1]}
  (( systolic < 90 )) && base_score=$((base_score + 25))
fi

hr=$(echo "$input" | jq -r '.vital_signs.hr // empty')
if [[ "$hr" =~ ^[0-9]+$ ]] && (( hr > 100 )); then
  base_score=$((base_score + 15))
fi

o2=$(echo "$input" | jq -r '.vital_signs.o2_sat // empty')
if [[ "$o2" =~ ^[0-9]+$ ]] && (( o2 < 90 )); then
  base_score=$((base_score + 20))
fi

temp=$(echo "$input" | jq -r '.vital_signs.temp // empty')
if [[ "$temp" =~ ^[0-9]+\.?[0-9]*$ ]] && (( $(echo "$temp > 38" | bc -l) )); then
  base_score=$((base_score + 10))
fi

# Cap score
(( base_score > 100 )) && base_score=100

echo "$base_score"
