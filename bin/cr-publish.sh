#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-publish.sh>;
#3> .
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

if [[ "$1" == "--help" ]]; then
   echo "usage: `basename $0` [-n] [--idempotent]"
   echo ""
   echo "  Run each conversion cockpit's publish/bin/publish.sh"
   echo "    Processing is controlled by CSV2RDF4LOD_ environment variables in the usual way."
   echo ""
   echo "             -n: dry run; do not actually run scripts."
   echo "   --idempotent: only run idempotent publication triggers."
   echo ""
   echo "See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Triggers#4-publication-triggers"
   exit 1
fi

see="https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $see"}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:data-root cr:source cr:dataset cr:directory-of-versions cr:conversion-cockpit"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

dryrun="false"
if [ "$1" == "-n" ]; then
   dryrun="true"
   dryrun.sh $dryrun beginning
   shift 
fi

idempotent="whatever"
if [ "$1" == "--idempotent" ]; then
   idempotent="demanded"
   echo "INFO: `basename $0` only pulling idempotent publication triggers." >&2
   shift 
fi

# Additional functionality for custom publication triggers:
#   https://github.com/timrdf/csv2rdf4lod-automation/wiki/Triggers#4-publication-triggers

bottom='7' # cr:data-root: ./git2prov-org/github_tetherless-world_opendap/version/2013-Dec-21/publish/bin/publish.sh
if [[ `cr-pwd-type.sh` == 'cr:source' ]]; then
   bottom='6'
elif [[ `cr-pwd-type.sh` == 'cr:dataset' ]]; then
   bottom='5'
elif [[ `cr-pwd-type.sh` == 'cr:directory-of-versions' ]]; then
   bottom='4'
elif [[ `cr-pwd-type.sh` == 'cr:conversion-cockpit' ]]; then
   bottom='3'
fi

for trigger in `find . -maxdepth $bottom -name "publish.sh"`; do 

   if [[ "$CSV2RDF4LOD_CONVERT_DEBUG_LEVEL" == 'fine' ]]; then
      echo $trigger
      echo "${trigger%publish/bin/publish.sh} ?(!=) $trigger"
   fi

   if [[ "${trigger%publish/bin/publish.sh}" != $trigger ]]; then
      # The original need was to step into each conversion cockpit to 
      # invoke the extant publication trigger.
      pushd ${trigger%publish/bin/publish.sh} &> /dev/null
         if [[ `is-pwd-a.sh cr:conversion-cockpit` == "yes" ]]; then
            if [[ $idempotent == 'whatever' || $idempotent == 'demanded' && `cr-idempotent.sh publish.sh` == 'yes' ]]; then
               if [ "$dryrun" != "true" ]; then
                  publish/bin/publish.sh
               else
                  cr-pwd.sh
               fi
            fi
         fi
      popd &> /dev/null
   else
      # The newer need is to handle custom publication triggers anywhere
      # within the dataset abstraction hierarchy.
      # e.g. https://github.com/tetherless-world/opendap/blob/master/data/source/us/opendap-prov/version/retrieve.sh#L77
      #      for https://github.com/tetherless-world/opendap/wiki/OPeNDAP-Provenance
      if [[ $idempotent == 'whatever' || $idempotent == 'demanded' && `cr-idempotent.sh $trigger` == 'yes' ]]; then
         pushd `dirname $trigger` &> /dev/null
            if [ "$dryrun" != "true" ]; then
               chmod +x `basename $trigger`
               ./`basename $trigger`
            else
               cr-pwd.sh
            fi
         popd &> /dev/null
      fi
   fi
done

dryrun.sh $dryrun ending
