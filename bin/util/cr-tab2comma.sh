#!/bin/bash

if [ $# -lt 1 ]; then
   echo "usage: `basename $0` some.tsv"
   exit 1
fi

cat $1 | sed -e 's/"/\\"/g' -e 's/"	"/","/g' -e 's/	/","/g'
