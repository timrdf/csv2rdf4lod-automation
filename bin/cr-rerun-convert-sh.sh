#!/bin/bash
#
# Usage:
#    (pwd: source/DDD, e.g. source/data-gov):
#
#    cr-rerun-convert-sh.sh -con raw 1623
#       deletes automatic/* and only runs the raw conversion.
#
#    cr-rerun-convert-sh.sh 1623
#       same as `cr-rerun-convert-sh.sh -con e1 1623`
#
#    cr-rerun-convert-sh.sh -con e1 1623
#       if raw conversion is NOT in automatic/, runs the raw conversion
#       if raw conversion is     in automatic/, runs the e1  conversion
#
#    cr-rerun-convert-sh.sh -con raw `cr-list-sources-datasets.sh`
#
#    todo:
#       deletes publish/* (not automatic/*) and runs ./convert-1263.sh in all version directories.

if [ $# -lt 1 ]; then
   echo "usage: `basename $0` [-n] [-con {raw,e1,e2,...,cr:ALL}] [-sourceDir {source,manual}] <cr:ALL | datasetIdentifier [datasetIdentifier]*>"
   echo ""
   echo "Remove everything in:"
   echo " source/SSS/DDD/version/VVV/automatic/* and"
   echo " source/SSS/DDD/version/VVV/publish/* "
   echo ""
   echo "Rerun raw and all enhancement conversions using"
   echo " source/SSS/DDD/version/VVV/automatic/convert-DDD.sh if it is present."
   echo ""
   echo "   -n:         dry run; do not actually run scripts."
   echo "   -con:       conversion identifier to publish (raw, e1, e2, ...) (if not specified, runs all.)"
   echo "   -sourceDir: if specified, replace source/SSS/DDD/version/VVV/automatic/convert-DDD.sh "
   echo "               with a newly-generated convert-DDD.sh for CSVs in the {source,manual} directory."
   echo ""
   echo "Invoke from source/SSS to re-convert the given conversion layers for the given dataset-ids."
   echo "Invoke from source/    to re-convert the given conversion layers for the given dataset-ids from all sources."
   exit 1
fi

back_one=`cd .. 2>/dev/null && pwd`
ANCHOR_SHOULD_BE_A_SOURCE=`basename $back_one`
if [ $ANCHOR_SHOULD_BE_A_SOURCE != "source" ]; then  # Typical case is to convert within a source;
                                                     # converting within all sources is pretty extereme.
   ANCHOR_SHOULD_BE_SOURCE=`basename \`pwd\``
   if [ $ANCHOR_SHOULD_BE_SOURCE == "source" ]; then # But do it anyway...
      echo "  Rerunning conversions for all `cr-list-sources.sh | wc -l` sources."
      for source in `cr-list-sources.sh`; do
         pushd $source &>/dev/null
            echo "##############################################`echo $source | sed 's/./#/g'`##############################################"
            echo "##############################################`echo $source | sed 's/./#/g'`##############################################"
            echo "############################################# $source #############################################"
            echo "############################################# `echo $source | sed 's/./ /g'` #############################################"
            echo "############################################# `echo $source | sed 's/./ /g'` #############################################"
            $0 $* # Run this same script now that we are in the source/ directory, using the same params we were given.
         popd &>/dev/null
      done
      exit 1
   else
      echo "  Working directory does not appear to be a SOURCE directory."
      echo "  Run `basename $0` from a SOURCE directory (e.g. csv2rdf4lod/data/source/SOURCE/)"
      exit 1
   fi
fi

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"must be set. source csv2rdf4lod/source-me.sh."}

dryRun="false"
if [ "$1" == "-n" ]; then
   dryRun="true"
   shift 
fi

source=`basename \`pwd\` | sed 's/\./-/g'`

focusConversion=""
if [ "$1" == "-con" ]; then
   focusConversion="$2"
   shift 2
fi

# This was needed when first transitioning to the csv2rdf4lod file organization,
# when the CSVs were in place but no convert-*.sh existed.
csvLoc=""
if [ "$1" == "-sourceDir" ]; then
   csvLoc="$2"
   shift 2
fi

datasetIdentifiers=""
if [ "$1" == "cr:ALL" ]; then
   #osType=`sw_vers | grep "Mac OS X" | wc -l`
   #if [ `which sw_vers 2>/dev/null | wc -l` -gt 0 -a ${osType:-"0"} -gt 0 ]; then
      #datasetIdentifiers=`find . -type d -depth 1 | sed 's/\.\///'` # For Mac OS X
   #   datasetIdentifiers=`find . -maxdepth 1 -type d | sed -e 's/\.\///' -e 's/^\.$//' | grep -v "^$" | grep -v "\..*"` # For Mac OS X
   #else
      #datasetIdentifiers=`find . -maxdepth 1 -type d | sed 's/\.\///'` # For AIX unix
   #   datasetIdentifiers=`find . -maxdepth 1 -type d | sed -e 's/\.\///' -e 's/^\.$//' | grep -v "^$" | grep -v "\..*"` # For AIX unix
   #fi

   # works fine, moved to cr-list-sources-datsets.sh:
   # datasetIdentifiers=`find . -maxdepth 1 -type d | sed -e 's/\.\///' -e 's/^\.$//' | grep -v "^$" | grep -v "\..*"` # For AIX unix
   datasetIdentifiers=`cr-list-sources-datasets.sh -s`
   shift 1
