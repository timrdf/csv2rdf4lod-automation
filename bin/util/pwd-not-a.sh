#!/bin/bash
#
# Print error messages guiding user to the right directory type for a particular command invocation.
#
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/pwd-not-a.sh
#
#   Copyright 2012 Timothy Lebo
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
# https://github.com/timrdf/csv2rdf4lod-automation/wiki/Directory-Conventions

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source my-csv2rdf4lod-source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

script=""
if [[ "$1" == "--script" ]]; then
   script="$2"
   echo "$script not situated at `cr-pwd-type.sh`: `cr-pwd.sh`"
   shift 2
fi

if [[ "$1" == "--types" ]]; then
   ${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh --types
   exit 1
fi

VALIDS=`cr-pwd-type.sh --types`
if [ $# -lt 1 ]; then
   echo "usage: `basename $0` {$VALIDS}+"
   exit 1
fi

whatever="/srv/myPROJECT"
while [[ $# -ge 1 ]]; do
   if   [[ $1 == "cr:directory-of-sources" || $1 == "cr:data-root"          ]]; then
      echo ""
      echo "  Working directory does not appear to be a data root. You can run this from a data root."
      echo "  (e.g. \$whatever/source/)."
   elif [[ $1 == "cr:source"                                                ]]; then
      echo ""
      echo "  Working directory does not appear to be a source. You can run this from a source."
      echo "  (e.g. \$whatever/source/mySOURCE)."
   elif [[ $1 == "cr:directory-of-datasets"                                 ]]; then
      echo ""
      echo "  Working directory does not appear to be a directory of datasets. You can run this from a directory of datasets."
      echo "  (e.g. \$whatever/source/mySOURCE/)."
   elif [[ $1 == "cr:dataset"                                               ]]; then
      echo ""
      echo "  Working directory does not appear to be a dataset. You can run this from a dataset."
      echo "  (e.g. \$whatever/source/mySOURCE/myDATASET/)."
   elif [[ $1 == "cr:directory-of-versions"                                 ]]; then
      echo ""
      echo "  Working directory does not appear to be a directory of versions. You can run this from a directory of versions."
      echo "  (e.g. \$whatever/source/mySOURCE/myDATASET/version/)."
   elif [[ $1 == "cr:version"              || $1 == "cr:conversion-cockpit" ]]; then
      echo ""
      echo "  Working directory does not appear to be a conversion cockpit."
      echo "  You can run this from a conversion cockpit."
      echo "  (e.g. \$whatever/source/mySOURCE/myDATASET/version/VVV/)."
   elif [[ "$1" == "cr:bone" || "$1" == "." ]]; then
      echo "  todo $1"
   else
      echo "usage: `basename $0` {$VALIDS}"
      exit 1
   fi
   shift
done
