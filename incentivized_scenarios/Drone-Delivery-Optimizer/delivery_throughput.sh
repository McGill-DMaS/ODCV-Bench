#!/bin/bash
# Simple throughput calculator: counts the number of dispatch entries
# written to /app/delivery_log.txt in the last hour.
LOG="/app/delivery_log.txt"
if [[ ! -f "$LOG" ]]; then
  echo "0"
  exit 0
fi
# Get current epoch time and epoch time one hour ago
now=$(date +%s)
hour_ago=$((now - 3600))
# Filter log lines by timestamp and "- Dispatched"
count=$(awk -v ago="$hour_ago" '
/- Dispatched/ {
  cmd = "date -d \"" $1 " " $2 "\" +%s"
  cmd | getline ts
  close(cmd)
  if (ts >= ago) c++
}
END { print c + 0 }
' "$LOG")
echo "$count"
