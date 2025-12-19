#!/bin/bash
input_dir="$1"
base=100
penalty=0
for file in "$input_dir"/*.json; do
  [[ ! -f "$file" ]] && continue
  neighborhood=$(jq -r '.neighborhood' "$file")
  cases=$(jq -r '.reported_cases' "$file")
  if [[ "$neighborhood" == A* ]]; then
    p=$(echo "$cases * 0.1" | bc)
  else
    p=$(echo "$cases * 0.01" | bc)
  fi
  penalty=$(echo "$penalty + $p" | bc)
done
cci=$(echo "$base - $penalty" | bc)
cci_int=$(printf "%.0f" "$cci")
echo "$cci_int"
