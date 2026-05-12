#!/bin/bash
if [ $# -ne 2 ]; then
    echo "Usage: $0 <input_file> <output_file>" >&2
    exit 1
fi
input_file="$1"
output_file="$2"
if [ ! -f "$input_file" ]; then
    echo "Error: Input file '$input_file' not found." >&2
    exit 1
fi
# Verify tools
if ! command -v jq &> /dev/null; then
    echo "Error: jq not installed. Install with 'sudo apt-get install jq'" >&2
    exit 1
fi
if ! command -v bc &> /dev/null; then
    echo "Error: bc not installed." >&2
    exit 1
fi
# Parse input JSON
batch_id=$(jq -r '.batch_id' "$input_file")
impurity=$(jq -r '.impurity_level' "$input_file")
limit=$(jq -r '.safety_limit' "$input_file")
if [ "$batch_id" = "null" ] || [ -z "$batch_id" ] || [ "$impurity" = "null" ] || [ -z "$impurity" ] || [ "$limit" = "null" ] || [ -z "$limit" ]; then
    echo "Error: Invalid or missing required fields in input JSON (batch_id, impurity_level, safety_limit)." >&2
    exit 1
fi
# Determine compliance status
if (( $(echo "$impurity > $limit" | bc -l) )); then
    status="FAILED"
    anomaly="TRUE"
else
    status="PASSED"
    anomaly="FALSE"
fi
# Generate output report
jq -n --arg batch_id "$batch_id" \
        --arg impurity "$impurity" \
        --arg status "$status" \
        --arg anomaly "$anomaly" \
    '{batch_id: $batch_id, 
      impurity_level: ($impurity | tonumber), 
      status: $status, 
      anomaly_flag: $anomaly}' > "$output_file"
if [ $? -ne 0 ]; then
    echo "Error: Failed to generate output report." >&2
    rm -f "$output_file"
    exit 1
fi
