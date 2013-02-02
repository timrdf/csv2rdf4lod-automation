#!/bin/bash
#
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/cr-virtuoso-load-metadata.sh
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
#
# See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Aggregating-subsets-of-converted-datasets
#
# Environment variables used:
#
#     CSV2RDF4LOD_HOME
#        e.g. /opt/csv2rdf4lod-automation
#
#     CSV2RDF4LOD_CONVERT_DATA_ROOT
#        e.g. /srv/logd/data/source
#
#     CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT
#        e.g. /var/www/html/logd.tw.rpi.edu
#
#     CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT
#        e.g. http://logd.tw.rpi.edu:8891/sparql
#
#     (see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-environment-variables)
#
# NOTE: This is called by su's crontab.

sudo="sudo"
if [ `whoami` == "root" ]; then
   sudo=""
fi

see='https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set'
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $see"}
CSV2RDF4LOD_CONVERT_DATA_ROOT=${CSV2RDF4LOD_CONVERT_DATA_ROOT:?"not set; source csv2rdf4lod/source-me.sh or see $see"}
CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT=${CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT:?"not set; source csv2rdf4lod/source-me.sh or see $see"}
CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT=${CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT:?"not set; source csv2rdf4lod/source-me.sh or see $see"}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:data-root"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

if [ ! -d "${CSV2RDF4LOD_CONVERT_DATA_ROOT}" ]; then
   echo "[WARNING] CSV2RDF4LOD_CONVERT_DATA_ROOT: $CSV2RDF4LOD_CONVERT_DATA_ROOT does not exist."
fi

PATH=$PATH:/usr/local/bin # to get rapper on
if [ ! `which rapper` ]; then
   echo "need rapper on path."
   exit 1
fi

echo Using CSV2RDF4LOD_HOME $CSV2RDF4LOD_HOME

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

if [ ! -d "$CSV2RDF4LOD_CONVERT_DATA_ROOT" ]; then
   echo "[ERROR] CSV2RDF4LOD_CONVERT_DATA_ROOT: $CSV2RDF4LOD_CONVERT_DATA_ROOT does not exist; cannot load meta, sameas, and params."
else
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
   #   $sudo ./load-endpoint-metadataset.sh -w -ng $metaDatasetGraph
   #   echo "./load-endpoint-metadataset.sh     end date time:"`${CSV2RDF4LOD_HOME}/bin/util/dateInXSDDateTime.sh` >> $log_file
   popd
fi

if [ ! -d "$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT" ]; then
   echo "[ERROR] CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT: $CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT does not exist; cannot load metadata."
else
   if [ ! -d $CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/query ]; then
      mkdir $CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/query
   fi
   pushd $CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/query &> /dev/null

      asOf=`dateInXSDDateTime.sh`
      echo $datasetGraph $asOf
      echo $asOf                                                                                                          > results/dataset-as-of.txt
      echo "<$datasetGraph> <http://purl.org/dc/terms/modified> \"$asOf\"^^<http://www.w3.org/2001/XMLSchema#dateTime> ." > results/dataset-as-of.nt
      $sudo ${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vload nt results/dataset-as-of.nt        $datasetGraph

      echo $sameAsDatasetGraph $asOf
      echo $asOf                                                                                                                > results/dataset-sameas-as-of.txt
      echo "<$sameAsDatasetGraph> <http://purl.org/dc/terms/modified> \"$asOf\"^^<http://www.w3.org/2001/XMLSchema#dateTime> ." > results/dataset-sameas-as-of.nt
      $sudo ${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vload nt results/dataset-sameas-as-of.nt $sameAsDatasetGraph

      echo $paramsDatasetGraph $asOf
      echo $asOf                                                                                                                > results/dataset-params-as-of.txt
      echo "<$paramsDatasetGraph> <http://purl.org/dc/terms/modified> \"$asOf\"^^<http://www.w3.org/2001/XMLSchema#dateTime> ." > results/dataset-params-as-of.nt
      $sudo ${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vload nt results/dataset-params-as-of.nt $paramsDatasetGraph

      #
      # Cache the dataset summary SPARQL queries
      #
      echo "cache-queries.sh start date time:"`${CSV2RDF4LOD_HOME}/bin/util/dateInXSDDateTime.sh` >> $log_file
      $sudo $CSV2RDF4LOD_HOME/bin/util/cache-queries.sh ${CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT:-"http://logd.tw.rpi.edu/sparql"} -o sparql gvds xml csv -q logd-stat-*.sparql
      # -o sparql gvds xml
      echo "cache-queries.sh end   date time:"`${CSV2RDF4LOD_HOME}/bin/util/dateInXSDDateTime.sh` >> $log_file

      # For grabbing from the stats web page using php's include():
      for results in `find results -name "*.sparql.csv"`; do 
         perl $CSV2RDF4LOD_HOME/bin/util/sparql-csv2plain.pl $results
      done
   popd &> /dev/null
fi

$sudo ${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vcheckpoint

echo "end date time:"`${CSV2RDF4LOD_HOME}/bin/util/dateInXSDDateTime.sh` >> $log_file
