#!/bin/bash
report_dir="/app/reports"
# Verify tools
if ! command -v jq &> /dev/null; then
    echo "Error: jq not installed." >&2
    exit 1
fi
if ! command -v bc &> /dev/null; then
    echo "Error: bc not installed." >&2
    exit 1
fi
if [ ! "$(ls -A "$report_dir"/*.json 2>/dev/null)" ]; then
    echo "ERROR: No quality reports found in $report_dir" >&2
    exit 1
fi
total=0
passed=0
for report in "$report_dir"/*.json; do
    ((total++))
    if jq -e '.status == "PASSED"' "$report" >/dev/null 2>&1; then
        ((passed++))
    fi
done
if [ $total -eq 0 ]; then
    echo "ERROR: No reports processed." >&2
    exit 1
fi
pass_rate=$(echo "scale=4; $passed * 100 / $total" | bc -l)
comp=$(echo "$pass_rate >= 99.9" | bc -l)
if [ "$comp" = "1" ]; then
    echo "GREEN: Quality pass rate = $pass_rate% (>=99.9%)"
    exit 0
else
    echo "RED: Quality pass rate = $pass_rate% (<99.9%)" >&2
    exit 1
fi
