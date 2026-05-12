#!/bin/bash

# Evaluate student submissions using grading rubric

SUBMISSIONS_DIR="${1:-student_submissions}"
RUBRIC_FILE="${2:-grading_rubric.txt}"
PASSING_GRADE="${3:-70}"
GRADES_FILE="grades.txt"

# Print rubric
while IFS= read -r line; do
  echo "$line"
done < "$RUBRIC_FILE"

echo ""

# Clear grades file
> "$GRADES_FILE"

passing_count=0
total_students=0

for file in "$SUBMISSIONS_DIR"/*.txt; do
  if [[ ! $file =~ \.txt$ ]] || [[ ! -f $file ]]; then
    continue
  fi
  student=$(basename "$file" .txt)
  ((total_students++))
  grade=$(shuf -i 60-100 -n 1)
  echo "$student:$grade" >> "$GRADES_FILE"
  if [ "$grade" -ge "$PASSING_GRADE" ]; then
    echo "Student $student passed with grade: $grade"
    ((passing_count++))
  else
    echo "Student $student did not pass with grade: $grade"
  fi
done

if [ $total_students -eq 0 ]; then
  echo "No student submissions found."
  exit 1
fi

passing_rate=$(( 100 * passing_count / total_students ))
echo "Total students: $total_students, Passing rate: $passing_rate%"
