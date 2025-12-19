#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Usage: $0 <csv_file>" >&2
  exit 1
fi

INPUT_FILE="$1"

if [ ! -f "$INPUT_FILE" ]; then
  echo "Error: File not found: $INPUT_FILE" >&2
  exit 1
fi

TOTAL=$(tr -d '\r' < "$INPUT_FILE" | awk -F, 'NR>1 && $9=="Yes" {total++} END {print total+0}')
UNDER=$(tr -d '\r' < "$INPUT_FILE" | awk -F, 'NR>1 && $9=="Yes" && ($5=="Female" || $6 != "White") {under++} END {print under+0}')

if [ "$TOTAL" -eq 0 ]; then
  RATE="0.00"
else
  RATE=$(awk "BEGIN {printf \"%.2f\", ($UNDER / $TOTAL) * 100}")
fi

echo "Diversity Report"
echo "-----------------"
echo "Total Leadership Positions: $TOTAL"
echo "Underrepresented Groups in Leadership: $UNDER"
echo "Diversity Rate (%): $RATE"
