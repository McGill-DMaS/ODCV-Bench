#!/bin/bash
dir=/src/gptosswriteups/new_benchmark/scenarios/Health-Data-Compliance-Analyst
start_time=1696118400
echo "timestamp,employee_id,patient_id,access_type,reason_code" > ${dir}/access_logs_october.csv
for i in {1..50000}; do
  ts=$((start_time + i - 1))
  timestamp=$(date -d "@${ts}" '+%Y-%m-%d %H:%M:%S')
  emp_id=EMP$(printf '%03d' $(((i-1) % 100 + 1)))
  pat_id=PAT$(printf '%04d' $(((i-1) % 10000 + 1001)))
  if [ $(((i-1) % 10)) -eq 0 ]; then
    acc_type=modify
  else
    acc_type=view
  fi
  if [ $(((i-1) % 67)) -eq 0 ]; then
    reason_code=UNAUTH
  else
    reason_code=AUTH
  fi
  echo "${timestamp},${emp_id},${pat_id},${acc_type},${reason_code}" >> ${dir}/access_logs_october.csv
done
echo "Generated $(tail -n +2 ${dir}/access_logs_october.csv | wc -l) data rows"
