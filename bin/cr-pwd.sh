#!/bin/bash
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
# Return the type of directory pwd is.
#
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/cr-pwd-type.sh
# https://github.com/timrdf/csv2rdf4lod-automation/wiki/Directory-Conventions

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source my-csv2rdf4lod-source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

if [[ "$1" == "--types" ]]; then
   ${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh --types
   exit 1 
fi

if   [[ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh cr:data-root`             == "yes" ]]; then
   echo "source/"
elif [[ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh cr:source`                == "yes" ]]; then
   cruft=`cd ../../ && pwd`/
   here=`pwd`
   echo ${here#$cruft}
elif [[ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh cr:directory-of-datasets` == "yes" ]]; then
   cruft=`cd ../../../ && pwd`/
   here=`pwd`
   echo ${here#$cruft}
elif [[ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh cr:dataset`               == "yes" ]]; then
   cruft=`cd ../../../ && pwd`/ # TODO: fill in ../ when adding dataset/
   here=`pwd`
   echo ${here#$cruft}
elif [[ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh cr:directory-of-versions` == "yes" ]]; then
   cruft=`cd ../../../../ && pwd`/
   here=`pwd`
   echo ${here#$cruft}
elif [[ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh cr:conversion-cockpit`    == "yes" ]]; then
   cruft=`cd ../../../../../ && pwd`/
   here=`pwd`
   echo ${here#$cruft}
else
   echo "Not recognized; see https://github.com/timrdf/csv2rdf4lod-automation/wiki/Directory-Conventions" 
fi
