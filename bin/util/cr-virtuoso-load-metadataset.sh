#!/bin/bash
# 
# Usage: logd-load-metadata-graph.sh [-w] [-ng http://named-graph-for-endpoint] [source-id dataset-id]*
# See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Aggregating-subsets-of-converted-datasets

echo "------------------- `basename $0` --------------------"
dryRun="true"
if [ "$1" == "-w" ]; then
   dryRun="false"
   shift
fi
if [ $dryRun == "true" ]; then
   echo
   echo
   echo
   echo "[WARNING] This is a dry run; triple store will NOT be modified. Use -w to load MetaDatasets into endpoint."
   echo
   echo
   echo
fi

metaDatasetGraph='http://purl.org/twc/vocab/conversion/MetaDataset'
if [ "$1" == "-ng" -a $# -gt 1 ]; then
   metaDatasetGraph="$2" 
   shift 2
fi
echo "[INFO] Will load MetaDataset(s) into named graph: $metaDatasetGraph "

# We can run as root or as a normal user.
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

get_dump_file() {
   source_id="$1"  # param 1: source_id
   dataset_id="$2" # param 2: dataset_id
   if [ -d $SOURCE/$source_id/$dataset_id/version ]; then
   latest_version_id=`ls -lt $SOURCE/$source_id/$dataset_id/version | grep "^d" | awk '{print $9}' | head -1`
   echo "-----------------------------------------" 
   echo "$source_id  $dataset_id  $latest_version_id "
   dump_ttl_zip=`ls -t $SOURCE/$source_id/$dataset_id/version/$latest_version_id/publish/*-$latest_version_id.ttl.*gz | head -1`
   echo "   $dump_ttl_zip"
   $assudo cp $dump_ttl_zip $TEMP
   else
      echo "WARNING: $source_id $dataset_id - $SOURCE/$source_id/$dataset_id/version not found."
   fi
}

echo "-----------------------------------------" 
echo "[INFO] Accumulating MetaDataset dump files to temp directory $TEMP "

if [ $# -gt 1 ]; then
   echo "MetaDataset source-ids and dataset-ids are provided as parameters. Including only those."
   while [ $# -gt 1 ]; do
      source_id="$1"
      dataset_id="$2"
      get_dump_file $source_id $dataset_id
      shift 2
   done
else 
   # International dataset catalog initiative:
   get_dump_file "data-baltimorecity-gov"   "catalog"
   get_dump_file "data-cityofchicago-org"   "catalog"
   get_dump_file "data-gc-ca"               "catalog"
   get_dump_file "data-gov-au"              "catalog"
   get_dump_file "data-govt-nz"             "catalog"
   get_dump_file "data-gov-uk"              "catalog"
   get_dump_file "data-london-gov-uk"       "catalog"
   get_dump_file "data-nsw-gov-au"          "catalog"
   get_dump_file "data-octo-dc-gov"         "catalog"
   get_dump_file "data-ok-gov"              "catalog"
   get_dump_file "data-oregon-gov"          "catalog"
   get_dump_file "data-seattle-gov"         "catalog"
   get_dump_file "data-vancouver-ca"        "catalog"
   get_dump_file "data-vic-gov-au"          "catalog"
   get_dump_file "data-wa-gov"              "catalog"
   get_dump_file "data-worldbank-org"       "catalog"
   get_dump_file "nysenate-gov"             "catalog"
   get_dump_file "ottawa-ca"                "catalog"
   get_dump_file "toronto-ca"               "catalog"


   get_dump_file "aporta-es"                "catalog"
   get_dump_file "consejotransparencia-cl"  "catalog"
   get_dump_file "data-rennes-metropole-fr" "catalog"
   get_dump_file "datakc-org"	              "catalog"
   get_dump_file "dati-piemonte-it"	        "catalog"
   get_dump_file "montevideo-gub-uy"	     "catalog"
   get_dump_file "navarra-es"               "catalog"
   get_dump_file "portalu-de"               "catalog"

   #special
   get_dump_file "data-gov"                 "92"
   get_dump_file "twc-rpi-edu"              "dataset-catalog"
   get_dump_file "geodata-gov"              "catalog"
fi

echo "-----------------------------------------" 

files_to_load="no"
for file in `find $TEMP -name "*gz"`; do files_to_load="yes"; done

if [ $files_to_load == "yes" -a ${dryRun:-"false"} == "false" ]; then
   echo "-----------------------------------------------------------"

   echo $assudo /opt/virtuoso/scripts/vdelete $metaDatasetGraph
   $assudo /opt/virtuoso/scripts/vdelete $metaDatasetGraph # TODO: use $CSV2RDF4LOD_HOME/bin/util/virtuoso/vdelete
   

   # Load data into graph
   echo "-----------------------------------------------------------"
   cd $TEMP
   for zip in `find . -name "*.gz"`; do
      gunzip $zip
      ttl=`echo $zip | sed 's/^\.\/// ; s/.gz$//'`
      echo "[INFO] Loading `pwd`/$ttl into $metaDatasetGraph"
      $assudo /opt/virtuoso/scripts/vload ttl $ttl $metaDatasetGraph # TODO: use $CSV2RDF4LOD_HOME/bin/util/virtuoso/vload
      $assudo rm $zip 2> /dev/null
   done
elif [ $files_to_load == "yes" ]; then
   echo ""
   echo "MetaDataset dump files accumulated in temp directory $TEMP:"
   echo ""
   ls -lt $TEMP | grep -v "^total"
fi

if [ $files_to_load == "no" ]; then
   echo ""
   echo "[WARNING]: did not find any files to load into $metaDatasetGraph"
fi

if [ $dryRun == "true" ]; then
   echo
   echo
   echo
   echo "[WARNING] This was a dry run; triple store was NOT be modified. Use -w to load MetaDatasets into endpoint."
   echo
   echo
   echo
fi
