#!/bin/bash
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}
surrogate="http://logd.tw.rpi.edu"
sourceID="cybershare-utep-edu"
datasetID="GravityMapPML"
datasetVersion="2011-Jul-25"
versionID="2011-Jul-25"
eID="1"

sourceDir="manual"
destDir="automatic"

graph="http://logd.tw.rpi.edu/source/cybershare-utep-edu/dataset/GravityMapPML/version/2011-Jul-25"
publishDir="publish"

export CSV2RDF4LOD_FORCE_PUBLISH="true"
source $CSV2RDF4LOD_HOME/bin/convert-aggregate.sh
export CSV2RDF4LOD_FORCE_PUBLISH="false"
