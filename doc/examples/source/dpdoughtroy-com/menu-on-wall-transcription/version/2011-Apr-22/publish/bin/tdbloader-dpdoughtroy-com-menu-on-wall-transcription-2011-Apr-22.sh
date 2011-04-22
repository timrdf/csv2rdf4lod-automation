#!/bin/bash

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh"}

delete=""
if [ ! -e publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.nt ]; then
  delete="publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.nt"
  if [ -e publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.nt.gz ]; then
    gunzip -c publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.nt.gz > publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.nt
  elif [ -e publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.ttl ]; then
    echo "cHuNking publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.ttl into publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.nt; will delete when done lod-mat'ing"
    $CSV2RDF4LOD_HOME/bin/util/bigttl2nt.sh publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.ttl > publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.nt
  elif [ -e publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.ttl.gz ]; then
    gunzip -c publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.ttl.gz > publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.ttl
    echo "cHuNking publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.ttl into publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.nt; will delete when done lod-mat'ing"
    $CSV2RDF4LOD_HOME/bin/util/bigttl2nt.sh publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.ttl > publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.nt
    rm publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.ttl
  else
    echo publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.nt, publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.nt.gz, publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.ttl, or publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.ttl.gz needed to lod-materialize.
    delete=""
    exit 1
  fi
fi

mkdir publish/tdb                      &> /dev/null
rm    publish/tdb/*.dat publish/tdb/*.idn &> /dev/null

echo dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.nt into publish/tdb as http://logd.tw.rpi.edu/source/dpdoughtroy-com/dataset/menu-on-wall-transcription/version/2011-Apr-22 >> publish/ng.info
echo `wc -l publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.nt` triples.

tdbloader --loc=publish/tdb --graph=`cat publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.nt.graph` publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.nt

if [ ${#delete} -gt 0 ]; then
   rm $delete
fi
