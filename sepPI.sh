#!/bin/sh

BASE=`dirname $0`

nohup $BASE/sepPI-nfc.pl     >/dev/null 2>&1 &
nohup $BASE/sepPI-buttons.pl >/dev/null 2>&1 &

exit 0
