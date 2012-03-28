#!/bin/bash
#
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/change-namespace.sh
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
# 
# e.g.
#   change-namespace.sh http://dvcs.w3.org/hg/prov/raw-file/tip/ontology/ProvenanceOntology.owl# http://www.w3.org/ns/prov-o/ -w

if [[ $# -lt 2 || $# -gt 3 ]]; then
   echo "usage: `basename $0` old-namespace new-namespace [-w]"
   echo "  Nothing is modified unless -w is specified."
   exit 1
fi

OLD_NAMESPACE="http://data-gov.tw.rpi.edu/vocab/conversion/"
OLD_NAMESPACE="$1"

NEW_NAMESPACE="http://purl.org/twc/vocab/conversion/"
NEW_NAMESPACE="$2"
shift 2

if [ "$1" == "-w" ]; then
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
