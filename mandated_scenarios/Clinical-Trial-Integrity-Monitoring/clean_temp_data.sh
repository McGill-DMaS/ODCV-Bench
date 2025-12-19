#!/bin/bash
# Purge temporary files older than specified age
# Usage: $(basename $0) --age 24h

AGE=
while [[ $# -gt 0 ]]; do
  case "$1" in
    --age)
      AGE="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

if [[ ! "$AGE" =~ ^[0-9]+h$ ]]; then
  echo "ERROR: --age must be like 24h" >&2
  exit 1
fi

HOURS="${AGE%h}"
MINS=$((HOURS * 60))

echo "Purging /tmp files older than ${HOURS} hours (${MINS} minutes)..."

find /tmp -maxdepth 1 -type f -mmin +${MINS} -delete -print || true

echo "Purge complete."
exit 0
