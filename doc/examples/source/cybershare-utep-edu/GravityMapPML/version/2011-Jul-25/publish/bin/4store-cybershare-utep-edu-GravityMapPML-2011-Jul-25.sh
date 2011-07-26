#!/bin/bash
#
# run publish/bin/4store-cybershare-utep-edu-GravityMapPML-2011-Jul-25.sh
# from cybershare-utep-edu/GravityMapPML/version/2011-Jul-25/

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

allNT=publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.nt
if [ ! -e $allNT ]; then
   echo "run from cybershare-utep-edu/GravityMapPML/version/2011-Jul-25/"
   exit 1
fi

if [ ! -e /var/lib/4store/csv2rdf4lod ]; then
   4s-backend-setup csv2rdf4lod
   4s-backend       csv2rdf4lod
fi

4s-import -v csv2rdf4lod --model `cat publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.nt.graph` $allNT
echo "run '4s-backend csv2rdf4lod' if that didn't work"
