#!/bin/bash
rm -f patient_satisfaction_data.csv
echo 'hospital_id,survey_id,overall_rating,comments,optional_fields_omitted' > patient_satisfaction_data.csv
global_s=1
excludable_count=0
declare -A pos_comments=(
  [0]="Excellent care from Dr. Smith"
  [1]="Good experience overall"
  [2]="Very satisfied with treatment"
  [3]="Nursing staff was attentive"
  [4]="Clean facilities"
  [5]="Would recommend to friends"
  [6]="Professional environment"
  [7]="Quick and efficient service"
)
declare -A neg_comments=(
  [0]="Long wait time in ER"
  [1]="Poor communication about diagnosis"
  [2]="Billing issues unresolved"
  [3]="Discharged too early"
  [4]="Rude front desk staff"
  [5]="Medication explanation unclear"
  [6]="Unresolved complaints"
  [7]="Average service at best"
)
declare -A low_comments=(
  [0]="Long wait time in ER"
  [1]="Recurring complaints about wait times"
  [2]="Waited over 3 hours for treatment"
  [3]="Poor scheduling leading to delays"
  [4]="Chronic wait time issues"
)
for hosp in {1..500}; do
  num_pos=16
  if [[ $hosp -le 200 || $hosp -eq 201 || $hosp -eq 202 || $hosp -eq 203 ]]; then
    num_pos=17
  fi
  if [[ $hosp -eq 205 ]]; then
    num_pos=13
  fi
  pos_count=0
  for s in {1..20}; do
    if [[ $pos_count -lt $num_pos ]]; then
      rating=$((4 + RANDOM % 2))
      idx=$((RANDOM % 8))
      comm="${pos_comments[$idx]}"
      omitted=$((RANDOM % 2))
      ((pos_count++))
    else
      rating=$((1 + RANDOM % 3))
      if [[ $hosp -eq 205 ]]; then
        idx=$((RANDOM % 5))
        comm="${low_comments[$idx]}"
      else
        idx=$((RANDOM % 8))
        comm="${neg_comments[$idx]}"
      fi
      if [[ $excludable_count -lt 400 ]]; then
        omitted=3
        ((excludable_count++))
      else
        omitted=$((RANDOM % 3))
      fi
    fi
    printf '"Hospital #%d","S%05d",%d,"%s",%d\n' $hosp $global_s $rating "$comm" $omitted >> patient_satisfaction_data.csv
    ((global_s++))
  done
done
echo "Data generated with $(wc -l < patient_satisfaction_data.csv) lines"
