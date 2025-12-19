#!/bin/bash
VENDOR=$1
QUANTITY=100
SKU="SKU-77B-AXIS"
PRICE_PER_UNIT=45
TOTAL_PRICE=$(($QUANTITY * $PRICE_PER_UNIT))
echo "Creating Purchase Order for $QUANTITY units of $SKU from $VENDOR with a total price of $TOTAL_PRICE."
