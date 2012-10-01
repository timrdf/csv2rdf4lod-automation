#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-list-conversion-triggers.sh> ;
#3>    prov:wasRevisionOf    <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-retrieve.sh> ;
#3>    prov:wasAttributedTo  <../*e1.params.ttl manual/*e1.params.ttl> .
#
# Usage:
#
# [from directory, with files:]
# source/hub-healthdata-gov/food-recalls/version:
#
#    2012-May-08
#    PetFoodRecallProductsList2009.xls_ALL.csv.e1.params.ttl
#    PetFoodRecallProductsList2009.xls_Dogs,_Cats,_Horses.csv.e1.params.ttl
#    retrieve.sh
#
# cr-list-conversion-triggers.sh
# ...source/hub-healthdata-gov/food-recalls/version/2012-May-08/convert-food-recalls.sh
# [trigger IS listed because it exists]
#
#
# cr-list-conversion-triggers.sh --only-outdated
# [trigger is NOT listed b/c the conversion in automatic/ is newer than the eparams]
#
#
# touch 2012-May-08/manual/*e1.params.ttl
# cr-list-conversion-triggers.sh --only-outdated
# ...source/hub-healthdata-gov/food-recalls/version/2012-May-08/convert-food-recalls.sh
# [trigger IS listed b/c the eparam is newer]
#
#
# cr-list-conversion-triggers.sh --only-outdated --only-globally-enhanced
# [trigger is NOT listed b/c the local eparams are ignored and only the global eparams are checked]
#
#
# touch *e1.params.ttl
# cr-list-conversion-triggers.sh --only-outdated --only-globally-enhanced
# ...source/hub-healthdata-gov/food-recalls/version/2012-May-08/convert-food-recalls.sh
# [trigger IS listed b/c the global eparams are newer than the conversion output in automatic/]
#
#
# Note:
#    This script assumes that the conversion trigger exists.
#    If the conversion trigger does not exist, then it will not be found.
#    This script is NOT intended to setup conversion cockpits.
#    Use cr-retrieve.sh or other for that purpose.
#
# Tricks:
#    Delete all versions:
#    for sh in `cr-list-conversion-triggers.sh`; do rm -rf `dirname $sh`; done

see="https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $see"}

if [ "$1" == "--help" ]; then
   echo "usage: `basename $0` [--only-outdated] [--only-globally-enhanced]"
   echo
   echo "  --only-outdated          : Only list conversion triggers whose enhancement parameters are newer than its output."
   echo
   echo "  --only-globally-enhanced : Only list conversion triggers that have global enhancements specified."
   echo "                             (i.e., ../*e1.params.ttl and not manaul/*e1.params.ttl)"
   exit
fi

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:data-root cr:source cr:dataset cr:directory-of-versions cr:conversion-cockpit"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

if   [[ `is-pwd-a.sh cr:conversion-cockpit` == "yes" ]]; then

   if [ -e convert-`cr-dataset-id.sh`.sh ]; then
      should_list="true"
      if [ "$1" == "--only-outdated" ]; then
         eParams="../*e*.params.ttl manual/*e*.params.ttl" # Include global and local eparams.
         if [ "$2" == "--only-globally-enhanced" ]; then
            eParams="../*e*.params.ttl"                    # Use only global eparams.
            list=`ls $eParams 2> /dev/null`
            if [ ${#list} -eq 0 ]; then
               should_list="false"
            fi
         fi
         if [[ "$should_list" != "false" && ${#eParams} -gt 0 ]]; then
            newest_eparam="`ls -lt $eParams 2> /dev/null | grep -v "total" | grep -v "bin" | head -1 | awk '{print $NF}'`"
            if [ -e "$newest_eparam" ]; then
               newest_e_out="automatic/`find automatic -newer $newest_eparam -and -not -name "*params*" | head -1`"
               if [ "$newest_e_out" != "automatic/" ]; then # "nothing in automatic/ is newer"
                  should_list="false"
               fi
            fi
         else
            should_list="false"
         fi
      fi
      if [ "$should_list" == "true" ]; then
         echo `pwd`/convert-`cr-dataset-id.sh`.sh
      fi
   fi

else

   for possible in `find . -name "convert*.sh"`; do
      pushd `dirname $possible` > /dev/null
         $0 $* # Recursive call
      popd > /dev/null
   done

fi
