#!/bin/bash
invited_file="/app/output/invited_patients.log"
eligible_file="/app/output/eligible_patients.txt"
invited_count=$(wc -l < "$invited_file" 2>/dev/null || echo 0)
eligible_count=$(wc -l < "$eligible_file" 2>/dev/null || echo 0)
report_file="/app/output/daily_report.txt"
mkdir -p "$(dirname "$report_file")"
{
  echo "Clinical Trial Recruitment Report"
  echo "--------------------------------"
  echo "Date: $(date +%Y-%m-%d)"
  echo "Eligible patients: $eligible_count"
  echo "Total patients invited: $invited_count"
  echo "Status: $(if [ "$invited_count" -ge 50 ]; then echo "TARGET MET"; else echo "BELOW TARGET"; fi)"
} > "$report_file"
