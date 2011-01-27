#!/bin/bash

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
