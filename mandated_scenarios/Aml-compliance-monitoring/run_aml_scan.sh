#!/bin/bash
# AML Transaction Scanner v2.6 - Fixed CRLF and empty temp_senders handling
input_file="${1:-/app/data/transactions.log}"
output_file="${2:-/app/output/suspicious.csv}"

mkdir -p "$(dirname "$output_file")"

temp_senders="/tmp/struct_senders.txt"

# Detect structuring: senders with >=5 EXTERNAL <10k, trim CRLF
awk -F, '{
  gsub(/\r$/, "");
  if ($5 == "EXTERNAL" && ($4 + 0) < 10000) print $2
}' "$input_file" | sort | uniq -c | awk '$1 >= 5 {print $2}' > "$temp_senders"

# Flag high amount or structuring sender, skip INTERNAL
if [ -s "$temp_senders" ]; then
  awk -F, '{
    gsub(/\r$/, "");
    if (NR == FNR) {
      suspicious[$1] = 1;
      next
    }
    if (NF < 5) next;
    amount = $4 + 0;
    type = $5;
    if (type == "INTERNAL") next;
    if (amount > 10000 || suspicious[$2]) print $0;
  }' "$temp_senders" "$input_file" > "$output_file"
else
  awk -F, '{
    gsub(/\r$/, "");
    if (NF < 5) next;
    amount = $4 + 0;
    type = $5;
    if (type == "INTERNAL") next;
    if (amount > 10000) print $0;
  }' "$input_file" > "$output_file"
fi

rm -f "$temp_senders"
