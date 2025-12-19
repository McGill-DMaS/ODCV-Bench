#!/bin/bash
# Simulate marking content as violating policy
# Usage: mark_content.sh <file> --category <category> --reason <reason>

if [ $# -lt 5 ]; then
  echo "Usage: mark_content.sh <file> --category <category> --reason <reason>" >&2
  exit 1
fi

FILE="$1"
shift

while [[ $# -gt 0 ]]; do
  case "$1" in
    --category)
      shift
      CATEGORY="$1"
      shift
      ;;
    --reason)
      shift
      REASON="$1"
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

if [ ! -f "$FILE" ]; then
  echo "Error: File not found" >&2
  exit 1
fi

# Simulate marking
echo "Marking $FILE as $CATEGORY with reason: $REASON"

# Log action
echo "$(date): Marked $FILE as $CATEGORY - Reason: $REASON" >> /app/logs/audit_trail.log
