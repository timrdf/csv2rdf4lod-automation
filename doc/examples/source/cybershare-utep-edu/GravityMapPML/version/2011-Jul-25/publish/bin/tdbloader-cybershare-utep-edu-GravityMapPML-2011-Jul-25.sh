#!/bin/bash

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

delete=""
#if [ ! -e publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.nt ]; then
#  delete="publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.nt"
#  if [ -e publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.nt.gz ]; then
#    gunzip -c publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.nt.gz > publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.nt
#  elif [ -e publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.ttl ]; then
#    echo "cHuNking publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.ttl into publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.nt; will delete when done lod-mat'ing"
#    $CSV2RDF4LOD_HOME/bin/util/bigttl2nt.sh publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.ttl > publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.nt
#  elif [ -e publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.ttl.gz ]; then
#    gunzip -c publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.ttl.gz > publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.ttl
#    echo "cHuNking publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.ttl into publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.nt; will delete when done lod-mat'ing"
#    $CSV2RDF4LOD_HOME/bin/util/bigttl2nt.sh publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.ttl > publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.nt
#    rm publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.ttl
#  else
#    echo publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.nt, publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.nt.gz, publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.ttl, or publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.ttl.gz needed to lod-materialize.
#    delete=""
#    exit 1
#  fi
#fi
load_file=""
if [ -e     "publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.nt" ]; then
  load_file="publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.nt"
elif [ -e   "publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.ttl" ]; then
  load_file="publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.ttl"
elif [ -e   "publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.ttl.gz" ]; then
  load_file="publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.ttl"
  gunzip -c  publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.ttl.gz > publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.ttl
     delete="publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.ttl"
elif [ -e   "publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.nt.gz" ]; then
  load_file="publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.nt"
  gunzip -c  publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.nt.gz > publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.nt
     delete="publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.nt"
fi

mkdir publish/tdb                         &> /dev/null
rm    publish/tdb/*.dat publish/tdb/*.idn &> /dev/null

echo `basename $load_file` into publish/tdb as http://logd.tw.rpi.edu/source/cybershare-utep-edu/dataset/GravityMapPML/version/2011-Jul-25 >> publish/ng.info

if [ $load_file = "publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.ttl" -a `stat -f "%z" "publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.ttl"` -gt 2000000000 ]; then
  dir="publish"
  echo "cHuNking publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.ttl in $dir"
  rm $dir/cHuNk*.ttl &> /dev/null
  ${CSV2RDF4LOD_HOME}/bin/split_ttl.pl $load_file
  for cHuNk in $dir/cHuNk*.ttl; do
    echo giving $cHuNk to tdbloader
    tdbloader --loc=publish/tdb --graph=`cat publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.nt.graph` $cHuNk
    rm $cHuNk
  done
else
  tdbloader --loc=publish/tdb --graph=`cat publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.nt.graph` $load_file
fi

if [ ${#delete} -gt 0 ]; then
   rm $delete
fi
