#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-publish.sh>;
#3>    rdfs:seeAlso <https://github.com/timrdf/csv2rdf4lod-automation/wiki/Triggers#4-publication-triggers;
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
   echo "usage: `basename $0` [-n] [--[no-]compress] [--[no-]turtle] [--[no-]ntriples] [--[no-]rdfxml] [--idempotent]"
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

serialization_flags=''
while [[ "$1" == '--compress'    || "$1" == '--turtle'    || "$1" == '--ntriples'    || "$1" == '--rdfxml' || \
         "$1" == '--no-compress' || "$1" == '--no-turtle' || "$1" == '--no-ntriples' || "$1" == '--no-rdfxml' ]]; do
   serialization_flags="$serialization_flags $1" && shift
done

idempotent="whatever"
if [ "$1" == "--idempotent" ]; then
   idempotent="demanded"
   echo "INFO: `basename $0` only pulling idempotent publication triggers." >&2
   shift 
fi

if [[ `is-pwd-a.sh cr:conversion-cockpit` == 'yes' && -e "$1" ]]; then
   # A third need (the first two are handled below) is to publish non-RDF 
   # files such as zip and png. This came to head with locv.tw.
   # It's also used by provweb's side of IPAW pingback paper.
   # The publish trigger can be called below when in a conversion cockpit,
   # WITHOUT parameters, and then that trigger can call this script WITH 
   # parameters and it'll fall into this bit and then quit.

   echo "Creating publication trigger." >&2
   mkdir -p publish
   nfo_filehashes="publish/`cr-sdv.sh`.nfo.ttl"
   cr-default-prefixes.sh --turtle > $nfo_filehashes 
   valid_rdf_files=''
   # NOTE: If this portion doesn't overwrite publish/bin/publish.sh, 
   #       then the outdated version will be run below.
   while [ $# -gt 0 ]; do
      file="$1" && shift # For each file that we were asked to publish...
      if [[ -n "$CSV2RDF4LOD_CONVERT_DEBUG_LEVEL" ]]; then
         echo PUBLISHING $# more after $file
      fi
      if [[ -e "$file" ]]; then
         valid=`valid-rdf.sh $file`
         if [[ "$valid" == 'yes' ]]; then
            valid_rdf_files="$valid_rdf_files $file" # NOTE: file argument limit
         fi
         echo "$file (valid RDF: $valid)"
         cr-ln-to-www-root.sh $file # We now publish all files, even if they're RDF that we're aggregating.
         nfo-filehash.sh $file >> $nfo_filehashes
      else
         "WARNING: `basename $0` file does not exist, not publishing it: $file"
      fi
   done
   if [[ -n "$valid_rdf_files" ]]; then
      aggregate-source-rdf.sh $serialization_flags $valid_rdf_files $nfo_filehashes
   fi
   exit # If we don't bail here, it becomes an infinite loop.
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
      if [[ "$CSV2RDF4LOD_CONVERT_DEBUG_LEVEL" == 'fine' ]]; then
         echo "Going into ${trigger%publish/bin/publish.sh}"
      fi
      # The original need was to step into each conversion cockpit to 
      # invoke the extant publication trigger.
      pushd ${trigger%publish/bin/publish.sh} &> /dev/null
         if [[ `is-pwd-a.sh cr:conversion-cockpit` == "yes" ]]; then
            if [[ $idempotent == 'whatever' || $idempotent == 'demanded' && `cr-idempotent.sh publish/bin/publish.sh` == 'yes' ]]; then
               if [ "$dryrun" != "true" ]; then
                  publish/bin/publish.sh
               else
                  cr-pwd.sh
               fi
            else
               if [[ "$CSV2RDF4LOD_CONVERT_DEBUG_LEVEL" == 'fine' ]]; then
                  echo "Idempotency fail."
               fi
            fi
         else
            if [[ "$CSV2RDF4LOD_CONVERT_DEBUG_LEVEL" == 'fine' ]]; then
               echo "Not a conversion cockpit."
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
