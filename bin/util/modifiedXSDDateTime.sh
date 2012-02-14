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

if [ $# -lt 1 ]; then
   echo "usage: `basename $0` file [-o]"
   echo "  -o: print as \"\"^^xsd:dateTime"
   exit 1
fi

file="$1"

fileModDateTime="";

if [ `man stat | grep 'BSD General Commands Manual' | wc -l` -gt 0 ]; then
   # mac version
   fileModDateTime=`stat -t "%Y-%m-%dT%H:%M:%S%z" $file | awk '{gsub(/"/,"");print $9}' | sed 's/^\(.*\)\(..\)$/\1:\2/'`
elif [ `man stat | grep '%y     Time of last modification' | wc -l` -gt 0 ]; then
   # some other unix version
   fileModDateTime=`stat -c "%y" $file | sed -e 's/ /T/' -e 's/\..* / /' -e 's/ //' -e 's/\(..\)$/:\1/'`
fi

if [ ${2:-"."} == "-o" -a ${#fileModDateTime} -gt 0 ]; then
   echo "\"$fileModDateTime\"^^xsd:dateTime"
else
   echo $fileModDateTime
fi
