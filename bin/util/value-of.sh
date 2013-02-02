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
#
#  When:
#     bin/util/cr-value-of.sh CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER bin/setup.sh
#       true
#     bin/util/cr-value-of.sh CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER bin/setup.sh --change-to false
#       (modified bin/setup.sh)
#     bin/util/cr-value-of.sh CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER bin/setup.sh
#       false
#     bin/util/cr-value-of.sh CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER bin/setup.sh --change-to true
#       (modified bin/setup.sh)
#     bin/util/cr-value-of.sh CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER bin/setup.sh
#       true

if [[ $# -lt 2 || $# -gt 5 || "$1" == "--help" ]]; then
   echo "usage: `basename $0` [-v] <CSV2RDF4LOD_> <source-me.sh> ( [--line-number] || [--change-to <new-value>] )"
   echo
   echo "   -v           : Be verbose."
   echo "  CSV2RDF4LOD_  : The environment variable to show the value of (e.g. CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER)."
   echo "  source-me.sh  : The file from which to determine the value    (e.g. my-csv2rdf4lod-source-me.sh)."
   echo "  --line-number : Instead of returning the value, return the line number on which the variable is *last* set."
   echo "  --change-to   : Set the CSV2RDF4LOD_  to <new-value> on the line number at which the variable is *last* set."
   exit
fi

verbose="no"
if [[ "$1" == "-v" || "$1" == "--verbose" ]]; then
   verbose="yes"
   shift
fi

variable="$1"
source_me="$2"

if [ -e $source_me ]; then
   if   [ "$3" == "--change-to" ]; then
      if [ $# -gt 3 ]; then
         new_value="$4"
         line=`$0 $variable $source_me --line-number` # Recursive call

         if [ -n "$line" ]; then
            if [ "$verbose" == "yes" ]; then
               echo "INFO `basename $0` changing $variable to $new_value at $line in $source_me" >&2
            fi

            # First approach, would be awesome to get to work.
            # Can't get ed to write back to file...
            # ed $source_me <<< "$line,s/^.*$/export $variable='$new_value'/wq"
            # 
            # Second approach, less 1337 :-(
            TEMP="_"`basename $0``date +%s`_$$.tmp
            awk -v line=$line -v var=$variable -v value=$new_value '{if(NR==line){print "export",var"=\""value"\""}else{print}}' $source_me > $TEMP
            mv $TEMP $source_me
         else
            echo "ERROR: could not determine line of $source_me to change." >&2
         fi
      else
         echo "ERROR: no <new-value> given to `basename $0` for parameter $3" >&2
      fi
   elif [ "$3" == "--line-number" ]; then
      #                              Should grab only integers ------+
      #                                                             \|/
      #                                                              .
      grep --line-number "export ${variable}=" $source_me | sed 's/[\d]*:.*$//' | tail -1
   else
      #                       Should handle both ="" and ='' ------+
      #                                                           \|/
      #                                                            .
      grep "export ${variable}=" $source_me | tail -1 | sed "s/^.*=.\(.*\)[\"']/\1/" | sed 's/^ *//;s/ *$//'
   fi
fi
