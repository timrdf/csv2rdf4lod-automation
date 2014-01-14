#!/bin/bash
#
#3> <> a conversion:RetrievalTrigger, conversion:Idempotent;
#3>    prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/dataset/cr-aggregate-dcat.sh>;
#3>    prov:wasDerivedFrom   <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/secondary/secondary/cr-aggregate-eparams.sh>;
#3>    rdfs:seeAlso          <https://github.com/timrdf/csv2rdf4lod-automation/wiki/Aggregating-subsets-of-converted-datasets> .

[ -n "`readlink $0`" ] && this=`readlink $0` || this=$0
HOME=$(cd ${this%/*/*} && echo ${PWD%/*})
export PATH=$PATH`$HOME/bin/util/cr-situate-paths.sh`
export CLASSPATH=$CLASSPATH`$HOME/bin/util/cr-situate-classpaths.sh`

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:bone"
if [ `is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

if [[ "$1" == "--help" ]]; then
   section='#aggregation-39-dataset-conversion-metadata-prov-o-dcterms-void'
   echo "usage: `basename $0` [-n] [version-identifier]"
   echo ""
   echo "Create a dataset from the aggregation of all csv2rdf4lod conversion parameter files."
   echo ""
   echo "               -n : perform dry run only; do not load named graph."
   echo "see https://github.com/timrdf/csv2rdf4lod-automation/wiki/Aggregating-subsets-of-converted-datasets$section"
   echo
   exit
fi

dryrun="false"
if [ "$1" == "-n" ]; then
   dryrun="true"
   dryrun.sh $dryrun beginning
   shift
fi

# "SDV" naming
if [[ -n "$CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID" ]]; then
   sourceID="$CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID"
elif [[ `is-pwd-a.sh 'cr:data-root'` == "yes" ]]; then
   section='#csv2rdf4lod_publish_our_source_id'
   see="https://github.com/timrdf/csv2rdf4lod-automation/wiki/Secondary-Derivative-Datasets$section"
   sourceID=${CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID:?"not set and ambiguous based on level in data root; see $see"}
else
   sourceID=`cr-source-id.sh`
fi
datasetID=`basename $this | sed -e 's/.sh$//'`
if [[ "$1" != "" ]]; then
   versionID="$1"
elif [[ `is-pwd-a.sh 'cr:conversion-cockpit'` == "yes" ]]; then
   versionID=`cr-version-id.sh`
else
   versionID=`date +%Y-%b-%d`
fi

pushd `cr-conversion-root.sh` &> /dev/null
   cockpit="$sourceID/$datasetID/version/$versionID"
   if [ "$dryrun" != "true" ]; then
      mkdir -p $cockpit/source $cockpit/automatic &> /dev/null
      rm -rf $cockpit/source/*                    &> /dev/null
   fi

   # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
   echo "Aggregating all DCAT access metadata in `pwd` into $cockpit/source/." >&2
   # from e.g. ./hub/countries/access.ttl to ./hub/countries/version/2013-Sep-06/access.ttl
   for dcat in `find . -mindepth 3 -maxdepth 5 -name "*dcat.ttl" -or -name "access.ttl"`; do
      echo ${dcat#./}
      sdv=$(cd `dirname $dcat` && cr-sdv.sh)
      if [ "$dryrun" != "true" ]; then
         ln $dcat $cockpit/source/$sdv.dcat.ttl
      fi
   done
   # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

   pushd $cockpit &> /dev/null
      echo
      echo aggregate-source-rdf.sh --link-as-latest automatic/meta.ttl source/* 
      if [ "$dryrun" != "true" ]; then
         cr-default-prefixes.sh --turtle                                     > automatic/meta.ttl
         echo "<`cr-dataset-uri.sh --uri`> a conversion:AggregateDataset ." >> automatic/meta.ttl
         cat automatic/meta.ttl | grep -v "@prefix"

         aggregate-source-rdf.sh --link-as-latest automatic/meta.ttl source/*
      fi
   popd &> /dev/null

popd &> /dev/null
dryrun.sh $dryrun ending
