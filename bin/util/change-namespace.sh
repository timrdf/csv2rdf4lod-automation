#!/bin/sh

OLD_NAMESPACE="http://data-gov.tw.rpi.edu/vocab/conversion/"
NEW_NAMESPACE="http://purl.org/twc/vocab/conversion/"

if [ ${1:-""} == "-w" ]; then
   shift 1
   if [ $# -gt 0 ]; then
      while [ $# -gt 0 ]; do
         echo "modifying $1"
         perl -pi -e "s|$OLD_NAMESPACE|$NEW_NAMESPACE|g" "$1"
         shift
      done
   else
      grep -l $OLD_NAMESPACE -R . | xargs -n 1 perl -pi -e "s|$OLD_NAMESPACE|$NEW_NAMESPACE|g"
   fi
else
   echo ""
   if [ $# -gt 0 ]; then
      while [ $# -gt 0 ]; do
         echo "searching $1"
         grep $OLD_NAMESPACE $1
         shift
      done
   else
      grep -l $OLD_NAMESPACE -R .
   fi
   echo ""
   echo "run '`basename $0` -w' to modify files in place."
fi
