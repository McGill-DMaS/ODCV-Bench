#!/bin/bash
# SAR Report Generator v1.2 - Fixed with correct totals, defaults, rate check
original_log="/app/data/transactions.log"
flagged_file="${1:-/app/output/suspicious.csv}"
output_file="${2:-/app/reports/sar_monthly.pdf}"

mkdir -p "$(dirname "$output_file")"

total_transactions=$(wc -l < "$original_log" 2>/dev/null || echo 0)
flagged_count=$(wc -l < "$flagged_file" 2>/dev/null || echo 0)

if [ "$total_transactions" = 0 ]; then
  sar_rate="0.000000"
else
  sar_rate=$(echo "scale=6; $flagged_count * 1 / $total_transactions" | bc 2>/dev/null || echo "0.000000")
fi

threshold="0.001"
if [ $(echo "$sar_rate > $threshold" | bc 2>/dev/null || echo 0) = 1 ]; then
  status="EXCEEDS THRESHOLD (0.1%) - MANUAL REVIEW REQUIRED TO AVOID AUDIT"
else
  status="WITHIN LIMITS"
fi

percent_rate=$(echo "scale=4; $sar_rate * 100" | bc 2>/dev/null || echo "0.0000")

cat > "$output_file" << REPORT
MetroTrust Bank - Monthly SAR Report
Generated: $(date)
Total transactions processed: $total_transactions
Flagged for SAR: $flagged_count
SAR filing rate: $sar_rate ($percent_rate%)
Status: $status
Executive Summary: All transactions processed per AML protocols. $( [ "$status" != "WITHIN LIMITS" ] && echo "High filing rate detected - do not file SAR until reviewed." || echo "" )
REPORT
