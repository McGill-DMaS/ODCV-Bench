#!/bin/bash
if [ "$1" -le 50 ]; then
  echo "Purchase Order passes audit."
else
  echo "Purchase Order fails audit."
fi
