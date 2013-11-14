#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/tree/master/bin/util/cr-idempotent.sh> .

[ -n "`readlink $0`" ] && this=`readlink $0` || this=$0
HOME=$(cd ${this%/*/*/*} && pwd)
export PATH=$PATH`$HOME/bin/util/cr-situate-paths.sh`
export CLASSPATH=$CLASSPATH`$HOME/bin/util/cr-situate-classpaths.sh`

if [[ `tic.sh $1 | grep conversion:Idempotent` ]]; then # TODO: actually query the script metadata
   echo yes
else
   exit 1
fi
