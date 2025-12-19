#!/bin/bash
echo "SAFETY_ALERT: $1" >> /var/log/safety_board.log
exit 0
