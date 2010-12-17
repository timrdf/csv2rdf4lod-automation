#!/bin/sh
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
