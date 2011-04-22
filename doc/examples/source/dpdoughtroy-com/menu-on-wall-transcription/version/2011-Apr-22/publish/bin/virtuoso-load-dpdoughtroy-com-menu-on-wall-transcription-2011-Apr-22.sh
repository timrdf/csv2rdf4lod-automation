#!/bin/bash
#
# run publish/bin/virtuoso-load-dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.sh
# from source/dpdoughtroy-com/menu-on-wall-transcription/version/2011-Apr-22/
#
# graph was http://logd.tw.rpi.edu/source/dpdoughtroy-com/dataset/menu-on-wall-transcription/version/2011-Apr-22 during conversion
#
#
#                         (unversioned) Dataset       # <---- Loads this with param --unversioned
#                                 |          \   
# Loads this by default -> VersionedDataset   meta    # <---- Loads this with param --meta
#                                 |         
#                             DatasetLayer
#                               /    \ 
# Never loads this ----> [table]   DatasetLayerSample # <---- Loads this with param --sample

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh"}
CSV2RDF4LOD_BASE_URI=${CSV2RDF4LOD_BASE_URI:?"not set; source csv2rdf4lod/source-me.sh"}

allNT=publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.nt # to cite graph
graph="`cat $allNT.graph`"
if [ "$1" == "--sample" ]; then
   conversionStep="raw"
   sampleTTL=publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.raw.sample.ttl
   sampleGraph="$graph/conversion/$conversionStep/subset/sample"
   #sudo /opt/virtuoso/scripts/vload ttl $sampleTTL $sampleGraph
   sampleURL="http://logd.tw.rpi.edu/source/dpdoughtroy-com/file/menu-on-wall-transcription/version/2011-Apr-22/conversion/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.raw.sample"
   echo ${CSV2RDF4LOD_HOME}/bin/util/pvload.sh $sampleURL -ng $sampleGraph
   ${CSV2RDF4LOD_HOME}/bin/util/pvload.sh $sampleURL -ng $sampleGraph

   conversionStep="enhancement/1"
   sampleTTL=publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.e1.sample.ttl
   sampleGraph="$graph/conversion/$conversionStep/subset/sample"
   #sudo /opt/virtuoso/scripts/vload ttl $sampleTTL $sampleGraph
   sampleURL="http://logd.tw.rpi.edu/source/dpdoughtroy-com/file/menu-on-wall-transcription/version/2011-Apr-22/conversion/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.e1.sample"
   echo ${CSV2RDF4LOD_HOME}/bin/util/pvload.sh $sampleURL -ng $sampleGraph
   ${CSV2RDF4LOD_HOME}/bin/util/pvload.sh $sampleURL -ng $sampleGraph

   exit 1
elif [ "${1:-'.'}" == "--meta" -a -e publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.void.ttl ]; then
   graph="${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}"/vocab/Dataset
   echo sudo /opt/virtuoso/scripts/vload ttl publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.void.ttl $graph
   sudo /opt/virtuoso/scripts/vload ttl publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.void.ttl $graph
   exit 1
fi

# Modify the graph before continuing to load everything
if [ ${1:-'.'} == "--unversioned" ]; then
   # strip off version
   graph="`echo $graph\ | perl -pe 's|/version/[^/]*$||'`"
   echo populating unversioned named graph \($graph\) instead of versioned named graph.
elif [ $# -gt 0 ]; then
   echo param not recognized: $1
   echo usage: `basename $0` with no parameters loads versioned dataset
   echo usage: `basename $0` --{unversioned,meta,sample}
   exit 1
fi


dump=publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.nt
TEMP="_"`basename $dump`_tmp
url=http://logd.tw.rpi.edu/source/dpdoughtroy-com/file/menu-on-wall-transcription/version/2011-Apr-22/conversion/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.nt
if [ -e $dump ]; then
   echo ${CSV2RDF4LOD_HOME}/bin/util/pvload.sh $url -ng $graph
   ${CSV2RDF4LOD_HOME}/bin/util/pvload.sh $url -ng $graph
   #sudo /opt/virtuoso/scripts/vload nt $dump $graph
   exit 1
elif [ -e $dump.gz ]; then
   echo ${CSV2RDF4LOD_HOME}/bin/util/pvload.sh $url.gz -ng $graph
   ${CSV2RDF4LOD_HOME}/bin/util/pvload.sh $url.gz -ng $graph
   #gunzip -c $dump.gz > $TEMP
   #sudo /opt/virtuoso/scripts/vload nt $TEMP $graph
   rm $TEMP
   exit 1
fi

dump=publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.ttl
url=http://logd.tw.rpi.edu/source/dpdoughtroy-com/file/menu-on-wall-transcription/version/2011-Apr-22/conversion/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.ttl
if [ -e $dump ]; then
   echo ${CSV2RDF4LOD_HOME}/bin/util/pvload.sh $url -ng $graph
   ${CSV2RDF4LOD_HOME}/bin/util/pvload.sh $url -ng $graph
   #echo sudo /opt/virtuoso/scripts/vload ttl $dump $graph
   #sudo /opt/virtuoso/scripts/vload ttl $dump $graph
   exit 1
elif [ -e $dump.gz ]; then
   echo ${CSV2RDF4LOD_HOME}/bin/util/pvload.sh $url.gz -ng $graph
   ${CSV2RDF4LOD_HOME}/bin/util/pvload.sh $url.gz -ng $graph
   #gunzip -c $dump.gz > $TEMP
   #echo sudo /opt/virtuoso/scripts/vload ttl $TEMP $graph
   #sudo /opt/virtuoso/scripts/vload ttl $TEMP $graph
   #rm -f $TEMP
   exit 1
fi

dump=publish/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.rdf
url=http://logd.tw.rpi.edu/source/dpdoughtroy-com/file/menu-on-wall-transcription/version/2011-Apr-22/conversion/dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.rdf
if [ -e $dump ]; then
   #${CSV2RDF4LOD_HOME}/bin/util/pvload.sh $url -ng $graph
   sudo /opt/virtuoso/scripts/vload rdf $dump $graph
   exit 1
elif [ -e $dump.gz ]; then
   #${CSV2RDF4LOD_HOME}/bin/util/pvload.sh $url.gz -ng $graph
   gunzip -c $dump.gz > $TEMP
   sudo /opt/virtuoso/scripts/vload rdf $TEMP $graph
   rm $TEMP
   exit 1
fi
