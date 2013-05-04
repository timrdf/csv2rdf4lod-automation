#!/bin/bash
# <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/cr-latest-logs.sh> .
#

see='https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set'
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $see"}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:data-root cr:dataset cr:source cr:directory-of-versions cr:conversion-cockpit"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

if [[ `is-pwd-a.sh cr:conversion-cockpit` == "yes" ]]; then

   if [ -e doc/logs/conversion-trigger-last-pulled ]; then
      find doc/logs -type f -newer doc/logs/conversion-trigger-last-pulled
   else
      ls -lt doc/logs 2> /dev/null | grep -v "total" | head -1 | awk '{print "doc/logs/"$NF}'
   fi

elif [[ `is-pwd-a.sh cr:directory-of-versions` == "yes" ]]; then
   for next in `cr-list-versions.sh | tail -1`; do
      pushd $next > /dev/null
         # Recursive call to base case 'cr:conversion-cockpit'
         echo $next/`$0 $*`
      popd > /dev/null
   done
elif [[ `is-pwd-a.sh cr:dataset` == "yes" ]]; then
   if [ -d version ]; then
      pushd version > /dev/null
         # Recursive call to base case 'cr:conversion-cockpit'
         echo version/`$0 $*`
      popd > /dev/null
   fi
elif [[ `is-pwd-a.sh cr:source` == "yes" ]]; then
   if [ -d cr-cron ]; then
      pushd cr-cron > /dev/null
         # Recursive call to base case 'cr:conversion-cockpit'
         echo cr-cron/`$0 $*`
      popd > /dev/null
   fi
elif [[ `is-pwd-a.sh cr:data-root cr:directory-of-datasets` == "yes" ]]; then
   if [[ -n "$CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID" && -d $CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID ]]; then
      pushd $CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID > /dev/null
         # Recursive call to base case 'cr:conversion-cockpit'
         echo $CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID/`$0 $*`
      popd > /dev/null
   fi
elif [[ `is-pwd-a.sh              cr:source                                                             ` == "yes" ]]; then
   # TODO
   pushd dataset > /dev/null
      # Recursive call to base case 'cr:conversion-cockpit'
      $0 $*
   popd > /dev/null
fi
