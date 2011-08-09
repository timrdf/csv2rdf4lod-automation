#!/bin/bash
#
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/cr-virtuoso-load-metadata.sh
#
# See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Aggregating-subsets-of-converted-datasets

# TODO: When running cron as root, need to make sure all vars are set: source /work/data-gov/v2010/csv2rdf4lod/config/csv2rdf4lod-source-me-logd.sh # replaces the above; now in svn. -lebot 2011 July 29

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}
CSV2RDF4LOD_CONVERT_DATA_ROOT=${CSV2RDF4LOD_CONVERT_DATA_ROOT:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}
CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT=${CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}
CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT=${CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}
if [ ! `which rapper` ]; then
   echo "need rapper on path."
   exit 1
fi

sudo="sudo"
if [ `whoami` == "root" ]; then
   sudo=""
fi

# Log the invocation of this script.
log_dir="${CSV2RDF4LOD_HOME}/log/`basename $0`"
if [ ! -d $log_dir ]; then
   $sudo mkdir -p $log_dir
   $sudo chmod a+w $log_dir
fi
log_file=$log_dir/`${CSV2RDF4LOD_HOME}/bin/util/dateInXSDDateTime.sh coin:slug`_`whoami`_pid$$.log
echo "start date time:"`${CSV2RDF4LOD_HOME}/bin/util/dateInXSDDateTime.sh` > $log_file
echo "user name: $SUDO_USER as "`whoami`                                  >> $log_file
echo "script:"$0                                                          >> $log_file
echo "working directory:"`pwd`                                            >> $log_file
echo $log_file
rm $log_dir/latest.log &> /dev/null
ln -s $log_file $log_dir/latest.log


if [ ! -d "${CSV2RDF4LOD_CONVERT_DATA_ROOT}" ]; then
   echo "[WARNING] CSV2RDF4LOD_CONVERT_DATA_ROOT: $CSV2RDF4LOD_CONVERT_DATA_ROOT does not exist; cannot load metadata."
   exit 1
fi
pushd ${CSV2RDF4LOD_CONVERT_DATA_ROOT}

   echo "cr-publish-void-to-endpoint.sh start date time:"`${CSV2RDF4LOD_HOME}/bin/util/dateInXSDDateTime.sh`   | tee -a $log_file
         datasetGraph=`cr-publish-void-to-endpoint.sh   -n auto 2>&1 | awk '/Will populate into/{print $7}'`
   cr-publish-void-to-endpoint.sh   auto # http://logd.tw.rpi.edu/vocab/Dataset
   echo "cr-publish-void-to-endpoint.sh end date time:"`${CSV2RDF4LOD_HOME}/bin/util/dateInXSDDateTime.sh`     | tee -a $log_file

   #echo "cr-publish-sameas-to-endpoint.sh start date time:"`${CSV2RDF4LOD_HOME}/bin/util/dateInXSDDateTime.sh` | tee -a $log_file
   #sameAsDatasetGraph=`cr-publish-sameas-to-endpoint.sh -n auto 2>&1 | awk '/Will populate into/{print $7}'`
   #cr-publish-sameas-to-endpoint.sh auto # http://purl.org/twc/vocab/conversion/SameAsDataset
   #echo "cr-publish-sameas-to-endpoint.sh end date time:"`${CSV2RDF4LOD_HOME}/bin/util/dateInXSDDateTime.sh`   | tee -a $log_file

   echo "cr-publish-params-to-endpoint.sh start date time:"`${CSV2RDF4LOD_HOME}/bin/util/dateInXSDDateTime.sh` | tee -a $log_file
   paramsDatasetGraph=`cr-publish-params-to-endpoint.sh -n auto 2>&1 | awk '/Will populate into/{print $7}'`
   cr-publish-params-to-endpoint.sh auto # http://purl.org/twc/vocab/conversion/ConversionProcess
   echo "cr-publish-params-to-endpoint.sh end date time:"`${CSV2RDF4LOD_HOME}/bin/util/dateInXSDDateTime.sh`   | tee -a $log_file

popd


if [ ! -d "${CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT}" ]; then 
   echo "[WARNING] CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT: $CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT does not exist; cannot cache queries."
   exit 1
