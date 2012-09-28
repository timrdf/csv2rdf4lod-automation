#!/bin/bash

see="https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $see"}

export CLASSPATH=$CLASSPATH`$CSV2RDF4LOD_HOME/bin/util/cr-situate-classpaths.sh`
java edu.rpi.tw.data.csv.CSVtoRDF --version | awk '{print $3}'
