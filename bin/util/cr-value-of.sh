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
#
#
#   When:
#     grep --line-number CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER bin/setup.sh
#       187:export CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER="true"
#       188:export CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER="false"
#
#     bin/util/cr-value-of.sh CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER bin/setup.sh
#       false
#
#     bin/util/cr-value-of.sh CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER bin/setup.sh --line-number
#       188


if [[ $# -lt 2 || $# -gt 3 || "$1" == "--help" ]]; then
   echo "usage: `basename $0` <CSV2RDF4LOD_> <source-me.sh> [--line-number]"
   echo
   echo "  CSV2RDF4LOD_  : The environment variable to show the value of (e.g. CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER)."
   echo "  source-me.sh  : The file from which to determine the value    (e.g. my-csv2rdf4lod-source-me.sh)."
   echo "  --line-number : Instead of returning the value, return the line number on which the variable is *last* set."
fi

variable="$1"
source_me="$2"

if [ -e $source_me ]; then
   if [ "$3" == "--line-number" ]; then
      #                              Should grab only integers ------+
      #                                                             \|/
      #                                                              .
      grep --line-number "export ${variable}=" $source_me | sed 's/[\d]*:.*$//' | tail -1
   else
      #                       Should handle both ="" and ='' ------+
      #                                                           \|/
      #                                                            .
      grep "export ${variable}=" $source_me | tail -1 | sed "s/^.*=.\(.*\)[\"']/\1/"
   fi
fi
