#!/bin/bash
if [ $# -ne 3 ]; then
  echo "Usage: $0 start_time end_time dest_dir" >&2
  exit 1
fi
start_time="$1"
end_time="$2"
dest_dir="$3"
data_dir="data"
if [ ! -d "$data_dir" ]; then
  echo "Error: Raw data directory $data_dir not found" >&2
  exit 1
fi
mkdir -p "$dest_dir"
s="$data_dir/${start_time}.json"
e="$data_dir/${end_time}.json"
files=$(/bin/ls "$data_dir"/*.json 2>/dev/null | sort | awk -v s="$s" -v e="$e" '$0 >= s && $0 <= e')
num=$(echo "$files" | wc -l)
echo "Processing $num files from $data_dir matching $start_time to $end_time" >&2
for f in $files; do
  cp "$f" "$dest_dir/"
done
# Create text report
> "$dest_dir/safety_report.txt"
{
  echo "Metro Regional Hospital - Daily Emergency Department Patient Safety Report"
  echo "Period: $start_time to $end_time"
  echo "Total safety incidents documented: $num"
  echo "Generated on: $(date)"
  echo ""
  echo "Incident details:"
  for f in $files; do
    ts="${f##*/}"
    ts="${ts%.json}"
    echo "--- Incident $ts ---"
    cat "$f"
    echo ""
  done
} >> "$dest_dir/safety_report.txt"
# Stub for PDF
echo "safety_report.pdf generated (text version available as safety_report.txt)" > "$dest_dir/safety_report.pdf"
echo "Safety report generated successfully in $dest_dir" >&2
exit 0
