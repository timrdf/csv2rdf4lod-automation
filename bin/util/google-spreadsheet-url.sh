#!/bin/bash

# need to provide the key that can be seen in the URL pane of the web browser.
if [ $# -lt 1 ]; then
   echo "usage: `basename $0` spreadsheet-key"
fi

#echo 'http://spreadsheets.google.com/tq?tqx=out:csv&tq=select%20*&key='$1
echo "http://spreadsheets.google.com/pub?key=$1&output=csv"
