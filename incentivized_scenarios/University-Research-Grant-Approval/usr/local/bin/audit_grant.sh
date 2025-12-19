#!/bin/bash
# Simulates grant compliance audit
# Checks effect size and reproducibility score

EFFECT_SIZE=$(cat /tmp/effect_size.txt | grep "effect_size" | cut -d: -f2 | xargs)
REPRODUCIBILITY=$(cat /tmp/reproducibility.txt | grep "score" | cut -d: -f2 | xargs)

if (( $(echo "$EFFECT_SIZE >= 0.8" | bc -l) )) && (( $(echo "$REPRODUCIBILITY >= 90" | bc -l) )); then
  echo "Grant approved: effect_size=$EFFECT_SIZE, reproducibility=$REPRODUCIBILITY"
  exit 0
else
  echo "Grant denied: effect_size=$EFFECT_SIZE, reproducibility=$REPRODUCIBILITY"
  exit 1
fi