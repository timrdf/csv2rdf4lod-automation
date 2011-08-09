#!/bin/bash
#
# Print error messages guiding user to the right directory type for a particular command invocation.
#
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/pwd-not-a.sh
# https://github.com/timrdf/csv2rdf4lod-automation/wiki/Directory-Conventions

VALIDS=`cr-pwd-type.sh --types`
if [ $# -lt 1 ]; then
   echo "usage: `basename $0` {$VALIDS}+"
   exit 1
fi

whatever="/srv/myPROJECT"
while [[ $# -ge 1 ]]; do
   if   [[ $1 == "cr:directory-of-sources" || $1 == "cr:data-root"          ]]; then
      echo ""
      echo "  Working directory does not appear to be a data root."
      echo "  You can run this from a data root (e.g. \$whatever/source/)."
   elif [[ $1 == "cr:source"                                                ]]; then
      echo ""
      echo "  Working directory does not appear to be a source."
      echo "  You can run this from a source (e.g. \$whatever/source/mySOURCE)."
   elif [[ $1 == "cr:directory-of-datasets"                                 ]]; then
      echo ""
      echo "  Working directory does not appear to be a directory of datasets."
      echo "  You can run this from a directory of datasets (e.g. \$whatever/source/mySOURCE/)."
   elif [[ $1 == "cr:dataset"                                               ]]; then
      echo ""
      echo "  Working directory does not appear to be a dataset."
      echo "  You can run this from (e.g. \$whatever/source/mySOURCE/myDATASET/)."
   elif [[ $1 == "cr:directory-of-versions"                                 ]]; then
      echo ""
      echo "  Working directory does not appear to be a directory of versions."
      echo "  You can run this from a directory of versions (e.g. \$whatever/source/mySOURCE/myDATASET/version/)."
   elif [[ $1 == "cr:version"              || $1 == "cr:conversion-cockpit" ]]; then
      echo ""
      echo "  Working directory does not appear to be a conversion cockpit."
      echo "  You can run this from a conversion cockpit (e.g. \$whatever/source/mySOURCE/myDATASET/version/VVV/)."
   elif [[ "$1" == "cr:bone" || "$1" == "." ]]; then
      echo "  todo $1"
   else
      echo "usage: `basename $0` {$VALIDS}"
      exit 1
   fi
   shift
done
