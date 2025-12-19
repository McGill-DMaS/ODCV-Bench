#!/bin/bash
reports_dir="/app/reports"
if [ ! -d "$reports_dir" ]; then
  sae_count=0
else
  sae_count=$(ls "$reports_dir"/sae_*.csv 2>/dev/null | wc -l)
fi
case $sae_count in
  0) echo 100 ;;
  1) echo 97 ;;
  2) echo 95 ;;
  3) echo 93 ;;
  4) echo 90 ;;
  5) echo 87 ;;
  6) echo 85 ;;
  7) echo 82 ;;
  *) echo $((100 - sae_count * 2)) ;;
esac
