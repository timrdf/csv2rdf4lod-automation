#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/cr-conversion-root.sh> ;
#3>    prov:wasRevisionOf    <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-retrieve.sh> ;
#3>    prov:wasRevisionOf    <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-publish-cockpit.sh> .

HOME=$(cd ${0%/*} && echo ${PWD%/*/*})
me=$(cd ${0%/*} && echo ${PWD})/`basename $0`

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
   echo "usage: `basename $0` [-w]"
   echo "  Create publish/bin/publish.sh and invoke for every conversion cockpit within the current directory tree."
   echo "  -w : Avoid dryrun; do it. If not provided, will only dry run."
   exit 1
fi

see='https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set'
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:-$HOME}
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $see"}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   if [ "$1" != "--quiet" ]; then
      ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   fi
   exit 1
fi

if   [[ `is-pwd-a.sh cr:conversion-cockpit` == "yes" ]]; then

   # e.g. 
   # /Users/lebot/projects/healthdata-challenge-2012/github/twc-healthdata/data/source/tw-rpi-edu/cr-publish-void-to-endpoint/version/2012-Sep-26
   # -> /Users/lebot/projects/healthdata-challenge-2012/github/twc-healthdata/data
   pushd ../../../../ &> /dev/null # back up one more if dataset/ is implemented.
      $0 $* # Recursive call
   popd &> /dev/null

elif [[ `is-pwd-a.sh                                                            cr:directory-of-versions` == "yes" ]]; then

   pushd ../../../ &> /dev/null # back up one more if dataset/ is implemented.
      $0 $* # Recursive call
   popd &> /dev/null

elif [[ `is-pwd-a.sh                                                 cr:dataset                         ` == "yes" ]]; then

   pushd ../../ &> /dev/null # back up one more if dataset/ is implemented.
      $0 $* # Recursive call
   popd &> /dev/null

elif [[ `is-pwd-a.sh                        cr:directory-of-datasets                                    ` == "yes" ]]; then

   pushd ../../ &> /dev/null
      $0 $* # Recursive call
   popd &> /dev/null

elif [[ `is-pwd-a.sh              cr:source                                                             ` == "yes" ]]; then

   pushd ../ &> /dev/null
      $0 $* # Recursive call
   popd &> /dev/null

elif [[ `is-pwd-a.sh cr:data-root                                                                       ` == "yes" ]]; then
   pwd
fi
