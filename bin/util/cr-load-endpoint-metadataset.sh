#!/bin/bash
# 
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/cr-load-endpoint-metadataset.sh
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
# Usage: logd-load-metadata-graph.sh [-w] [-ng http://named-graph-for-endpoint] [source-id dataset-id]*
#
# See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Aggregating-subsets-of-converted-datasets
#
# Environment variables used:
#
#     CSV2RDF4LOD_HOME                                 - path root for all csv2rdf4lod scripts.
#     CSV2RDF4LOD_CONVERT_DATA_ROOT                    - (but it gets run from here...)
#     CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID                - to put collected files into a new dataset in the data root.
#     CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT     - if cr:auto, query this to find out the catalog:Metadatasets to load.
#     CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT - to publish complete dump file.
#
#     (see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-environment-variables)
# 
# Examples:
#
# logd-load-metadata-graph.sh -ng http://purl.org/twc/vocab/conversion/MetaDataset-timtest   data-gov 92   twc-rpi-edu dataset-catalog   at-ckan-net catalog

see='https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set'
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $see"}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:data-root"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

if [[ "$1" == "--help" ]]; then
   echo "usage: `basename $0` [-w] [--target] [--clear-graph] [-ng graph-name] (cr:auto | cr:hard | [source-id dataset-id]*)"
   echo
   echo "         -w or --write : Prevent dryrun and load endpoint."
   echo "              --target : Return the name of graph that will be loaded; then quit."
   echo "         --clear-graph : Clear the named graph (only if there is something to replace it)."
   echo "            graph-name : Named graph in triple store to load MetaDatasets."
   echo
   echo "               cr:auto : Obtain the source-id and dataset-id pairs by SPARQL-querying the endpoint."
   echo "               cr:hard : Use a hard-coded list of source-id and dataset-id."
   echo "  source-id dataset-id : Identifiers for the dataset to load."
   exit 1
fi

dryRun="true"
if [[ "$1" == "-w" || "$1" == "--write" ]]; then
   dryRun="false"
   shift
fi

graphName='http://purl.org/twc/vocab/conversion/MetaDataset'

if [ "$1" == "--target" ]; then
   echo $graphName
   $CSV2RDF4LOD_HOME/bin/util/virtuoso/vload --target
   exit 0
fi

clearGraph="no"
if [ "$1" == "--clear-graph" ]; then
   clearGraph="yes"
   shift
fi

