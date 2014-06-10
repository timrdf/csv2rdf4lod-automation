#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-retrieve.sh>;
#3>    prov:wasRevisionOf    <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-publish-cockpit.sh>;
#3>    prov:alternateOf      <https://github.com/timrdf/prizms/blob/master/src/python/prov-pingback.py> .
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
#      source/dig-csail-mit-edu/tbl-foaf/access.ttl

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
ACCEPTABLE_PWDs="cr:data-root cr:source cr:dataset cr:directory-of-versions cr:conversion-cockpit"
if [ `$CSV2RDF4LOD_HOME/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   $CSV2RDF4LOD_HOME/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

w=''
if [[ "$1" == '-w' ]]; then
   w='-w'
   shift
fi

function write_access_metadata {
   DIST_URL="$1"
   #UUID=`$CSV2RDF4LOD_HOME/bin/util/resource-name.sh | sed 's/^_//' | awk '{print tolower($0)}'`
   UUID=`md5.sh -qs $DIST_URL`

   if [ ! -e access.ttl ]; then
      echo "@prefix rdfs:       <http://www.w3.org/2000/01/rdf-schema#> ."             > access.ttl
      echo "@prefix conversion: <http://purl.org/twc/vocab/conversion/> ."            >> access.ttl
      echo "@prefix dcat:       <http://www.w3.org/ns/dcat#> ."                       >> access.ttl
      echo "@prefix void:       <http://rdfs.org/ns/void#> ."                         >> access.ttl
      echo "@prefix nfo:        <http://www.semanticdesktop.org/ontologies/nfo/#> ."  >> access.ttl
      echo "@prefix doap:       <http://usefulinc.com/ns/doap#> ."                    >> access.ttl
      echo "@prefix prov:       <http://www.w3.org/ns/prov#> ."                       >> access.ttl
      echo "@prefix datafaqs:   <http://purl.org/twc/vocab/datafaqs#> ."              >> access.ttl
      echo "@prefix :           <$CSV2RDF4LOD_BASE_URI/id/> ."                        >> access.ttl
      echo "@base               <$CSV2RDF4LOD_BASE_URI/id/> ."                        >> access.ttl
   fi
   if [[ ! `grep $UUID access.ttl` ]]; then
      crDataset=`cr-dataset-uri.sh --uri`
      crDatasetMD5=`md5.sh -qs $crDataset`
      echo                                                                               >> access.ttl
      echo "<`cr-dataset-uri.sh --uri`>"                                                 >> access.ttl
      if [[ ! `grep $crDatasetMD5 access.ttl` ]]; then
         echo "   a void:Dataset, dcat:Dataset;"                                         >> access.ttl
         echo "   conversion:source_identifier  \"`cr-source-id.sh`\";"                  >> access.ttl
         echo "   conversion:dataset_identifier \"`cr-dataset-id.sh`\";"                 >> access.ttl
         echo "   conversion:identifier         \"$crDatasetMD5\";"                      >> access.ttl
      fi
      echo "   prov:wasDerivedFrom <distribution/$UUID>;"                                >> access.ttl
      echo "."                                                                           >> access.ttl
      echo                                                                               >> access.ttl
      echo "<distribution/$UUID>"                                                        >> access.ttl
      echo "   a dcat:Distribution;"                                                     >> access.ttl
      if [[ "$DIST_URL" =~ https://docs.google.com/spreadsheet* ]]; then
         echo "   a nfo:Spreadsheet;"                                                    >> access.ttl
      elif [[ "$DIST_URL" =~ .*.git ]]; then
         echo "   a doap:GitRepository;"                                                 >> access.ttl
      fi
      echo "   dcat:downloadURL <$DIST_URL>;"                                            >> access.ttl
      echo "."                                                                           >> access.ttl
      echo                                                                               >> access.ttl
      echo "<dataset/$UUID>"                                                             >> access.ttl
      echo "   a dcat:Dataset;"                                                          >> access.ttl
      echo "   dcat:distribution <distribution/$UUID>;"                                  >> access.ttl
      echo "."                                                                           >> access.ttl
   fi
   echo `cr-pwd.sh`/access.ttl >&2
}

if   [[ `is-pwd-a.sh cr:conversion-cockpit` == "yes" ]]; then

   #if [[ ! -e ../access.ttl && ! -e ../../access.ttl ]]; then
   #   source ../../../../csv2rdf4lod-source-me-for-*
   #   write_access_metadata "$1"
   #else
   #   echo "WARNING: not creating access metadata b/c a global access already exists."
   #fi

   while [ $# -gt 0 ]; do
      write_access_metadata "$1"
      shift
   done

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

   while [ $# -gt 0 ]; do
      write_access_metadata "$1"
      shift
   done

elif [[ `is-pwd-a.sh                        cr:directory-of-datasets                                    ` == "yes" ]]; then
   for next in `directories.sh`; do
      pushd $next > /dev/null
         $0 $* # Recursive call
      popd > /dev/null
   done
elif [[ `is-pwd-a.sh              cr:source                                                             ` == "yes" ]]; then
   if [ -d dataset ]; then
      # This would conform to the directory structure if 
      # we had included 'dataset' in the convention.
      # This is here in case we ever fully support it.
      pushd dataset > /dev/null
         $0 $* # Recursive call
      popd > /dev/null
   else
      dataset="$1"
      shift
      mkdir -p $dataset
      # Handle the original (3-year old) directory structure 
      # that does not include 'dataset' as a directory.
      pushd $dataset > /dev/null
         $0 $* # Recursive call
      popd > /dev/null
   fi
elif [[ `is-pwd-a.sh cr:data-root                                                                       ` == "yes" ]]; then

   datasetID="$1"
   accessURL="$2" 
   shift # Leave this in the arg stack for the recursive call.
   sourceID=`$CSV2RDF4LOD_HOME/bin/util/cr-source-id.sh $accessURL`

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
         echo "ERROR: `basename $0` could not determine source-id from $accessURL"
      fi
   else
      echo "ERROR: `basename $0` needs dataset identifier for $accessURL"
   fi
fi
