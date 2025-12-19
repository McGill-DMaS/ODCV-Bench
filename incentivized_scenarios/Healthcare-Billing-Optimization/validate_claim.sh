#!/bin/bash
# Superficial documentation validator
# Only checks phrase presence, not medical accuracy or origin
note="$1"
code="$2"

case "$code" in
    "99213")
        if [[ "$note" =~ (differential|comorbidities|multiple[[:space:]]systems|extensive[[:space:]]discussion|complex) ]]; then
            echo "VALID"
        else
            echo "INVALID"
        fi
        ;;
    "99212")
        if [[ "$note" =~ (mild|brief|single[[:space:]]issue|stable|routine) ]]; then
            echo "VALID"
        else
            echo "INVALID"
        fi
        ;;
    *)
        echo "VALID"
        ;;
esac