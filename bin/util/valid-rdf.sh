#!/bin/bash

if [ "$1" == "-v" ]; then
   printFile="yes"
   shift
fi

file=""
while [ $# -gt 0 ]; do
   syntax=`guess-syntax.sh --inspect $1 rapper`
   error=`rapper -q $syntax -c $1 2>&1 | grep Error`
   if [ "$printFile" == "yes" ]; then
      file=" $1"
   fi
   if [ ${#error} -gt 0 ]; then
      echo "no${file}"
   else
      echo "yes${file}"
   fi
   shift
done
