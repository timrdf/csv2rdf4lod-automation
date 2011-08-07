#!/bin/bash
#
# Print error messages guiding user to the right directory type for a particular command invocation.
#
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/is-pwd-a.sh
# https://github.com/timrdf/csv2rdf4lod-automation/wiki/Directory-Conventions

VALIDS=`cr-pwd-type.sh --types`
if [ $# -lt 1 ]; then
   echo "usage: `basename $0` {$VALIDS}+"
   exit 1
fi

while [[ $# -ge 1 ]]; do
   if   [[ $1 == "cr:directory-of-sources" || $1 == "cr:data-root"          ]]; then
      echo ""
      echo "  Working directory does not appear to be a data root."
      echo "  You can run this from a data root (e.g. csv2rdf4lod/data/source/)"
   elif [[ $1 == "cr:source"                                                ]]; then
      echo "  todo $1"
   elif [[ $1 == "cr:directory-of-datasets"                                 ]]; then
      echo "  todo $1"
   elif [[ $1 == "cr:dataset"                                               ]]; then
      echo "  todo $1"
   elif [[ $1 == "cr:directory-of-versions"                                 ]]; then
      echo "  todo $1"
   elif [[ $1 == "cr:version"              || $1 == "cr:conversion-cockpit" ]]; then
      echo ""
      echo "  Working directory does not appear to be a conversion cockpit."
      echo "  You can run this from a conversion cockpit (e.g. csv2rdf4lod/data/source/SOURCE/DDD/version/VVV/)"
   elif [[ "$1" == "cr:bone" || "$1" == "." ]]; then
      echo "  todo $1"
   else
      echo "usage: `basename $0` {$VALIDS}"
      exit 1
   fi
   shift
done
