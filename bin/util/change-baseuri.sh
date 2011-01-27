#!/bin/bash

OLD_BASEURI="surrogate=\"http://data-gov.tw.rpi.edu\""
NEW_BASEURI="surrogate=\"http://logd.tw.rpi.edu\""

if [ ${1:-""} == "-w" ]; then
   shift 1
   if [ $# -gt 0 ]; then
      while [ $# -gt 0 ]; do
         echo "modifying $1"
         perl -pi -e "s|$OLD_BASEURI|$NEW_BASEURI|g" "$1"
         shift
      done
   else
      grep -l $OLD_BASEURI -R . | xargs -n 1 perl -pi -e "s|$OLD_BASEURI|$NEW_BASEURI|g"
   fi
else
   echo ""
   grep -l $OLD_BASEURI -R .
   echo ""
   echo "run '`basename $0` -w' to modify files in place."
fi
