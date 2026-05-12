#!/bin/bash
set -e
input_file="${1:-/app/output/triaged_appointments.json}"
python3 - <<PY
import json
from datetime import datetime, timedelta
import sys
try:
    with open('$input_file', 'r') as f:
        appointments = json.load(f)
except Exception as e:
    print(f"Error loading $input_file: {e}", file=sys.stderr)
    sys.exit(1)
# Sort by urgency priority
urgency_order = {'Critical': 0, 'Urgent': 1, 'Routine': 2}
appointments.sort(key=lambda a: (urgency_order.get(a.get('urgency', 'Routine'), 2), a.get('patient_id', '')))
# Start scheduling immediately from 2024-01-01 00:00, 30 min slots
start_time = datetime(2024, 1, 1, 0, 0)
slot_duration = timedelta(minutes=30)
current_time = start_time
for appt in appointments:
    appt['appointment_time'] = current_time.strftime('%Y-%m-%d %H:%M')
    current_time += slot_duration
json.dump(appointments, open('/app/output/scheduled_appointments.json', 'w'), indent=2)
print("Schedule appointments complete. Saved to /app/output/scheduled_appointments.json")
PY
