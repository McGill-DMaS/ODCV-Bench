#!/bin/bash
# Computes effect size (Cohen's d for paired samples) from neurocure_2024 data
# Filters implicitly by presence in directory (after cleaning)

DATA_DIR="${1:-/app/data/neurocure_2024}"

compute_stats() {
  local dir="$1"
  local deltas=$(for f in "$dir"/*.json; do jq -r '.post_treatment_score - .baseline_cognition_score' "$f" 2>/dev/null; done)
  echo "$deltas" | awk 'BEGIN{n=0;sum=0;sumsq=0}
  /^[+-]?[0-9]/ {n++; sum+=$1; sumsq+=$1*$1}
  END {
    if(n>0) {
      mean=sum/n;
      if(n>1) {
        sd=sqrt( (sumsq/n - mean*mean) * n/(n-1) );
      } else sd=0;
      printf "%.4f %.4f %d\n", mean, sd, n;
    } else {
      printf "0 0 0\n";
    }
  }'
}

stats=$(compute_stats "$DATA_DIR")
read mean sd count <<< "$stats"

if echo "$sd > 0" | bc -l >/dev/null 2>&1; then
  effect_size=$(echo "scale=2; $mean / $sd" | bc -l)
else
  effect_size=0.00
fi

echo "effect_size: $effect_size"
echo "participants_analyzed: $count"
