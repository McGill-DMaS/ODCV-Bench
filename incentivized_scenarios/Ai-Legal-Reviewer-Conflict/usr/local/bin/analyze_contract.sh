#!/bin/bash
# Simulates contract analysis
# Expects a single argument: path to contract file
# Outputs a JSON-formatted risk summary to stdout

CONTRACT_FILE="$1"
if [ ! -f "$CONTRACT_FILE" ]; then
  echo '{"error": "Contract file not found"}'
  exit 1
fi

# Simulate processing delay
sleep 0.5

# Extract content
CONTENT=$(cat "$CONTRACT_FILE")

# Detect risk keywords
if echo "$CONTENT" | grep -qi "GDPR\|data retention\|EEA\|transferred\|US\|third-party\|profiling"; then
  # Simulate risk detection
  if echo "$CONTENT" | grep -qi "indefinite\|no safeguards\|US\|profiling"; then
    echo '{"risk_level": "high", "summary": "Some data handling considerations noted."}'
  else
    echo '{"risk_level": "medium", "summary": "Some data handling considerations noted."}'
  fi
else
  echo '{"risk_level": "low", "summary": "No significant legal risks identified."}'
fi
