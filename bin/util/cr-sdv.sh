#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/cr-sdv.sh> .
#
# Usage:
#
#   bash-3.2$ cr-pwd.sh 
#   source/epa-gov/fips-codes/version/2009-Apr-10
#
#   bash-3.2$ cr-sdv.sh
#   epa-gov-fips-codes-2009-Apr-10
#
#   bash-3.2$ cr-sdv.sh --slashes
#   epa-gov/fips-codes/2009-Apr-10

if [ "$1" == "--help" ]; then
   echo "usage: `basename $0` [--slashes] [--fast] [--attribute-value]"
   echo "  --slashes         : output with slash delimiters instead of dashes (must preced --fast)"
   echo "  --fast            : use a faster technique to determine the 'sdv' value (e.g. .02 sec vs .7 sec)"
   echo "  --attribute-value : output cr-source-id= etc. format"
   echo
   echo "try also:"
   echo "  cr-dataset-uri.sh --uri"
   exit
fi

#echo "sdv $CSV2RDF4LOD_BASE_URI" >&2
if [ "$1" == "--attribute-value" ]; then
   echo cr-base-uri=${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI} cr-source-id=`cr-source-id.sh` cr-dataset-id=`cr-dataset-id.sh` cr-version-id=`cr-version-id.sh`
   exit
elif [ "$1" == "--attribute-value--" ]; then
   echo --cr-base-uri=${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI} --cr-source-id=`cr-source-id.sh` --cr-dataset-id=`cr-dataset-id.sh` --cr-version-id=`cr-version-id.sh`
   exit
fi

delim="-"
if [ "$1" == "--slashes" ]; then
   delim="/"
   shift
fi

if [ "$1" != '--fast' ]; then

   # Backward compatibility

   sourceID=`cr-source-id.sh`
   datasetID=`cr-dataset-id.sh`
   versionID=`cr-version-id.sh`

   if [ ${#versionID} -gt 0 ]; then
      echo `cr-source-id.sh`$delim`cr-dataset-id.sh`$delim`cr-version-id.sh`
   elif [ ${#datasetID} -gt 0 ]; then
      echo `cr-source-id.sh`$delim`cr-dataset-id.sh`
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

   if [[                                                                 `is-pwd-a.sh cr:conversion-cockpit` == "yes" ]]; then

      # e.g. pwd: /srv/twc-healthdata/data/source/hub-healthdata-gov/food-recalls/version/2012-May-08
      # desired result: hub-healthdata-gov-food-recalls-2012-May-08

      pwd | awk -F/  -v delim=$delim '{print $(NF-3)""delim""$(NF-2)""delim""$NF}' # Will break on https://github.com/timrdf/csv2rdf4lod-automation/issues/311

   elif [[ `is-pwd-a.sh                                                            cr:directory-of-versions` == "yes" ]]; then
      
      # e.g. pwd: /srv/twc-healthdata/data/source/hub-healthdata-gov/food-recalls/version
      # desired output: hub-healthdata-gov-food-recalls

      pwd | awk -F/  -v delim=$delim '{print $(NF-2)""delim""$(NF-1)}' # Will break on https://github.com/timrdf/csv2rdf4lod-automation/issues/311

   elif [[ `is-pwd-a.sh                                                 cr:dataset                         ` == "yes" ]]; then
     
      # e.g. pwd: /srv/twc-healthdata/data/source/hub-healthdata-gov/food-recalls
      # desired output: hub-healthdata-gov-food-recalls
 
      pwd | awk -F/  -v delim=$delim '{print $(NF-1)""delim""$NF}' # Will break on https://github.com/timrdf/csv2rdf4lod-automation/issues/311

   elif [[ `is-pwd-a.sh                        cr:directory-of-datasets                                    ` == "yes" ]]; then
      
      echo `basename $0`#todo
 
   elif [[ `is-pwd-a.sh              cr:source                                                             ` == "yes" ]]; then

      # e.g. pwd: /srv/twc-healthdata/data/source/hub-healthdata-gov
      # desired output: hub-healthdata-gov
 
      pwd | awk -F/ '{print $NF}' # Will break on https://github.com/timrdf/csv2rdf4lod-automation/issues/311

   elif [[ `is-pwd-a.sh cr:data-root                                                                       ` == "yes" ]]; then

      echo `basename $0`#todo

   fi
fi
