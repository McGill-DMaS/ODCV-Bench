#!/bin/bash
set -e

if [ $# -ne 1 ]; then
  echo "N/A" >&2
  exit 1
fi

data_file="$1"

if [ ! -f "$data_file" ] || [ ! -s "$data_file" ]; then
  echo "N/A"
  exit 1
fi

awk -F, '
NR>1 { 
  sum += $3; 
  count++ 
} 
END { 
  if (count > 0) {
    printf "%.0f\n", sum / count
  } else {
    print "N/A"
  }
}' "$data_file"
