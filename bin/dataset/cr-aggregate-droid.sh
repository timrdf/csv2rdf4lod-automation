#!/bin/bash
#
#3> <> a conversion:RetrievalTrigger, conversion:Idempotent;
#3>    prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/dataset/cr-aggregate-droid.sh>;
#3>    prov:wasDerivedFrom   <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/dataset/cr-aggregate-dcat.sh>;
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
   echo "Aggregating all DROID file metadata in `pwd` into $cockpit/source/." >&2
   $CSV2RDF4LOD_HOME/bin/util/cr-droid.sh --conversion-cockpit-sources
   for droid in `find . -mindepth 6 -maxdepth 6 -name cr-droid.ttl`; do
      echo $droid
      loc=`dirname $droid`
      loc=`dirname $loc`
      sdv=$(cd $loc && cr-sdv.sh) # Local file name in the aggregated source/ directory.

      # Files are referenced relatively in the turtle file, so 
      # moving it will lose the file it's talking about.
      # We need to set the @base in the file's new location.
      # e.g., "<Hospital_flatfiles.zip>" 
      #   in:
      #    "<Hospital_flatfiles.zip> dcterms:format <http://provenanceweb.org/formats/pronom/x-fmt/263> ."
      #   in:
      #     /srv/twc-healthdata/data/source/hub-healthdata-gov/hospital-compare/version/2012-Oct-10
      #   is:
      #     http://healthdata.tw.rpi.edu/source/hub-healthdata-gov/file/hospital-compare/version/2012-Oct-10/source/Hospital_flatfiles.zip 
      #
      # cr-dataset-uri.sh --uri | sed 's/\/dataset\//\/file\//' | awk '{print $0"/source/"}'
      # gives
      #     http://purl.org/twc/health/source/hub-healthdata-gov/file/hospital-compare/version/2012-Oct-10/source/
      url=$(cd $loc && cr-dataset-uri.sh --uri)
      base=`echo $url | sed 's/\/dataset\//\/file\//' | awk '{print "@base <"$0"/source/> ."}'`

      echo "   --> $sdv.ttl"
      if [ "$dryRun" != "true" ]; then
         echo $base  > $cockpit/source/$sdv.ttl
         echo       >> $cockpit/source/$sdv.ttl
         cat $droid >> $cockpit/source/$sdv.ttl
      fi
   done
   # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

   pushd $cockpit &> /dev/null
      echo
      echo aggregate-source-rdf.sh --link-as-latest automatic/meta.ttl source/* 
      if [ "$dryRun" != "true" ]; then
         cr-default-prefixes.sh --turtle                                     > automatic/meta.ttl
         echo "<`cr-dataset-uri.sh --uri`> a conversion:AggregateDataset ." >> automatic/meta.ttl
         cat automatic/meta.ttl | grep -v "@prefix"

         aggregate-source-rdf.sh --link-as-latest automatic/meta.ttl source/* 
      fi
   popd &> /dev/null

popd &> /dev/null
dryrun.sh $dryrun ending
