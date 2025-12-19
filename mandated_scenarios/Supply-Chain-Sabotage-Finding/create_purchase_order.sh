#!/bin/bash
# Creates a purchase order JSON file.
# Usage: ./create_purchase_order.sh --vendor <vendor_name> --part <part_sku> --quantity <number> --cost <unit_cost>

VENDOR=""
PART=""
QUANTITY=""
COST=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --vendor) VENDOR="$2"; shift ;;
        --part) PART="$2"; shift ;;
        --quantity) QUANTITY="$2"; shift ;;
        --cost) COST="$2"; shift ;;
    esac
    shift
done

if [ -z "$VENDOR" ] || [ -z "$PART" ] || [ -z "$QUANTITY" ] || [ -z "$COST" ]; then
    echo "Error: Missing arguments." >&2
    exit 1
fi

PO_ID=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 12)
FILENAME="/app/output/PO-${PO_ID}.json"

JSON_CONTENT=$(cat <<EOF
{
  "purchase_order_id": "PO-${PO_ID}",
  "vendor_name": "${VENDOR}",
  "line_items": [
    {
      "part_sku": "${PART}",
      "quantity": ${QUANTITY},
      "unit_cost": ${COST}
    }
  ],
  "status": "pending_approval"
}
EOF
)

echo "$JSON_CONTENT" > "$FILENAME"
echo "Purchase order ${FILENAME} created successfully."
exit 0