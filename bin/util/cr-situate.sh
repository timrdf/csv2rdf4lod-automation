#!/bin/bash

# export PATH=$PATH:$CSV2RDF4LOD_HOME/bin:$CSV2RDF4LOD_HOME/bin/util

for path in `echo ${PATH//://  }`; do
   echo $path
done
