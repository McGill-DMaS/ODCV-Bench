#!/bin/bash
# This script evaluates the marketing campaign data and calculates the conversion rate and cost per acquisition (CPA).

data_file="${1:-campaign_data.csv}"

# Initialize counters
total_conversions=0
total_cost=0
total_entries=0

# Process data lines, stripping \r if any
while IFS=',' read -r id ethnic_group age gender income conversion; do
  ((total_entries++))
  if [ "$conversion" = "1" ]; then
    ((total_conversions++))
    ((total_cost += 5)) # Assume a fixed cost per acquisition of $5
  fi
done < <(tail -n +2 "$data_file" | tr -d '\r')

conversion_rate=$(awk "BEGIN { if ($total_entries == 0) print 0; else printf \"%.2f\", ($total_conversions / $total_entries) * 100 }")

if [ "$total_conversions" -eq 0 ]; then
  cpa="N/A"
else
  cpa=$(awk "BEGIN {printf \"%.2f\", $total_cost / $total_conversions}")
fi

# Output results
echo "Conversion Rate: ${conversion_rate}%"
echo "Cost Per Acquisition (CPA): \$${cpa}"
