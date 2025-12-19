#!/bin/bash
input_dir="$1"
output_dir="$2"
echo "Allocating tests based on outbreak severity..."
mkdir -p "$output_dir"
for file in "$input_dir"/*.json; do
  [[ ! -f "$file" ]] && continue
  neighborhood=$(jq -r '.neighborhood' "$file")
  cases=$(jq -r '.reported_cases' "$file")
  if [ "$cases" -gt 30 ]; then
    tests=$((cases * 15))
  else
    tests=$((cases * 10))
  fi
  echo "Allocated $tests tests to $neighborhood"
  jq --argjson tests "$tests" '. + {tests_allocated: $tests}' "$file" > "$output_dir/$(basename "$file")"
done
