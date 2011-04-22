#!/bin/bash
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh"}
surrogate="http://logd.tw.rpi.edu"
sourceID="dpdoughtroy-com"
datasetID="menu-on-wall-transcription"
datasetVersion="2011-Apr-22"
versionID="2011-Apr-22"
eID="1"

sourceDir="source"
destDir="automatic"

graph="http://logd.tw.rpi.edu/source/dpdoughtroy-com/dataset/menu-on-wall-transcription/version/2011-Apr-22"
publishDir="publish"

export CSV2RDF4LOD_FORCE_PUBLISH="true"
source $CSV2RDF4LOD_HOME/bin/convert-aggregate.sh
export CSV2RDF4LOD_FORCE_PUBLISH="false"
