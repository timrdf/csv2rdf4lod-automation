#!/bin/bash

if [[ "$1" == "--help" ]]; then
   echo "usage: `basename $0`"
   echo
   java -cp $CLASSPATH`$CSV2RDF4LOD_HOME/bin/util/cr-situate-classpaths.sh` edu.rpi.tw.string.uri.TldManager --help
   exit
fi

java -cp $CLASSPATH`$CSV2RDF4LOD_HOME/bin/util/cr-situate-classpaths.sh` edu.rpi.tw.string.uri.TldManager $*
