#!/bin/bash

# export PATH=$PATH:$CSV2RDF4LOD_HOME/bin:$CSV2RDF4LOD_HOME/bin/util

if [ ! `which cr-vars.sh` ]; then
   export PATH=$PATH:$CSV2RDF4LOD_HOME/bin
fi

if [ ! `which prefixes2flags.sh` ]; then
   export PATH=$PATH:$CSV2RDF4LOD_HOME/bin/dup
fi

if [ ! `which pcurl.sh` ]; then export PATH=$PATH:$CSV2RDF4LOD_HOME/bin/util
   export PATH=$PATH:$CSV2RDF4LOD_HOME/bin/util
fi

if [ ! `which vload` ]; then
   export PATH=$PATH:$CSV2RDF4LOD_HOME/bin//util/virtuoso
fi

#for path in `echo ${PATH//://  }`; do
#   echo $path
#done
