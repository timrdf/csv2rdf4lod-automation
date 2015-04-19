# <> prov:specializationOf <https://raw.github.com/timrdf/csv2rdf4lod-automation/master/bin/convert-aggregate.sh> .
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

# Aggregate conversion outputs into publishable datafiles.
#
# Up to this point, all processing was done using filenames provided by the dataset source organization.
# Put all data into $sourceID-$datasetID-$versionID dump files and construct command appropriate
# for lod-materialization.
#
#
# This script is ___NOT___ to be called directly:
# Called by conversion trigger (e.g. convert-DATASET.sh)
# The conversion trigger is created by manually invoking cr-create-conversion-trigger.sh)
# This script can also be invoked by running publish/bin/publish.sh (created by the conversion trigger)

see='https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set'
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $see"}

if [ "$CSV2RDF4LOD_CONVERT_DEBUG_LEVEL" == "fine" ]; then
   # The following variables are needed by this script
   # They are set by publish/bin/publish.sh before calling this script.

   echo $sourceID  `cr-source-id.sh`
   echo $datasetID `cr-dataset-id.sh`
   echo $versionID `cr-version-id.sh`

   echo $eID TODO

   echo $graph `cr-dataset-uri.sh --uri`

   CSV2RDF4LOD_FORCE_PUBLISH="true"
fi

# These directory names have become canonical.
# The flexibility to change them is no longer desirable.
convertDir=${convertDir:-automatic}   # Could be renamed to 'converted'?
#publishDir=${publishDir:-publish}    # hard coded now, as it should be.
# # # # # # # # # # # # # # # # # # # #


# These variables are embedded in the directory conventions.
baseURI=${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}
 sourceID=`cr-source-id.sh`     #
datasetID=`cr-dataset-id.sh`    #
versionID=`cr-version-id.sh`    #
# see https://github.com/timrdf/csv2rdf4lod-automation/wiki/Directory-Conventions

# NOTE: eID is provided by conversion trigger, but the case where it is not provided should be handled
# (e.g. when cr-publish-cockpit.sh calls this script)

graph=`cr-dataset-uri.sh --uri`

if [ "$CSV2RDF4LOD_FORCE_PUBLISH" == "true" ]; then
   echo "convert-aggregate.sh publishing raw and enhancements (forced)." | tee -a $CSV2RDF4LOD_LOG
   echo "===========================================================================================" | tee -a $CSV2RDF4LOD_LOG
else
   if [ "$CSV2RDF4LOD_PUBLISH" == "false" ]; then
         echo "convert-aggregate.sh not publishing b/c \$CSV2RDF4LOD_PUBLISH=false."                        | tee -a $CSV2RDF4LOD_LOG
         echo "===========================================================================================" | tee -a $CSV2RDF4LOD_LOG
         rm $CSV2RDF4LOD_LOG
         CSV2RDF4LOD_LOG=""
         exit 1
   fi
   rawdumps="no"; for dump in `find $convertDir -name "*.raw.ttl"`;   do rawdumps="yes"; done
   edumps="no";   for dump in `find $convertDir -name "*.e$eID.ttl"`; do edumps="yes";   done
   if [[ "$CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER" == "true" && "$CSV2RDF4LOD_PUBLISH_DELAY_UNTIL_ENHANCED" == "false" && "$edumps" == "no" ]]; then
      echo "convert-aggregate.sh delaying publishing until an enhancement is available."                                                  | tee -a $CSV2RDF4LOD_LOG
   fi
   if [ "$CSV2RDF4LOD_PUBLISH_DELAY_UNTIL_ENHANCED" == "true" ]; then
      #if [[ $runEnhancement == "yes" && ( `ls $convertDir/*.e$eID.ttl 2> /dev/null | wc -l` > 0 || ${CSV2RDF4LOD_CONVERT_EXAMPLE_SUBSET_ONLY-"."} == "true" ) ]]; then
      if [[ $runEnhancement == "yes" && ( $edumps == "yes" || "$CSV2RDF4LOD_CONVERT_EXAMPLE_SUBSET_ONLY" == "true" ) ]]; then
         echo "convert-aggregate.sh publishing raw and enhancements."                                                                     | tee -a $CSV2RDF4LOD_LOG
      else
         # NOTE: If multiple files to convert and the LAST file is not enhanced,
         #       the runEnhancement flag will be "no" and convert-aggregate.sh will not aggregate.
         # To overcome this bug, manually run publish/bin/publish.sh to force the aggregation.
         sourceme="my-csv2rdf4lod-source-me.sh"
         echo "convert-aggregate.sh delaying publishing until an enhancement is available."                                               | tee -a $CSV2RDF4LOD_LOG
         echo "  To publish with only raw, set CSV2RDF4LOD_PUBLISH_DELAY_UNTIL_ENHANCED=\"false\" in \$CSV2RDF4LOD_HOME/$sourceme.sh."    | tee -a $CSV2RDF4LOD_LOG
         echo "  To publish raw with enhanced, add enhancement to $eParamsDir/$datafile.e$eID.params.ttl and rerun convert-$datasetID.sh" | tee -a $CSV2RDF4LOD_LOG
         echo "  To force publishing now, run publish/bin/publish.sh"                                                                     | tee -a $CSV2RDF4LOD_LOG
         echo "==========================================================================================="                               | tee -a $CSV2RDF4LOD_LOG
         rm $CSV2RDF4LOD_LOG
         CSV2RDF4LOD_LOG=""
         exit 1
      fi
   fi
   newest_publication="publish/`ls -lt publish/ | grep -v "total" | grep -v "bin" | head -1 | awk '{print $NF}'`"
   if [ -e "$newest_publication" ]; then
      newest_automatic="automatic/`find automatic -newer $newest_publication -and -not -name "*params*" | head -1`"
      if [ "$newest_automatic" == "automatic/" ]; then
         echo "INFO `basename $0` skipping aggregation into publish/ because nothing in automatic/ is newer."
         exit
      fi
   fi
fi

if [ ! -e publish/bin ]; then
   mkdir -p publish/bin
fi
touch publish

myMD5=`md5.sh $0`

