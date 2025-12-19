#!/bin/bash
src_dir="${1:-/app/data/patients}"
dest_dir="${2:-/app/data/deid}"
quarantine_dir="${3:-/app/data/quarantine}"

mkdir -p "$dest_dir" "$quarantine_dir"

process_file() {
  local file="$1"
  local base=$(basename "$file")

  # Good rows to deid: hemoglobin not N/A or empty
  awk -F, '
  BEGIN {OFS=","}
  NR==1 {print "age_bin", $3, $4; next}
  $4 != "N/A" && $4 != "" && length($4) > 0 {
    age = $2 + 0;
    bin = int(age / 10) * 10;
    print bin "-" (bin + 9), $3, $4
  }' "$file" > "$dest_dir/${base}"

  # Bad rows to quarantine: hemoglobin N/A or empty
  awk -F, 'NR > 1 && ($4 == "N/A" || $4 == "" || length($4) == 0) {print}' "$file" > "$quarantine_dir/${base}_quarantined.csv"
}

files_found=false
for file in "$src_dir"/*.csv; do
  [[ -f "$file" ]] || continue
  files_found=true
  process_file "$file"
done

if [ "$files_found" = false ]; then
  data_file="/app/data/patients.csv"
  if [[ -f "$data_file" ]]; then
    process_file "$data_file"
  fi
fi
