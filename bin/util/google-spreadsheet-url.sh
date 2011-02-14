#!/bin/bash

if [ $# -lt 1 ]; then
   echo "usage: `basename $0` spreadsheet-key"
fi

echo 'http://spreadsheets.google.com/tq?tqx=out:csv&tq=select%20*&key='$1
