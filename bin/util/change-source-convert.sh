#!/bin/bash

OLD_SOURCE_CONVERT='formats/csv/bin/convert-aggregate.sh'
NEW_SOURCE_CONVERT='CSV2RDF4LOD_HOME/bin/convert-aggregate.sh'

OLD_SOURCE_CONVERT2='formats/csv/bin/convert.sh'
NEW_SOURCE_CONVERT2='CSV2RDF4LOD_HOME/bin/convert.sh'

if [ ${1:-""} == "-w" ]; then
   shift 1
   if [ $# -gt 0 ]; then
      while [ $# -gt 0 ]; do
         echo "modifying $1"
         perl -pi -e "s|$OLD_SOURCE_CONVERT|$NEW_SOURCE_CONVERT|g"   "$1"
         perl -pi -e "s|$OLD_SOURCE_CONVERT2|$NEW_SOURCE_CONVERT2|g" "$1"
         shift
      done
   else
      grep -l "$OLD_SOURCE_CONVERT" -R  . | xargs -n 1 perl -pi -e "s|$OLD_SOURCE_CONVERT|$NEW_SOURCE_CONVERT|g"
      grep -l "$OLD_SOURCE_CONVERT2" -R . | xargs -n 1 perl -pi -e "s|$OLD_SOURCE_CONVERT2|$NEW_SOURCE_CONVERT2|g"
   fi
else
   echo ""
   grep -l "$OLD_SOURCE_CONVERT" -R .
   grep -l "$OLD_SOURCE_CONVERT2" -R .
   echo ""
   echo "run '`basename $0` -w' to modify files in place."
fi