if [ ${#versionID} -le 0 ]; then
   # For legacy compatibility. datasetVersion was renamed to versionID.
   versionID=$datasetVersion
fi
    S_D_V=$sourceID-$datasetID-$versionID
     pSDV=publish/$sourceID-$datasetID-$versionID
   allRaw=publish/$sourceID-$datasetID-$versionID.raw.ttl
    allEX=publish/$sourceID-$datasetID-$versionID.e$eID.ttl # only the current enhancement.
   allTTL=publish/$sourceID-$datasetID-$versionID.ttl
    allNT=publish/$sourceID-$datasetID-$versionID.nt
allRDFXML=publish/$sourceID-$datasetID-$versionID.rdf
  allVOID=publish/$sourceID-$datasetID-$versionID.void.ttl
allVOIDNT=publish/$sourceID-$datasetID-$versionID.void.nt
   allPML=publish/$sourceID-$datasetID-$versionID.pml.ttl
allSAMEAS=publish/$sourceID-$datasetID-$versionID.sameas.nt
rawSAMPLE=publish/$sourceID-$datasetID-$versionID.raw.sample.ttl
versionedDatasetURI="$baseURI/source/$sourceID/dataset/$datasetID/version/$versionID"
     rawSampleGraph="$baseURI/source/$sourceID/dataset/$datasetID/version/$versionID/conversion/raw/subset/sample"
         http_allNT="$baseURI/source/${sourceID}/file/${datasetID}/version/${versionID}/conversion/${sourceID}-${datasetID}-${versionID}.nt"
        http_allTTL="$baseURI/source/${sourceID}/file/${datasetID}/version/${versionID}/conversion/${sourceID}-${datasetID}-${versionID}.ttl"
     http_allRDFXML="$baseURI/source/${sourceID}/file/${datasetID}/version/${versionID}/conversion/${sourceID}-${datasetID}-${versionID}.rdf"

# Special case needs:
    allNT_L=$sourceID-$datasetID-$versionID.nt        # L: Local name (not including directory; for use when pushd'ing to cHuNk)
allSAMEAS_L=$sourceID-$datasetID-$versionID.sameas.nt

filesToCompress=""

# TODO: align with CSV2RDF4LOD_CONVERT_DUMP_FILE_EXTENSIONS                 "cr:auto" => ttl.gz
# bin/util/dump-file-extensions.sh defaults to gz
zip="gz"
if [ ! `which rapper` ]; then
   # check if rapper is on path, if not, report error.
   echo "NOTE: rapper not found. Some serializations will probably be empty." | tee -a $CSV2RDF4LOD_LOG
fi

or_see_github="or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"

layerSlugs=""
conversionIDs=""

#
# Raw ttl
#
convertedRaw="no"; for raw in `find automatic -name "*.raw.ttl"`; do convertedRaw="yes"; done
if [ $convertedRaw == "yes" ]; then
   echo $allRaw | tee -a $CSV2RDF4LOD_LOG
   cat automatic/*.raw.ttl > $allRaw
   filesToCompress="$allRaw"
   conversionIDs="$conversionIDs raw"
   layerSlugs="$layerSlugs raw"
else
   echo "$allRaw - omitted" | tee -a $CSV2RDF4LOD_LOG
fi

#
# Sample of raw (enhanced samples done below)
#
convertedRawSamples="no"; for raw in `find automatic -name "*.raw.sample.ttl"`; do convertedRawSamples="yes"; done
if [ $convertedRawSamples == "yes" ]; then
   echo $pSDV.raw.sample.ttl | tee -a $CSV2RDF4LOD_LOG
   cat automatic/*.raw.sample.ttl > $pSDV.raw.sample.ttl
else
   echo 'publish/*.raw.sample.ttl - omitted'
fi

#
# Individual enhancement ttl (any that are not aggregated)
#
# Got messed up when added sample.ttl:
#     enhancementLevels=`ls $convertDir/*.e*.ttl 2> /dev/null | grep -v void.ttl | sed -e 's/^.*\.e\([^.]*\).ttl/\1/' | sort -u`
# This works, but moved to script:
#     enhancementLevels=`find $convertDir -name "*.e[!.].ttl" | sed -e 's/^.*\.e\([^.]*\).ttl/\1/' | sort -u` # WARNING: only handles e1 through e9
enhancementLevels=`cr-list-enhancement-identifiers.sh` # WARNING: only handles e1 through e9
filesToCompress=""
anyEsDone="no"
for eIDD in $enhancementLevels; do # eIDD to avoid overwritting currently-requested enhancement eID
   eTTL=publish/$sourceID-$datasetID-$versionID.e$eIDD.ttl
   eTTLsample=publish/$sourceID-$datasetID-$versionID.e$eIDD.sample.ttl

   # Aggregate the enhancements.
   echo $eTTL | tee -a $CSV2RDF4LOD_LOG
   cat automatic/*.e$eIDD.ttl > $eTTL
   if [[ "$CSV2RDF4LOD_PUBLISH_COMPRESS" == "true" && "$CSV2RDF4LOD_PUBLISH_TTL_LAYERS" == "true" ]]; then
      filesToCompress="$filesToCompress $eTTL"
   fi

   convertedEnhancedSamples="no"; for raw in `find automatic -name "*.$eIDD.sample.ttl"`; do convertedEnhancedSamples="yes"; done
   if [[ "$convertedEnhancedSamples" == 'yes' ]]; then
      # Sample the aggregated enhancements.
      echo $eTTLsample | tee -a $CSV2RDF4LOD_LOG
      if [ $anyEsDone == "no" ]; then
         cat automatic/*.e$eIDD.sample.ttl  > $eTTLsample
         anyEsDone="yes"
      else
         cat automatic/*.e$eIDD.sample.ttl >> $eTTLsample
      fi
   else
      echo 'publish/*.e'$eIDD'.sample.ttl - omitted'
   fi

   conversionIDs="$conversionIDs e$eIDD"
   layerSlugs="$layerSlugs enhancement/$eIDD"
done


#
# Provenance - PML
#
echo $allPML | tee -a $CSV2RDF4LOD_LOG
rm $allPML 2> /dev/null
for dir in source manual automatic; do
   for prov in pml prov; do
      for provFile in `find $dir -name "*.$prov.ttl"`; do
         # source/STATE_SINGLE_PW.CSV ->
         # http://logd.tw.rpi.edu/source/data-gov/file/1008/version/2010-Aug-30/source/STATE_SINGLE_PW.CSV
         # rapper -g -o turtle source/STATE_SINGLE_PW.CSV.pml.ttl  http://logd.tw.rpi.edu/source/data-gov/file/1008/version/2010-Aug-30/source/
         sourceFile=`echo $provFile | sed "s/.$prov.ttl$//"`
         base4rapper="$baseURI/source/${sourceID}/file/${datasetID}/version/${versionID}/$dir/"
         echo "  (including $provFile)" | tee -a $CSV2RDF4LOD_LOG
         if [ `which rapper` ]; then
            rapper -g -o turtle $provFile $base4rapper >> $allPML 2> /dev/null
         else
            echo "@base <$base4rapper> ." >> $allPML
            echo ""                       >> $allPML
            cat $provFile                 >> $allPML
         fi
         echo "<$graph> <http://purl.org/dc/terms/source> <`basename $sourceFile`> ." >> $allPML
         echo                                                                         >> $allPML
      done
   done
done
TEMP_pml="_"`basename $0``date +%s`_$$.tmp
if [ -d ../../doc ]; then
   for pml in `find ../../doc -name "*.pml.ttl"`; do
      base4rapper="$baseURI/source/${sourceID}/doc_file/${datasetID}/`echo $pml | sed 's/......doc.//'`"
      # TODO: has a base of: @base <http://logd.tw.rpi.edu/source/data-gov/doc_file/1008/1008.html.pml.ttl>
      cp $pml $TEMP_pml
      echo "  (including $pml)" | tee -a $CSV2RDF4LOD_LOG
      if [ `which rapper` ]; then
         rapper -g -o turtle $TEMP_pml $base4rapper >> $allPML 2> /dev/null
      else
         echo "@base <$base4rapper> ." >> $allPML
         echo "" >> $allPML
         cat $TEMP_pml >> $allPML
      fi
   done
fi
rm $TEMP_pml 2> /dev/null

# spring 2010 us-uk demo: pushd source/; ls *.xls | awk -f /m4rker/formats/rdf/pml/bin/source2pmlsh.sh > ../pml.sh; popd


#
# All void
#
if [ "$CSV2RDF4LOD_PUBLISH_SUBSET_VOID" != "false" ]; then
   echo $allVOID | tee -a $CSV2RDF4LOD_LOG
   rm -f $allVOID.TEMP 2> /dev/null
   for void in `find $convertDir -name "*.void.ttl" 2> /dev/null`; do
      echo "  (including $void)" | tee -a $CSV2RDF4LOD_LOG
      cat $void >> $allVOID.TEMP
   done
   if [ -e $allVOID.TEMP ]; then # VoID should aways be there. (but not if examples and sample subsets are true)
      if [ `which rapper` ]; then
         rapper -q -i turtle -o turtle $allVOID.TEMP > $allVOID
         rm -f $allVOID.TEMP
      else
         mv $allVOID.TEMP $allVOID
      fi
   else
      echo "$allVOID - (none)" | tee -a $CSV2RDF4LOD_LOG
   fi
else
   echo "$allVOID - skipping; set CSV2RDF4LOD_PUBLISH_SUBSET_VOID=true in source-me.sh to publish Meta." | tee -a $CSV2RDF4LOD_LOG
fi
if [ -e doc/logs ]; then
   numLogs=`find doc/logs -name 'csv2rdf4lod_log_*' | wc -l`
fi
echo "# num logs: $numLogs" >> $allVOID
echo "<$versionedDatasetURI> <http://purl.org/twc/vocab/conversion/num_invocation_logs> ${numLogs:-0} ." >> $allVOID # TODO: how to make sure it is an integer?

echo "  (including $allPML)" | tee -a $CSV2RDF4LOD_LOG
echo "# BEGIN: $allPML:" >> $allVOID
cat $allPML 2> /dev/null >> $allVOID
if [ -e $allVOID.DO_NOT_LIST ]; then
   mv $allVOID $allVOID.DO_NOT_LIST
fi



#
# All ttl (since current was updated, concat all)
#
willDeleteMsg=""
if [ ${CSV2RDF4LOD_PUBLISH_TTL:-"."} != "true" ]; then
   willDeleteMsg=" (will delete at end of processing because \$CSV2RDF4LOD_PUBLISH_TTL=.)"
else
   filesToCompress="$filesToCompress $allTTL"
fi

echo $allTTL $willDeleteMsg | tee -a $CSV2RDF4LOD_LOG
anyEsDone="no"
for eIDD in $enhancementLevels; do # eIDD to avoid overwritting currently-requested enhancement eID
   eTTL=publish/$sourceID-$datasetID-$versionID.e$eIDD.ttl

   echo "  (including $eTTL)" | tee -a $CSV2RDF4LOD_LOG

   if [ $anyEsDone == "no" ]; then
      echo "# BEGIN: $eTTL:"  > $allTTL
      cat $eTTL              >> $allTTL
      anyEsDone="yes"
   else
      echo "# BEGIN: $eTTL:" >> $allTTL
      cat $eTTL              >> $allTTL
   fi
   #cat $convertDir/*.e$eID.ttl | rapper -q -i turtle -o turtle - http://www.no.org | grep -v "http://www.no.org" >  $allE1   2> /dev/null
   #cat $allE1 $allRaw        | rapper -q -i turtle -o turtle - http://www.no.org | grep -v "http://www.no.org" > $allTTL   2> /dev/null
done
if [ $convertedRaw == "yes" ]; then
   echo "  (including $allRaw)" | tee -a $CSV2RDF4LOD_LOG
   echo "# BEGIN: $allRaw:"     >> $allTTL
   cat $allRaw                  >> $allTTL
fi
if [ -e $allVOID ]; then
   echo "  (including $allVOID)" | tee -a $CSV2RDF4LOD_LOG
   echo "# BEGIN: $allVOID:"    >> $allTTL
   cat $allVOID                 >> $allTTL
fi
#grep "^@prefix" $allTTL | sort -u > $convertDir/prefixes-$sourceID-$datasetID-$versionID.ttl
#rapper -i turtle $allTTL -o turtle   > $allTTL.ttl 2> /dev/null # Sorts conversion-ordered TTL into lexiographical order.


#
# All nt
#
if [ ${CSV2RDF4LOD_PUBLISH_NT:-"."} == "true" -o ${CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION:-"."} == "true" ]; then
   willDeleteMsg=""
   if [ ${CSV2RDF4LOD_PUBLISH_NT:-"."} != "true" ]; then
      willDeleteMsg=" (will delete at end of processing because \$CSV2RDF4LOD_PUBLISH_NT=true)"
   else
      filesToCompress="$filesToCompress $allNT"
   fi
   echo "$allNT $willDeleteMsg" | tee -a $CSV2RDF4LOD_LOG
   if [ `find publish -size +1900M -name $sourceID-$datasetID-$versionID.ttl | wc -l` -gt 0 ]; then # +1900M, +10M for debugging
      # Rapper can't handle a turtle file bigger than ~2GB (1900M to be safe). Split it up and feed it.
      $CSV2RDF4LOD_HOME/bin/util/bigttl2nt.sh $allTTL > $allNT 2> /dev/null
   else
      # Process the entire file at once; it's small enough.
      rapper -i turtle $allTTL -o ntriples > $allNT 2> /dev/null
      # NT does not need to be saved, but we need to parse it for the sameAs triples.
   fi
else
   echo "$allNT - skipping; set CSV2RDF4LOD_PUBLISH_NT=true in source-me.sh to publish N-Triples." | tee -a $CSV2RDF4LOD_LOG
fi
echo $graph > $allNT.graph
echo $graph > $pSDV.sd_name


#
# sameas subset
#
if [ "$CSV2RDF4LOD_PUBLISH_SUBSET_SAMEAS" == "true" ]; then
   numSameAs=`grep owl:sameAs $allTTL | wc -l | awk '{print $1}'`
   if [ $numSameAs -gt 0 ]; then
      echo "$allSAMEAS ($numSameAs triples)" | tee -a $CSV2RDF4LOD_LOG
      if [ -e $allNT ];then
         # echo "   (cat'ing NT)" | tee -a $CSV2RDF4LOD_LOG
         cat $allNT | awk -f $CSV2RDF4LOD_HOME/bin/util/sameasInNT.awk > $allSAMEAS
      elif [ `find publish -size +1900M -name $sourceID-$datasetID-$versionID.ttl | wc -l` -gt 0 ]; then # +1900M, +10M for debugging
         # Rapper can't handle a turtle file bigger than ~2GB (1900M to be safe). Split it up and feed it.
         # echo "   (bigttl2nt.sh'ing NT)" | tee -a $CSV2RDF4LOD_LOG
         $CSV2RDF4LOD_HOME/bin/util/bigttl2nt.sh $allTTL 2> /dev/null | awk -f $CSV2RDF4LOD_HOME/bin/util/sameasInNT.awk > $allSAMEAS
      else
         # Process the entire file at once; it's small enough.
         # echo "   (rapper'ing NT)" | tee -a $CSV2RDF4LOD_LOG
         rapper -i turtle $allTTL -o ntriples 2> /dev/null | awk -f $CSV2RDF4LOD_HOME/bin/util/sameasInNT.awk > $allSAMEAS
      fi
   else
      echo "$allSAMEAS - skipping; no owl:sameAs in $allTTL." | tee -a $CSV2RDF4LOD_LOG
   fi
else
   echo "$allSAMEAS - skipping; set CSV2RDF4LOD_PUBLISH_SUBSET_SAMEAS=true in source-me.sh to publish sameas subset." | tee -a $CSV2RDF4LOD_LOG
fi


#
# All rdfxml
#
if [ ${CSV2RDF4LOD_PUBLISH_RDFXML:-"."} == "true" ]; then
   echo $allRDFXML | tee -a $CSV2RDF4LOD_LOG
   # Rapper can't handle a turtle file bigger than ~2GB (1900M to be safe).
   if [ `find publish -size +1900M -name $sourceID-$datasetID-$versionID.ttl | wc -l` -gt 0 ]; then
      # Use N-Triples (will be uglier).
      rapper -i ntriples $allNT  -o rdfxml > $allRDFXML 2> /dev/null
   else
      # Use TTL (will be prettier).
      rapper -i turtle   $allTTL -o rdfxml > $allRDFXML 2> /dev/null
   fi
   filesToCompress="$filesToCompress $allRDFXML"
else
   echo "$allRDFXML - skipping; set CSV2RDF4LOD_PUBLISH_RDFXML=true in source-me.sh to publish RDF/XML." | tee -a $CSV2RDF4LOD_LOG
fi



#
# Compressed dump files
#
if [ "$CSV2RDF4LOD_PUBLISH_COMPRESS" == "true" ]; then
   for dumpFile in $filesToCompress ; do
      echo "$dumpFile.$zip (will delete uncompressed version at end of processing)" | tee -a $CSV2RDF4LOD_LOG
      dumpFileDir=`dirname $dumpFile`
      dumpFileBase=`basename $dumpFile`
      pushd $dumpFileDir &> /dev/null
         tar czf $dumpFileBase.$zip $dumpFileBase  # TODO:notar

         # TODO ^^ this tar command is a no-op, the .zip gets replaced below. Remove the above command?

         # Don't use tar if there is only ever one file; use gzip instead:
         cat $dumpFileBase | gzip > $dumpFileBase.$zip # TODO:notar

         # WARNING:
         # gunzip $dumpFileBase.gz # will remove .gz file
         # INSTEAD:
         # gunzip -c $dumpFileBase.gz > $dumpFileBase # Keep .gz and write to original.
         # FYI:
         # bzip has a -k option to keep it around.
      popd &> /dev/null
      # NOTE, pre-tarball will be deleted at end of this script.
   done
fi



#
# ln or cp from publish/ to www root.
#
# publish/cordad-at-rpi-edu-transfer-coefficents-2010-Jul-14.e1.ttl -->
# source/STATE_SINGLE_PW.CSV -> http://logd.tw.rpi.edu/source/data-gov/file/1008/version/2010-Jul-21/source/STATE_SINGLE_PW.CSV
#
# WWWROOT/source/cordad-at-rpi-edu/file/transfer-coefficents/version/2010-Jul-14/conversion/cordad-at-rpi-edu-transfer-coefficents-2010-Jul-14.e1

# NOTE: bin/aggregate-source-rdf.sh is duplicating this

lnwwwrootSH="publish/bin/ln-to-www-root-${sourceID}-${datasetID}-${versionID}.sh"
echo $lnwwwrootSH | tee -a $CSV2RDF4LOD_LOG

echo "#!/bin/bash"                                                                                    > $lnwwwrootSH
echo "#"                                                                                             >> $lnwwwrootSH
echo "# run from `cr-pwd.sh`"                                                                        >> $lnwwwrootSH
echo "#"                                                                                             >> $lnwwwrootSH
echo "# CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT"                                            >> $lnwwwrootSH
echo "# was "                                                                                        >> $lnwwwrootSH
echo "# ${CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT}"                                         >> $lnwwwrootSH
echo "# when this script was created. "                                                              >> $lnwwwrootSH
echo ""                                                                                              >> $lnwwwrootSH
echo "wwwroot=\$CSV2RDF4LOD_PUBLISH_VARWWW_ROOT"                                                     >> $lnwwwrootSH
echo "if [ -z \"\$wwwroot\" ]; then"                                                                 >> $lnwwwrootSH
echo "  wwwroot=\$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT"                                  >> $lnwwwrootSH
echo "fi"                                                                                            >> $lnwwwrootSH
echo "if [ -z \"\$wwwroot\" ]; then"                                                                 >> $lnwwwrootSH
echo "  echo \"wwwroot not defined.\""                                                               >> $lnwwwrootSH
echo "  exit 1"                                                                                      >> $lnwwwrootSH
echo "fi"                                                                                            >> $lnwwwrootSH
echo ""                                                                                              >> $lnwwwrootSH
echo "verbose=\"no\""                                                                                >> $lnwwwrootSH
echo "if [[ \"\$1\" == \"-v\" ]]; then"                                                              >> $lnwwwrootSH
echo "  verbose=\"yes\""                                                                             >> $lnwwwrootSH
echo "  shift"                                                                                       >> $lnwwwrootSH
echo "fi"                                                                                            >> $lnwwwrootSH
echo ""                                                                                              >> $lnwwwrootSH
echo "symbolic=\"\""                                                                                 >> $lnwwwrootSH
echo "pwd=\"\""                                                                                      >> $lnwwwrootSH
echo "if [[ \"\$1\" == \"-s\" || \"\$CSV2RDF4LOD_PUBLISH_VARWWW_LINK_TYPE\" == \"soft\" ]]; then"    >> $lnwwwrootSH
echo "  symbolic=\"-sf \""                                                                           >> $lnwwwrootSH
echo "  pwd=\`pwd\`/"                                                                                >> $lnwwwrootSH
#echo "  echo SYMBOLIC: \$symbolic \$pwd"                                                            >> $lnwwwrootSH
echo "  shift"                                                                                       >> $lnwwwrootSH
echo "fi"                                                                                            >> $lnwwwrootSH
echo ""                                                                                              >> $lnwwwrootSH
echo "sudo=\"sudo\""                                                                                 >> $lnwwwrootSH
echo "if [ \`whoami\` == "root" ]; then"                                                             >> $lnwwwrootSH
echo "   sudo=\"\""                                                                                  >> $lnwwwrootSH
echo "elif [[ \"\`stat --format=%U \"\$wwwroot/source\"\`\" == \`whoami\` ]]; then"                  >> $lnwwwrootSH
echo "   sudo=\"\""                                                                                  >> $lnwwwrootSH
echo "fi"                                                                                            >> $lnwwwrootSH
echo ""                                                                                              >> $lnwwwrootSH
echo "file=\"file\""                                                                                 >> $lnwwwrootSH
echo ""                                                                                              >> $lnwwwrootSH
echo "##################################################"                                            >> $lnwwwrootSH
echo "# Link all original files from the /file/ directory structure to the web directory."           >> $lnwwwrootSH
echo "# (these are from source/)"                                                                    >> $lnwwwrootSH
for sourceFileProvenance in `ls source/*.pml.ttl 2> /dev/null`; do
   sourceFile=`echo $sourceFileProvenance | sed 's/.pml.ttl$//'`
   echo "if [ -e \"$sourceFile\" ]; then "                                                                   >> $lnwwwrootSH
   echo "   wwwfile=\"\$wwwroot/source/$sourceID/file/$datasetID/version/$versionID/$sourceFile\""           >> $lnwwwrootSH
   echo "   if [ -e \$wwwfile ]; then "                                                                      >> $lnwwwrootSH
   echo "     \$sudo rm -f \$wwwfile"                                                                        >> $lnwwwrootSH
   echo "   else"                                                                                            >> $lnwwwrootSH
   echo "     \$sudo mkdir -p \`dirname \$wwwfile\`"                                                         >> $lnwwwrootSH
   echo "   fi"                                                                                              >> $lnwwwrootSH
   echo "   echo \"  \$wwwfile\""                                                                            >> $lnwwwrootSH
#   echo "   echo \$sudo ln \$symbolic \"\${pwd}$sourceFile\" \"\$wwwfile\""                          >> $lnwwwrootSH # TODO rm
   echo "   \$sudo ln \$symbolic \"\${pwd}$sourceFile\" \"\$wwwfile\""                                       >> $lnwwwrootSH
   echo "else"                                                                                               >> $lnwwwrootSH
   echo "   echo \"          -- $sourceFile omitted --\""                                                    >> $lnwwwrootSH
   echo "fi"                                                                                                 >> $lnwwwrootSH
   echo ""                                                                                                   >> $lnwwwrootSH
   echo "if [ -e \"$sourceFileProvenance\" ]; then"                                                          >> $lnwwwrootSH
   echo "   wwwfile=\"\$wwwroot/source/$sourceID/file/$datasetID/version/$versionID/$sourceFileProvenance\"" >> $lnwwwrootSH
   echo "   if [ -e \"\$wwwfile\" ]; then "                                                                  >> $lnwwwrootSH
   echo "     \$sudo rm -f \$wwwfile"                                                                        >> $lnwwwrootSH
   echo "   else"                                                                                            >> $lnwwwrootSH
   echo "     \$sudo mkdir -p \`dirname \"\$wwwfile\"\`"                                                     >> $lnwwwrootSH
   echo "   fi"                                                                                              >> $lnwwwrootSH
   echo "   echo \"  \$wwwfile\""                                                                            >> $lnwwwrootSH
#   echo "   echo \$sudo ln \$symbolic \"\${pwd}$sourceFileProvenance\" \"\$wwwfile\""                       >> $lnwwwrootSH # TODO
   echo "   \$sudo ln \$symbolic \"\${pwd}$sourceFileProvenance\" \"\$wwwfile\""                             >> $lnwwwrootSH
   echo "else"                                                                                               >> $lnwwwrootSH
   echo "   echo \"          -- $sourceFileProvenance omitted --\""                                          >> $lnwwwrootSH
   echo "fi"                                                                                                 >> $lnwwwrootSH
   echo ""                                                                                                   >> $lnwwwrootSH
done

echo "##################################################"                                              >> $lnwwwrootSH
echo "# Link all INPUT CSV files from the /file/ directory structure to the web directory."            >> $lnwwwrootSH
echo "# (this could be from manual/ or source/"                                                        >> $lnwwwrootSH
if [ -e $convertDir/._CSV2RDF4LOD_file_list.txt ]; then
   for inputFile in `cat $convertDir/._CSV2RDF4LOD_file_list.txt`; do # convert.sh builds this list b/c it knows what files were converted.
      echo "if [ -e \"$inputFile\" ]; then "                                                           >> $lnwwwrootSH
      echo "   wwwfile=\"\$wwwroot/source/$sourceID/file/$datasetID/version/$versionID/$inputFile\""   >> $lnwwwrootSH
      echo "   if [ -e \"\$wwwfile\" ]; then "                                                         >> $lnwwwrootSH
      echo "      \$sudo rm -f \"\$wwwfile\""                                                          >> $lnwwwrootSH
      echo "   else"                                                                                   >> $lnwwwrootSH
      echo "      \$sudo mkdir -p \`dirname \"\$wwwfile\"\`"                                           >> $lnwwwrootSH
      echo "   fi"                                                                                     >> $lnwwwrootSH
      echo "   echo \"  \$wwwfile\""                                                                   >> $lnwwwrootSH
      # echo "   echo \$sudo ln \$symbolic \"\${pwd}$inputFile\" \"\$wwwfile\""                        >> $lnwwwrootSH # TODO
      echo "   \$sudo ln \$symbolic \"\${pwd}$inputFile\" \"\$wwwfile\""                               >> $lnwwwrootSH
      echo "else"                                                                                      >> $lnwwwrootSH
      echo "   echo \"          -- $inputFile omitted --\""                                            >> $lnwwwrootSH
      echo "fi"                                                                                        >> $lnwwwrootSH
      echo ""                                                                                          >> $lnwwwrootSH
   done
fi
TEMP_file_list="_"`basename $0``date +%s`_$$.tmp
# automatic/STATE_SINGLE_PW.CSV.raw.params.ttl -> http://logd.tw.rpi.edu/source/data-gov/file/1008/version/1st-anniversary/automatic/STATE_SINGLE_PW.CSV.raw.params.ttl

find automatic -name '*.params.ttl' | sed 's/^\.\///'  > $TEMP_file_list
find manual    -name '*.params.ttl' | sed 's/^\.\///' >> $TEMP_file_list
echo "##################################################"                                                >> $lnwwwrootSH
echo "# Link all raw and enhancement PARAMETERS from the file directory structure to the web directory." >> $lnwwwrootSH
echo "#"                                                                                                 >> $lnwwwrootSH
for paramFile in `cat $TEMP_file_list`; do
   echo "if [ -e \"$paramFile\" ]; then "                                                                >> $lnwwwrootSH
   echo "   wwwfile=\"\$wwwroot/source/$sourceID/file/$datasetID/version/$versionID/$paramFile\""        >> $lnwwwrootSH
   echo "   if [ -e \"\$wwwfile\" ]; then "                                                              >> $lnwwwrootSH
   echo "     \$sudo rm -f \"\$wwwfile\""                                                                >> $lnwwwrootSH
   echo "   else"                                                                                        >> $lnwwwrootSH
   echo "     \$sudo mkdir -p \`dirname \"\$wwwfile\"\`"                                                 >> $lnwwwrootSH
   echo "   fi"                                                                                          >> $lnwwwrootSH
   echo "   echo \"  \$wwwfile\""                                                                        >> $lnwwwrootSH
   # echo "   echo \$sudo ln \$symbolic \"\${pwd}$paramFile\" \"\$wwwfile\""                             >> $lnwwwrootSH # TODO
   echo "   \$sudo ln \$symbolic \"\${pwd}$paramFile\" \"\$wwwfile\""                                    >> $lnwwwrootSH
   echo "else"                                                                                           >> $lnwwwrootSH
   echo "   echo \"          -- $paramFile omitted --\""                                                 >> $lnwwwrootSH
   echo "fi"                                                                                             >> $lnwwwrootSH
   echo ""                                                                                               >> $lnwwwrootSH
done

find source -name '*.pml.ttl'                                     > $TEMP_file_list
find source -name '*.[Zz][Ii][Pp].pml.ttl' | sed 's/.pml.ttl$//' >> $TEMP_file_list
find manual -name '*.pml.ttl'                                    >> $TEMP_file_list
find manual -name '*.[Zz][Ii][Pp].pml.ttl' | sed 's/.pml.ttl$//' >> $TEMP_file_list
echo "##################################################"                                            >> $lnwwwrootSH
echo "# Link all PROVENANCE files that describe how the input CSV files were obtained."              >> $lnwwwrootSH
echo "#"                                                                                             >> $lnwwwrootSH
for pmlFile in `cat $TEMP_file_list`
do
   echo "if [ -e \"$pmlFile\" ]; then "                                                              >> $lnwwwrootSH
   echo "   wwwfile=\"\$wwwroot/source/$sourceID/file/$datasetID/version/$versionID/$pmlFile\""      >> $lnwwwrootSH
   echo "   if [ -e \"\$wwwfile\" ]; then"                                                           >> $lnwwwrootSH
   echo "     \$sudo rm -f \"\$wwwfile\""                                                            >> $lnwwwrootSH
   echo "   else"                                                                                    >> $lnwwwrootSH
   echo "     \$sudo mkdir -p \`dirname \"\$wwwfile\"\`"                                             >> $lnwwwrootSH
   echo "   fi"                                                                                      >> $lnwwwrootSH
   echo "   echo \"  \$wwwfile\""                                                                    >> $lnwwwrootSH
#   echo "   echo \$sudo ln \$symbolic \"\${pwd}$pmlFile\" \"\$wwwfile\""                            >> $lnwwwrootSH # TODO
   echo "   \$sudo ln \$symbolic \"\${pwd}$pmlFile\" \"\$wwwfile\""                                  >> $lnwwwrootSH
   echo "else"                                                                                       >> $lnwwwrootSH
   echo "   echo \"          -- $pmlFile omitted --\""                                               >> $lnwwwrootSH
   echo "fi"                                                                                         >> $lnwwwrootSH
   echo ""                                                                                           >> $lnwwwrootSH
done
rm $TEMP_file_list

echo "##################################################"                                                     >> $lnwwwrootSH
echo "# Link all bundled RDF output files from the source/.../file directory structure to the web directory." >> $lnwwwrootSH
echo "#"                                                                                                      >> $lnwwwrootSH
# Version rollup of all layers (all serializations)
for serialization in ttl nt rdf
do
   echo "dump=$sourceID-$datasetID-$versionID.$serialization"                                        >> $lnwwwrootSH
   echo "wwwfile=\$wwwroot/source/$sourceID/file/$datasetID/version/$versionID/conversion/\$dump"    >> $lnwwwrootSH
   echo "if [ -e publish/\$dump.$zip ]; then "                                                       >> $lnwwwrootSH
   echo "   if [ -e \$wwwfile.$zip ]; then"                                                          >> $lnwwwrootSH
   echo "    \$sudo rm -f \$wwwfile.$zip"                                                            >> $lnwwwrootSH
   echo "   else"                                                                                    >> $lnwwwrootSH
   echo "     \$sudo mkdir -p \`dirname \$wwwfile.$zip\`"                                            >> $lnwwwrootSH
   echo "   fi"                                                                                      >> $lnwwwrootSH
   echo "   echo \"  \$wwwfile.$zip\""                                                               >> $lnwwwrootSH
#   echo "   echo \$sudo ln \$symbolic \${pwd}publish/\$dump.$zip \$wwwfile.$zip"                    >> $lnwwwrootSH  # TODO
   echo "   \$sudo ln \$symbolic \${pwd}publish/\$dump.$zip \$wwwfile.$zip"                          >> $lnwwwrootSH
   echo ""                                                                                           >> $lnwwwrootSH
   echo "   if [ -e \$wwwfile ]; then"                                                               >> $lnwwwrootSH
   echo "      echo \"  \$wwwfile\" - removing b/c $zip available"                                   >> $lnwwwrootSH
   echo "      \$sudo rm -f \$wwwfile # clean up to save space"                                      >> $lnwwwrootSH
   echo "   fi"                                                                                      >> $lnwwwrootSH
   echo "elif [ -e publish/\$dump ]; then "                                                          >> $lnwwwrootSH
   echo "   if [ -e \$wwwfile ]; then "                                                              >> $lnwwwrootSH
   echo "      \$sudo rm -f \$wwwfile"                                                               >> $lnwwwrootSH
   echo "   else"                                                                                    >> $lnwwwrootSH
   echo "      \$sudo mkdir -p \`dirname \$wwwfile\`"                                                >> $lnwwwrootSH
   echo "   fi"                                                                                      >> $lnwwwrootSH
   echo "   echo \"  \$wwwfile\""                                                                    >> $lnwwwrootSH
#   echo "   echo \$sudo ln \$symbolic \${pwd}publish/\$dump \$wwwfile"                              >> $lnwwwrootSH # TODO
   echo "   \$sudo ln \$symbolic \${pwd}publish/\$dump \$wwwfile"                                    >> $lnwwwrootSH
   echo "else"                                                                                       >> $lnwwwrootSH
   echo "   echo \"          -- full $serialization omitted -- \""                                   >> $lnwwwrootSH
   echo "fi"                                                                                         >> $lnwwwrootSH
   echo ""                                                                                           >> $lnwwwrootSH
done
# Individual layers (all serializations)
for conversionID in $conversionIDs sameas void # <---- Add root-level subsets here.
do
   for serialization in ttl nt rdf
   do
      echo "dump=$sourceID-$datasetID-$versionID.$conversionID.$serialization"                       >> $lnwwwrootSH
      echo "wwwfile=\$wwwroot/source/$sourceID/file/$datasetID/version/$versionID/conversion/\$dump" >> $lnwwwrootSH
      echo "if [ -e publish/\$dump.$zip ]; then"                                                     >> $lnwwwrootSH
      echo "   if [ -e \$wwwfile.$zip ]; then"                                                       >> $lnwwwrootSH
      echo "      \$sudo rm -f \$wwwfile.$zip"                                                       >> $lnwwwrootSH
      echo "   else"                                                                                 >> $lnwwwrootSH
      echo "      \$sudo mkdir -p \`dirname \$wwwfile.$zip\`"                                        >> $lnwwwrootSH
      echo "   fi"                                                                                   >> $lnwwwrootSH
      echo "   echo \"  \$wwwfile.$zip\""                                                            >> $lnwwwrootSH
      echo "   \$sudo ln \$symbolic \${pwd}publish/\$dump.$zip \$wwwfile.$zip"                       >> $lnwwwrootSH
      echo ""                                                                                        >> $lnwwwrootSH
      echo "   if [ -e \$wwwfile ]; then"                                                            >> $lnwwwrootSH
      echo "      echo \"  \$wwwfile\" - removing b/c $zip available"                                >> $lnwwwrootSH
      echo "      \$sudo rm -f \$wwwfile # clean up to save space"                                   >> $lnwwwrootSH
      echo "   fi"                                                                                   >> $lnwwwrootSH
      echo "elif [ -e publish/\$dump ]; then "                                                       >> $lnwwwrootSH
      echo "   if [ -e \$wwwfile ]; then "                                                           >> $lnwwwrootSH
      echo "      \$sudo rm -f \$wwwfile"                                                            >> $lnwwwrootSH
      echo "   else"                                                                                 >> $lnwwwrootSH
      echo "      \$sudo mkdir -p \`dirname \$wwwfile\`"                                             >> $lnwwwrootSH
      echo "   fi"                                                                                   >> $lnwwwrootSH
      echo "   echo \"  \$wwwfile\""                                                                 >> $lnwwwrootSH
#      echo "   echo \$sudo ln \$symbolic \${pwd}publish/\$dump \$wwwfile"                           >> $lnwwwrootSH # TODO
      echo "   \$sudo ln \$symbolic \${pwd}publish/\$dump \$wwwfile"                                 >> $lnwwwrootSH
      echo "else"                                                                                    >> $lnwwwrootSH
      echo "   echo \"          -- $conversionID $serialization omitted --\""                        >> $lnwwwrootSH
      echo "fi"                                                                                      >> $lnwwwrootSH
      echo ""                                                                                        >> $lnwwwrootSH
      for subset in sample                     # <---- Add layer-level subsets here.
      do # ln:
         #    publish/data-gov-1008-2010-Jul-21.raw.sample.ttl
         # to:
         #    /var/www/html/logd.tw.rpi.edu/source/data-gov/file/1008/version/2010-Jul-21/conversion/data-gov-1008-2010-Jul-21.raw.sample
         # to get:
         #    http://logd.tw.rpi.edu/source/data-gov/file/1008/version/2010-Jul-21/conversion/data-gov-1008-2010-Jul-21.raw.sample
         echo "dump=$sourceID-$datasetID-$versionID.$conversionID.$subset.$serialization"               >> $lnwwwrootSH
         echo "wwwfile=\$wwwroot/source/$sourceID/file/$datasetID/version/$versionID/conversion/\$dump" >> $lnwwwrootSH
         echo "if [ -e publish/\$dump ]; then "                                                         >> $lnwwwrootSH
         echo "   if [ -e \$wwwfile ]; then "                                                           >> $lnwwwrootSH
         echo "      \$sudo rm -f \$wwwfile"                                                            >> $lnwwwrootSH
         echo "   else"                                                                                 >> $lnwwwrootSH
         echo "      \$sudo mkdir -p \`dirname \$wwwfile\`"                                             >> $lnwwwrootSH
         echo "   fi"                                                                                   >> $lnwwwrootSH
         echo "   echo \"  \$wwwfile\""                                                                 >> $lnwwwrootSH
#         echo "   echo \$sudo ln \$symbolic \${pwd}publish/\$dump \$wwwfile"                           >> $lnwwwrootSH # TODO
         echo "   \$sudo ln \$symbolic \${pwd}publish/\$dump \$wwwfile"                                 >> $lnwwwrootSH
         echo "else"                                                                                    >> $lnwwwrootSH
         echo "   echo \"          -- $conversionID $subset $serialization omitted --\""                >> $lnwwwrootSH
         echo "fi"                                                                                      >> $lnwwwrootSH
         echo ""                                                                                        >> $lnwwwrootSH
      done
   done
   echo ""                                                                                              >> $lnwwwrootSH
done

chmod +x $lnwwwrootSH

if [[ ( -e "$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT" || -e "$CSV2RDF4LOD_PUBLISH_VARWWW_ROOT" ) && \
           "$CSV2RDF4LOD_PUBLISH_VARWWW_DUMP_FILES" == "true" ]]; then
   echo
   echo "   ///= = = = = = = = = = = = = = = = = = = = = $lnwwwrootSH = = = = = = = = = = = = = = = = = = = = = = =\\\\\\"
   echo
   echo "${CSV2RDF4LOD_PUBLISH_VARWWW_ROOT:-$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT} - linking dump files into web root:" | tee -a $CSV2RDF4LOD_LOG
   # Execute the script we just generated.
   $lnwwwrootSH #2> /dev/null
   echo "    \\\\\\ = = = = = = = = = = = = = = = = = = = = (end) $lnwwwrootSH = = = = = = = = = = = = = = = = = = = = = = =///"
   echo
else
   echo "$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT - skipping. Set CSV2RDF4LOD_PUBLISH_VARWWW_DUMP_FILES=true and CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT to /var/www" | tee -a $CSV2RDF4LOD_LOG
   echo "`echo $CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/ | sed 's/./ /g'` or run $lnwwwrootSH manually."
fi



#
# TDB
#
local_tdb_dir=publish/tdb
TDB_DIR=${CSV2RDF4LOD_PUBLISH_TDB_DIR:-$local_tdb_dir}
josekiConfigFile=publish/bin/joseki-config-anterior-${sourceID}-${datasetID}-${versionID}.ttl
if [ ! -e $josekiConfigFile ]; then
   cat $CSV2RDF4LOD_HOME/bin/dup/joseki-config-ANTERIOR.ttl | awk '{gsub("__TDB__DIRECTORY__",dir);print $0}' dir=`pwd`/$TDB_DIR > $josekiConfigFile
fi
loadtdbSH="publish/bin/tdbloader-${sourceID}-${datasetID}-${versionID}.sh"
echo "#!/bin/bash"                                                                             > $loadtdbSH
echo ""                                                                                       >> $loadtdbSH
echo 'CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}' >> $loadtdbSH
echo ""                                                                                       >> $loadtdbSH
echo "delete=\"\""                                                                            >> $loadtdbSH
echo "#if [ ! -e $allNT ]; then"                                                              >> $loadtdbSH
echo "#  delete=\"$allNT\""                                                                   >> $loadtdbSH
echo "#  if [ -e $allNT.$zip ]; then"                                                         >> $loadtdbSH
echo "#    gunzip -c $allNT.$zip > $allNT"                                                    >> $loadtdbSH
echo "#  elif [ -e $allTTL ]; then"                                                           >> $loadtdbSH
echo "#    echo \"cHuNking $allTTL into $allNT; will delete when done lod-mat'ing\""          >> $loadtdbSH
echo "#    \$CSV2RDF4LOD_HOME/bin/util/bigttl2nt.sh $allTTL > $allNT"                         >> $loadtdbSH
echo "#  elif [ -e $allTTL.$zip ]; then"                                                      >> $loadtdbSH
echo "#    gunzip -c $allTTL.$zip > $allTTL"                                                  >> $loadtdbSH
echo "#    echo \"cHuNking $allTTL into $allNT; will delete when done lod-mat'ing\""          >> $loadtdbSH
echo "#    \$CSV2RDF4LOD_HOME/bin/util/bigttl2nt.sh $allTTL > $allNT"                         >> $loadtdbSH
echo "#    rm $allTTL"                                                                        >> $loadtdbSH
echo "#  else"                                                                                >> $loadtdbSH
echo "#    echo $allNT, $allNT.$zip, $allTTL, or $allTTL.$zip needed to lod-materialize."     >> $loadtdbSH
echo "#    delete=\"\""                                                                       >> $loadtdbSH
echo "#    exit 1"                                                                            >> $loadtdbSH
echo "#  fi"                                                                                  >> $loadtdbSH
echo "#fi"                                                                                    >> $loadtdbSH
echo "load_file=\"\""                                                                         >> $loadtdbSH
echo "if [ -e     \"$allNT\" ]; then"                                                         >> $loadtdbSH
echo "  load_file=\"$allNT\""                                                                 >> $loadtdbSH
echo "elif [ -e   \"$allTTL\" ]; then"                                                        >> $loadtdbSH
echo "  load_file=\"$allTTL\""                                                                >> $loadtdbSH
echo "elif [ -e   \"$allTTL.$zip\" ]; then"                                                   >> $loadtdbSH
echo "  load_file=\"$allTTL\""                                                                >> $loadtdbSH
echo "  gunzip -c  $allTTL.$zip > $allTTL"                                                    >> $loadtdbSH
echo "     delete=\"$allTTL\""                                                                >> $loadtdbSH
echo "elif [ -e   \"$allNT.$zip\" ]; then"                                                    >> $loadtdbSH
echo "  load_file=\"$allNT\""                                                                 >> $loadtdbSH
echo "  gunzip -c  $allNT.$zip > $allNT"                                                      >> $loadtdbSH
echo "     delete=\"$allNT\""                                                                 >> $loadtdbSH
echo "fi"                                                                                     >> $loadtdbSH
echo ""                                                                                       >> $loadtdbSH
echo "mkdir $TDB_DIR                         &> /dev/null"                                    >> $loadtdbSH
echo "rm    $TDB_DIR/*.dat $TDB_DIR/*.idn &> /dev/null"                                       >> $loadtdbSH
echo ""                                                                                       >> $loadtdbSH
echo "if [[ \${#load_file} -eq 0 ]]; then"                                                    >> $loadtdbSH
echo "   echo \"[ERROR] \`basename \$0 \`could not find dump file to load.\""                 >> $loadtdbSH
echo "   exit 1"                                                                              >> $loadtdbSH
echo "fi"                                                                                     >> $loadtdbSH
echo "echo \`basename \$load_file\` into $TDB_DIR as $graph >> publish/ng.info"           >> $loadtdbSH
echo ""                                                                                       >> $loadtdbSH
#                                                                             billion="000000000"
#echo "if [ \$load_file = \"$allTTL\" -a \`stat -f \"%z\" \"$allTTL\"\` -gt 2$billion ]; then" >> $loadtdbSH # replaced b/c stat -c "%s" on some flavors of unix.
echo "#if [[ ! \`which tdbloader\` ]]; then"                                                     >> $loadtdbSH
echo "#   echo \"ERROR: tdbloader not found.\""                                                >> $loadtdbSH
echo "#   exit"                                                                                >> $loadtdbSH
echo "#fi"                                                                                     >> $loadtdbSH
echo "if [[ \$load_file == \"$allTTL\" && \"\`too-big-for-rapper.sh\`\" == \"yes\" ]]; then"  >> $loadtdbSH
echo "  dir=\"`dirname $allTTL`\""                                                            >> $loadtdbSH
echo "  echo \"cHuNking $allTTL in \$dir\""                                                   >> $loadtdbSH
echo "  rm \$dir/cHuNk*.ttl &> /dev/null"                                                     >> $loadtdbSH
echo "  \${CSV2RDF4LOD_HOME}/bin/split_ttl.pl \$load_file"                                    >> $loadtdbSH
echo "  for cHuNk in \$dir/cHuNk*.ttl; do"                                                    >> $loadtdbSH
echo "    echo giving \$cHuNk to tdbloader"                                                   >> $loadtdbSH
echo "    tdbloader --loc=$TDB_DIR --graph=\`cat $allNT.graph\` \$cHuNk"                      >> $loadtdbSH
echo "    rm \$cHuNk"                                                                         >> $loadtdbSH
echo "  done"                                                                                 >> $loadtdbSH
echo "else"                                                                                   >> $loadtdbSH
echo "  tdbloader --loc=$TDB_DIR --graph=\`cat $allNT.graph\` \$load_file"                    >> $loadtdbSH
echo "fi"                                                                                     >> $loadtdbSH
echo ""                                                                                       >> $loadtdbSH
echo "if [ \${#delete} -gt 0 ]; then"                                                         >> $loadtdbSH
echo "   rm \$delete"                                                                         >> $loadtdbSH
echo "fi"                                                                                     >> $loadtdbSH
chmod +x                                                                                         $loadtdbSH

if [ ${CSV2RDF4LOD_PUBLISH_TDB:-"."} == "true" ]; then
   echo $TDB_DIR/ | tee -a $CSV2RDF4LOD_LOG
   echo
   echo "    /// = = = = = = = = = = = = = = = = = = = = $loadtdbSH = = = = = = = = = = = = = = = = = = = = = = =\\\\\\"
   echo
   $loadtdbSH
   echo "    \\\\\\ = = = = = = = = = = = = = = = = = = = = (end) $loadtdbSH = = = = = = = = = = = = = = = = = = = = = = =///"
   $loadtdbSH
   echo
else
   echo "$TDB_DIR/     - skipping; set CSV2RDF4LOD_PUBLISH_TDB=true in source-me.sh to load conversions into $TDB_DIR/." | tee -a $CSV2RDF4LOD_LOG
   echo "`echo $TDB_DIR/ | sed 's/./ /g'`     - or run $loadtdbSH."                                                      | tee -a $CSV2RDF4LOD_LOG
   echo "`echo $TDB_DIR/ | sed 's/./ /g'`     - then run \$TDBROOT/bin/rdfserver with $josekiConfigFile."                | tee -a $CSV2RDF4LOD_LOG
fi



#
# 4store
#
fourstoreSH=publish/bin/4store-${sourceID}-${datasetID}-${versionID}.sh
fourstoreKB=${CSV2RDF4LOD_PUBLISH_4STORE_KB:-'csv2rdf4lod'}
fourstoreKBDir=/var/lib/4store/$fourstoreKB
echo "#!/bin/bash"                                                                         > $fourstoreSH
echo "#"                                                                                >> $fourstoreSH
echo "# run $fourstoreSH"                                                               >> $fourstoreSH
echo "# from ${sourceID}/$datasetID/version/$versionID/"                           >> $fourstoreSH
echo ""                                                                                 >> $fourstoreSH
echo 'CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}' >> $fourstoreSH
echo ""                                                                                 >> $fourstoreSH
echo "allNT=$allNT"                                                                     >> $fourstoreSH
echo "if [ ! -e \$allNT ]; then"                                                        >> $fourstoreSH
echo "   echo \"run from ${sourceID}/$datasetID/version/$versionID/\""             >> $fourstoreSH
echo "   exit 1"                                                                        >> $fourstoreSH
echo "fi"                                                                               >> $fourstoreSH
echo ""                                                                                 >> $fourstoreSH
echo "if [ ! -e $fourstoreKBDir ]; then"                                                >> $fourstoreSH
echo "   4s-backend-setup $fourstoreKB"                                                 >> $fourstoreSH
echo "   4s-backend       $fourstoreKB"                                                 >> $fourstoreSH
echo "fi"                                                                               >> $fourstoreSH
echo ""                                                                                 >> $fourstoreSH
echo "4s-import -v $fourstoreKB --model \`cat $allNT.graph\` \$allNT"                   >> $fourstoreSH
echo "echo \"run '4s-backend $fourstoreKB' if that didn't work\""                       >> $fourstoreSH
chmod +x                                                                                   $fourstoreSH


#
# Virtuoso
#
# NOTE: bin/aggregate-source-rdf.sh copied from this.
vloadSH=publish/bin/virtuoso-load-${sourceID}-${datasetID}-${versionID}.sh
vloadvoidSH=publish/bin/virtuoso-load-${sourceID}-${datasetID}-${versionID}-void.sh
vdeleteSH=publish/bin/virtuoso-delete-${sourceID}-${datasetID}-${versionID}.sh
echo "#!/bin/bash"                                                                                                           > $vloadSH
echo "#"                                                                                                                    >> $vloadSH
echo "# run $vloadSH"                                                                                                       >> $vloadSH
echo "# from `pwd | sed 's/^.*source/source/'`/"                                                                            >> $vloadSH
echo "#"                                                                                                                    >> $vloadSH
echo "# graph was $graph during conversion"                                                                                 >> $vloadSH
echo "# metadataset graph was $CSV2RDF4LOD_PUBLISH_METADATASET_GRAPH_NAME during conversion"                                >> $vloadSH
echo "#"                                                                                                                    >> $vloadSH
echo "#        \$CSV2RDF4LOD_PUBLISH_METADATASET_GRAPH_NAME            # <---- Loads into this with param --as-metadatset"  >> $vloadSH
echo "#"                                                                                                                    >> $vloadSH
echo "#"                                                                                                                    >> $vloadSH
echo "#                               AbstractDataset                  # <---- Loads into this with param --abstract"       >> $vloadSH
echo "#                     (http://.org/source/sss/dataset/ddd)                                                         "  >> $vloadSH
echo "#                                     |                   \                                                        "  >> $vloadSH
echo "# Loads into this by default -> VersionedDataset           meta  # <---- Loads into this with param --meta"           >> $vloadSH
echo "#              (http://.org/source/sss/dataset/ddd/version/vvv)                                                    "  >> $vloadSH
echo "#                                     |                                                                            "  >> $vloadSH
echo "#                                LayerDataset                                                                      "  >> $vloadSH
echo "#                                   /    \                                                                         "  >> $vloadSH
echo "# Never loads into this ----> [table]   DatasetSample            # <---- Loads into this with param --sample"         >> $vloadSH
echo "#"                                                                                                                    >> $vloadSH
echo "# See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Aggregating-subsets-of-converted-datasets"                >> $vloadSH
echo "# See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Named-graph-organization"                                 >> $vloadSH
echo ""                                                                                                                     >> $vloadSH
echo 'CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}'         >> $vloadSH
echo 'CSV2RDF4LOD_BASE_URI=${CSV2RDF4LOD_BASE_URI:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}' >> $vloadSH
# deviates from orig design, but more concise by making (reasonable?) assumptions:
#echo "for serialization in nt ttl rdf"                                                                                     >> $vloadSH
#echo "do"                                                                                                                  >> $vloadSH
#echo "  dump=$allNT.\$serialization"                                                                                       >> $vloadSH
#echo "done"                                                                                                                >> $vloadSH
echo ""                                                                                                                     >> $vloadSH
echo "action='pvload.sh -ng'"                                                                                               >> $vloadSH
echo "if [ \`is-pwd-a.sh cr:dev\` == 'yes' ]; then"                                                                         >> $vloadSH
echo "   echo \"Refusing to publish; see 'cr:dev and refusing to publish' at\""                                             >> $vloadSH
echo "   echo \"  https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-environment-variables-%28considerations-for-a-distributed-workflow%29\"" >> $vloadSH
echo "   exit 1"                                                                                                            >> $vloadSH
echo "fi"                                                                                                                   >> $vloadSH
echo "if [[ -e '$lnwwwrootSH' && \"\$action\" =~ pvload* ]]; then"                                                          >> $vloadSH
echo "   # Make sure that the file we will load from the web is published"                                                  >> $vloadSH
echo "   $lnwwwrootSH &> /dev/null "                                                                                        >> $vloadSH
echo "fi"                                                                                                                   >> $vloadSH
echo ""                                                                                                                     >> $vloadSH
echo "base=\"\${CSV2RDF4LOD_BASE_URI_OVERRIDE:-\$CSV2RDF4LOD_BASE_URI}\""                                                   >> $vloadSH
echo "graph=\"\$base/source/${sourceID}/dataset/${datasetID}/version/${versionID}\"" >> $vloadSH
echo "metaGraph=\"\$graph\""                                                                                                >> $vloadSH
echo "if [ \"\$1\" == \"--sample\" ]; then"                                                                                 >> $vloadSH
http_allRawSample="\$base/source/${sourceID}/file/${datasetID}/version/${versionID}/conversion/${sourceID}-${datasetID}-${versionID}.rdf"
for layerSlug in $layerSlugs # <---- Add root-level subsets here.
do
   layerID=`echo $layerSlug | sed 's/^.*\//e/'` # enhancement/1 -> e1
   echo "   layerSlug=\"$layerSlug\""                                                                                       >> $vloadSH # .-todo
   echo "   sampleGraph=\"\$graph/conversion/\$layerSlug/subset/sample\""                                                   >> $vloadSH
#   echo "   #sampleTTL=$pSDV.`echo $layerSlug | sed 's/^.*\//e/'`.sample.ttl"                                              >> $vloadSH # .-todo
#   echo "   #sudo /opt/virtuoso/scripts/vload ttl \$sampleTTL \$sampleGraph"                                               >> $vloadSH
   echo "   sampleURL=\"\$base/source/${sourceID}/file/${datasetID}/version/${versionID}/conversion/${S_D_V}.${layerID}.sample.ttl\"" >> $vloadSH
   #                  http://logd.tw.rpi.edu/source/twc-rpi-edu/file/instance-hub-us-states-and-territories/version/2011-Mar-31_17-51-07/conversion/twc-rpi-edu-instance-hub-us-states-and-territories-2011-Mar-31_17-51-07.e1.sample
   echo "   echo pvload.sh \$sampleURL -ng \$sampleGraph"                                                                   >> $vloadSH
   echo "   \${CSV2RDF4LOD_HOME}/bin/util/pvload.sh \$sampleURL -ng \$sampleGraph"                                          >> $vloadSH
   echo ""                                                                                                                  >> $vloadSH
done
echo "   exit 1"                                                                                                            >> $vloadSH
echo "elif [[ \"\$1\" == \"--meta\" && -e '$allVOID' ]]; then"                                                              >> $vloadSH
echo "   metaURL=\"\$base/source/${sourceID}/file/${datasetID}/version/${versionID}/conversion/${S_D_V}.void.ttl\""         >> $vloadSH
echo "   metaGraph=\"\$base\"/vocab/Dataset"                                                                                >> $vloadSH
#echo "   #echo sudo /opt/virtuoso/scripts/vload ttl $allVOID \$graph"                                                      >> $vloadSH
#echo "   #sudo /opt/virtuoso/scripts/vload ttl $allVOID \$graph"                                                           >> $vloadSH
echo "   echo pvload.sh \$metaURL -ng \$metaGraph"                                                                          >> $vloadSH
echo "   \${CSV2RDF4LOD_HOME}/bin/util/pvload.sh \$metaURL -ng \$metaGraph"                                                 >> $vloadSH
echo "   exit 1"                                                                                                            >> $vloadSH
echo "fi"                                                                                                                   >> $vloadSH
echo ""                                                                                                                     >> $vloadSH
echo "# Change the target graph before continuing to load everything"                                                       >> $vloadSH
echo "if [[ \"\$1\" == \"--unversioned\" || \"\$1\" == \"--abstract\" ]]; then"                                             >> $vloadSH
echo "   # strip off version"                                                                                               >> $vloadSH
echo "   graph=\"\`echo \$graph\ | perl -pe 's|/version/[^/]*$||'\`\""                                                      >> $vloadSH
echo "   graph=\"\$base/source/${sourceID}/dataset/${datasetID}\""                                                          >> $vloadSH
echo "   echo populating abstract named graph \(\$graph\) instead of versioned named graph."                                >> $vloadSH
echo "elif [[ \"\$1\" == \"--meta\" ]]; then"                                                                               >> $vloadSH
echo "   metaGraph=\"\$base/vocab/Dataset\""                                                                                >> $vloadSH
echo "elif [[ \"\$1\" == \"--as-metadataset\" ]]; then"                                                                     >> $vloadSH
echo "   graph=\"\${CSV2RDF4LOD_PUBLISH_METADATASET_GRAPH_NAME:-'http://purl.org/twc/vocab/conversion/MetaDataset'}\""      >> $vloadSH
echo "   metaGraph=\"\$graph\""                                                                                             >> $vloadSH
echo "elif [[ \"\$CSV2RDF4LOD_PUBLISH_SPARQL_ENDPOINT_SEPARATE_NG_PROVENANCE\" == 'true' ]]; then"                          >> $vloadSH
echo "   metaGraph=\`pvload.sh --prov-graph-name \$graph\`"                                                                 >> $vloadSH
echo "elif [ \$# -gt 0 ]; then"                                                                                             >> $vloadSH
echo "   echo param not recognized: \$1"                                                                                    >> $vloadSH
echo "   echo usage: \`basename \$0\` with no parameters loads versioned dataset"                                           >> $vloadSH
echo "   echo usage: \`basename \$0\` --{sample, meta, abstract}"                                                           >> $vloadSH
echo "   exit 1"                                                                                                            >> $vloadSH
echo "fi"                                                                                                                   >> $vloadSH
echo ""                                                                                                                     >> $vloadSH
echo "# Load the metadata, either in the same named graph as the data or into a more global one."                           >> $vloadSH
echo "metaURL=\"\$base/source/${sourceID}/file/${datasetID}/version/${versionID}/conversion/${S_D_V}.void.ttl\""            >> $vloadSH
echo "echo pvload.sh \$metaURL -ng \$metaGraph"                                                                             >> $vloadSH
echo "\${CSV2RDF4LOD_HOME}/bin/util/pvload.sh \$metaURL -ng \$metaGraph"                                                    >> $vloadSH
echo "if [[ \"\$1\" == \"--meta\" ]]; then"                                                                                 >> $vloadSH
echo "   exit 1"                                                                                                            >> $vloadSH
echo "fi"                                                                                                                   >> $vloadSH
# http://logd.tw.rpi.edu/source/nitrd-gov/dataset/DDD/version/2011-Jan-27
# http://logd.tw.rpi.edu/source/nitrd-gov/file/DDD/version/2011-Jan-27/conversion/nitrd-gov-DDD-2011-Jan-27.ttl.gz
echo ""                                                                                                                     >> $vloadSH
echo ""                                                                                                                     >> $vloadSH
echo ""                                                                                                                     >> $vloadSH
echo "[[ \"\$CSV2RDF4LOD_PUBLISH_SPARQL_ENDPOINT_SEPARATE_NG_PROVENANCE\" == 'true' ]] && sep='--separate-provenance' || sep=''" >> $vloadSH
echo "dump='$allNT'"                                                                                                        >> $vloadSH
echo "url='$http_allNT'"                                                                                                    >> $vloadSH
echo "if [ -e \$dump ]; then"                                                                                               >> $vloadSH
echo "   echo pvload.sh \$url -ng \$graph \$sep"                                                                            >> $vloadSH
echo "   \${CSV2RDF4LOD_HOME}/bin/util/pvload.sh \$url -ng \$graph \$sep"                                                   >> $vloadSH
echo "   exit 1"                                                                                                            >> $vloadSH
echo "elif [ -e \$dump.$zip ]; then"                                                                                        >> $vloadSH
echo "   echo pvload.sh \$url.$zip -ng \$graph \$sep"                                                                       >> $vloadSH
echo "   \${CSV2RDF4LOD_HOME}/bin/util/pvload.sh \$url.$zip -ng \$graph \$sep"                                              >> $vloadSH
echo "   exit 1"                                                                                                            >> $vloadSH
echo "fi"                                                                                                                   >> $vloadSH
echo ""                                                                                                                     >> $vloadSH
echo "dump='$allTTL'"                                                                                                       >> $vloadSH
echo "url='$http_allTTL'"                                                                                                   >> $vloadSH
echo "if [ -e \$dump ]; then"                                                                                               >> $vloadSH
echo "   echo pvload.sh \$url -ng \$graph \$sep"                                                                            >> $vloadSH
echo "   \${CSV2RDF4LOD_HOME}/bin/util/pvload.sh \$url -ng \$graph \$sep"                                                   >> $vloadSH
echo "   exit 1"                                                                                                            >> $vloadSH
echo "elif [ -e \$dump.$zip ]; then"                                                                                        >> $vloadSH
echo "   echo pvload.sh \$url.$zip -ng \$graph \$sep"                                                                       >> $vloadSH
echo "   \${CSV2RDF4LOD_HOME}/bin/util/pvload.sh \$url.$zip -ng \$graph \$sep"                                              >> $vloadSH
echo "   exit 1"                                                                                                            >> $vloadSH
echo "fi"                                                                                                                   >> $vloadSH
echo ""                                                                                                                     >> $vloadSH
echo "dump='$allRDFXML'"                                                                                                    >> $vloadSH
echo "url='$http_allRDFXML'"                                                                                                >> $vloadSH
echo "if [ -e \$dump ]; then"                                                                                               >> $vloadSH
echo "   \${CSV2RDF4LOD_HOME}/bin/util/pvload.sh \$url -ng \$graph \$sep"                                                   >> $vloadSH
echo "   exit 1"                                                                                                            >> $vloadSH
echo "elif [ -e \$dump.$zip ]; then"                                                                                        >> $vloadSH
echo "   \${CSV2RDF4LOD_HOME}/bin/util/pvload.sh \$url.$zip -ng \$graph \$sep"                                              >> $vloadSH
echo "   exit 1"                                                                                                            >> $vloadSH
echo "fi"                                                                                                                   >> $vloadSH
echo "#3> <> prov:wasAttributedTo <$baseURI/id/csv2rdf4lod/$myMD5> ."                                                       >> $vloadSH
echo "#                           convert-aggregate.sh"                                                                     >> $vloadSH
echo "#3> <> prov:generatedAtTime \"`dateInXSDDateTime.sh`\"^^xsd:dateTime ."                                               >> $vloadSH
echo "#3> <$baseURI/id/csv2rdf4lod/$myMD5> foaf:name \"`basename $0`\" ."                                                   >> $vloadSH
chmod +x $vloadSH
cat $vloadSH | sed 's/pvload.sh .*-ng/pvdelete.sh/g' | sed 's/vload [^ ]* [^^ ]* /vdelete /' | grep -v "tar xzf" | grep -v "unzip" | grep -v "rm " > $vdeleteSH # TODO:notar
chmod +x $vdeleteSH

loaded="no"
if [ "$CSV2RDF4LOD_PUBLISH_VIRTUOSO" == "true" ]; then
   if [ "$CSV2RDF4LOD_PUBLISH_FULL_CONVERSIONS" == "true" ]; then
      echo
      echo "   ///= = = = = = = = = = = = = = = = = = = = = $vdeleteSH = = = = = = = = = = = = = = = = = = = = = = =\\\\\\"
      echo
      $vdeleteSH
      echo "    \\\\\\ = = = = = = = = = = = = = = = = = = = = (end) $vdeleteSH = = = = = = = = = = = = = = = = = = = = = = =///"
      echo
      echo "    /// = = = = = = = = = = = = = = = = = = = = $vloadSH = = = = = = = = = = = = = = = = = = = = = = =\\\\\\"
      echo
      $vloadSH
      echo "    \\\\\\ = = = = = = = = = = = = = = = = = = = = (end) $vloadSH = = = = = = = = = = = = = = = = = = = = = = =///"
      echo
      loaded="yes"
   else
      echo "$CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT - skipping load of full conversion; set CSV2RDF4LOD_PUBLISH_FULL_CONVERSIONS=true to automatically load full conversions into the triple store."
   fi
   if [ "$CSV2RDF4LOD_PUBLISH_SUBSET_SAMPLES" == "true" ]; then
      echo
      echo "    /// = = = = = = = = = = = = = = = = = = = = $vdeleteSH = = = = = = = = = = = = = = = = = = = = = = =\\\\\\"
      echo
      $vdeleteSH --sample
      echo "    \\\\\\ = = = = = = = = = = = = = = = = = = = = (end) $vdeleteSH = = = = = = = = = = = = = = = = = = = = = = =///"
      echo
      echo "    /// = = = = = = = = = = = = = = = = = = = = $vloadSH = = = = = = = = = = = = = = = = = = = = = = =\\\\\\"
      echo
      $vloadSH   --sample
      echo "    \\\\\\ = = = = = = = = = = = = = = = = = = = = (end) $vloadSH = = = = = = = = = = = = = = = = = = = = = = =///"
      echo
      loaded="yes"
   else
      echo "$CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT - skipping load of conversion samples; set CSV2RDF4LOD_PUBLISH_SUBSET_SAMPLES=true to automatically load conversion samples into the triple store."
   fi
else
   echo "$CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT - skipping; set CSV2RDF4LOD_PUBLISH_VIRTUOSO=true to automatically load conversions into the triple store."
fi

if [[ "$loaded" == "yes" ]]; then
   if [ "$CSV2RDF4LOD_PUBLISH_ANNOUNCE_TO_SINDICE" == "true" ]; then
      echo
      echo "    /// = = = = = = = = = = = = = = = = = = = = ping-sindice.sh = = = = = = = = = = = = = = = = = = = = = = =\\\\\\"
      echo
      url=`cr-dataset-uri.sh --uri`
      echo "http://api.sindice.com/v2/ping <-- $url"
      ping-sindice.sh -w $url
      echo "    \\\\\\ = = = = = = = = = = = = = = = = = = = = (end) ping-sindice.sh = = = = = = = = = = = = = = = = = = = = = = =///"
      echo
   else
      echo "http://api.sindice.com/v2/ping - skipping; set CSV2RDF4LOD_PUBLISH_ANNOUNCE_TO_SINDICE=true to announce to Sindice."
   fi
fi

#
# LOD-materialize
#
local_materialization_dir=publish/lod-mat

lodmat='$CSV2RDF4LOD_HOME/bin/lod-materialize/${c_lod_mat}lod-materialize.pl'
prefixDefs=`$CSV2RDF4LOD_HOME/bin/dup/prefixes2flags.sh $allTTL`
mappingPatterns='--uripattern="/source/([^/]+)/dataset/(.*)" --filepattern="/source/\\1/file/\\2"'
mappingPatternsVocab='--uripattern="/source/([^/]+)/vocab/(.*)" --filepattern="/source/\\1/vocab_file/\\2"'
mappingPatternsProvenance='--uripattern="/source/([^/]+)/provenance/(.*)" --filepattern="/source/\\1/file/\\2"'
CSV2RDF4LOD_BASE_URI=${CSV2RDF4LOD_BASE_URI:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}
MATERIALIZATION_DIR=${CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT:-$local_materialization_dir}

lodmatSH=publish/bin/lod-materialize-${sourceID}-${datasetID}-${versionID}.sh
echo "#!/bin/bash"                                                                                              > $lodmatSH
echo "#"                                                                                                       >> $lodmatSH
echo "# run $convertDir/lod-materialize-${sourceID}-${datasetID}-${versionID}.sh"                            >> $lodmatSH
echo "# from ${sourceID}/$datasetID/version/$versionID/"                                                  >> $lodmatSH
echo ""                                                                                                        >> $lodmatSH
echo 'CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}'                        >> $lodmatSH
echo ""                                                                                                        >> $lodmatSH
echo "delete=\"\""                                                                                             >> $lodmatSH
echo "if [ ! -e $allNT ]; then"                                                                                >> $lodmatSH
echo "  delete=\"$allNT\""                                                                                     >> $lodmatSH
echo "  if [ -e $allNT.$zip ]; then"                                                                           >> $lodmatSH
#echo "    tar xzf $allNT.$zip"                                                                                  >> $lodmatSH # TODO:notar
echo "    gunzip -c \$allNT.$zip > \$allNT"                                                                      >> $lodmatSH # TODO:notar
echo "  elif [ -e $allTTL ]; then"                                                                             >> $lodmatSH
echo "    echo \"cHuNking $allTTL into $allNT; will delete when done lod-mat'ing\""                            >> $lodmatSH
echo "    \$CSV2RDF4LOD_HOME/bin/util/bigttl2nt.sh $allTTL > $allNT"                                           >> $lodmatSH
echo "  elif [ -e $allTTL.$zip ]; then"                                                                        >> $lodmatSH
#echo "    tar xzf $allTTL.$zip"                                                                                 >> $lodmatSH # TODO:notar
echo "    gunzip -c \$allTTL.$zip > \$allTTL"                                                                    >> $lodmatSH # TODO:notar
echo "    echo \"cHuNking $allTTL into $allNT; will delete when done lod-mat'ing\""                            >> $lodmatSH
echo "    \$CSV2RDF4LOD_HOME/bin/util/bigttl2nt.sh $allTTL > $allNT"                                           >> $lodmatSH
echo "    rm $allTTL"                                                                                          >> $lodmatSH
echo "  else"                                                                                                  >> $lodmatSH
echo "    echo $allNT, $allNT.$zip, $allTTL, or $allTTL.$zip needed to lod-materialize."                       >> $lodmatSH
echo "    delete=\"\""                                                                                         >> $lodmatSH
echo "    exit 1"                                                                                              >> $lodmatSH
echo "  fi"                                                                                                    >> $lodmatSH
echo "fi"                                                                                                      >> $lodmatSH
echo ""                                                                                                        >> $lodmatSH
echo "                # The newer C version of lod-mat is faster."                                             >> $lodmatSH
echo "c_lod_mat=\"c/\"  # It is in the directory called 'c' within the lod-materialization project."           >> $lodmatSH
echo "                # The C version silently passes some parameters that the native perl version used."      >> $lodmatSH
echo "if [ ! -e \$CSV2RDF4LOD_HOME/bin/lod-materialize/c/lod-materialize ]; then"                              >> $lodmatSH
echo "   c_lod_mat=\"\" # If it is not available, use the older perl version."                                 >> $lodmatSH
echo "   echo \"WARNING: REALLY SLOW lod-materialization going on. Run make in \$CSV2RDF4LOD_HOME/bin/lod-materialize/c/\"" >> $lodmatSH
echo "fi"                                                                                                      >> $lodmatSH
echo ""                                                                                                        >> $lodmatSH
echo "writeBuffer=\"--buffer-size=\${CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WRITE_FREQUENCY:-\"1000000\"}\""  >> $lodmatSH
echo "humanReport=\"--progress=\${CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_REPORT_FREQUENCY:-\"10000\"}\""      >> $lodmatSH
echo "concurrency=\"--concurrency=\${CSV2RDF4LOD_CONCURRENCY:-\"1\"}\""                                        >> $lodmatSH
echo "freqParams=\" \$writeBuffer \$humanReport \$concurrency \""                                              >> $lodmatSH
echo ""                                                                                                        >> $lodmatSH
echo "# -D namespace abbreviations, -p: print progress"                                                        >> $lodmatSH
echo perl $lodmat -i=ntriples $prefixDefs $mappingPatterns           \$freqParams --directoryindex=CSV2RDF4LODINDEX $allNT $baseURI $MATERIALIZATION_DIR >> $lodmatSH
echo ""                                                                                                        >> $lodmatSH
echo perl $lodmat -i=ntriples $prefixDefs $mappingPatternsVocab      \$freqParams --directoryindex=CSV2RDF4LODINDEX $allNT $baseURI $MATERIALIZATION_DIR >> $lodmatSH
echo ""                                                                                                        >> $lodmatSH
echo perl $lodmat -i=ntriples $prefixDefs $mappingPatternsProvenance \$freqParams --directoryindex=CSV2RDF4LODINDEX $allNT $baseURI $MATERIALIZATION_DIR >> $lodmatSH
echo ""                                                                                                        >> $lodmatSH
echo "if [ \${#delete} -gt 0 ]; then"                                                                          >> $lodmatSH
echo "   rm \$delete"                                                                                          >> $lodmatSH
echo "fi"                                                                                                      >> $lodmatSH
chmod +x                                                                                                          $lodmatSH

lodmatvoidSH=publish/bin/lod-materialize-${sourceID}-${datasetID}-${versionID}-void.sh
echo "#!/bin/bash"                                                                                                > $lodmatvoidSH
echo "#"                                                                                                       >> $lodmatvoidSH
echo "# run $convertDir/lod-materialize-${sourceID}-${datasetID}-${versionID}.sh"                            >> $lodmatvoidSH
echo "# from ${sourceID}/$datasetID/version/$versionID/"                                                  >> $lodmatvoidSH
echo ""                                                                                                        >> $lodmatvoidSH
echo 'CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}'                        >> $lodmatvoidSH
echo ""                                                                                                        >> $lodmatvoidSH
echo "delete=\"false\""                                                                                        >> $lodmatvoidSH
echo "if [ ! -e $allVOIDNT ]; then"                                                                            >> $lodmatvoidSH
echo "   # Note: tarball does not need to be handled b/c only layer dump files are tarballed."                 >> $lodmatvoidSH
echo "   echo \"cHuNking $allVOID into $allVOIDNT; will delete when done lod-mat'ing\""                        >> $lodmatvoidSH
echo "   \$CSV2RDF4LOD_HOME/bin/util/bigttl2nt.sh $allVOID > $allVOIDNT"                                       >> $lodmatvoidSH
echo "   delete=\"true\""                                                                                      >> $lodmatvoidSH
echo "fi"                                                                                                      >> $lodmatvoidSH
echo ""                                                                                                        >> $lodmatvoidSH
echo "                # The newer C version of lod-mat is faster."                                             >> $lodmatvoidSH
echo "c_lod_mat=\"c/\"  # It is in the directory called 'c' within the lod-materialization project."           >> $lodmatvoidSH
echo "                # The C version silently passes some parameters that the native perl version used."      >> $lodmatvoidSH
echo "if [ ! -e \$CSV2RDF4LOD_HOME/bin/lod-materialize/c/lod-materialize ]; then"                              >> $lodmatvoidSH
echo "   c_lod_mat=\"\" # If it is not available, use the older perl version."                                 >> $lodmatvoidSH
echo "   echo \"WARNING: REALLY SLOW lod-materialization going on. Run make in \$CSV2RDF4LOD_HOME/bin/lod-materialize/c/\"" >> $lodmatvoidSH
echo "fi"                                                                                                      >> $lodmatvoidSH
echo ""                                                                                                        >> $lodmatvoidSH
echo "writeBuffer=\"--buffer-size=\${CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WRITE_FREQUENCY:-\"1000000\"}\""  >> $lodmatvoidSH
echo "humanReport=\"--progress=\${CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_REPORT_FREQUENCY:-\"10000\"}\""      >> $lodmatvoidSH
echo "concurrency=\"--concurrency=\${CSV2RDF4LOD_CONCURRENCY:-\"1\"}\""                                        >> $lodmatvoidSH
echo "freqParams=\" \$writeBuffer \$humanReport \$concurrency \""                                              >> $lodmatvoidSH
echo ""                                                                                                        >> $lodmatvoidSH
echo "# -D namespace abbreviations, -p: print progress"                                                        >> $lodmatvoidSH
echo perl $lodmat -i=ntriples $prefixDefs $mappingPatterns           \$freqParams --directoryindex=CSV2RDF4LODINDEX $allVOIDNT $baseURI $MATERIALIZATION_DIR >> $lodmatvoidSH
echo ""                                                                                                        >> $lodmatvoidSH
echo perl $lodmat -i=ntriples $prefixDefs $mappingPatternsVocab      \$freqParams --directoryindex=CSV2RDF4LODINDEX $allVOIDNT $baseURI $MATERIALIZATION_DIR >> $lodmatvoidSH
echo ""                                                                                                        >> $lodmatvoidSH
echo perl $lodmat -i=ntriples $prefixDefs $mappingPatternsProvenance \$freqParams --directoryindex=CSV2RDF4LODINDEX $allVOIDNT $baseURI $MATERIALIZATION_DIR >> $lodmatvoidSH
echo ""                                                                                                        >> $lodmatvoidSH
echo "if [ \$delete == \"true\" ]; then"                                                                       >> $lodmatvoidSH
echo "   rm $allVOIDNT"                                                                                        >> $lodmatvoidSH
echo "fi"                                                                                                      >> $lodmatvoidSH
chmod +x                                                                                                          $lodmatvoidSH

lodmatapacheSH=publish/bin/lod-materialize-apache-${sourceID}-${datasetID}-${versionID}.sh
echo "#!/bin/bash"                                                                                                > $lodmatapacheSH
echo "#"                                                                                                       >> $lodmatapacheSH
echo "# run $convertDir/lod-materialize-apache-${sourceID}-${datasetID}-${versionID}.sh"                     >> $lodmatapacheSH
echo "# from ${sourceID}/$datasetID/version/$versionID/"                                                  >> $lodmatapacheSH
echo ""                                                                                                        >> $lodmatapacheSH
echo "                # The newer C version of lod-mat is faster."                                             >> $lodmatapacheSH
echo "c_lod_mat=\"c/\"  # It is in the directory called 'c' within the lod-materialization project."           >> $lodmatapacheSH
echo "                # The C version silently passes some parameters that the native perl version used."      >> $lodmatapacheSH
echo "if [ ! -e \$CSV2RDF4LOD_HOME/bin/lod-materialize/c/lod-materialize ]; then"                              >> $lodmatapacheSH
echo "   c_lod_mat=\"\" # If it is not available, use the older perl version."                                 >> $lodmatapacheSH
echo "   echo \"WARNING: REALLY SLOW lod-materialization going on. Run make in \$CSV2RDF4LOD_HOME/bin/lod-materialize/c/\"" >> $lodmatapacheSH
echo "fi"                                                                                                      >> $lodmatapacheSH
echo ""                                                                                                        >> $lodmatapacheSH
echo perl $lodmat -i=ntriples $mappingPatterns      --apache $allNT $baseURI $MATERIALIZATION_DIR              >> $lodmatapacheSH
echo perl $lodmat -i=ntriples $mappingPatternsVocab --apache $allNT $baseURI $MATERIALIZATION_DIR              >> $lodmatapacheSH
chmod +x                                                                                                          $lodmatapacheSH

if [ ${CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION:-"."} == "true" ]; then # Producing lod-mat can take a fair amount of time and space...
   if [ $MATERIALIZATION_DIR != $local_materialization_dir ]; then
      echo "$local_materialization_dir  - overridden by CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT" | tee -a $CSV2RDF4LOD_LOG
   fi
   echo "`echo $MATERIALIZATION_DIR/ | sed 's/\/\/$/\//'` - overriding $local_materialization_dir; target destination for lod-materialization" | tee -a $CSV2RDF4LOD_LOG
   if [ $MATERIALIZATION_DIR == $local_materialization_dir ]; then
      echo "  clearing $MATERIALIZATION_DIR" | tee -a $CSV2RDF4LOD_LOG
      rm -rf $MATERIALIZATION_DIR/* &> /dev/null
   fi
   echo
   echo "    /// = = = = = = = = = = = = = = = = = = = = $lodmatSH = = = = = = = = = = = = = = = = = = = = = = =\\\\\\"
   echo
   $lodmatSH
   echo "    \\\\\\ = = = = = = = = = = = = = = = = = = = = (end) $lodmatSH = = = = = = = = = = = = = = = = = = = = = = =///"
   echo
else
   echo "$MATERIALIZATION_DIR/ - skipping; set CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION=true in source-me.sh to load conversions into $MATERIALIZATION_DIR/," | tee -a $CSV2RDF4LOD_LOG
   echo "`echo $MATERIALIZATION_DIR/ | sed 's/./ /g'` - or run $convertDir/lod-materialize-${sourceID}-${datasetID}-${versionID}.sh." | tee -a $CSV2RDF4LOD_LOG
fi

if [ -e $allTTL -a ${CSV2RDF4LOD_PUBLISH_TTL:-"."} != "true" ]; then
   rm $allTTL
fi
if [ -e $allNT -a ${CSV2RDF4LOD_PUBLISH_NT:-"."} != "true" ]; then
   rm $allNT
fi






#
# Removed the pre-compressed dump files
#
if [ "$CSV2RDF4LOD_PUBLISH_COMPRESS" == "true" ]; then
   for dumpFile in $filesToCompress ; do
      # Compressed file was created earlier in this script.
      if [ -e $dumpFile.$zip ]; then
         echo "$dumpFile - removed b/c \$CSV2RDF4LOD_PUBLISH_COMPRESS=\"true\"" | tee -a $CSV2RDF4LOD_LOG
         rm $dumpFile
      fi
   done
   # This causes too much unconsidered issues:
   #if [ "$CSV2RDF4LOD_PUBLISH_PURGE_AUTODIR" == "true" ]; then
   #   echo "automatic/* purging b/c CSV2RDF4LOD_PUBLISH_PURGE_AUTODIR == true"
   #   rm -rf automatic/*
   #fi
fi







CSV2RDF4LOD_LOG=""
echo convert-aggregate.sh done | tee -a $CSV2RDF4LOD_LOG
echo "===========================================================================================" | tee -a $CSV2RDF4LOD_LOG
#chmod -w $CSV2RDF4LOD_LOG
