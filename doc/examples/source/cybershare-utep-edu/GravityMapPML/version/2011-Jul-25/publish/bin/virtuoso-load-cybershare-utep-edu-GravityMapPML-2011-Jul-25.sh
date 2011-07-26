#!/bin/bash
#
# run publish/bin/virtuoso-load-cybershare-utep-edu-GravityMapPML-2011-Jul-25.sh
# from source/cybershare-utep-edu/GravityMapPML/version/2011-Jul-25/
#
# graph was http://logd.tw.rpi.edu/source/cybershare-utep-edu/dataset/GravityMapPML/version/2011-Jul-25 during conversion
#
#
#                         (unversioned) Dataset       # <---- Loads this with param --unversioned
#                                 |          \   
# Loads this by default -> VersionedDataset   meta    # <---- Loads this with param --meta
#                                 |         
#                             DatasetLayer
#                               /    \ 
# Never loads this ----> [table]   DatasetLayerSample # <---- Loads this with param --sample

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}
CSV2RDF4LOD_BASE_URI=${CSV2RDF4LOD_BASE_URI:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

allNT=publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.nt # to cite graph
graph="`cat $allNT.graph`"
if [ "$1" == "--sample" ]; then
   layerSlug="raw"
   sampleGraph="$graph/conversion/$layerSlug/subset/sample"
   sampleURL="${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}/source/cybershare-utep-edu/file/GravityMapPML/version/2011-Jul-25/conversion/cybershare-utep-edu-GravityMapPML-2011-Jul-25.raw.sample.ttl"
   echo ${CSV2RDF4LOD_HOME}/bin/util/pvload.sh $sampleURL -ng $sampleGraph
   ${CSV2RDF4LOD_HOME}/bin/util/pvload.sh $sampleURL -ng $sampleGraph

   layerSlug="enhancement/1"
   sampleGraph="$graph/conversion/$layerSlug/subset/sample"
   sampleURL="${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}/source/cybershare-utep-edu/file/GravityMapPML/version/2011-Jul-25/conversion/cybershare-utep-edu-GravityMapPML-2011-Jul-25.e1.sample.ttl"
   echo ${CSV2RDF4LOD_HOME}/bin/util/pvload.sh $sampleURL -ng $sampleGraph
   ${CSV2RDF4LOD_HOME}/bin/util/pvload.sh $sampleURL -ng $sampleGraph

   exit 1
elif [ "${1:-'.'}" == "--meta" -a -e publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.void.ttl ]; then
   metaURL="${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}/source/cybershare-utep-edu/file/GravityMapPML/version/2011-Jul-25/conversion/cybershare-utep-edu-GravityMapPML-2011-Jul-25.void.ttl"
   metaGraph="${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}"/vocab/Dataset
   echo ${CSV2RDF4LOD_HOME}/bin/util/pvload.sh $metaURL -ng $metaGraph
   ${CSV2RDF4LOD_HOME}/bin/util/pvload.sh $metaURL -ng $metaGraph
   exit 1
fi

# Modify the graph before continuing to load everything
if [[ ${1:-'.'} == "--unversioned" || ${1:-'.'} == "--abstract" ]]; then
   # strip off version
   graph="`echo $graph\ | perl -pe 's|/version/[^/]*$||'`"
   graph="${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}/source/cybershare-utep-edu/dataset/GravityMapPML"
   echo populating abstract named graph \($graph\) instead of versioned named graph.
elif [ $# -gt 0 ]; then
   echo param not recognized: $1
   echo usage: `basename $0` with no parameters loads versioned dataset
   echo usage: `basename $0` --{sample, meta, abstract}
   exit 1
fi

dump=publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.nt
url=http://logd.tw.rpi.edu/source/cybershare-utep-edu/file/GravityMapPML/version/2011-Jul-25/conversion/cybershare-utep-edu-GravityMapPML-2011-Jul-25.nt
if [ -e $dump ]; then
   echo ${CSV2RDF4LOD_HOME}/bin/util/pvload.sh $url -ng $graph
   ${CSV2RDF4LOD_HOME}/bin/util/pvload.sh $url -ng $graph
   exit 1
elif [ -e $dump.gz ]; then
   echo ${CSV2RDF4LOD_HOME}/bin/util/pvload.sh $url.gz -ng $graph
   ${CSV2RDF4LOD_HOME}/bin/util/pvload.sh $url.gz -ng $graph
   exit 1
fi

dump=publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.ttl
url=http://logd.tw.rpi.edu/source/cybershare-utep-edu/file/GravityMapPML/version/2011-Jul-25/conversion/cybershare-utep-edu-GravityMapPML-2011-Jul-25.ttl
if [ -e $dump ]; then
   echo ${CSV2RDF4LOD_HOME}/bin/util/pvload.sh $url -ng $graph
   ${CSV2RDF4LOD_HOME}/bin/util/pvload.sh $url -ng $graph
   exit 1
elif [ -e $dump.gz ]; then
   echo ${CSV2RDF4LOD_HOME}/bin/util/pvload.sh $url.gz -ng $graph
   ${CSV2RDF4LOD_HOME}/bin/util/pvload.sh $url.gz -ng $graph
   exit 1
fi

dump=publish/cybershare-utep-edu-GravityMapPML-2011-Jul-25.rdf
url=http://logd.tw.rpi.edu/source/cybershare-utep-edu/file/GravityMapPML/version/2011-Jul-25/conversion/cybershare-utep-edu-GravityMapPML-2011-Jul-25.rdf
if [ -e $dump ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pvload.sh $url -ng $graph
   sudo /opt/virtuoso/scripts/vload rdf $dump $graph
   exit 1
elif [ -e $dump.gz ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pvload.sh $url.gz -ng $graph
   exit 1
fi
