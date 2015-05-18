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
# Give any params to get URI-friendly coin:slug
# see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CoIN:-Composition-of-Identifier-Names

if [ $# -eq 0 ]; then
   date +%Y-%m-%dT%H:%M:%S%z | sed 's/^\(.*\)\(..\)$/\1:\2/'
elif [ $1 == "coin:slug" ]; then
   date +%Y-%m-%dT%H_%M_%S%z | sed 's/^\(.*\)\(..\)$/\1:\2/' | sed 's/:/-/g; s/\+/-/g'
elif [ $1 == "--turtle" ]; then
   date +%Y-%m-%dT%H:%M:%S%z | sed 's/^\(.*\)\(..\)$/\1:\2/' | awk '{print"\""$0"\"^^xsd:dateTime"}'
elif [ $1 == "--uri-path" ]; then
   if [[ "$2" != "" ]]; then
      #echo "$2" | sed 's/[-:]/\//;s/[-:]/\//;s/T/\/T\//;s/[-:]/\//;s/[-:]/\//;s/\([+-]\)/\/\1/;s/[:]/\//'
      # hi=`dateInXSDDateTime.sh` && echo $hi && dateInXSDDateTime.sh --uri-path $hi
      #   2015-05-18T10:24:45-04:00
      #   2015/05/18/T/10/24/45/-04/00
      
      # Remove the timezone
      echo "$2" | sed 's/[-:]/\//;s/[-:]/\//;s/T/\/T\//;s/[-:]/\//;s/[-:]/\//;s/[+-].*$//'
      # hi=`dateInXSDDateTime.sh` && echo $hi && dateInXSDDateTime.sh --uri-path $hi
      # 2015-05-18T10:26:22-04:00
      # 2015/05/18/T/10/26/22
   else
      date +%Y/%m/%d/T/%H/%M/%S/%z
   fi
else
   date +%Y-%m-%dT%H:%M:%S%z | sed 's/^\(.*\)\(..\)$/\1:\2/'
fi
# note was used at one time: date +%Y-%m-%dT%H:%M:%S%z | sed 's/^\(.*\)\(..\)$/\1:\2/'

# Could be used: date +%Y-%m-%dT%H:%M:%S%z | sed 's/\(..\)$/:\1/'
