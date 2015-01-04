#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-page.sh>;
#3>    prov:wasRevisionOf    <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-dcat-retrieval-url.sh> .
#
# Environment variables needed:
#
#   CSV2RDF4LOD_HOME
#   CSV2RDF4LOD_BASE_URI
#
# Usage:
#
#   $cr-pwd-type.sh 
#      cr:data-root
#
#   $cr-dcat-retrieval-url.sh tbl-foaf http://dig.csail.mit.edu/2008/webdav/timbl/foaf.rdf
#      source/dig-csail-mit-edu/tbl-foaf/page.ttl

if [[ "$1" == "--help" || "$1" == "-h" || $# < 1 ]]; then
   echo
   echo "usage: `basename $0` [-w] [dataset-id] <distribution-url>"
   echo
   echo "  Create a file containing an RDF description of how to access the sitated dataset using <distribution-url>."
   echo
   echo "                -w : Avoid interactivity; do it."
   echo "        dataset-id : The dataset identifier for the dataset to create."
   #echo "  --skip-if-exists : If a version exists for the dataset, do not retrieve it."
   exit 1
fi

see='https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set'
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $see"}

see='https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set'
CSV2RDF4LOD_BASE_URI=${CSV2RDF4LOD_BASE_URI:?"not set; source csv2rdf4lod/source-me.sh or see $see"}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:source cr:data-root cr:dataset cr:directory-of-versions cr:conversion-cockpit"
if [ `$CSV2RDF4LOD_HOME/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   $CSV2RDF4LOD_HOME/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

w=''
if [[ "$1" == '-w' ]]; then
   w='-w'
   shift
fi

function write_page_metadata {
   DIST_URL="$1"
   UUID=`$CSV2RDF4LOD_HOME/bin/util/resource-name.sh | sed 's/^_//' | awk '{print tolower($0)}'`

   just_created_it='no'
   if [[ ! -e page.ttl ]]; then
      cr-default-prefixes.sh --turtle                                                  > page.ttl
      echo "@prefix :           <$CSV2RDF4LOD_BASE_URI/id/> ."                        >> page.ttl
      just_created_it='yes'
   fi
   echo                                                                               >> page.ttl
   echo "<$CSV2RDF4LOD_BASE_URI/source/`cr-source-id.sh`/dataset/`cr-dataset-id.sh`>" >> page.ttl
   if [[ "$just_created_it" == 'yes' ]]; then
      echo "   a void:Dataset, dcat:Dataset;"                                         >> page.ttl
      # TODO: type it to AbstractDataset, VersionedDataset, etc.
      echo "   conversion:source_identifier  \"`cr-source-id.sh`\";"                  >> page.ttl
      echo "   conversion:dataset_identifier \"`cr-dataset-id.sh`\";"                 >> page.ttl
   fi
   echo "   foaf:page <$DIST_URL>;"                                                   >> page.ttl
   echo "."                                                                           >> page.ttl
   echo `cr-pwd.sh`/page.ttl >&2
}

function write_source_agent_metadata {
   DIST_URL="$1"
   UUID=`$CSV2RDF4LOD_HOME/bin/util/resource-name.sh | sed 's/^_//' | awk '{print tolower($0)}'`

   just_created_it='no'
   if [[ ! -e page.ttl ]]; then
      cr-default-prefixes.sh --turtle                                                  > page.ttl
      echo "@prefix :           <$CSV2RDF4LOD_BASE_URI/id/> ."                        >> page.ttl
      just_created_it='yes'
   fi
   echo                                                                               >> page.ttl
   echo "<$CSV2RDF4LOD_BASE_URI/source/`cr-source-id.sh`>"                            >> page.ttl
   if [[ "$just_created_it" == 'yes' ]]; then
      echo "   a foaf:Agent, prov:Agent;"                                             >> page.ttl
      echo "   dcterms:identifier  \"`cr-source-id.sh`\";"                            >> page.ttl
   fi
   echo "   foaf:page <$DIST_URL>;"                                                   >> page.ttl
   echo "."                                                                           >> page.ttl
   echo `cr-pwd.sh`/page.ttl >&2
}

if   [[ `is-pwd-a.sh cr:conversion-cockpit` == "yes" ]]; then

   if [[ ! -e ../page.ttl && ! -e ../../page.ttl ]]; then
      source ../../../../csv2rdf4lod-source-me-for-*
      write_page_metadata "$1"
   else
      echo "WARNING: not creating page metadata b/c a global page already exists."
   fi

elif [[ `is-pwd-a.sh                                                 cr:dataset cr:directory-of-versions` == "yes" ]]; then

   # TODO: generalize this; https://github.com/timrdf/csv2rdf4lod-automation/issues/323
   if [ -e ../../csv2rdf4lod-source-me.sh ]; then
      # Include project-specific https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-environment-variables
      source ../../csv2rdf4lod-source-me.sh
   else
      see='https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-environment-variables-(considerations-for-a-distributed-workflow)'
      echo "#3> <> rdfs:seeAlso <$see> ." > ../../../../csv2rdf4lod-source-me.sh
   fi

   for sourceme in `find ../../ -name "csv2rdf4lod-source-me-for-*"`; do
      source $sourceme
   done
   for sourceme in `find ../../../ -name "csv2rdf4lod-source-me-for-*"`; do
      source $sourceme
   done

   write_page_metadata "$1"

elif [[ `is-pwd-a.sh                        cr:directory-of-datasets                                    ` == "yes" ]]; then
   for next in `directories.sh`; do
      pushd $next > /dev/null
         $0 $* # Recursive call
      popd > /dev/null
   done
elif [[ `is-pwd-a.sh              cr:source                                                             ` == "yes" ]]; then
   write_source_agent_metadata $1
   #if [ -d dataset ]; then
   #   # This would conform to the directory structure if 
   #   # we had included 'dataset' in the convention.
   #   # This is here in case we ever fully support it.
   #   pushd dataset > /dev/null
   #      $0 $* # Recursive call
   #   popd > /dev/null
   #else
   #   # Handle the original (3-year old) directory structure 
   #   # that does not include 'dataset' as a directory.
   #   for dataset in `cr-list-datasets.sh`; do
   #      pushd $dataset > /dev/null
   #         $0 $* # Recursive call
   #      popd > /dev/null
   #   done
   #fi
elif [[ `is-pwd-a.sh cr:data-root                                                                       ` == "yes" ]]; then

   datasetID="$1"
   pageURL="$2" 
   shift # Leave this in the arg stack for the recursive call.
   sourceID=`$CSV2RDF4LOD_HOME/bin/util/cr-source-id.sh $pageURL`

   if [[ -n "$datasetID" ]]; then
      if [[ -n "$sourceID" ]]; then
         if [[ ! -e "$sourceID/$datasetID" ]]; then
            if [[ "$w" == "-w" ]]; then
               mkdir -p $sourceID/$datasetID
            else
               read -p "Q: Make directory for source-id/dataset-id: \"$sourceID/$datasetID\" ? [y/n] " -u 1 make_it
               if [[ "$make_it" == [yY] ]]; then
                  mkdir -p $sourceID/$datasetID
               fi
            fi
         fi
         if [[ -d "$sourceID/$datasetID" ]]; then
            pushd $sourceID/$datasetID > /dev/null
               $0 $w $* # Recursive call
            popd > /dev/null
         fi
      else
         echo "ERROR: `basename $0` could not determine source-id from $pageURL"
      fi
   else
      echo "ERROR: `basename $0` needs dataset identifier for $pageURL"
   fi
fi
