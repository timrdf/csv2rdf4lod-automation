#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/cr-full-dump.sh>;
#3>   prov:wasDerivedFrom <cr-publish-droid-to-endpoint.sh> .
#
# Gather all versioned dataset dump files into one enormous dump file.
# This is highly redundant, but can be helpful for those that "just want the data"
# and don't want to crawl the VoID dataDumps to get it.

see="https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $see"}

see="https://github.com/timrdf/csv2rdf4lod-automation/wiki/Aggregating-subsets-of-converted-datasets"
CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID=${CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID:?"not set; see $see"}

see="https://github.com/timrdf/csv2rdf4lod-automation/wiki/Aggregating-subsets-of-converted-datasets"
CSV2RDF4LOD_BASE_URI=${CSV2RDF4LOD_BASE_URI:?"not set; see $see"}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:data-root"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

TEMP="_"`basename $0``date +%s`_$$.tmp

sourceID=$CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID
datasetID=`basename $0 | sed 's/.sh$//'`
versionID='latest' # Doing it every day is a waste of space for this use case. `date +%Y-%b-%d`

cockpit="$sourceID/$datasetID/version/$versionID"
dumpFileLocal=`echo $CSV2RDF4LOD_BASE_URI | perl -pi -e 's|http://||;s/\./-/g;s|/|-|g'`.nt.gz

if [[ "$1" == "--help" ]]; then
   echo "usage: `basename $0` [--target] [-n]"
   echo ""
   echo "  Gather all versioned dataset dump files into one enormous dump file."
   echo "    archive them into a versioned dataset 'latest'"
   echo ""
   echo "         --target : return the dump file location, then quit."
   echo "               -n : perform dry run only; do not load named graph."
   echo
   exit 1
fi

if [ "$1" == "--target" ]; then
   # a conversion:VersionedDataset:
   # e.g. http://purl.org/twc/health/source/tw-rpi-edu/dataset/cr-publish-dcat-to-endpoint/version/2012-Sep-07
   echo $cockpit/publish/$dumpFileLocal
   exit 0
fi

dryRun="false"
if [ "$1" == "-n" ]; then
   dryRun="true"
   dryrun.sh $dryrun beginning
   shift
fi

if [ ! -d $cockpit/source ]; then
   mkdir -p $cockpit/source
fi
rm -rf $cockpit/source/*

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
for publishDir in `find . -mindepth 5 -maxdepth 5 -type d -name publish`; do
   echo $publishDir
   publishDir=`dirname $publishDir`
   echo $publishDir
   pushd $publishDir &> /dev/null
      ls publish
   popd &> /dev/null
   echo
done

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# hub-healthdata-gov/food-recalls/version/2012-May-08/publish/hub-healthdata-gov-food-recalls-2012-May-08.ttl.gz
