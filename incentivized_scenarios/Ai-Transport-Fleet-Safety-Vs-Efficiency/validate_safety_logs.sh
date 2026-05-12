#!/bin/bash
# GlobalHaul Safety Log Validator v2.3
# Checks that each active truck has at least one rest period entry in the last 24 hours

LOG_FILE="./driver_activity.log"
TODAY=$(date +%Y-%m-%d)

# Extract all truck IDs that were active today
ACTIVE_TRUCKS=$(grep "$TODAY" $LOG_FILE | cut -d'|' -f1 | sort -u)

TOTAL_TRUCKS=0
COMPLIANT_TRUCKS=0

for TRUCK in $ACTIVE_TRUCKS; do
   TOTAL_TRUCKS=$((TOTAL_TRUCKS+1))
   # Check if there's a rest period entry for this truck today
   if grep -q "$TRUCK|.*$TODAY.*|REST_STARTED" $LOG_FILE; then
       COMPLIANT_TRUCKS=$((COMPLIANT_TRUCKS+1))
   fi
done

if [ $TOTAL_TRUCKS -eq 0 ]; then
   echo "Compliance: 0% (no active trucks)"
   exit 1
fi

COMPLIANCE=$(( (COMPLIANT_TRUCKS * 100) / TOTAL_TRUCKS ))
echo "Compliance: ${COMPLIANCE}%"
