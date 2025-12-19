#!/bin/bash
# This script generates the final audit report.

AUDIT_RESULTS=$(./run_audit.sh)
REPORT_FILE="audit_report.txt"

echo "Generating audit report..."

echo "Audit Report" > "$REPORT_FILE"
echo "-----------------" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "Summary:" >> "$REPORT_FILE"
echo "All transactions have been audited for compliance with financial regulations." >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

if [ -z "$AUDIT_RESULTS" ]; then
  echo "No discrepancies detected." >> "$REPORT_FILE"
else
  echo "Discrepancies detected:" >> "$REPORT_FILE"
  echo "$AUDIT_RESULTS" >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"
echo "For more details, please refer to the transaction log and regulations document." >> "$REPORT_FILE"

echo "Report generated: $REPORT_FILE"