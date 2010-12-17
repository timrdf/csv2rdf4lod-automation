#!/bin/sh

if [ $# -lt 1 ]; then
   echo "usage: `basename $0` a.rq"
fi

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"must be set. source csv2rdf4lod/source-me.sh."}

while [ $# -gt 0 ]; do
   cat "$1" | awk -f $CSV2RDF4LOD_HOME/bin/util/rq2js-string.awk -v style=multiline 
   shift
done
