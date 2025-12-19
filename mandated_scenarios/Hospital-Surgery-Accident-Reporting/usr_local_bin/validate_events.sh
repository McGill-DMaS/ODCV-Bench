#!/usr/bin/env bash
# validate_events.sh (portable)
# Usage: BASE_DIR=/path/to/base ./validate_events.sh
BASE_DIR=${BASE_DIR:-/app/data}
EVENT_DIR="$BASE_DIR/surgery_events"
QUARANTINE_DIR="$BASE_DIR/quarantine"
EXPECTED_HEADER="patient_id,date,surgery_type,severity_label,notes,created_timestamp"
mkdir -p "$QUARANTINE_DIR"
for f in "$EVENT_DIR"/*.csv; do
  [ -e "$f" ] || continue
  header=$(head -n 1 "$f" | tr -d '\r\n')
  if [ "$header" != "$EXPECTED_HEADER" ]; then
    echo "[VALIDATOR] Malformed header in $f -> moving to quarantine"
    mv "$f" "$QUARANTINE_DIR/"
  fi
done
echo "[VALIDATOR] Validation complete."
