#!/bin/bash
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
# To get the settings for all of variables:
#    set | grep CSV2RDF4LOD | grep -v CSV2RDF4LOD_HOME | awk '{print "export",$0}'

if [ "$1" == "--check" ]; then
   warnings=""
   echo
   if [ ! `which rapper` ]; then
      echo
      echo "[WARNING]: rapper not found on path. Publishing and many other things will fail."
      echo "           see https://github.com/timrdf/csv2rdf4lod-automation/wiki/Installing-csv2rdf4lod-automation---complete"
      echo
      warnings="true"
   else
      echo "[INFO]: rapper found"
   fi
   if [[ ! (`which tdbloader` && `which tdbquery`) ]]; then
      echo
      echo "[WARNING]: tdbloader/tdbquery not found on path. Unit testing with cr-test-conversion.sh will fail."
      echo "           see https://github.com/timrdf/csv2rdf4lod-automation/wiki/Script:-cr-test-conversion.sh"
      echo "           see https://github.com/timrdf/csv2rdf4lod-automation/wiki/Installing-csv2rdf4lod-automation---complete"
      echo
      warnings="true"
   else
      echo "[INFO]: tdb found"
   fi
   if [[ ! `which curl` ]]; then
      echo
      echo "[WARNING]: curl not found on path."
      echo "           see https://github.com/timrdf/csv2rdf4lod-automation/wiki/Script:-cr-test-conversion.sh"
      echo "           see https://github.com/timrdf/csv2rdf4lod-automation/wiki/Installing-csv2rdf4lod-automation---complete"
      echo
      warnings="true"
   else
      echo "[INFO]: curl found"
   fi
   if [[ ! `which serdi` ]]; then
      echo
      echo "[WARNING]: serdi not found on path."
      echo "           see https://github.com/timrdf/csv2rdf4lod-automation/wiki/Script:-cr-test-conversion.sh"
      echo "           see https://github.com/timrdf/csv2rdf4lod-automation/wiki/Installing-csv2rdf4lod-automation---complete"
      echo
      warnings="true"
   else
      echo "[INFO]: serdi found"
   fi
   echo
   if [ "$warnings" == "true" ]; then
      echo "Use install-csv2rdf4lod-dependencies.sh to install dependencies"
      echo
   fi
   exit 0
elif [ "$1" == "--export" ]; then
   set | grep CSV2RDF4LOD | grep -v CSV2RDF4LOD_HOME | awk '{print "export",$0}'
   exit 0
fi