if [ "$1" == "-ng" -a $# -gt 1 ]; then
   graphName="$2" 
   shift 2
fi

echo "------------------- `basename $0` --------------------"
if [ $dryRun == "true" ]; then
   echo
   echo
   echo
   echo "WARNING `basename $0`: This is a dry run; triple store will NOT be modified. Use -w to load MetaDatasets into endpoint."
   echo
   echo
   echo
fi

echo "INFO `basename $0`: Will load MetaDataset(s) into named graph: $graphName "

# We can run as root or as a normal user.
assudo="sudo"
if [ `whoami` == "root" ]; then
   assudo=""
fi

#######################
# init: clean up intermediate results folder
me=`basename $0 | sed 's/.sh$//'`
SOURCE="$CSV2RDF4LOD_CONVERT_DATA_ROOT"
                                                       TODAY="${CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID:-"$me"}/$me/version/`date +%Y-%b-%d`/source"
 WEB_TODAY="$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/${CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID:-"$me"}/$me/version/`date +%Y-%b-%d`"
WEB_LATEST="$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/${CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID:-"$me"}/$me/version/latest"
echo "INFO `basename $0`: Accumulating MetaDataset dump files:"
echo "INFO `basename $0`:   into local $TODAY"
echo "INFO `basename $0`:   and web $WEB_TODAY"
if [ "$dryRun" == "false" ];then
   $assudo rm    -rf $TODAY 2> /dev/null
   $assudo mkdir -p  $TODAY 2> /dev/null
   $assudo rm    -rf $WEB_TODAY/source/*
   $assudo mkdir -p  $WEB_TODAY/source $WEB_TODAY/publish; 
fi

get_dump_file() {
   source_id="$1"  # param 1: source_id
   dataset_id="$2" # param 2: dataset_id
   if [ -d $SOURCE/$source_id/$dataset_id/version ]; then
      latest_version_id=`ls -lt $SOURCE/$source_id/$dataset_id/version | grep "^d" | awk '{print $NF}' | head -1`
      echo "-----------------------------------------" 
      echo "$source_id  $dataset_id  $latest_version_id "

      dump_ttl=`ls -t $SOURCE/$source_id/$dataset_id/version/$latest_version_id/publish/*-$latest_version_id.ttl.*gz 2> /dev/null | head -1`
      if [[ ! -e "$dump_ttl" ]]; then
         # Try as compressed
         dump_ttl=`ls -t $SOURCE/$source_id/$dataset_id/version/$latest_version_id/publish/*-$latest_version_id.ttl 2> /dev/null | head -1`
      fi
      if [[ -e "$dump_ttl" ]]; then
         # Try as uncompressed
         echo "INFO `basename $0`   $dump_ttl"
         echo "INFO       to $TODAY"
         $assudo cp $dump_ttl $TODAY
      else 
         echo "WARNING `basename $0`: $source_id $dataset_id - $SOURCE/$source_id/$dataset_id/version/$latest_version_id/publish/*-$latest_version_id.ttl[.gz] not found."
      fi
   else
      echo "WARNING `basename $0`: $source_id $dataset_id - $SOURCE/$source_id/$dataset_id/version not found."
   fi
}

echo "-----------------------------------------" 
echo "INFO `basename $0`: Will accumulate MetaDataset dump files to directory: $TODAY "

if [ "$1" == "cr:auto" ]; then

   echo "INFO `basename $0`: cr:auto: Querying $CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT for source-ids and dataset-ids."

elif [ $# -gt 1 ]; then

   echo "INFO `basename $0`: MetaDataset source-ids and dataset-ids are provided as parameters. Including only those."
   while [ $# -gt 1 ]; do
      source_id="$1"
      dataset_id="$2"
      get_dump_file $source_id $dataset_id
      shift 2
   done

elif [[ "$1" == "cr:hard" || $# == 0 ]]; then 

   echo "INFO `basename $0`: MetaDataset source-ids and dataset-ids hard coded here."

   # This list grabbed from https://docs.google.com/spreadsheet/ccc?key=0ArTeDpS4-nUDdFFpbW9uN2t1ZjAyeUc2U1ZJd0xTZ1E&hl=en_US#gid=0
   # 2011 Nov 13 lebot
   get_dump_file "a2gov-org" "catalog"
   get_dump_file "africover-org" "catalog"
   get_dump_file "aporta-es" "catalog"
   get_dump_file "arvada-org" "catalog"
   get_dump_file "at-ckan-net" "catalog"
   get_dump_file "br-ckan-net" "catalog"
   get_dump_file "calgaryonlinestore-com" "catalog"
   get_dump_file "can-do-honolulu-gov" "catalog"
   get_dump_file "cat-open-org-nz" "catalog"
   get_dump_file "citywindsor-ca" "catalog"
   get_dump_file "civicapps-org" "catalog"
   get_dump_file "colorado-gov" "catalog"
   get_dump_file "comune-fi-it" "catalog"
   get_dump_file "comune-udine-it" "catalog"
   get_dump_file "consejotransparencia-cl" "catalog"
   get_dump_file "cz-ckan-net" "catalog"
   get_dump_file "dados-gov-br" "catalog"
   get_dump_file "data-baltimorecity-gov" "catalog"
   get_dump_file "data-ca-gov" "catalog"
   get_dump_file "datacatalog-cookcountyil-gov" "catalog"
   get_dump_file "data-cityofchicago-org" "catalog"
   get_dump_file "data-digitaliser-dk" "catalog"
   get_dump_file "data-edmonton-ca" "catalog"
   get_dump_file "data-gc-ca" "catalog"
   get_dump_file "datagm-org-uk" "catalog"
   get_dump_file "data-gov" "92"
   get_dump_file "data-gov-au" "catalog"
   get_dump_file "data-gov-bc-ca" "catalog"
   get_dump_file "data-gov-be" "catalog"
   get_dump_file "data-gov-md" "catalog"
   get_dump_file "data-gov-sg" "catalog"
   get_dump_file "data-govt-nz" "catalog"
   get_dump_file "data-gov-uk" "catalog"
   get_dump_file "data-grandtoulouse-fr" "catalog"
   get_dump_file "data-illinois-gov" "catalog"
   get_dump_file "datakc-org" "catalog"
   get_dump_file "data-linz-gv-at" "catalog"
   get_dump_file "datalocale-fr" "catalog"
   get_dump_file "data-london-gov-uk" "catalog"
   get_dump_file "data-medicare-gov" "catalog"
   get_dump_file "data-nasa-gov" "catalog"
   get_dump_file "datanest-fair-play-sk" "catalog"
   get_dump_file "data-nola-gov" "catalog"
   get_dump_file "data-norge-no" "catalog"
   get_dump_file "data-nsw-gov-au" "catalog"
   get_dump_file "data-octo-dc-gov" "catalog"
   get_dump_file "data-ok-gov" "catalog"
   get_dump_file "data-oregon-gov" "catalog"
   get_dump_file "data-rennes-metropole-fr" "catalog"
   get_dump_file "data-seattle-gov" "catalog"
   get_dump_file "datasf-org" "catalog"
   get_dump_file "data-suomi-fi" "catalog"
   get_dump_file "data-vancouver-ca" "catalog"
   get_dump_file "data-vic-gov-au" "catalog"
   get_dump_file "data-wa-gov" "catalog"
   get_dump_file "data-wien-gv-at" "catalog"
   get_dump_file "data-worldbank-org" "catalog"
   get_dump_file "daten-berlin-de" "catalog"
   get_dump_file "dati-emilia-romagna-it" "catalog"
   get_dump_file "dati-gov-it" "catalog"
   get_dump_file "dati-piemonte-it" "catalog"
   get_dump_file "datos-gijon-es" "catalog"
   get_dump_file "datos-gob-cl" "catalog"
   get_dump_file "en-openei-org" "catalog"
   get_dump_file "env-gov-bc-ca" "catalog"
   get_dump_file "finances-worldbank-org" "catalog"
   get_dump_file "geodata-gov" "catalog"
   get_dump_file "geoweb-dnv-org" "catalog"
   get_dump_file "gov-hk" "catalog"
   get_dump_file "ie-ckan-net" "catalog"
   get_dump_file "kozadat-neumannhaz-hu" "catalog"
   get_dump_file "lichfielddc-gov-uk" "catalog"
   get_dump_file "linkedopendata-it" "catalog"
   get_dump_file "london-ca" "catalog"
   get_dump_file "lt-ckan-net" "catalog"
   get_dump_file "maine-gov" "catalog"
   get_dump_file "manchester-gov-uk" "catalog"
   get_dump_file "michigan-gov" "catalog"
   get_dump_file "mississauga-ca" "catalog"
   get_dump_file "montevideo-gub-uy" "catalog"
   get_dump_file "munlima-gob-pe" "catalog"
   get_dump_file "navarra-es" "catalog"
   get_dump_file "nebraska-gov" "catalog"
   get_dump_file "niagarafalls-ca" "catalog"
   get_dump_file "nycopendata-socrata-com" "catalog"
   get_dump_file "nysenate-gov" "catalog"
   get_dump_file "offenedaten-de" "catalog"
   get_dump_file "openbelgium-be" "catalog"
   get_dump_file "opendatacordoba-com" "catalog"
   get_dump_file "opendata-go-ke" "catalog"
   get_dump_file "opendata-jccm-es" "catalog"
   get_dump_file "opendata-montpelliernumerique-fr" "catalog"
   get_dump_file "opendatani-info" "catalog"
   get_dump_file "opendata-paris-fr" "catalog"
   get_dump_file "opendataphilly-org" "catalog"
   get_dump_file "opendata-warwickshire-gov-uk" "catalog"
   get_dump_file "opengovdata-ru" "catalog"
   get_dump_file "opengov-es" "catalog"
   get_dump_file "opengov-se" "catalog"
   get_dump_file "ottawa-ca" "catalog"
   get_dump_file "picandmix-org-uk" "catalog"
   get_dump_file "portalu-de" "catalog"
   get_dump_file "princegeorge-ca" "catalog"
   get_dump_file "profiles-bristol-gov-uk" "catalog"
   get_dump_file "register-data-overheid-nl" "catalog"
   get_dump_file "risp-asturias-es" "catalog"
   get_dump_file "sardegnageoportale-it" "catalog"
   get_dump_file "surrey-ca" "catalog"
   get_dump_file "sutton-gov-uk" "catalog"
   get_dump_file "tol-ca" "catalog"
   get_dump_file "toronto-ca" "catalog"
   get_dump_file "utah-gov" "catalog"
   get_dump_file "zaragoza-es" "catalog"
fi

echo "-----------------------------------------" 

files_to_load="no"
for file in `find $TODAY -name "*.ttl"`;     do files_to_load="yes"; done
for file in `find $TODAY -name "*.ttl.gz"`;  do files_to_load="yes"; done
for file in `find $TODAY -name "*.ttl.tgz"`; do files_to_load="yes"; done

if [ $files_to_load == "yes" -a "$dryRun" == "false" ]; then
   echo "-----------------------------------------------------------"

   if [ "$clearGraph" == "yes" ]; then
      echo ${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vdelete $graphName
      ${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vdelete $graphName
   fi
   
   echo "-----------------------------------------------------------"
   # Uncompress dump files.
   # TODO: check working dirctories, this was cd.
   pushd $TODAY &> /dev/null

      for zip in `find . -name "*.tgz"`; do # NOTE: the file extension might be lying. It could be just a zip
         ttl=`echo $zip | sed 's/^\.\/// ; s/.tgz$//'`
         echo "[INFO]: uncompressing $zip to $ttl"
         gunzip -c $zip > $ttl
         $assudo rm $zip 2> /dev/null
      done

      for zip in `find . -name "*.gz"`; do
         echo "[INFO]: uncompressing $zip"
         gunzip $zip
         #ttl=`echo $zip | sed 's/^\.\/// ; s/.gz$//'`
         $assudo rm $zip 2> /dev/null
      done

      softness="-s"; if [ "$CSV2RDF4LOD_PUBLISH_VARWWW_LINK_TYPE" == "hard" ]; then softness=""; fi

      # Load data into triple store named graph.
      rm -f $WEB_TODAY/publish/metadatasets.*
      for ttl in `find . -name "*.ttl"`; do
         ttl=`echo $ttl | sed 's/^\.\///'`
         echo "INFO `basename $0`: Loading `pwd`/$ttl into $graphName"
         ${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vload ttl $ttl $graphName | grep -v " into "

         # and link to web.
         echo "INFO `basename $0`: Linking $ttl to $WEB_TODAY/source/"
         ln $softness `pwd`/$ttl $WEB_TODAY/source
      
         # and plop into a single monolith
         echo "INFO `basename $0`: Adding to monolith Turtle"
         cat $ttl                             >> $WEB_TODAY/publish/metadatasets.ttl
      done
      if [ `which serdi` ]; then
         echo "[INFO] metadatasets.ttl -> metadatasets.nt from `pwd` to $WEB_TODAY with `which serdi`"
         serdi metadatasets.ttl > $WEB_TODAY/publish/metadatasets.nt 
         # serdi -i turtle -o ntriples metadatasets.ttl > metadatasets.nt
      else
         echo "[WARNING] cannot convert ttl to nt with serdi from `pwd` to $WEB_TODAY"
      fi
   popd &> /dev/null

   echo "INFO `basename $0`: Creating monolith RDF/XML with `which rapper`"
   rapper -q -i ntriples -o rdfxml $WEB_TODAY/publish/metadatasets.nt >> $WEB_TODAY/publish/metadatasets.rdf
   #rm $WEB_TODAY/publish/metadatasets.nt
   
   rm $WEB_LATEST
   ln -s $WEB_TODAY $WEB_LATEST

elif [ $files_to_load == "yes" ]; then
   echo ""
   echo "INFO `basename $0`: MetaDataset dump files accumulated in $TODAY:"
   echo ""
   ls -lt $TODAY | grep -v "^total"
fi

if [ $files_to_load == "no" ]; then
   echo ""
   echo "WARNING `basename $0`: did not find any files to load into $graphName"
fi

if [ $dryRun == "true" ]; then
   echo
   echo
   echo
   echo "WARNING `basename $0`: This was a dry run; triple store was NOT be modified. Use -w to load MetaDatasets into endpoint."
   echo
   echo
   echo
fi
