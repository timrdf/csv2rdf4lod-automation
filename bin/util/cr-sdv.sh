#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/cr-sdv.sh> .

if [ "$1" == "--help" ]; then
   echo "usage: `basename $0` [--fast]"
   echo "  --fast : use a faster technique to determine the 'sdv' value"
   exit
fi

if [ "$1" != '--fast' ]; then

   # Backward compatibility

   sourceID=`cr-source-id.sh`
   datasetID=`cr-dataset-id.sh`
   versionID=`cr-version-id.sh`

   if [ ${#versionID} -gt 0 ]; then
      echo `cr-source-id.sh`-`cr-dataset-id.sh`-`cr-version-id.sh`
   elif [ ${#datasetID} -gt 0 ]; then
      echo `cr-source-id.sh`-`cr-dataset-id.sh`
   elif [ ${#sourceID} -gt 0 ]; then
      echo `cr-source-id.sh`
   fi

else

   # Use cr-pwd.sh to determine sdv faster.
   # The slow way can take up to 3 seconds, while cr-pwd.sh takes 0.25 seconds.
   # is-pwd-a.sh takes another 0.25 seconds, so we'll skip the error checking since this is a core utility.

   CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $see"}

   # cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
   #ACCEPTABLE_PWDs="cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit"
   #if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   #   echo `pwd` `cr-pwd.sh` `cr-pwd-type.sh` `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs`
   #   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   #   exit 1
   #fi

   #TEMP="_"`basename $0``date +%s`_$$.tmp

   if [[ `is-pwd-a.sh cr:conversion-cockpit` == "yes" ]]; then

      # e.g. pwd: /srv/twc-healthdata/data/source/hub-healthdata-gov/food-recalls/version/2012-May-08
      # desired result: hub-healthdata-gov-food-recalls-2012-May-08

      pwd | awk -F/ '{print $(NF-3)"-"$(NF-2)"-"$NF}' # Will break on https://github.com/timrdf/csv2rdf4lod-automation/issues/311

   elif [[ `is-pwd-a.sh                                                            cr:directory-of-versions` == "yes" ]]; then
      
      # e.g. pwd: /srv/twc-healthdata/data/source/hub-healthdata-gov/food-recalls/version
      # desired output: hub-healthdata-gov-food-recalls

      pwd | awk -F/ '{print $(NF-2)"-"$(NF-1)}' # Will break on https://github.com/timrdf/csv2rdf4lod-automation/issues/311

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

   #if [ -e $TEMP ]; then
   #   rm -f $TEMP
   #fi

fi
