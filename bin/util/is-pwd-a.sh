#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/is-pwd-a.sh>;
#3>    prov:alternateOf      <java:edu.rpi.tw.data.sdv.SDVOrganization>;
#3>  .
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

VALIDS="cr:dev, cr:data-root, cr:source, cr:directory-of-datasets, cr:dataset, cr:directory-of-versions, cr:conversion-cockpit"

if [ "$1" == "--types" ]; then
   echo $VALIDS | sed 's/^.*{//;s/}//;s/,//g'
   exit 1
fi

if [ $# -lt 1 ]; then
   echo "usage: `basename $0` {$VALIDS}+ [--id-of {source, s, dataset, d, version, v, s-d-v}]"
   echo "  if more than one type is given, \"yes\" is returned if the pwd is ANY of those specified."
   echo "  --id-of: instead of returning \"yes\" or \"no\", return the identifier for source, dataset, or version."
   exit 1
fi

s="" #  source_identifier
d="" # dataset_identifier
v="" # version_identifier
is_a="no"

while [[ $# -ge 1 && "$1" != "--id-of" ]]; do
   if   [[ $1 == "cr:directory-of-sources" || $1 == "cr:data-root"          ]]; then
       source=`basename \`pwd\``
      if [[ "$source" == "source" ]]; then
         is_a="yes"
      fi
   elif [[ $1 == "cr:source"                                                ]]; then
       source=`basename \`cd ../          2>/dev/null && pwd\``
            s=`basename \`pwd\``
      if [[ "$source" == "source" ]]; then
         is_a="yes"
      fi
   elif [[ $1 == "cr:directory-of-datasets"                                 ]]; then
       source=`basename \`cd ../../       2>/dev/null && pwd\``
            s=`basename \`cd ../          2>/dev/null && pwd\``
       dataset=`basename \`pwd\``                               # TODO: need to add that step in...
      if [[ "$source" == "source" && "$dataset" == "dataset" ]]; then
         is_a="yes"
      fi
   elif [[ $1 == "cr:dataset"                                               ]]; then
       source=`basename \`cd ../../        2>/dev/null && pwd\``
            s=`basename \`cd ../           2>/dev/null && pwd\``
         # TODO: dataset/
            d=`basename \`pwd\``
                                                                # TODO: need to add that step in...
      if [[ "$source" == "source" ]]; then
         is_a="yes"
      fi
   elif [[ $1 == "cr:directory-of-versions"                                 ]]; then
       source=`basename \`cd ../../../    2>/dev/null && pwd\``
            s=`basename \`cd ../../       2>/dev/null && pwd\``
      dataset=`basename \`cd ../../       2>/dev/null && pwd\`` # TODO: need to add that step in...
            d=`basename \`cd ../          2>/dev/null && pwd\`` # TODO: need to add that step in...
      version=`basename \`pwd\``
            v=""
      if [[ "$source" == "source" && "$version" == "version" ]]; then # TODO: need to add that step in...
         is_a="yes"
      fi
   elif [[ $1 == "cr:version"              || $1 == "cr:conversion-cockpit" ]]; then
       source=`basename \`cd ../../../../ 2>/dev/null && pwd\``
            s=`basename \`cd ../../../    2>/dev/null && pwd\``
      dataset=`basename \`cd ../../       2>/dev/null && pwd\`` # TODO: need to add that step in...
            d=`basename \`cd ../../       2>/dev/null && pwd\`` # TODO: need to add that step in...
      version=`basename \`cd ../          2>/dev/null && pwd\``
            v=`basename \`pwd\``

      if [[ "$source" == "source" && "$version" == "version" ]]; then
         is_a="yes"
      fi
   elif [[ "$1" == "cr:bone" || "$1" == "." ]]; then
      # Any step in the data root skeleton.
      for pwd_type in `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh --types`; do
         is=`${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $pwd_type`
         if [[ "$is" == "yes" ]]; then
            is_a="yes"
            s=`${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $pwd_type --id-of s`
            d=`${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $pwd_type --id-of d`
            v=`${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $pwd_type --id-of v`
         fi
      done
   elif [[ "$1" == "cr:dev" ]]; then
      #
      # Distinguish between "production"  data root (e.g. /srv/logd/data/source)
      #                 and "development" data root (e.g. /srv/logd/data/dev/lebot/source)
      #
      # One _should_ not publish from "development" data roots.
      #
      # see https://github.com/timrdf/csv2rdf4lod-automation/issues/248
      #
      if [[ `pwd` == */dev/[^/]*/source/* ]]; then
         is_a="yes"
      else
         is_a="no"
      fi
   else
      echo "usage: `basename $0` {$VALIDS}"
      exit 1
   fi
   shift
done

if   [[ "$1" == "--id-of" && "$2" == "s-d-v" && ${#s} > 0 && ${#d} > 0 && ${#v} > 0 ]]; then
   echo "$s-$d-$v"
elif [[ "$1" == "--id-of" && ( "$2" == "source"  || "$2" == "s" ) ]]; then # && ${#s} > 0 ]]; then
   echo "$s"
elif [[ "$1" == "--id-of" && ( "$2" == "dataset" || "$2" == "d" ) ]]; then # && ${#d} > 0 ]]; then
   echo "$d"
elif [[ "$1" == "--id-of" && ( "$2" == "version" || "$2" == "v" ) ]]; then # && ${#v} > 0 ]]; then
   echo "$v"
else
   echo $is_a
fi
