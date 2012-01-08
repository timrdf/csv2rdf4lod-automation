#!bin/bash
#
# This script is a one-off;
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/cr-load-endpoint-metadata.sh
# is the intended home after this script gets generalized.
#
# See also:
#     https://github.com/timrdf/csv2rdf4lod-automation/wiki/Aggregating-subsets-of-converted-datasets
#
# Environment variables used:
#
#     CSV2RDF4LOD_HOME
#     CSV2RDF4LOD_CONVERT_DATA_ROOT
#     CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT
#     CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT
#
#     (see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-environment-variables)

# NOTE: This is called by su's crontab.








PATH=$PATH:/usr/local/bin/                                        # to get rapper on
#source /work/data-gov/v2010/csv2rdf4lod/source-me-bulk-convert.sh # to set environment variables.
#source /work/data-gov/v2010/csv2rdf4lod/source-me-bulk-compress-convert.sh # to set environment variables.
#source /work/data-gov/v2010/csv2rdf4lod/config/csv2rdf4lod-source-me-logd.sh # replaces the above; now in svn. -lebot 2011 July 29
echo Using CSV2RDF4LOD_HOME $CSV2RDF4LOD_HOME


# Log the invocation of this script.
log_dir="${CSV2RDF4LOD_HOME}/log/`basename $0`"
if [ ! -d $log_dir ]; then
   mkdir -p $log_dir
   chmod a+w $log_dir
fi
log_file=$log_dir/`${CSV2RDF4LOD_HOME}/bin/util/dateInXSDDateTime.sh coin:slug`_`whoami`_pid$$.log
echo "start date time:"`${CSV2RDF4LOD_HOME}/bin/util/dateInXSDDateTime.sh` > $log_file
echo "user name: $SUDO_USER as "`whoami`                                  >> $log_file
echo "script:"$0                                                          >> $log_file
echo "working directory:"`pwd`                                            >> $log_file
echo $log_file
rm $log_dir/latest.log &> /dev/null
ln -s $log_file $log_dir/latest.log







# TODO: move this to a separate cron job. This is a TRIAL! -lebot 2011 July 29
#pushd /work/data-gov/v2010/csv2rdf4lod/data/source/data-gov/92/version &> /dev/null
#./2source.sh
#popd &> /dev/null
# TODO: move this to a separate cron job.





pushd $CSV2RDF4LOD_CONVERT_DATA_ROOT

   echo cr-publish-void-to-endpoint.sh
   echo "cr-publish-void-to-endpoint.sh   start date time:"`${CSV2RDF4LOD_HOME}/bin/util/dateInXSDDateTime.sh` >> $log_file
   datasetGraph=`cr-publish-void-to-endpoint.sh --target` 
   cr-publish-void-to-endpoint.sh $datasetGraph                    # http://logd.tw.rpi.edu/vocab/Dataset
   echo "cr-publish-void-to-endpoint.sh     end date time:"`${CSV2RDF4LOD_HOME}/bin/util/dateInXSDDateTime.sh` >> $log_file

   echo cr-publish-sameas-to-endpoint.sh
   echo "cr-publish-sameas-to-endpoint.sh start date time:"`${CSV2RDF4LOD_HOME}/bin/util/dateInXSDDateTime.sh` >> $log_file
   sameAsDatasetGraph=`cr-publish-sameas-to-endpoint.sh --target` 
   cr-publish-sameas-to-endpoint.sh $sameAsDatasetGraph            # http://purl.org/twc/vocab/conversion/SameAsDataset
   echo "cr-publish-sameas-to-endpoint.sh   end date time:"`${CSV2RDF4LOD_HOME}/bin/util/dateInXSDDateTime.sh` >> $log_file

   echo cr-publish-params-to-endpoint.sh
   echo "cr-publish-params-to-endpoint.sh start date time:"`${CSV2RDF4LOD_HOME}/bin/util/dateInXSDDateTime.sh` >> $log_file
   paramsDatasetGraph=`cr-publish-params-to-endpoint.sh --target`
   cr-publish-params-to-endpoint.sh $paramsDatasetGraph            # http://purl.org/twc/vocab/conversion/ConversionProcess
   echo "cr-publish-params-to-endpoint.sh   end date time:"`${CSV2RDF4LOD_HOME}/bin/util/dateInXSDDateTime.sh` >> $log_file

   # Populate the MetaDataset named graph.
# This is done separately now. lebot 2012-Jan-08
#   metaDatasetGraph=`$CSV2RDF4LOD_HOME/bin/util/cr-load-endpoint-metadataset.sh --target`      # http://purl.org/twc/vocab/conversion/MetaDataset
#   echo "./load-endpoint-metadataset.sh   start date time:"`${CSV2RDF4LOD_HOME}/bin/util/dateInXSDDateTime.sh` >> $log_file
#   $assudo ./load-endpoint-metadataset.sh -w -ng $metaDatasetGraph
#   echo "./load-endpoint-metadataset.sh     end date time:"`${CSV2RDF4LOD_HOME}/bin/util/dateInXSDDateTime.sh` >> $log_file
popd

pushd ${CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT:-"/var/www/html/logd.tw.rpi.edu"}/query 
   assudo="sudo"
   if [ `whoami` == "root" ]; then
      assudo=""
   fi

   asOf=`dateInXSDDateTime.sh`
   echo $datasetGraph $asOf
   echo $asOf                                                                                                          > results/dataset-as-of.txt
   echo "<$datasetGraph> <http://purl.org/dc/terms/modified> \"$asOf\"^^<http://www.w3.org/2001/XMLSchema#dateTime> ." > results/dataset-as-of.nt
   $assudo ${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vload nt results/dataset-as-of.nt        $datasetGraph

   echo $sameAsDatasetGraph $asOf
   echo $asOf                                                                                                                > results/dataset-sameas-as-of.txt
   echo "<$sameAsDatasetGraph> <http://purl.org/dc/terms/modified> \"$asOf\"^^<http://www.w3.org/2001/XMLSchema#dateTime> ." > results/dataset-sameas-as-of.nt
   $assudo ${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vload nt results/dataset-sameas-as-of.nt $sameAsDatasetGraph

   echo $paramsDatasetGraph $asOf
   echo $asOf                                                                                                                > results/dataset-params-as-of.txt
   echo "<$paramsDatasetGraph> <http://purl.org/dc/terms/modified> \"$asOf\"^^<http://www.w3.org/2001/XMLSchema#dateTime> ." > results/dataset-params-as-of.nt
   $assudo ${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vload nt results/dataset-params-as-of.nt $paramsDatasetGraph

   #
   # Cache the dataset summary SPARQL queries
   #
   echo "cache-queries.sh start date time:"`${CSV2RDF4LOD_HOME}/bin/util/dateInXSDDateTime.sh` >> $log_file
   $assudo cache-queries.sh ${CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT:-"http://logd.tw.rpi.edu/sparql"} -o sparql gvds xml csv -q logd-stat-*.sparql
   # -o sparql gvds xml
   echo "cache-queries.sh end date time:"`${CSV2RDF4LOD_HOME}/bin/util/dateInXSDDateTime.sh` >> $log_file

   # For grabbing from the stats web page using php's include():
   for results in `find results -name "*.sparql.csv"`; do 
      perl $CSV2RDF4LOD_HOME/bin/util/sparql-csv2plain.pl $results
   done
popd

$assudo ${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vcheckpoint

echo "end date time:"`${CSV2RDF4LOD_HOME}/bin/util/dateInXSDDateTime.sh` >> $log_file