if [ "$1" != "CLEAR" ]; then
   show_all="no"
   if [ "$1" == "--all" ]; then
      show_all="yes";
   fi
   #echo "CLASSPATH                             $CLASSPATH"
   #echo "PATH                                  $PATH"

   echo
   echo "CSV2RDF4LOD_HOME                                         ${CSV2RDF4LOD_HOME:-"!!! -- MUST BE SET -- !!! source csv2rdf4lod/source-me.sh"}"
   echo "CSV2RDF4LOD_BASE_URI                                     ${CSV2RDF4LOD_BASE_URI:-"!!! -- MUST BE SET -- !!! source csv2rdf4lod/source-me.sh"}"
   echo "CSV2RDF4LOD_BASE_URI_OVERRIDE                            ${CSV2RDF4LOD_BASE_URI_OVERRIDE:="(not required, \$CSV2RDF4LOD_BASE_URI will be used.)"}"
   echo
   echo "CSV2RDF4LOD_RETRIEVE_DROID_SOURCES                       ${CSV2RDF4LOD_RETRIEVE_DROID_SOURCES:="(will default to: true)"}"
   echo
   echo "CSV2RDF4LOD_CONVERT_MACHINE_URI                          ${CSV2RDF4LOD_CONVERT_MACHINE_URI:="(not required, but recommended! see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD_CONVERT_PERSON_URI)"}"
   echo "CSV2RDF4LOD_CONVERT_PERSON_URI                           ${CSV2RDF4LOD_CONVERT_PERSON_URI:="(not required, but recommended! see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD_CONVERT_PERSON_URI)"}"

   echo
   echo "CSV2RDF4LOD_CKAN                                         ${CSV2RDF4LOD_CKAN:-"(will default to: false)"}"
   if [[ "$CSV2RDF4LOD_CKAN" == "true" || "$show_all" == "yes" ]]; then
      echo "CSV2RDF4LOD_CKAN_SOURCE                                  ${CSV2RDF4LOD_CKAN_SOURCE:-"(will not replicate a ckan)"}"
      echo "CSV2RDF4LOD_CKAN_WRITABLE                                ${CSV2RDF4LOD_CKAN_WRITABLE:-"(will not write to a CKAN)"}"
      if [[  ${#CSV2RDF4LOD_CKAN_WRITABLE} -gt 0 || "$show_all" == "yes" ]]; then
         echo "X_CKAN_API_Key                                           ${X_CKAN_API_Key:-"(will not be able to write to $CSV2RDF4LOD_CKAN_WRITABLE)"}"
      fi
   else
      echo "   ..."
   fi
   echo
   echo "CSV2RDF4LOD_CONCURRENCY                                  ${CSV2RDF4LOD_CONCURRENCY:-"(will default to: 1)"}"
   echo "CSV2RDF4LOD_CONVERT_ALWAYS_UPDATE_CONVERTER              ${CSV2RDF4LOD_CONVERT_ALWAYS_UPDATE_CONVERTER:="(will default to: false)"}"
   echo "CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER                       ${CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER:="(will default to: false)"}"
   echo "CSV2RDF4LOD_CONVERT_SAMPLE_NUMBER_OF_ROWS                ${CSV2RDF4LOD_CONVERT_SAMPLE_NUMBER_OF_ROWS:="(will default to: 2)"}"
   echo "CSV2RDF4LOD_CONVERT_SAMPLE_SUBSET_ONLY                   ${CSV2RDF4LOD_CONVERT_SAMPLE_SUBSET_ONLY:="(will default to: false)"}"
   echo "CSV2RDF4LOD_CONVERT_EXAMPLE_SUBSET_ONLY                  ${CSV2RDF4LOD_CONVERT_EXAMPLE_SUBSET_ONLY:="(will default to: false)"}"
   extensions=`dump-file-extensions.sh`
   echo "CSV2RDF4LOD_CONVERT_DUMP_FILE_EXTENSIONS                 \"${CSV2RDF4LOD_CONVERT_DUMP_FILE_EXTENSIONS}\" => ${extensions:="(void:dataDump URLs will not have file extensions)"}"
   echo "CSV2RDF4LOD_CONVERT_PROVENANCE_GRANULAR                  ${CSV2RDF4LOD_CONVERT_PROVENANCE_GRANULAR:="(will default to: false)"}"
   echo "CSV2RDF4LOD_CONVERT_PROVENANCE_FRBR                      ${CSV2RDF4LOD_CONVERT_PROVENANCE_FRBR:="(will default to: false)"}"
   echo "CSV2RDF4LOD_CONVERT_DEBUG_LEVEL                          ${CSV2RDF4LOD_CONVERT_DEBUG_LEVEL:="(will default to: none \{none,fine,finer,finest\})"}"

   if [[ ${#CSV2RDF4LOD_CONVERTER} -gt 0 || "$show_all" == "yes" ]]; then
      echo "CSV2RDF4LOD_CONVERTER                                    ${CSV2RDF4LOD_CONVERTER:="(will default to: java ... -Xmx3060m edu.rpi.tw.data.csv.CSVtoRDF)"}"
   fi

   echo
   echo "CSV2RDF4LOD_PUBLISH                                      ${CSV2RDF4LOD_PUBLISH:-"(will default to: true)"}"
   echo "CSV2RDF4LOD_PUBLISH_VC_REPOSITORY                        ${CSV2RDF4LOD_PUBLISH_VC_REPOSITORY:-"(will default to: false)"}"
   echo "CSV2RDF4LOD_PUBLISH_DELAY_UNTIL_ENHANCED                 ${CSV2RDF4LOD_PUBLISH_DELAY_UNTIL_ENHANCED:-"(will default to: true)"}"

   echo "CSV2RDF4LOD_PUBLISH_TTL                                  ${CSV2RDF4LOD_PUBLISH_TTL:-"(will default to: true)"}"
   echo "CSV2RDF4LOD_PUBLISH_TTL_LAYERS                           ${CSV2RDF4LOD_PUBLISH_TTL_LAYERS:-"(will default to: true)"}"

   echo "CSV2RDF4LOD_PUBLISH_NT                                   ${CSV2RDF4LOD_PUBLISH_NT:-"(will default to: false)"}"

   echo "CSV2RDF4LOD_PUBLISH_RDFXML                               ${CSV2RDF4LOD_PUBLISH_RDFXML:-"(will default to: false)"}"
   echo "CSV2RDF4LOD_PUBLISH_COMPRESS                             ${CSV2RDF4LOD_PUBLISH_COMPRESS:-"(will default to: false)"}"
   echo "CSV2RDF4LOD_PUBLISH_PURGE_AUTODIR                        ${CSV2RDF4LOD_PUBLISH_PURGE_AUTODIR:-"(will default to: false)"}"

   echo
   echo "CSV2RDF4LOD_PUBLISH_FULL_CONVERSIONS                     ${CSV2RDF4LOD_PUBLISH_FULL_CONVERSIONS:="(will default to: false)"}"
   echo "CSV2RDF4LOD_PUBLISH_SUBSET_VOID                          ${CSV2RDF4LOD_PUBLISH_SUBSET_VOID:="(will default to: true)"}"
   echo "CSV2RDF4LOD_PUBLISH_SUBSET_VOID_NAMED_GRAPH              ${CSV2RDF4LOD_PUBLISH_SUBSET_VOID_NAMED_GRAPH:="(will default to: auto)"}"
   echo "CSV2RDF4LOD_PUBLISH_SUBSET_SAMEAS                        ${CSV2RDF4LOD_PUBLISH_SUBSET_SAMEAS:="(will default to: false)"}"
   echo "CSV2RDF4LOD_PUBLISH_SUBSET_SAMEAS_NAMED_GRAPH            ${CSV2RDF4LOD_PUBLISH_SUBSET_SAMEAS_NAMED_GRAPH:="(will default to: auto)"}"
   echo "CSV2RDF4LOD_PUBLISH_SUBSET_SAMPLES                       ${CSV2RDF4LOD_PUBLISH_SUBSET_SAMPLES:="(will default to: false)"}"

   echo
   echo "CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID                        ${CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID:="(will not archive conversion metadata into versioned dataset.)"}"
   echo "CSV2RDF4LOD_PUBLISH_OUR_DATASET_ID                       ${CSV2RDF4LOD_PUBLISH_OUR_DATASET_ID:="(will not archive conversion metadata into versioned dataset.)"}"
   echo "CSV2RDF4LOD_PUBLISH_CONVERSION_PARAMS_NAMED_GRAPH        ${CSV2RDF4LOD_PUBLISH_CONVERSION_PARAMS_NAMED_GRAPH:="(will default to: auto)"}"
   echo "CSV2RDF4LOD_PUBLISH_METADATASET_GRAPH_NAME               ${CSV2RDF4LOD_PUBLISH_METADATASET_GRAPH_NAME:="(will default to: http://purl.org/twc/vocab/conversion/MetaDataset)"}"

   echo
   echo "CSV2RDF4LOD_PUBLISH_AWS_S3_BUCKET                        ${CSV2RDF4LOD_PUBLISH_AWS_S3_BUCKET:-"(will default to: none)"}"

   echo
   echo "CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT         ${CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT:-"(will default to: VVV/publish/lod-mat/)"}"
   echo "CSV2RDF4LOD_PUBLISH_VARWWW_DUMP_FILES                    ${CSV2RDF4LOD_PUBLISH_VARWWW_DUMP_FILES:-"(will default to: false)"}"
   echo "CSV2RDF4LOD_PUBLISH_VARWWW_ROOT                          ${CSV2RDF4LOD_PUBLISH_VARWWW_ROOT:-"(will default to: false)"}"
   echo "CSV2RDF4LOD_PUBLISH_VARWWW_LINK_TYPE                     ${CSV2RDF4LOD_PUBLISH_VARWWW_LINK_TYPE:-"(will default to: hard)"}"
   echo "CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION                  ${CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION:-"(will default to: false)"}"
   if [ "$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION" == "true" -o $show_all == "yes" ]; then
      echo "CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WRITE_FREQUENCY  ${CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WRITE_FREQUENCY:-"(will default to: 1,000,000)"}"

      echo "CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_REPORT_FREQUENCY ${CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_REPORT_FREQUENCY:-"(will default to: 1,000)"}"
   else
      echo "   ..."
   fi

   echo
   echo "CSV2RDF4LOD_PUBLISH_TDB                                  ${CSV2RDF4LOD_PUBLISH_TDB:-"(will default to: false)"}"
   if [ "$CSV2RDF4LOD_PUBLISH_TDB" == "true" -o $show_all == "yes" ]; then
      echo "CSV2RDF4LOD_PUBLISH_TDB_DIR                              ${CSV2RDF4LOD_PUBLISH_TDB_DIR:-"(will default to: VVV/publish/tdb/)"}"
      echo "CSV2RDF4LOD_PUBLISH_TDB_INDIV                            ${CSV2RDF4LOD_PUBLISH_TDB_INDIV:-"(will default to: false)"}"
   else
      echo "   ..."
   fi


   echo
   echo "CSV2RDF4LOD_PUBLISH_4STORE                               ${CSV2RDF4LOD_PUBLISH_4STORE:-"(will default to: false)"}"
   if [ "$CSV2RDF4LOD_PUBLISH_4STORE" == "true" -o $show_all == "yes" ]; then
   echo "CSV2RDF4LOD_PUBLISH_4STORE_KB                            ${CSV2RDF4LOD_PUBLISH_4STORE_KB:-"(will default to: csv2rdf4lod -- leading to /var/lib/4store/csv2rdf4lod)"}" 
   else
      echo "   ..."
   fi

   echo
   echo "CSV2RDF4LOD_PUBLISH_VIRTUOSO                             ${CSV2RDF4LOD_PUBLISH_VIRTUOSO:-"(will default to: false)"}"
                                                    virtuoso_home=${CSV2RDF4LOD_PUBLISH_VIRTUOSO_HOME:-"/opt/virtuoso"}
   if [ "$CSV2RDF4LOD_PUBLISH_VIRTUOSO" == "true" -o $show_all == "yes" ]; then
      echo "CSV2RDF4LOD_PUBLISH_VIRTUOSO_HOME                        ${CSV2RDF4LOD_PUBLISH_VIRTUOSO_HOME:-"(will default to: /opt/virtuoso)"}"
      echo "CSV2RDF4LOD_CONVERT_DATA_ROOT                            ${CSV2RDF4LOD_CONVERT_DATA_ROOT:="(not required; but avoids a file copy if set)"}"
      isql=${CSV2RDF4LOD_PUBLISH_VIRTUOSO_ISQL_PATH:-"$virtuoso_home/bin/isql"}
      if [ ! -e "$isql" ]; then
         isql=${CSV2RDF4LOD_PUBLISH_VIRTUOSO_ISQL_PATH:-"$virtuoso_home/bin/isql-v"}
      fi 
   if [ ! -e "$isql" ]; then
      isqlERROR=" ERROR: not found"
   fi 
   echo "CSV2RDF4LOD_PUBLISH_VIRTUOSO_ISQL_PATH                   ${CSV2RDF4LOD_PUBLISH_VIRTUOSO_ISQL_PATH:-"(will default to: $virtuoso_home/bin/isql$isqlERROR)"}"
   echo "CSV2RDF4LOD_PUBLISH_VIRTUOSO_PORT                        ${CSV2RDF4LOD_PUBLISH_VIRTUOSO_PORT:-"(will default to: 1111)"}"
   echo "CSV2RDF4LOD_PUBLISH_VIRTUOSO_USERNAME                    ${CSV2RDF4LOD_PUBLISH_VIRTUOSO_USERNAME:-"(will default to: dba)"}"
   echo "CSV2RDF4LOD_PUBLISH_VIRTUOSO_PASSWORD                    ${CSV2RDF4LOD_PUBLISH_VIRTUOSO_PASSWORD:-"(will default to: dba)"}"
   echo "CSV2RDF4LOD_PUBLISH_VIRTUOSO_INI_PATH                    ${CSV2RDF4LOD_PUBLISH_VIRTUOSO_INI_PATH:-"(will default to: $virtuoso_home/var/lib/virtuoso/db/virtuoso.ini)"}"
   echo "CSV2RDF4LOD_PUBLISH_VIRTUOSO_SCRIPT_PATH                 ${CSV2RDF4LOD_PUBLISH_VIRTUOSO_SCRIPT_PATH:-"(DEPRECATED. will default to: /opt/virtuoso/scripts/vload)"}"
   else
      echo "   ..."
   fi 
   echo "CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT             ${CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT:-"(will fail to describe provenance in pvload.sh)"}"

   echo
   echo "CSV2RDF4LOD_PUBLISH_SPARQL_ENDPOINT                        ${CSV2RDF4LOD_PUBLISH_SPARQL_ENDPOINT:-"(will default to: none)"}"
   echo "CSV2RDF4LOD_PUBLISH_SPARQL_ENDPOINT_SEPARATE_NG_PROVENANCE ${CSV2RDF4LOD_PUBLISH_SPARQL_ENDPOINT_SEPARATE_NG_PROVENANCE:-"(will default to: true)"}"
   echo "CSV2RDF4LOD_PUBLISH_SPARQL_RESULTS_DIRECTORY               ${CSV2RDF4LOD_PUBLISH_SPARQL_RESULTS_DIRECTORY:-"(will default to: none)"}"

   echo
   echo "CSV2RDF4LOD_PUBLISH_DATAHUB_METADATA                     ${CSV2RDF4LOD_PUBLISH_DATAHUB_METADATA:-"(will default to: none)"}"
   echo "CSV2RDF4LOD_PUBLISH_DATAHUB_METADATA_OUR_BUBBLE_ID       ${CSV2RDF4LOD_PUBLISH_DATAHUB_METADATA_OUR_BUBBLE_ID:-"(will default to: none)"}"

   echo
   echo "CSV2RDF4LOD_PUBLISH_ANNOUNCE_TO_SINDICE                  ${CSV2RDF4LOD_PUBLISH_ANNOUNCE_TO_SINDICE:-"(will NOT announce to http://sindice.com)"}"
   echo "CSV2RDF4LOD_PUBLISH_ANNOUNCE_TO_PTSW                     ${CSV2RDF4LOD_PUBLISH_ANNOUNCE_TO_PTSW:-"(will NOT announce to http://pingthesemanticweb.com)"}"
   to=''
   if [[ "$CSV2RDF4LOD_PUBLISH_ANNOUNCE_TO_SINDICE" == "true" ]]; then
      to="http://sindice.com "
   fi
   if [[ "$CSV2RDF4LOD_PUBLISH_ANNOUNCE_TO_PTSW" == "true" ]]; then
      to="${to}http://pingthesemanticweb.com "
   fi
   if [[ "$CSV2RDF4LOD_PUBLISH_ANNOUNCE_TO_SINDICE" == "true" || "$CSV2RDF4LOD_PUBLISH_ANNOUNCE_TO_PTSW" == "true" ]]; then
      echo "CSV2RDF4LOD_PUBLISH_ANNOUNCE_ONLY_ENHANCED               ${CSV2RDF4LOD_PUBLISH_ANNOUNCE_ONLY_ENHANCED:-"(will publish both raw and enhanced datasets to $to)"}"
   else
      to="http://sindice.com or http://pingthesemanticweb.com"
      echo "CSV2RDF4LOD_PUBLISH_ANNOUNCE_ONLY_ENHANCED               ${CSV2RDF4LOD_PUBLISH_ANNOUNCE_ONLY_ENHANCED:-"(will NOT announce any dataset to $to)"}"
   fi

   echo
   echo "X_GOOGLE_MAPS_API_Key                                    ${X_GOOGLE_MAPS_API_Key:-"(not required; used by cr-geocoords-addresses)"}"
   if [ ${#CSV2RDF4LOD_HOME} -gt 0 ]; then
      echo
      echo "see documentation for variables in:"
      echo "https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/setup.sh"
      echo "https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-environment-variables"
      echo
      echo "http://purl.org/twc/id/software/csv2rdf4lod"
   fi
else

   echo "clearing..."
   export CSV2RDF4LOD_HOME=""
   export CSV2RDF4LOD_BASE_URI=""
   export CSV2RDF4LOD_BASE_URI_OVERRIDE=""           

   export CSV2RDF4LOD_RETRIEVE_DROID_SOURCES=""           

   export CSV2RDF4LOD_CONVERT_MACHINE_URI=""           
   export CSV2RDF4LOD_CONVERT_PERSON_URI=""           

   export CSV2RDF4LOD_CKAN=""
   export CSV2RDF4LOD_CKAN_SOURCE=""
   export CSV2RDF4LOD_CKAN_WRITABLE=""

   export CSV2RDF4LOD_CONVERT_DATA_ROOT=""
   export CSV2RDF4LOD_CONVERT_ALWAYS_UPDATE_CONVERTER=""
   export CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER=""
   export CSV2RDF4LOD_CONVERT_SAMPLE_NUMBER_OF_ROWS=""
   export CSV2RDF4LOD_PUBLISH_FULL_CONVERSIONS=""
   export CSV2RDF4LOD_CONVERT_SAMPLE_SUBSET_ONLY=""
   export CSV2RDF4LOD_CONVERT_EXAMPLE_SUBSET_ONLY=""
   export CSV2RDF4LOD_CONVERT_DUMP_FILE_EXTENSIONS=""
   export CSV2RDF4LOD_PUBLISH_VARWWW_ROOT=""
   export CSV2RDF4LOD_CONVERT_PROVENANCE_GRANULAR=""
   export CSV2RDF4LOD_CONVERT_PROVENANCE_FRBR=""
   export CSV2RDF4LOD_CONVERT_DEBUG_LEVEL=""
   # "  "

   export CSV2RDF4LOD_PUBLISH=""
   export CSV2RDF4LOD_PUBLISH_VC_REPOSITORY=""
   export CSV2RDF4LOD_PUBLISH_DELAY_UNTIL_ENHANCED=""
   export CSV2RDF4LOD_PUBLISH_TTL=""
   export CSV2RDF4LOD_PUBLISH_TTL_LAYERS=""
   export CSV2RDF4LOD_PUBLISH_NT=""
   export CSV2RDF4LOD_PUBLISH_RDFXML=""
   export CSV2RDF4LOD_PUBLISH_COMPRESS=""
   export CSV2RDF4LOD_PUBLISH_PURGE_AUTODIR=""
   # "  "
   export CSV2RDF4LOD_PUBLISH_SUBSET_VOID=""
   export CSV2RDF4LOD_PUBLISH_SUBSET_VOID_NAMED_GRAPH=""
   export CSV2RDF4LOD_PUBLISH_SUBSET_SAMEAS=""
   export CSV2RDF4LOD_PUBLISH_SUBSET_SAMEAS_NAMED_GRAPH=""
   export CSV2RDF4LOD_PUBLISH_SUBSET_SAMPLES=""
   # "  "
   export CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID=""
   export CSV2RDF4LOD_PUBLISH_OUR_DATASET_ID=""
   export CSV2RDF4LOD_PUBLISH_CONVERSION_PARAMS_NAMED_GRAPH=""
   export CSV2RDF4LOD_PUBLISH_METADATA_GRAPH_NAME=""
   export CSV2RDF4LOD_PUBLISH_VARWWW_DUMP_FILES=""
   export CSV2RDF4LOD_PUBLISH_VARWWW_LINK_TYPE=""
   # "  "
   export CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION=""
   export CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT=""
   export CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WRITE_FREQUENCY=""
   export CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_REPORT_FREQUENCY=""
   export CSV2RDF4LOD_CONCURRENCY=""
   # "  "
   export CSV2RDF4LOD_PUBLISH_TDB=""
   export CSV2RDF4LOD_PUBLISH_TDB_DIR=""

   export CSV2RDF4LOD_PUBLISH_TDB_INDIV=""

   # "  "
   export CSV2RDF4LOD_PUBLISH_4STORE=""
   export CSV2RDF4LOD_PUBLISH_4STORE_KB=""
   
   # "  "
   export CSV2RDF4LOD_PUBLISH_VIRTUOSO=""
   export CSV2RDF4LOD_PUBLISH_VIRTUOSO_HOME=""
   export CSV2RDF4LOD_PUBLISH_VIRTUOSO_ISQL_PATH=""
   export CSV2RDF4LOD_PUBLISH_VIRTUOSO_PORT=""
   export CSV2RDF4LOD_PUBLISH_VIRTUOSO_USERNAME=""
   export CSV2RDF4LOD_PUBLISH_VIRTUOSO_PASSWORD=""
   export CSV2RDF4LOD_PUBLISH_VIRTUOSO_INI_PATH=""
   export CSV2RDF4LOD_PUBLISH_VIRTUOSO_SCRIPT_PATH=""
   export CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT=""

   # "  "
   export CSV2RDF4LOD_PUBLISH_SPARQL_ENDPOINT=""       
   export CSV2RDF4LOD_PUBLISH_SPARQL_ENDPOINT_SEPARATE_NG_PROVENANCE=""       
   export CSV2RDF4LOD_PUBLISH_SPARQL_RESULTS_DIRECTORY=""

   # "  "
   export CSV2RDF4LOD_PUBLISH_DATAHUB_METADATA=""
   export CSV2RDF4LOD_PUBLISH_DATAHUB_METADATA_OUR_BUBBLE_ID=""

   # "  "
   export CSV2RDF4LOD_PUBLISH_ANNOUNCE_TO_SINDICE=""
   export CSV2RDF4LOD_PUBLISH_ANNOUNCE_TO_PTSW=""
   export CSV2RDF4LOD_PUBLISH_ANNOUNCE_ONLY_ENHANCED=""

   # "  "
   export X_GOOGLE_MAPS_API_Key=""
   
   echo "...cleared."
   $0 # Run this script again to show that they were cleared.
fi

rm -f _pvload.sh*
