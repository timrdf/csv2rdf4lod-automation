#!/bin/sh
#
# usage:
#   cr-create-dataset-dir.sh -d dataset-1 -v version-1 
#   cr-create-dataset-dir.sh -d dataset-1 -v version-1 version-2
#   cr-create-dataset-dir.sh -d dataset-1 -v version-1 version-2 version-3
#
#   cr-create-dataset-dir.sh -d tus-cps-2006-07 tusc-cps-2003 tus-cps-2001-02
#
#   cr-create-dataset-dir.sh -v version-1 -d dataset-1 
#   cr-create-dataset-dir.sh -v version-1 -d dataset-1 dataset-2
#   cr-create-dataset-dir.sh -v version-1 -d dataset-1 dataset-2 dataset-3
#
#   cr-create-dataset-dir.sh -v 2010-Jul-14 `find . -depth 1 -type d | sed 's/^..//' | awk '{printf(" -d %s",$0)}'`

usage="usage: `basename $0` {-d datasetIdentifier | -v datasetVersion}+"

if [ $# -lt 2 ]; then
   echo $usage
   exit 1
fi

if [ -d source -a -d manual ]; then
   echo "  Working directory appears to be a VERSION directory (e.g. source/SOURCE/DATASET/version/VERSION/)."
   echo "  Run `basename $0` from a SOURCE directory (e.g. source/SOURCE/)"
   exit 1
fi

back_one=`cd .. 2>/dev/null && pwd`
ANCHOR_SHOULD_BE_SOURCE=`basename $back_one`
if [ $ANCHOR_SHOULD_BE_SOURCE != 'source' ]; then
   echo "  Working directory does not appear to be a SOURCE directory."
   echo "  Run `basename $0` from a SOURCE directory (e.g. csv2rdf4lod/data/source/SOURCE/)"
   exit 1
fi

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh"}

datasetIdentifier=""
versionIdentifier=""

while [ $# -gt 0 ]; do

   if [ "$1" == "-d" ]; then
      flag="$1"
      shift
   elif [ "$1" == "-v" ]; then
      flag="$1"
      shift
   fi

   if [ "$flag" == "" ]; then
      echo "flag not set; skipping \"$1\"."
      shift
      continue
   fi

   if [ $flag == "-d" ]; then
      datasetIdentifier="$1"  
   elif [ $flag == "-v" ]; then
      datasetVersion="$1"  
   fi
   shift

   if [ "$datasetIdentifier" == "" ]; then
      echo "skipping -d \"$datasetIdentifier\" -v \"$datasetVersion\"; because -d empty."
      continue
   fi

   if [ "$datasetVersion" == "" ]; then
      datasetVersion="unversioned"
   fi

   echo "-d \"$datasetIdentifier\" -v \"$datasetVersion\""

   if [ ! -e $datasetIdentifier ]; then
      echo $datasetIdentifier
      mkdir $datasetIdentifier
   fi

   if [ ! -e $datasetIdentifier/doc ]; then
      echo $datasetIdentifier/doc
      mkdir $datasetIdentifier/doc
   fi

   if [ ! -e $datasetIdentifier/version ]; then
      echo $datasetIdentifier/version
      mkdir $datasetIdentifier/version
   fi

   sourceDir=version/$datasetVersion/source
   base="../../.."

   if [ ! -e $datasetIdentifier/version/$datasetVersion ]; then
      echo $datasetIdentifier/version/$datasetVersion
      mkdir $datasetIdentifier/version/$datasetVersion
   fi
   if [ ! -e $datasetIdentifier/version/$datasetVersion/source ]; then
      echo $datasetIdentifier/version/$datasetVersion/source
      mkdir $datasetIdentifier/version/$datasetVersion/source
   fi
   if [ ! -e $datasetIdentifier/version/$datasetVersion/manual ]; then
      echo $datasetIdentifier/version/$datasetVersion/manual
      mkdir $datasetIdentifier/version/$datasetVersion/manual
   fi

   if [ ! -e $datasetIdentifier/version/$datasetVersion/convert-$datasetIdentifier.sh ]; then
      if [ `find $datasetIdentifier/$sourceDir -type f -and -name '*[Cc][Ss][Vv]' | wc -l` -gt 0 ]; then
         pushd $datasetIdentifier/version/$datasetVersion &> /dev/null
         # TODO: spaces in filenames are not being handled correctly. e.g., dataset 1500-1505.
         cr-create-convert-sh.sh -d $datasetIdentifier `find source -type f -and -name '*.[Cc][Ss][Vv]'` > convert-$datasetIdentifier.sh 
         # perl is grabbing the .csv.pml.ttl and should not be.
         #cr-create-convert-sh.sh -d $datasetIdentifier `perl -l -MFile::Find -e 'find(sub { my $name = $File::Find::name; next unless (-r $_ and -f _ and /[.]csv/i); $name =~ s/ /\\ /g; print $name; }, @ARGV);' source` > convert-$datasetIdentifier.sh 
      fi
   fi
done
