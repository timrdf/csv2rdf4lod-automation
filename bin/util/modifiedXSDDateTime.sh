#!/bin/sh

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
