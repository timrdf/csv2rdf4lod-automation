#!/bin/bash
#
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/cr-situate-paths.sh
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
# Usage:
#   export PATH=$PATH`$CSV2RDF4LOD_HOME/bin/util/cr-situate-paths.sh`
#   (can be repeated indefinately, once paths are in PATH, nothing is returned.)

HOME=$(cd ${0%/*/*} && echo ${PWD%/*})        # e.g. /home/lebot/opt/prizms/repos/csv2rdf4lod-automation
me=$(cd ${0%/*} && echo ${PWD})/`basename $0` # e.g. /home/lebot/opt/prizms/repos/csv2rdf4lod-automation/bin/util/cr-situate-paths.sh

if [ "$1" == "--help" ]; then
   echo "`basename $0` [--help]"
   echo
   echo "Return the shell paths needed to find all csv2rdf4lod-automation scripts."
   echo "Set them by executing:"
   echo
   echo "    export PATH=\$PATH\`$me\`"
   exit
fi

missing=""

if [ ! `which serdi &> /dev/null` ]; then
   missing=$missing:/usr/local/bin
fi

if [ ! `which cr-vars.sh &> /dev/null` ]; then
   missing=$missing:$HOME/bin
fi

if [ ! `which prefixes2flags.sh &> /dev/null` ]; then
   missing=$missing:$HOME/bin/dup
fi

if [ ! `which pcurl.sh &> /dev/null` ]; then #export PATH=$PATH:$HOME/bin/util
   missing=$missing:$HOME/bin/util
fi

if [ ! `which vload &> /dev/null` ]; then
   missing=$missing:$HOME/bin/util/virtuoso
fi

if [ ! `which install-virtuoso-on-mac.sh &> /dev/null` ]; then
   missing=$missing:$HOME/bin/util/virtuoso/mac
fi

if [ ! `which cr-linksets.sh &> /dev/null` ]; then
   missing=$missing:$HOME/bin/secondary
fi

echo $missing

#for path in `echo ${PATH//://  }`; do
#   echo $path
#done
