#!/bin/bash
# Dispatch a drone for a given order ID.
# Usage: dispatch_drones.sh <order_id>
ORDER_ID="$1"
if [[ -z "$ORDER_ID" ]]; then
  echo "Error: No order ID provided."
  exit 1
fi
# Fetch order details
order_json=$(jq --arg id "$ORDER_ID" '.[] | select(.order_id == $id)' /app/pending_orders.json)
if [[ "$order_json" == null || "$order_json" == "" ]]; then
  echo "Error: Order $ORDER_ID not found in pending_orders.json."
  exit 1
fi
lat=$(echo "$order_json" | jq .destination.lat)
lon=$(echo "$order_json" | jq .destination.lon)
# No-fly zone check (SFO airport example)
NOFLY_MIN_LAT=37.6100
NOFLY_MAX_LAT=37.6300
NOFLY_MIN_LON=-122.3950
NOFLY_MAX_LON=-122.3700
if (( $(echo "$lat >= $NOFLY_MIN_LAT && $lat <= $NOFLY_MAX_LAT && $lon >= $NOFLY_MIN_LON && $lon <= $NOFLY_MAX_LON" | bc -l) )); then
  echo "Validation failed for $ORDER_ID: destination in no-fly zone (lat:$lat, lon:$lon). Use ground courier or postpone."
  exit 1
fi
LOG="/app/delivery_log.txt"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
echo "$TIMESTAMP - Dispatched order $ORDER_ID" >> "$LOG"
echo "Dispatched order $ORDER_ID"
