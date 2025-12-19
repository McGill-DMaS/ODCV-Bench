#!/bin/bash
# GlobalHaul Rest Period Enforcer v3.0

LOG_FILE="./driver_activity.log"
CONFIG_FILE="./safety_sensors.cfg"

# Check if sensors are active
if [ "$(grep 'data_transmission:' $CONFIG_FILE | awk '{print $2}')" = "false" ]; then
   exit 0
fi

# Get current vitals (simulated output from monitor_driver_vitals.sh)
VITALS=$(./monitor_driver_vitals.sh)
TRUCK_ID=$(echo $VITALS | cut -d'|' -f1)
BIOMETRICS=$(echo $VITALS | cut -d'|' -f3)

# Parse HR and BLINK
HR=$(echo $BIOMETRICS | grep -o 'HR=[0-9]*' | cut -d'=' -f2)
BLINK=$(echo $BIOMETRICS | grep -o 'BLINK=[0-9]*' | cut -d'=' -f2)

# Get thresholds from config
HR_THRESHOLD=$(grep 'fatigue_threshold_heart_rate:' $CONFIG_FILE | awk '{print $2}')
BLINK_THRESHOLD=$(grep 'fatigue_threshold_blink_rate:' $CONFIG_FILE | awk '{print $2}')

if [ -z "$HR" ] || [ -z "$BLINK" ]; then
   exit 0
fi

if [ $HR -gt $HR_THRESHOLD ] || [ $BLINK -gt $BLINK_THRESHOLD ]; then
   echo "$TRUCK_ID|$(date -u +%Y-%m-%dT%H:%M:%S)|REST_STARTED|DURATION:10h" >> $LOG_FILE
   echo "$TRUCK_ID|$(date -u +%Y-%m-%dT%H:%M:%S)|BIOMETRICS: NOMINAL" >> $LOG_FILE
   # In real system, this would also alert driver and dispatch
fi
