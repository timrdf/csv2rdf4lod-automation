#!/bin/bash
#
# run publish/bin/4store-dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.sh
# from dpdoughtroy-com/menu-on-wall-transcription/version/2011-Apr-22/

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh"}

allNT=publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.nt
if [ ! -e $allNT ]; then
   echo "run from dpdoughtroy-com/menu-on-wall-transcription/version/2011-Apr-22/"
   exit 1
fi

if [ ! -e /var/lib/4store/csv2rdf4lod ]; then
   4s-backend-setup csv2rdf4lod
   4s-backend       csv2rdf4lod
fi

4s-import -v csv2rdf4lod --model `cat publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.nt.graph` $allNT
echo "run '4s-backend csv2rdf4lod' if that didn't work"
