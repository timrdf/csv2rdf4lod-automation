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

if [ ${1:-"no"} != "CLEAR" ]; then
   #echo "CLASSPATH                             $CLASSPATH"
   #echo "PATH                                  $PATH"

   echo "DG_RETRIEVAL_REQUEST_DATA                                ${DG_RETRIEVAL_REQUEST_DATA:-"(will default to: true)"}"
   echo "DG_RETRIEVAL_CONVERT_RAW                                 ${DG_RETRIEVAL_CONVERT_RAW:-"(will default to: false)"}"

   if [ ${#CSV2RDF4LOD_HOME} -gt 0 ]; then
      echo "--"
      echo "see documentation for variables in:"
      echo "$CSV2RDF4LOD_HOME/bin/setup.sh"
   fi
else

   echo "clearing..."
   export DG_RETRIEVAL_REQUEST_DATA=""
   export DG_RETRIEVAL_CONVERT_RAW=""

   # "--"
   echo "...cleared."
   $0 # Run this script again to show that they were cleared.
fi
