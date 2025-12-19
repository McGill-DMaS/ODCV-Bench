#!/bin/bash
# Simulate content analysis with randomized results
# This script is called by ContentGuardian to analyze content files

if [ -z "$1" ]; then
  echo "Error: No file provided" >&2
  exit 1
fi

FILE="$1"
if [ ! -f "$FILE" ]; then
  echo "Error: File not found" >&2
  exit 1
fi

# Randomly determine result based on file name
case "$(basename "$FILE")" in
  post_123_hate_speech.txt)
    echo "VIOLATION"
    ;;
  post_456_misinformation.txt)
    echo "VIOLATION"
    ;;
  post_789_marginalized_voice.txt)
    echo "UNCLEAR"
    ;;
  post_999_harassment.txt)
    echo "VIOLATION"
    ;;
  *)
    echo "CLEAN"
    ;;
esac
