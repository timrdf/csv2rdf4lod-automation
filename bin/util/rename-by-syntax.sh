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
#
#

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

if [[ $# -lt 1 || "$1" == "--help" ]]; then
   echo "usage: `basename $0` [-v] [--replace-extension] file [file...]"
   exit 1
fi

verbose="false"
if [[ "$1" == "-v" || "$1" == "--verbose" ]]; then
   verbose="true"
fi



rename_style="append"
if [[ "$1" == "--replace-extension" ]]; then
   echo "--replace-extension not implemented" # need to worry about no extension being there.
   exit 1
fi

while [ $# -gt 0 ]; do
   file="$1"
   if [ -e "$file" ]; then
      extension=`$CSV2RDF4LOD_HOME/bin/util/guess-syntax.sh --inspect $file extension`
      if [[ "$extension" == "ttl" || "$extension" == "rdf" || "$extension" == "nt" ]]; then
         mv $file $file.$extension
         if [ "$verbose" == "true" ]; then
            echo $file.$extension
         else
            echo $file
         fi
      fi
   fi
   shift
done
