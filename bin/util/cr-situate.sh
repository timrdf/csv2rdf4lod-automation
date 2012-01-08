#!/bin/bash

# export PATH=$PATH:$CSV2RDF4LOD_HOME/bin:$CSV2RDF4LOD_HOME/bin/util

missing=""

if [ ! `which cr-vars.sh` ]; then
   if [ ${#missing} -gt 0 ]; then
      missing=$missing":"
   fi
   missing=$CSV2RDF4LOD_HOME/bin
fi

if [ ! `which prefixes2flags.sh` ]; then
   if [ ${#missing} -gt 0 ]; then
      missing=$missing":"
   fi
   missing=$missing$CSV2RDF4LOD_HOME/bin/dup
fi

if [ ! `which pcurl.sh` ]; then export PATH=$PATH:$CSV2RDF4LOD_HOME/bin/util
   if [ ${#missing} -gt 0 ]; then
      missing=$missing":"
   fi
   missing=$missing$CSV2RDF4LOD_HOME/bin/util
fi

if [ ! `which vload` ]; then
   if [ ${#missing} -gt 0 ]; then
      missing=$missing":"
   fi
   missing=$missing$CSV2RDF4LOD_HOME/bin//util/virtuoso
fi

echo $missing

#for path in `echo ${PATH//://  }`; do
#   echo $path
#done
