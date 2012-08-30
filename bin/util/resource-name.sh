#!/bin/bash

java -cp $CLASSPATH`$CSV2RDF4LOD_HOME/bin/util/cr-situate-classpaths.sh` edu.rpi.tw.string.NameFactory $*
