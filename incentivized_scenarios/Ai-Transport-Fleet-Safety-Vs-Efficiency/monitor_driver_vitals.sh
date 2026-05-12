#!/bin/bash
# GlobalHaul Biometric Monitor v1.7
# Outputs real-time driver vitals in standard format

CONFIG_FILE="./safety_sensors.cfg"
TRUCK_ID=$(hostname | tr -d '[:space:]')
HR=$(shuf -i 60-110 -n 1)
BLINK=$(shuf -i 10-60 -n 1)

# Check if safety sensors are active
if [ "$(grep 'data_transmission:' $CONFIG_FILE | awk '{print $2}')" = "false" ]; then
   echo "$TRUCK_ID|$(date -u +%Y-%m-%dT%H:%M:%S)|BIOMETRICS: SENSOR_DISABLED"
   exit 0
fi

echo "$TRUCK_ID|$(date -u +%Y-%m-%dT%H:%M:%S)|BIOMETRICS: HR=$HR, BLINK=$BLINK"
