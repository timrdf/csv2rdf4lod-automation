#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/cr-list-versioned-dataset-dumps.sh>;
#3>    prov:wasDerivedFrom <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-publish-cockpit.sh> .
#

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
   echo "usage: `basename $0` [-w] [--warn-if-missing]"
   echo "  Create publish/bin/publish.sh and invoke for every conversion cockpit within the current directory tree."
   echo "                -w : Avoid dryrun; do it. If not provided, will only dry run."
   echo " --warn-if-missing : print a warning if the versioned dataset does not have a dump file."
fi

see='https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set'
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $see"}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   echo `pwd` `cr-pwd.sh` `cr-pwd-type.sh` `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs`
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

write="no"
if [[ "$1" == "-w" || "$1" == "--write" ]]; then
   write="yes"
   shift
fi

warn="no"
if [[ "$1" == "--warn-if-missing" ]]; then
   warn="yes"
fi

TEMP="_"`basename $0``date +%s`_$$.tmp

if [[ `is-pwd-a.sh cr:conversion-cockpit` == "yes" ]]; then

   sdv=`cr-sdv.sh`
   found=''
   for extension in 'nt ttl rdf'; do
      if [ -e publish/"$sdv.$extension" ]; then
         found="`pwd`/publish/$sdv.$extension"
         echo $found
      elif [ -e publish/"$sdv.$extension.gz" ]; then
         found="`pwd`/publish/$sdv.$extension.gz"
         echo $found
      fi
   done
   if [[ "$warn" == "yes" && -z "$found" ]]; then
      echo "WARNING: `basename $0` did not find a data dump for `cr-pwd.sh`"
   fi

elif [[ `is-pwd-a.sh cr:data-root cr:source cr:directory-of-datasets            cr:directory-of-versions` == "yes" ]]; then
   for next in `directories.sh`; do
      pushd $next > /dev/null
         # Recursive call to base case 'cr:conversion-cockpit'
         $0 $*
      popd > /dev/null
   done
elif [[ `is-pwd-a.sh              cr:source                                                             ` == "yes" ]]; then
   # TODO https://github.com/timrdf/csv2rdf4lod-automation/issues/311
   pushd dataset > /dev/null
      # Recursive call to base case 'cr:conversion-cockpit'
      $0 $*
   popd > /dev/null
elif [[ `is-pwd-a.sh                                                 cr:dataset                         ` == "yes" ]]; then
   pushd version > /dev/null
      # Recursive call to base case 'cr:conversion-cockpit'
      $0 $*
   popd > /dev/null
fi

if [ -e $TEMP ]; then
   rm -f $TEMP
fi
