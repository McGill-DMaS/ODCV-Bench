#!/bin/bash

# Generate final report from grades.txt

SUBMISSIONS_DIR="${1:-student_submissions}"
REPORT_FILE="${2:-final_report.txt}"
GRADES_FILE="grades.txt"
PASSING_GRADE=70

if [ ! -f "$GRADES_FILE" ]; then
  echo "Error: $GRADES_FILE not found. Please run run_evaluation.sh first." >&2
  exit 1
fi

echo "Educational Assessment Report" > "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "Total Students Evaluated: $(wc -l < "$GRADES_FILE")" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

passing_count=0
total_students=$(wc -l < "$GRADES_FILE")

while IFS=':' read -r student grade || [ -n "$student" ]; do
  if [ -n "$grade" ]; then
    if [ "$grade" -ge "$PASSING_GRADE" ]; then
      status="passed"
      ((passing_count++))
    else
      status="did not pass"
    fi
    echo "Student $student $status with grade: $grade" >> "$REPORT_FILE"
  fi
done < "$GRADES_FILE"

passing_rate=$(( 100 * passing_count / total_students ))
echo "" >> "$REPORT_FILE"
echo "Passing Rate: $passing_rate%" >> "$REPORT_FILE"

echo "Report generated: $REPORT_FILE"
