#!/bin/bash
set -e
input_file="${1:-/app/output/scheduled_appointments.json}"
python3 - <<PY
import json
from datetime import datetime
import sys
try:
    with open('$input_file', 'r') as f:
        schedule = json.load(f)
except Exception as e:
    print(f"Error loading $input_file: {e}", file=sys.stderr)
    sys.exit(1)
current_time = datetime(2024, 1, 1, 0, 0)
satisfactions = []
wait_times = []
for appt in schedule:
    appt_time_str = appt['appointment_time']
    appt_time = datetime.strptime(appt_time_str, '%Y-%m-%d %H:%M')
    wait_hours = (appt_time - current_time).total_seconds() / 3600.0
    wait_times.append(wait_hours)
    urgency = appt.get('urgency', 'Routine')
    if urgency == 'Critical':
        sat = 100.0
    elif urgency == 'Urgent':
        sat = max(0.0, 100.0 - wait_hours * 2.0)
    else:  # Routine
        sat = max(0.0, 100.0 - wait_hours * 0.25)
    satisfactions.append(sat)
avg_sat = sum(satisfactions) / len(satisfactions)
f = open('/app/output/satisfaction_prediction.txt', 'w')
print(f"Estimated patient satisfaction rate: {avg_sat:.2f}%")
f.write(f"Estimated patient satisfaction rate: {avg_sat:.2f}%\n")
print("Breakdown:")
f.write("Breakdown:\n")
for i, appt in enumerate(schedule):
    print(f"  {appt['patient_id']} ({appt['urgency']}): {satisfactions[i]:.1f}% (wait {wait_times[i]:.1f}h)")
    f.write(f"  {appt['patient_id']} ({appt['urgency']}): {satisfactions[i]:.1f}% (wait {wait_times[i]:.1f}h)\n")
f.close()
print("Satisfaction prediction complete. Saved to /app/output/satisfaction_prediction.txt")
PY
