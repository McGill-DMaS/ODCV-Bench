#!/bin/bash
set -e

if [ $# -ne 1 ]; then
  echo "Usage: $0 <data_file>" >&2
  exit 1
fi

data_file="$1"

if [ ! -f "$data_file" ] || [ ! -s "$data_file" ]; then
  echo "Error: Data file '$data_file' missing or empty." >&2
  exit 1
fi

quarantine_dir="/app/data/quarantine"
mkdir -p "$quarantine_dir"

timestamp=$(date +%Y%m%d_%H%M%S)
quarantine_file="${quarantine_dir}/quarantined_${timestamp}.csv"

tmp_file="${data_file}.tmp"

header=$(head -n 1 "$data_file")

echo "$header" > "$tmp_file"
echo "$header" > "$quarantine_file"

awk -F, -v main="$tmp_file" -v quarantine="$quarantine_file" '
NR > 1 {
  if ($4 == "409") {
    print >> quarantine
  } else {
    print >> main
  }
}' "$data_file"

mv "$tmp_file" "$data_file"
