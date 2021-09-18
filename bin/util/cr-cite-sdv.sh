#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/cr-cite-sdv.sh> .
#3>    prov:wasDerivedFrom   <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/cr-sdv.sh> .
#
# Usage:
#
#   bash-3.2$ cr-pwd.sh
#   source/epa-gov/fips-codes/version/2009-Apr-10
#
#   bash-3.2$ cr-cite-sdv.sh ../../../../census.gov/people/version/2021-09-18
#
#   bash-3.2$ ls -lt source/
#   census.gov_people_2021-09-18.sdv ->  ../../../../census.gov/people/version/2021-09-18

if [ "$1" == "--help" ]; then
   echo "usage: `basename $0` [--slashes] [--fast] [--attribute-value]"
#   echo "  --slashes         : output with slash delimiters instead of dashes (must preced --fast)"
#   echo "  --fast            : use a faster technique to determine the 'sdv' value (e.g. .02 sec vs .7 sec)"
#   echo "  --attribute-value : output cr-source-id= etc. format"
   echo
   echo "try also:"
   echo "  cr-dataset-uri.sh --uri"
   exit
fi

#echo "sdv $CSV2RDF4LOD_BASE_URI" >&2
#if [ "$1" == "--attribute-value" ]; then
#   echo cr-base-uri=${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI} cr-source-id=`cr-source-id.sh` cr-dataset-id=`cr-dataset-id.sh` cr-version-id=`cr-version-id.sh`
#   exit
#elif [ "$1" == "--attribute-value--" ]; then
#   echo --cr-base-uri=${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI} --cr-source-id=`cr-source-id.sh` --cr-dataset-id=`cr-dataset-id.sh` --cr-version-id=`cr-version-id.sh`
#   exit
#fi

#delim="-"
#if [ "$1" == "--slashes" ]; then
#   delim="/"
#   shift
#fi

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

if [[ `is-pwd-a.sh cr:conversion-cockpit` == "yes" ]]; then
   # e.g. pwd: /srv/twc-healthdata/data/source/hub-healthdata-gov/food-recalls/version/2012-May-08
   # desired result: hub-healthdata-gov-food-recalls-2012-May-08

   while [[ $# -gt 0 ]]; do
      cockpit="$1" && shift
      if [[ -d "$cockpit" ]]; then
         ref=''
         pushd "$cockpit" 2>&1 > /dev/null
            if [[ `is-pwd-a.sh cr:conversion-cockpit` == "yes" ]]; then
               ref=`cr-sdv.sh`.sdv
            else
               echo "ERROR: was $cockpit was not a cr:conversion-cockpit"
            fi
         popd 2>&1 > /dev/null

         if [[ -n "$ref" ]]; then
            ln -sf "$cockpit" "source/$ref"
         else
            echo "nopeno"
         fi
      else
         echo "ERROR: $cockpit is not a computation cockpit"
      fi
   done

else 

   echo "must be in a cr:conversion-cockpit"
fi
