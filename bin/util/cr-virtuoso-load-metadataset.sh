#!/bin/bash
# 
# Usage: logd-load-metadata-graph.sh [-n] [http://named-graph-for-endpoint]

echo "-----------------------------------------" 
echo "initializing ........." 
dryRun="false"
if [ "$1" == "-n" ]; then
   dryRun="true"
   echo "[INFO] dryRun flagged, no triple store loading. Remove -n parameter to actually load dump files into endpoint."
   shift
fi

metaDatasetGraph='http://purl.org/twc/vocab/conversion/MetaDataset'
if [ $# -gt 0 ]; then
   metaDatasetGraph="$1" 
fi
echo "[INFO] metadata graph URI is: $metaDatasetGraph "

assudo="sudo"
if [ `whoami` == "root" ]; then
   assudo=""
fi

#######################
# init: clean up intermediate results folder
SOURCE="/work/data-gov/v2010/csv2rdf4lod/data/source"
TEMP="/work/data-gov/temp/logd-load-metadata-graph"
$assudo rm -rf $TEMP 2> /dev/null
$assudo mkdir -p $TEMP

echo "[INFO] temp data directory is: $TEMP "
echo "(`ls $TEMP | wc -l` files)"
echo ""

get_dump_file() {
   source_id="$1"  # param 1: source_id
   dataset_id="$2" # param 2: dataset_id
   latest_version_id=`ls -lt $SOURCE/$source_id/$dataset_id/version | grep "^d" | awk '{print $9}' | head -1`
   echo "[INFO] dataset metadata:     $source_id     $dataset_id     $latest_version_id "
   dump_ttl_zip=`ls -t $SOURCE/$source_id/$dataset_id/version/$latest_version_id/publish/*-$latest_version_id.ttl.*gz | head -1`
   echo "[INFO] dataset dump file:  $dump_ttl_zip"
   $assudo cp $dump_ttl_zip $TEMP
}

echo "-----------------------------------------" 
echo "prepare dump file ........." 

# International dataset catalog initiative:
get_dump_file "data-baltimorecity-gov"            "catalog"
get_dump_file "data-cityofchicago-org"            "catalog"
get_dump_file "data-gc-ca"            "catalog"
get_dump_file "data-gov-au"            "catalog"
get_dump_file "data-govt-nz"            "catalog"
get_dump_file "data-gov-uk"            "catalog"
get_dump_file "data-london-gov-uk"            "catalog"
get_dump_file "data-nsw-gov-au"            "catalog"
get_dump_file "data-octo-dc-gov"            "catalog"
get_dump_file "data-ok-gov"            "catalog"
get_dump_file "data-oregon-gov"            "catalog"
get_dump_file "data-seattle-gov"            "catalog"
get_dump_file "data-vancouver-ca"            "catalog"
get_dump_file "data-vic-gov-au"            "catalog"
get_dump_file "data-wa-gov"            "catalog"
get_dump_file "data-worldbank-org"            "catalog"
get_dump_file "nysenate-gov"            "catalog"
get_dump_file "ottawa-ca"            "catalog"
get_dump_file "toronto-ca"            "catalog"


get_dump_file "aporta-es"  "catalog"
get_dump_file "consejotransparencia-cl"  "catalog"
get_dump_file "data-rennes-metropole-fr"	"catalog"
get_dump_file "datakc-org"	"catalog"
get_dump_file "dati-piemonte-it"	"catalog"
get_dump_file "montevideo-gub-uy"	"catalog"
get_dump_file "navarra-es"            "catalog"
get_dump_file "portalu-de"            "catalog"

#special
get_dump_file "data-gov" "92"
get_dump_file "twc-rpi-edu" "dataset-catalog"
get_dump_file "geodata-gov"            "catalog"

echo "-----------------------------------------" 
echo " triple store management ........." 

if [ `ls $TEMP/*gz | wc -l` -gt 0 -a ${dryRun:-"false"} == "false" ]; then
   echo "-----------------------------------------------------------"
   echo " clean up named graph "
   
   $assudo /opt/virtuoso/scripts/vdelete $metaDatasetGraph
   

   echo "-----------------------------------------------------------"
   echo " load data into graph "
   
   cd $TEMP

   for zip in `find . -name "*.gz"`; do
      gunzip $zip
      ttl=`echo $zip | sed 's/^\.\/// ; s/.gz$//'`
      echo "[INFO] Loading `pwd`/$ttl into $metaDatasetGraph"
      $assudo /opt/virtuoso/scripts/vload ttl $ttl $metaDatasetGraph
      $assudo rm $zip 2> /dev/null
   done
elif [ `ls $TEMP/*gz | wc -l` -le 0 ]; then
   echo "[WARNING]: did not find any files to load into $metaDatasetGraph"
else
   echo ""
   ls -lt $TEMP
fi
