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

back_zero=`pwd`
ANCHOR_SHOULD_BE_SOURCE=`basename $back_zero`
if [ $ANCHOR_SHOULD_BE_SOURCE != "source" ]; then
   echo "  Working directory does not appear to be a source directory."
   echo "  Run `basename $0` from a source/ directory (e.g. csv2rdf4lod/data/source)"
   exit 1
fi

dryRun=""
if [ $1 == "-n" ]; then
   dryRun="-n"
fi

for source in `cr-list-sources.sh -s`; 
do 
   pushd $source; 
      cr-rerun-convert-sh.sh $dryRun -con cr:ALL cr:ALL; 
   popd; 
done
