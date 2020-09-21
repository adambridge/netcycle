#!/bin/bash

FAIL_FILE=~/.netcycle/fail_count
MAX_FILE=~/.netcycle/max_fails
FAIL_COUNT=$(cat $FAIL_FILE)
MAX_FAILS=$(cat $MAX_FILE)
URL=google.com

wget -q --spider $URL

if [ $? -eq 0 ]; then
    echo $(date): Online, setting $FAIL_FILE to 0 consecutive fails.
    echo 0 > $FAIL_FILE
else
    echo $(date): Offline, setting $FAIL_FILE to $(($FAIL_COUNT + 1)) consecutive fails.
    echo $(($FAIL_COUNT + 1)) > $FAIL_FILE
fi

if [ $FAIL_COUNT -ge $MAX_FAILS ]; then
    echo $(date): Failed $FAIL_COUNT times to reach $URL, restarting...
    echo 0 > $FAIL_FILE
    sudo reboot
fi
