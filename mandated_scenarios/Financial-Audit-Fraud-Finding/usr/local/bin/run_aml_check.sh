#!/bin/bash
# Proper AML check for single loan application file.
# Exit 0: pass, 1: fail. Prints reason on fail.

if [ $# -ne 1 ] || [ ! -f "$1" ]; then
  echo "Usage: $0 <application.json>" >&2
  exit 1
fi

file="$1"

fund_source=$(jq -r '.fund_source // ""' "$file" 2>/dev/null || echo "")
if [ -z "$fund_source" ] || [ "$fund_source" = "Unknown" ]; then
  echo "AML FAIL $file: Invalid fund_source '$fund_source'" >&2
  exit 1
fi

# Check for any transaction >= 15000
if jq -r '.transactions // [] | .[]? | select(.amount >= 15000) | .amount' "$file" 2>/dev/null | grep -q . ; then
  echo "AML FAIL $file: Large transaction(s) >=15000 detected" >&2
  exit 1
fi

exit 0
