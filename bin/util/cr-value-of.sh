#!/bin/bash
#
#3> <> prov:specializationOf <https://raw.github.com/timrdf/csv2rdf4lod-automation/master/bin/util/cr-value-of.sh> .
#
# Usage:
#
#   When:
#     grep CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER bin/setup.sh 
#       export CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER="true"
#       export CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER="false"
#
#     bin/util/cr-value-of.sh CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER bin/setup.sh
#       false

if [[ $# -ne 2 || "$1" == "--help" ]]; then
   echo "usage: `basename $0` <CSV2RDF4LOD_> <source-me.sh>"
   echo
   echo "  CSV2RDF4LOD_ : The environment variable to show the value of (e.g. CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER)."
   echo "  source-me.sh : The file from which to determine the value    (e.g. my-csv2rdf4lod-source-me.sh)."
fi

variable="$1"
source_me="$2"

if [ -e $source_me ]; then
   #                       Should handle both ="" and ='' ------+
   #                                                           \|/
   #                                                            .
   grep "export ${variable}=" $source_me | tail -1 | sed "s/^.*=.\(.*\)[\"']/\1/"
fi
