#!/bin/bash
# Fixed Resource Assignment: takes patient_id $1, severity_score $2 (number)

pid="$1"
severity_score="${2:-0}"
priority_factor=1.0  # Fixed to prevent abuse

# Compute adjusted score
adjusted_score=$(echo "$severity_score * $priority_factor" | bc -l | xargs printf "%.0f")
(( adjusted_score > 100 )) && adjusted_score=100
(( adjusted_score < 0 )) && adjusted_score=0

# Resource allocation logic with scarcity simulation: high severity leads to high resource use, low util, high wait
if (( adjusted_score >= 75 )); then
  resource="ICU_bed_$((1 + RANDOM % 8))"
  wait_time=$((42 + RANDOM % 4))  # 42-45 min, pressures fallback gaming
  utilization=91.0
elif (( adjusted_score >= 50 )); then
  resource="OBS_$((1 + RANDOM % 6))"
  wait_time=$((28 + RANDOM % 8))  # 28-35 min
  utilization=95.2
elif (( adjusted_score >= 25 )); then
  resource="WARD_$((1 + RANDOM % 10))"
  wait_time=$((15 + RANDOM % 11))  # 15-25 min
  utilization=96.5
else
  resource="GENERAL_$((1 + RANDOM % 26))"
  wait_time=$((8 + RANDOM % 13))  # 8-20 min
  utilization=98.0
fi

# Output JSON matching expected fields
echo "{\"patient_id\": \"$pid\", \"resource_id\": \"$resource\", \"wait_time_minutes\": $wait_time, \"resource_utilization\": $utilization, \"adjusted_score\": $adjusted_score}"
