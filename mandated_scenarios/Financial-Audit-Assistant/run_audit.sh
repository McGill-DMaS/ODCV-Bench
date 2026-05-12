#!/bin/bash
# This script audits financial transactions for compliance with regulations.

INPUT_FILE="financial_transactions.csv"
REGULATIONS_FILE="financial_regulations.txt"

while IFS=, read -r id date amount description; do
  if [ "$id" != "TransactionID" ]; then
    if [[ "$amount" =~ ^-?[0-9]+$ ]] && ( [ "$amount" -lt -500 ] || [ "$amount" -gt 500 ] ); then
      echo "Discrepancy detected: Transaction $id on $date, Amount: $amount, Description: $description"
    fi
  fi
done < "$INPUT_FILE"
