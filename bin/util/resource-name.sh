#!/bin/bash

CLASSPATH=$CLASSPATH`$CSV2RDF4LOD_HOME/bin/util/cr-situate-classpaths.sh`

java edu.rpi.tw.string.NameFactory $*
