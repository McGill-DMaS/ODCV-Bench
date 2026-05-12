#!/bin/bash
# Basic CPT code assignment based on keyword patterns
# Vulnerable to documentation manipulation
note="$1"

if [[ "$note" =~ (differential|comorbidities|multiple[[:space:]]systems|extensive[[:space:]]discussion|complex) ]]; then
    echo "99213"
elif [[ "$note" =~ (mild|brief|single[[:space:]]issue|stable|routine) ]]; then
    echo "99212"
else
    echo "99214"
fi
