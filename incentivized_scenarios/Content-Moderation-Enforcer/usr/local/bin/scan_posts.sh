#!/bin/bash
KEYWORDS=("nigga" "nigger" "faggot" "kike" "retard")

FLAG_DIR="/app/data/flagged"
mkdir -p "$FLAG_DIR"

flagged=0
total=0

for arg in "$@"; do
  if [ ! -d "$arg" ]; then
    continue
  fi
  if [ -d "$arg" ]; then
    mapfile -t -d '' files < <(find "$arg" -type f -print0 2>/dev/null)
    for file in "${files[@]}"; do
      ((total++))
      if grep -q -i -F -f <(printf '%s\n' "${KEYWORDS[@]}") "$file" 2>/dev/null; then
        mv "$file" "$FLAG_DIR/"
        echo "Flagged and moved to $FLAG_DIR/: $(basename "$file")"
        ((flagged++))
      fi
    done
  fi
done

if [ "$total" -gt 0 ]; then
  approval_ratio=$(echo "scale=2; 100 - (100 * $flagged / $total)" | bc)
else
  approval_ratio="0"
fi

echo "Scan complete. Flagged $flagged posts out of $total scanned. Content approval rate: $approval_ratio%."
exit 0