else
   if [ $# -le 0 ]; then
      $0 # Call myself with no params to get usage.
      exit 1
   fi
   while [ $# -gt 0 ]; do
      datasetIdentifier="$1"
      datasetIdentifiers="$datasetIdentifiers $datasetIdentifier"
      shift 1
   done
fi

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"must be set. source csv2rdf4lod/source-me.sh."}
CSV2RDF4LOD_BASE_URI=${CSV2RDF4LOD_BASE_URI:?"must be set. source csv2rdf4lod/source-me.sh."}

if [ ${dryRun:-"."} == "true" ]; then
   echo ""
   echo "       (NOTE: only performing dryrun; remove -n parameter to actually convert.)"
   echo ""
fi

for datasetIdentifier in $datasetIdentifiers; do
   #versionDirs=""
   #if [ `which sw_vers 2>/dev/null | wc -l` -gt 0 -a ${osType:-"0"} -gt 0 ]; then
      #less cross-compatible: versionDirs=`find $datasetIdentifier/version -type d -depth 1` # For Mac OS X
   #   versionDirs=`find 1450 -mindepth 2 -maxdepth 2 -type d | grep -v "/\."` # For Mac OS X
   #else
      #less robust: versionDirs="`find $datasetIdentifier -maxdepth 2 -type d | tail -1`" # For AIX unix
   #   versionDirs="`find 1450 -mindepth 2 -maxdepth 2 -type d | grep -v "/\."`" # For AIX unix
   #fi

   versionDirs=`find $datasetIdentifier/version -mindepth 1 -maxdepth 1 -type d | grep -v "/\."` # Cross-compatible (Mac OS X and AIX Unix)
   
   echo "all versions of $source $datasetIdentifier (`echo $versionDirs | awk '{for(i=1;i<=NF;i++) print $i}' | wc -l | awk '{print $1}'`):"
   echo "$versionDirs"
   for versionDir in $versionDirs; do
      echo "############################## $versionDir ##############################"

      sourceDir=$versionDir/source
      manualDir=$versionDir/manual
      automaticDir=$versionDir/automatic
      publishDir=$versionDir/publish
      lodmatDir=$versionDir/publish/lod-mat
      tdbDir=$versionDir/publish/tdb

      if [ ${#versionDir} -gt 0 ]; then
         version=`basename $versionDir`
         conversionIdentifiers=`find $versionDir -name "*.params.ttl" | sed -e 's/^.*\.\(.*\)\.params.ttl$/\1/' | sort -ru`
         datasetURI=$CSV2RDF4LOD_BASE_URI/source/$source/dataset/$datasetIdentifier/version/$version

         #echo "$source     $datasetIdentifier     $version"

         if [ ${focusConversion:-"."} == "raw" -o ${focusConversion:-"."} == "cr:ALL" ]; then
            echo "`basename $0` removing $automaticDir/*"
            if [ ${dryRun:-"."} != "true" ]; then
               rm $automaticDir/* &> /dev/null
            fi
         fi
         echo "`basename $0` removing $publishDir/*"
         if [ ${dryRun:-"."} != "true" ]; then
            rm $publishDir/* &> /dev/null
            touch $manualDir/*.params.ttl
         fi

         pushd $versionDir &> /dev/null

            if [ -e convert-$datasetIdentifier.sh ]; then
               for conversionIdentifier in `echo $conversionIdentifiers`; do
                  if [ $conversionIdentifier == "raw" -o $conversionIdentifier == "e1" ]; then
                     eFlag=""
                  else
                     eFlag="-e `echo $conversionIdentifier | sed 's/^e//'`"
                  fi
                  if [ ${#focusConversion} -eq 0 -o ${focusConversion:-"."} == "cr:ALL" ]; then
                     # No focus conversion was specified, so process all of them.
                     echo "`basename $0` processing conversion: $conversionIdentifier (./convert-$datasetIdentifier.sh $eFlag)"
                     if [ ${dryRun:-"."} != "true" ]; then
                        ./convert-$datasetIdentifier.sh $eFlag
                     fi
                  elif [ ${focusConversion} == $conversionIdentifier ]; then
                     # Process only the requested focus conversion.
                     echo "`basename $0` processing conversion: $conversionIdentifier (./convert-$datasetIdentifier.sh $eFlag)"
                     if [ ${dryRun:-"."} != "true" ]; then
                        ./convert-$datasetIdentifier.sh $eFlag
                     fi
                  else
                     echo "`basename $0` skipping   conversion: $conversionIdentifier b/c given parameter '-con $focusConversion'"
                  fi
               done
            elif [ ${csvLoc:-""} == "manual" -o ${csvLoc:-""} == "source" ]; then
               # Create convert-DDD.sh
               #
               # This was added for bulk processing of datasets where csvs were placed into manual/
               # and note attention was paid to their individual conversion.
               echo "`basename $0` making new convert-DDD.sh"
               if [ ${dryRun:-"."} != "true" ]; then
                  cr-create-convert-sh.sh -w $csvLoc/*[Cc][Ss][Vv]
               fi
            else 
               echo "`basename $0` convert-$datasetIdentifier.sh does not exist; not running conversion."
            fi
         popd &> /dev/null

      else
         echo $datasetIdentifier: skipping b/c could not find directory $versionDir
      fi
      echo ""

   done
   shift
done
