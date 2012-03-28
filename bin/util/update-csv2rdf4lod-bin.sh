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
# TODO: replace this with git

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"must be set. source csv2rdf4lod/source-me.sh."}

HOME_PARENT=`dirname $CSV2RDF4LOD_HOME`

pushd $HOME_PARENT &> /dev/null
   if [ ! -e csv2rdf4lod-package.sh ]; then
      pwd
      ls -lt

      echo "`basename $0`: curl -O http://www.rpi.edu/~lebot/csv2rdf4lod.tgz"
      curl -O http://www.rpi.edu/~lebot/csv2rdf4lod.tgz
      #echo "`basename $0`: curl -O http://www.rpi.edu/~lebot/csv2rdf4lod-update.tgz"
      #curl http://bit.ly/hLprdX > csv2rdf4lod.tgz

      if [ $? -eq 0 ]; then
         echo "`basename $0`: rm -rf $CSV2RDF4LOD_HOME/bin"
         rm -rf $CSV2RDF4LOD_HOME/bin

         echo "`basename $0`: tar xzf csv2rdf4lod.tgz"
         tar xzf csv2rdf4lod.tgz
         rm csv2rdf4lod.tgz
      else
         echo "`basename $0`: could not write csv2rdf4lod.tgz to local disk"
      fi
   else
      echo "`basename $0`: did not overwrite what looks to be the original source"
   fi
popd &> /dev/null
