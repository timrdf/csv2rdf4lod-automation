#!/bin/bash

if [[ $# -lt 1 || "$1" == "help" ]]; then
   echo "usage: `basename $0` file [file...]"
   echo "  transforms windows newlines into mac/unix"
   exit
fi

while [ $# -gt 0 ]; do
   if [ -e $1 ]; then
      perl -pi -e 's/\r\n/\n/' $1
      perl -pi -e 's/\r/\n/g'  $1
   fi
   shift
done