fi
if [ ! -d "${CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT}/query/results" ]; then 
   $sudo mkdir -p ${CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT}/query/results
fi
pushd ${CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT}/query 

   asOf=`dateInXSDDateTime.sh`
   echo
   echo "--- $datasetGraph $asOf"
   $sudo echo $asOf                                                                                                                > results/dataset-as-of.txt
   $sudo echo "<$datasetGraph>       <http://purl.org/dc/terms/modified> \"$asOf\"^^<http://www.w3.org/2001/XMLSchema#dateTime> ." > results/dataset-as-of.nt
   # @deprecated: $sudo /opt/virtuoso/scripts/vload nt results/dataset-as-of.nt        $datasetGraph
   ${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vload nt results/dataset-as-of.nt        $datasetGraph

   echo
   echo "--- $sameAsDatasetGraph $asOf"
   $sudo echo $asOf                                                                                                                > results/dataset-sameas-as-of.txt
   $sudo echo "<$sameAsDatasetGraph> <http://purl.org/dc/terms/modified> \"$asOf\"^^<http://www.w3.org/2001/XMLSchema#dateTime> ." > results/dataset-sameas-as-of.nt
   # @deprecated: $sudo /opt/virtuoso/scripts/vload nt results/dataset-sameas-as-of.nt $sameAsDatasetGraph
   ${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vload nt results/dataset-sameas-as-of.nt $sameAsDatasetGraph

   echo
   echo "--- $paramsDatasetGraph $asOf"
   $sudo echo $asOf                                                                                                                > results/dataset-params-as-of.txt
   $sudo echo "<$paramsDatasetGraph> <http://purl.org/dc/terms/modified> \"$asOf\"^^<http://www.w3.org/2001/XMLSchema#dateTime> ." > results/dataset-params-as-of.nt
   # @deprecated: $sudo /opt/virtuoso/scripts/vload nt results/dataset-params-as-of.nt $paramsDatasetGraph
   ${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vload nt results/dataset-params-as-of.nt $paramsDatasetGraph

   #
   # Cache the dataset summary SPARQL queries
   #
   if [ ! -e cr-load-endpoint-metadataset.rq ]; then
      $sudo cat $CSV2RDF4LOD_HOME/bin/util/cr-load-endpoint-metadataset.trq | sed "s/\?:graph/<$datasetGraph>/" > cr-load-endpoint-metadataset.rq
   fi
   echo
   echo "cache-queries.sh start date time:"`${CSV2RDF4LOD_HOME}/bin/util/dateInXSDDateTime.sh` | tee -a $log_file
   for query in `find . -name "*.rq$" -o -name "*.sparql$"`; do
      $sudo cache-queries.sh ${CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT} -o sparql gvds xml csv -q $query
   done
   # -o sparql gvds xml
   echo "cache-queries.sh end date time:"`${CSV2RDF4LOD_HOME}/bin/util/dateInXSDDateTime.sh` | tee -a $log_file

   # For grabbing from the stats web page using php's include():
   for results in `find results -name "*.sparql.csv"`; do 
      $sudo perl $CSV2RDF4LOD_HOME/bin/util/sparql-csv2plain.pl $results
   done
popd

pushd ${CSV2RDF4LOD_CONVERT_DATA_ROOT}
   # Populate the MetaDataset named graph.
   metaDatasetGraph='http://purl.org/twc/vocab/conversion/MetaDataset'
   echo "cr-virtuoso-load-metadataset.sh start date time:"`${CSV2RDF4LOD_HOME}/bin/util/dateInXSDDateTime.sh`  | tee -a $log_file
                                                    # @deprecated: $sudo ./logd-load-metadata-graph.sh -w -ng $metaDatasetGraph
   $CSV2RDF4LOD_HOME/bin/util/cr-virtuoso-load-metadataset.sh -w -ng $metaDatasetGraph
   echo "cr-virtuoso-load-metadataset.sh end date time:"`${CSV2RDF4LOD_HOME}/bin/util/dateInXSDDateTime.sh`    | tee -a $log_file
popd

echo "end date time:"`${CSV2RDF4LOD_HOME}/bin/util/dateInXSDDateTime.sh` | tee -a $log_file
