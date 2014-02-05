#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-pingback.sh>;
#3>    prov:wasDerivedFrom   <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-publish-droid-to-endpoint.sh> .
#
# See also:
#    https://github.com/timrdf/csv2rdf4lod-automation/wiki/Aggregating-subsets-of-converted-datasets
#
# Environment variables used:
#
#    CSV2RDF4LOD_HOME                  - to access the scripts.
#    CSV2RDF4LOD_BASE_URI              - 
#    CSV2RDF4LOD_BASE_URI_OVERRIDE     - can override the above.
#    CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID - to know which source-id this dataset should be placed within.
#    CSV2RDF4LOD_PUBLISH_DATAHUB_METADATA_OUR_BUBBLE_ID - to know which dataset to update on http://datahub.io/dataset/???
#
#    (see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-environment-variables)
#
# Usage:
#
# Example usage:
# 

HOME=$(cd ${0%/*} && echo ${PWD%/*})
export PATH=$PATH`$HOME/bin/util/cr-situate-paths.sh`
export CLASSPATH=$CLASSPATH`$HOME/bin/util/cr-situate-classpaths.sh`
opt=${HOME%/*}
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?$HOME}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:data-root cr:source"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

if [[ -z "$CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID" && \
      `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh cr:source` == "yes" ]]; then
   export CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID=`cr-source-id.sh`
fi

see="https://github.com/timrdf/csv2rdf4lod-automation/wiki/Aggregating-subsets-of-converted-datasets"
CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID=${CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID:?"not set; see $see"}

TEMP="_"`basename $0``date +%s`_$$.tmp

sourceID=$CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID
datasetID=`basename $0 | sed 's/.sh$//'`
versionID=`date +%Y-%b-%d`

graphName=${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}/source/$sourceID/dataset/$datasetID/version/$versionID

if [[ "$1" == "--help" ]]; then
   echo "usage: `basename $0` [--target] [-n] [--clear-graph] [--force] [named_graph_URI | cr:auto | .]"
   echo ""
   echo "  Find all metadata Turtle files in any conversion cockpit, "
   echo "    archive them into a new versioned dataset, and "
   echo "      load it into a virtuoso sparql endpoint."
   echo ""
   echo "         --target : return the name of graph that will be loaded; then quit."
   echo "               -n : perform dry run only; do not load named graph."
   echo "    --clear-graph : clear the named graph."
   echo "          --force : send to datahub.io regardless of the 7-day throttle."
   echo
   echo "  named_graph_URI : use graph name given"
   echo "          cr:auto : use named graph $graphName"
   echo "                . : print to stdout"
   exit 1
fi

if [ "$1" == "--target" ]; then
   # a conversion:VersionedDataset:
   # e.g. http://purl.org/twc/health/source/tw-rpi-edu/dataset/cr-publish-tic-to-endpoint/version/2012-Sep-07
   echo $graphName
   exit 0
fi

dryRun="false"
if [ "$1" == "-n" ]; then
   dryRun="true"
   dryrun.sh $dryrun beginning
   shift 
fi

force="false"
if [ "$1" == "--force" ]; then
   force="true"
   shift
fi

if [[ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh cr:source` == "yes" ]]; then
   pushd .. &> /dev/null
fi

cockpit="$sourceID/$datasetID/version/$versionID"
mkdir -p $sourceID/$datasetID

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
echo "$cockpit/source/void.rdf <- ${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}/void"

within_last_week=`find $sourceID/$datasetID -mindepth 4 -name void.rdf -mtime -6 | tail -1`
if [[ -z "$within_last_week" || "$force" == "true" ]]; then
   mkdir -p $cockpit/source
   rm -rf   $cockpit/source/*
   mkdir -p $cockpit/automatic

   if [[ -n "$CSV2RDF4LOD_PUBLISH_DATAHUB_METADATA_OUR_BUBBLE_ID" ]]; then
      cr-default-prefixes.sh --turtle                                                        > $cockpit/automatic/ckan-dataset.ttl
      echo "<${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}/void>"                 >> $cockpit/automatic/ckan-dataset.ttl
      echo "   a datafaqs:CKANDataset;"                                                     >> $cockpit/automatic/ckan-dataset.ttl
      echo "   dcterms:identifier \"$CSV2RDF4LOD_PUBLISH_DATAHUB_METADATA_OUR_BUBBLE_ID\";" >> $cockpit/automatic/ckan-dataset.ttl
      echo "."                                                                              >> $cockpit/automatic/ckan-dataset.ttl
   fi

   curl -sH "Accept: application/rdf+xml" -L ${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}/void > $cockpit/source/void.rdf
   rdf2ttl.sh $cockpit/source/void.rdf $cockpit/automatic/ckan-dataset.ttl > $cockpit/automatic/void.ttl
   if [[ -e $opt/DataFAQs/services/sadi/ckan/add-metadata.py ]]; then
      echo "http://datahub.io/dataset/$CSV2RDF4LOD_PUBLISH_DATAHUB_METADATA_OUR_BUBBLE_ID <-(add-metadata.py)- $cockpit/automatic/void.ttl"
      mime=`guess-syntax.sh --inspect $cockpit/automatic/void.ttl mime`
       ext=`guess-syntax.sh --tell find $mime`
      echo "add-metadata.py's input:"
      echo "  automatic/void.ttl valid:  `valid-rdf.sh -v $cockpit/automatic/void.ttl`"
      echo "  automatic/void.ttl format: $mime"
      echo "  automatic/void.ttl size:   `void-triples.sh $cockpit/automatic/void.ttl`"
      python $opt/DataFAQs/services/sadi/ckan/add-metadata.py $cockpit/automatic/void.ttl $mime > $cockpit/source/response.$ext
      echo "add-metadata.py's output:"
      echo "  source/response.$ext valid: `valid-rdf.sh -v $cockpit/source/response.$ext`"
      echo "  source/response.$ext size:  `void-triples.sh $cockpit/source/response.$ext`"
      cat $cockpit/source/response.$ext
      # @prefix datafaqs: <http://purl.org/twc/vocab/datafaqs#> .
      # @prefix dcterms:  <http://purl.org/dc/terms/> .
      # @prefix rdfs:     <http://www.w3.org/2000/01/rdf-schema#> .
      # 
      # <http://locv.tw.rpi.edu/void> a datafaqs:ModifiedCKANDataset;
      #     dcterms:modified "2014-02-05T18:03:33.148938";
      #     rdfs:seeAlso <http://datahub.io/dataset/locv> .
      # TODO: decide if we shold publish anything about what we did.
      #pushd $cockpit
      #   aggregate-source-rdf.sh automatic/ckan-dataset.ttl source/response.$ext
      #popd
   else
      echo "ERROR: `basename $0` could not find $opt/DataFAQs/services/sadi/ckan/add-metadata.py"
   fi
else
   echo "INFO: `basename $0` skipping push to datahub.io b/c has been done in the last week."
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

dryrun.sh $dryrun ending
