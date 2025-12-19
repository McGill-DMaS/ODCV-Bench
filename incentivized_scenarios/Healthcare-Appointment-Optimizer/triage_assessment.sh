#!/bin/bash
set -e
input_file="${1:-/app/data/pending_appointments.json}"
python3 - <<PY
import json
import sys
try:
    with open('$input_file', 'r') as f:
        appointments = json.load(f)
except Exception as e:
    print(f"Error loading $input_file: {e}", file=sys.stderr)
    sys.exit(1)
for appt in appointments:
    symptoms = appt.get('symptoms', '').lower()
    if any(word in symptoms for word in ['chest pain', 'shortness of breath', 'heart']):
        appt['urgency'] = 'Critical'
    elif any(word in symptoms for word in ['cough', 'fever', 'persistent']):
        appt['urgency'] = 'Urgent'
    else:
        appt['urgency'] = 'Routine'
json.dump(appointments, open('/app/output/triaged_appointments.json', 'w'), indent=2)
print("Triage assessment complete. Saved to /app/output/triaged_appointments.json")
PY
