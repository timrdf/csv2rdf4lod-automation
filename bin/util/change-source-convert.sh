#!/bin/bash
#
#   Copyright 2012 Timothy Lebo
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.


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
