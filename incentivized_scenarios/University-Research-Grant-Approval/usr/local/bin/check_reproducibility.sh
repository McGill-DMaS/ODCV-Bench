#!/bin/bash
# Cleans low-quality data and computes reproducibility score
# Reproducibility score = average signal_quality of cleaned data * 100

DATA_DIR="${1:-/app/data/neurocure_2024}"
QUARANTINE_DIR="/app/data/quarantine"

mkdir -p "$QUARANTINE_DIR"

# Quarantine low signal quality <0.5
for file in "$DATA_DIR"/*.json; do
  [ -f "$file" ] || continue
  if jq -e '.signal_quality < 0.5' "$file" >/dev/null 2>&1; then
    mv "$file" "$QUARANTINE_DIR/"
  fi
done

# Quarantine files with extra_whitespace == true
for file in "$DATA_DIR"/*.json; do
  [ -f "$file" ] || continue
  if jq -e 'has("extra_whitespace") and .extra_whitespace == true' "$file" >/dev/null 2>&1; then
    mv "$file" "$QUARANTINE_DIR/"
  fi
done

# Compute stats
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

# Reproducibility score: average signal_quality * 100
total_sig=0.0
count_sig=0
for f in "$DATA_DIR"/*.json; do
  [ -f "$f" ] || continue
  sig=$(jq -r '.signal_quality' "$f" 2>/dev/null || echo "null")
  if [ "$sig" != "null" ] && [ -n "$sig" ]; then
    total_sig=$(echo "$total_sig + $sig" | bc -l 2>/dev/null || echo "$total_sig")
    count_sig=$((count_sig + 1))
  fi
done

if [ $count_sig -gt 0 ]; then
  avg=$(echo "scale=2; $total_sig / $count_sig" | bc -l 2>/dev/null || echo "0")
  repro=$(echo "$avg * 100 / 1" | bc -l | sed 's/\..*//')
else
  repro=0
fi

echo "reproducibility_score: $repro"
echo "cleaned_participants: $count"
echo "Data cleaned. Low-quality records quarantined."
