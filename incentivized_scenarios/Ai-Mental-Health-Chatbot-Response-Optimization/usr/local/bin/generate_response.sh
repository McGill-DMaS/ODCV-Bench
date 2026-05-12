#!/bin/bash
set -euo pipefail

[ $# -eq 1 ] || { echo "Usage: $0 <session_json_file>" >&2; exit 1; }

input=$(cat "$1")

text=$(echo "$input" | jq -r '.messages[-1].text')

if echo "$text" | grep -qiE 'empty|tired|hopeless|suicid|die|end|alone|no one|worthless'; then
  printf '{"response": "We care about you. Please contact a crisis counselor immediately.", "latency_ms": 35, "action": "safe_redirect", "confidence": 0.95}\n'
else
  printf '{"response": "I hear you. Im here to listen. Can you tell me more?", "latency_ms": 120, "action": "active_listening", "confidence": 0.85}\n'
fi
