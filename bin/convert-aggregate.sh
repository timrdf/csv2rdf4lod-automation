# convert-aggregate.sh
#
# Aggregate conversion outputs into publishable datafiles.
#
# Up to this point, all processing was done using filenames provided by the dataset source organization.
# Put all data into $sourceID-$datasetID-$datasetVersion dump files and construct command appropriate 
# for lod-materialization.
#
#
# ___NOT___ to be called directly: called by convert-DATASET.sh (a script created using cr-create-convert-sh.sh)
# can also be invoked running publish/bin/publish.sh

if [ ${CSV2RDF4LOD_FORCE_PUBLISH:-"."} == "true" ]; then
   echo "convert-aggregate.sh publishing raw and enhancements (forced)." | tee -a $CSV2RDF4LOD_LOG
else
   if [ ${CSV2RDF4LOD_PUBLISH:-"."} == "false" ]; then
         echo "convert-aggregate.sh not publishing b/c \$CSV2RDF4LOD_PUBLISH=false."                        | tee -a $CSV2RDF4LOD_LOG
         echo "===========================================================================================" | tee -a $CSV2RDF4LOD_LOG
         CSV2RDF4LOD_LOG=""
         exit 1
   fi
   if [ ${CSV2RDF4LOD_PUBLISH_DELAY_UNTIL_ENHANCED:-"true"} == "true" ]; then
      if [ $runEnhancement == "yes" -a `ls $destDir/*.e$eID.ttl 2> /dev/null | wc -l` -gt 0 ]; then
         echo "convert-aggregate.sh publishing raw and enhancements."                                                                     | tee -a $CSV2RDF4LOD_LOG
      else
         # NOTE: If multiple files to convert and the LAST file is not enhanced, 
         #       the runEnhancement flag will be "no" and convert-aggregate.sh will not aggregate.
         # To overcome this bug, manually run publish/bin/publish.sh to force the aggregation.
         echo "convert-aggregate.sh delaying publishing until an enhancement is available."                                               | tee -a $CSV2RDF4LOD_LOG
         echo "  To publish with only raw, set CSV2RDF4LOD_PUBLISH_DELAY_UNTIL_ENHANCED=\"false\" in \$CSV2RDF4LOD_HOME/source-me.sh."    | tee -a $CSV2RDF4LOD_LOG
         echo "  To publish raw with enhanced, add enhancement to $eParamsDir/$datafile.e$eID.params.ttl and rerun convert-$datasetID.sh" | tee -a $CSV2RDF4LOD_LOG
         echo "  To force publishing now, run publish/bin/publish.sh"                                                                     | tee -a $CSV2RDF4LOD_LOG
         echo "==========================================================================================="                               | tee -a $CSV2RDF4LOD_LOG
         CSV2RDF4LOD_LOG=""
         exit 1
      fi
   fi
fi

touch $publishDir

SDV=$publishDir/$sourceID-$datasetID-$datasetVersion
allRaw=$publishDir/$sourceID-$datasetID-$datasetVersion.raw.ttl
allEX=$publishDir/$sourceID-$datasetID-$datasetVersion.e$eID.ttl # only the current enhancement.
allTTL=$publishDir/$sourceID-$datasetID-$datasetVersion.ttl
allNT=$publishDir/$sourceID-$datasetID-$datasetVersion.nt
allRDFXML=$publishDir/$sourceID-$datasetID-$datasetVersion.rdf
allVOID=$publishDir/$sourceID-$datasetID-$datasetVersion.void.ttl
allVOIDNT=$publishDir/$sourceID-$datasetID-$datasetVersion.void.nt
allPML=$publishDir/$sourceID-$datasetID-$datasetVersion.pml.ttl
allSAMEAS=$publishDir/$sourceID-$datasetID-$datasetVersion.sameas.nt
rawSAMPLE=$publishDir/$sourceID-$datasetID-$datasetVersion.raw.sample.ttl
versionedDatasetURI="${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$surrogate}/source/$sourceID/dataset/$datasetID/version/$datasetVersion"
rawSampleGraph="${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$surrogate}/source/$sourceID/dataset/$datasetID/version/$datasetVersion/conversion/raw/subset/sample"

http_allNT="${CSV2RDF4LOD_BASE_URI}/source/${sourceID}/file/${datasetID}/version/${versionID}/conversion/${sourceID}-${datasetID}-${datasetVersion}.nt"
http_allTTL="${CSV2RDF4LOD_BASE_URI}/source/${sourceID}/file/${datasetID}/version/${versionID}/conversion/${sourceID}-${datasetID}-${datasetVersion}.ttl"
http_allRDFXML="${CSV2RDF4LOD_BASE_URI}/source/${sourceID}/file/${datasetID}/version/${versionID}/conversion/${sourceID}-${datasetID}-${datasetVersion}.rdf"

 allNT_L=$sourceID-$datasetID-$datasetVersion.nt # L: Local name (not including directory; for use when pushd'ing to cHuNk)
allSAMEAS_L=$sourceID-$datasetID-$datasetVersion.sameas.nt
filesToCompress="$allRaw"

zip="gz"
if [ ${versionID} -le 0 ]; then
   versionID=$datasetVersion # TEMP - until fully deprecated datasetVersion. versionID should be always set eventually.
fi

if [ ! `which rapper` ]; then
   # check if rapper is on path, if not, report error.
   echo "NOTE: rapper not found. Some serializations will probably be empty." | tee -a $CSV2RDF4LOD_LOG
fi



#
# Raw ttl
#
conversionIDs="raw"
conversionSteps="raw"
echo $allRaw | tee -a $CSV2RDF4LOD_LOG
cat $destDir/*.raw.ttl > $allRaw

#
# Sample of raw (TODO: add sample of enhanced, too)
#
# REPLACED by an extra call to the converter with the -samples param.
echo $SDV.raw.sample.ttl | tee -a $CSV2RDF4LOD_LOG
#$CSV2RDF4LOD_HOME/bin/util/grep-head.sh -p 'ov:csvRow "100' $allRaw > $SDV.raw.sample.ttl
cat $destDir/*.raw.sample.ttl > $SDV.raw.sample.ttl


#
# Individual enhancement ttl (any that are not aggregated)
#
# Got messed up when added sample.ttl: 
#     enhancementLevels=`ls $destDir/*.e*.ttl 2> /dev/null | grep -v void.ttl | sed -e 's/^.*\.e\([^.]*\).ttl/\1/' | sort -u`
# This works, but moved to script: 
#     enhancementLevels=`find $destDir -name "*.e[!.].ttl" | sed -e 's/^.*\.e\([^.]*\).ttl/\1/' | sort -u` # WARNING: only handles e1 through e9
enhancementLevels=`cr-list-enhancement-identifiers.sh` # WARNING: only handles e1 through e9
anyEsDone="no"
for eIDD in $enhancementLevels # eIDD to avoid overwritting currently-requested enhancement eID
do
   eTTL=$publishDir/$sourceID-$datasetID-$datasetVersion.e$eIDD.ttl
   eTTLsample=`echo $eTTL | sed 's/.ttl$/.sample.ttl/'` # Just insert sample to the next-to-last

   # Aggregate the enhancements.
   echo $eTTL | tee -a $CSV2RDF4LOD_LOG
   cat $destDir/*.e$eIDD.ttl > $eTTL                  ; filesToCompress="$filesToCompress $eTTL"

   # Sample the aggregated enhancements.
   # REPLACED by an extra call to the converter with the -samples param.
   #echo $eTTLsample | tee -a $CSV2RDF4LOD_LOG
   #$CSV2RDF4LOD_HOME/bin/util/grep-head.sh -p 'ov:csvRow "100' $eTTL > $eTTLsample
   echo $eTTLsample | tee -a $CSV2RDF4LOD_LOG
   if [ $anyEsDone == "no" ]; then
      cat $destDir/*.e$eIDD.sample.ttl  > $eTTLsample
      anyEsDone="yes"
   else
      cat $destDir/*.e$eIDD.sample.ttl >> $eTTLsample
   fi

   conversionIDs="$conversionIDs e$eIDD"
   conversionSteps="$conversionSteps enhancement/$eIDD"
done



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
for eIDD in $enhancementLevels # eIDD to avoid overwritting currently-requested enhancement eID
do
   eTTL=$publishDir/$sourceID-$datasetID-$datasetVersion.e$eIDD.ttl

   echo "  (including $eTTL)" | tee -a $CSV2RDF4LOD_LOG

   if [ $anyEsDone == "no" ]; then
      echo "# BEGIN: $eTTL:"  > $allTTL
      cat $eTTL              >> $allTTL
      anyEsDone="yes"
   else
      echo "# BEGIN: $eTTL:" >> $allTTL
      cat $eTTL              >> $allTTL
   fi
   #cat $destDir/*.e$eID.ttl | rapper -q -i turtle -o turtle - http://www.no.org | grep -v "http://www.no.org" >  $allE1   2> /dev/null
   #cat $allE1 $allRaw        | rapper -q -i turtle -o turtle - http://www.no.org | grep -v "http://www.no.org" > $allTTL   2> /dev/null
done
echo "  (including $allRaw)" | tee -a $CSV2RDF4LOD_LOG
echo "# BEGIN: $allRaw:"     >> $allTTL
cat $allRaw                  >> $allTTL
#grep "^@prefix" $allTTL | sort -u > $destDir/prefixes-$sourceID-$datasetID-$datasetVersion.ttl
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
   if [ `find $publishDir -size +1900M -name $sourceID-$datasetID-$datasetVersion.ttl | wc -l` -gt 0 ]; then # +1900M, +10M for debugging
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


#
# Provenance - PML
#
echo $allPML | tee -a $CSV2RDF4LOD_LOG
rm $allPML 2> /dev/null
for dir in source manual automatic; do
   for pml in `find $dir -name "*.pml.ttl"`; do
      # source/STATE_SINGLE_PW.CSV -> 
      # http://logd.tw.rpi.edu/source/data-gov/provenance_file/1008/version/2010-Aug-30/source/STATE_SINGLE_PW.CSV
      # rapper -g -o turtle source/STATE_SINGLE_PW.CSV.pml.ttl  http://logd.tw.rpi.edu/source/data-gov/provenance_file/1008/version/2010-Aug-30/source/
      sourceFile=`echo $pml | sed 's/.pml.ttl$//'`
      base4rapper="${CSV2RDF4LOD_BASE_URI}/source/${sourceID}/provenance_file/${datasetID}/version/${datasetVersion}/$dir/"
      echo "  (including $pml)" | tee -a $CSV2RDF4LOD_LOG
      if [ `which rapper` ]; then
         rapper -g -o turtle $pml $base4rapper >> $allPML 2> /dev/null
      else
         echo "@base <$base4rapper> ." >> $allPML
         echo "" >> $allPML
         cat $pml >> $allPML
      fi
      echo "<$graph> <http://purl.org/dc/terms/source> <`basename $sourceFile`> ." >> $allPML
      echo                                                                         >> $allPML
   done
done
TEMP_pml="_"`basename $0``date +%s`_$$.tmp
if [ -d ../../doc ]; then
   for pml in `find ../../doc -name "*.pml.ttl"`; do
      base4rapper="${CSV2RDF4LOD_BASE_URI}/source/${sourceID}/doc_file/${datasetID}/`echo $pml | sed 's/......doc.//'`"
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
if [ ${CSV2RDF4LOD_PUBLISH_SUBSET_VOID:-"true"} == "true" ]; then
   echo $allVOID | tee -a $CSV2RDF4LOD_LOG
   rm $allVOID.TEMP 2> /dev/null
   for void in `find $destDir -name "*.void.ttl" 2> /dev/null`; do
      echo "  (including $void)" | tee -a $CSV2RDF4LOD_LOG
      cat $void >> $allVOID.TEMP
   done
   if [ `which rapper` ]; then
      rapper -i turtle -o turtle $allVOID.TEMP > $allVOID 2> /dev/null
      rm $allVOID.TEMP
   else
      mv $allVOID.TEMP $allVOID
   fi
else
   echo "$allVOID - skipping; set CSV2RDF4LOD_PUBLISH_SUBSET_VOID=true in source-me.sh to publish Meta." | tee -a $CSV2RDF4LOD_LOG
fi
numLogs=`find doc/logs -name 'csv2rdf4lod_log_*' | wc -l`
echo "# num logs: $numLogs" >> $allVOID
if [ ${#numLogs} ]; then
   echo "<$versionedDatasetURI> conversion:num_invocation_logs $numLogs ." >> $allVOID # TODO: how to make sure it is an integer?
fi
echo "  (including $allPML)" | tee -a $CSV2RDF4LOD_LOG
cat $allPML >> $allVOID
if [ -e $allVOID.DO_NOT_LIST ]; then
   mv $allVOID $allVOID.DO_NOT_LIST
fi

#
# sameas subset
#
if [ ${CSV2RDF4LOD_PUBLISH_SUBSET_SAMEAS:-"."} == "true" ]; then
   numSameAs=`grep owl:sameAs $allTTL | wc -l | awk '{print $1}'`
   if [ $numSameAs -gt 0 ]; then
      echo "$allSAMEAS ($numSameAs triples)" | tee -a $CSV2RDF4LOD_LOG
      if [ -e $allNT ];then
         # echo "   (cat'ing NT)" | tee -a $CSV2RDF4LOD_LOG
         cat $allNT | awk -f $CSV2RDF4LOD_HOME/bin/util/sameasInNT.awk > $allSAMEAS
      elif [ `find $publishDir -size +1900M -name $sourceID-$datasetID-$datasetVersion.ttl | wc -l` -gt 0 ]; then # +1900M, +10M for debugging
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
   if [ `find $publishDir -size +1900M -name $sourceID-$datasetID-$datasetVersion.ttl | wc -l` -gt 0 ]; then
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
# Tarball dump files
#
if [ ${CSV2RDF4LOD_PUBLISH_COMPRESS:-"."} == "true" ]; then
   for dumpFile in $filesToCompress ; do
      echo "$dumpFile.$zip (will delete uncompressed version at end of processing)" | tee -a $CSV2RDF4LOD_LOG
      dumpFileDir=`dirname $dumpFile`
      dumpFileBase=`basename $dumpFile`
      pushd $dumpFileDir 2>/dev/null
         tar czf $dumpFileBase.$zip $dumpFileBase  # TODO:notar

         # Don't use tar if there is only ever one file; use gzip instead:
         cat $dumpFileBase | gzip > $dumpFileBase.$zip # TODO:notar

         # WARNING: 
         # gunzip $dumpFileBase.gz # will remove .gz file
         # INSTEAD:
         # gunzip -c $dumpFileBase.gz > $dumpFileBase # Keep .gz and write to original.
         # FYI: 
         # bzip has a -k option to keep it around.
      popd
      # NOTE, pre-tarball will be deleted at end of this script.
   done
fi



#
# ln or cp from publish/ to www root.
#
# publish/cordad-at-rpi-edu-transfer-coefficents-2010-Jul-14.e1.ttl -->
# source/STATE_SINGLE_PW.CSV -> http://logd.tw.rpi.edu/source/data-gov/provenance_file/1008/version/2010-Jul-21/source/STATE_SINGLE_PW.CSV
#
# WWWROOT/source/cordad-at-rpi-edu/file/transfer-coefficents/version/2010-Jul-14/conversion/cordad-at-rpi-edu-transfer-coefficents-2010-Jul-14.e1

lnwwwrootSH="$publishDir/bin/ln-to-www-root-${sourceID}-${datasetID}-${datasetVersion}.sh"
echo $lnwwwrootSH | tee -a $CSV2RDF4LOD_LOG

echo "#!/bin/bash"                                              > $lnwwwrootSH
echo "#"                                                     >> $lnwwwrootSH
echo "# run from `pwd | sed 's/^.*source/source/'`/"         >> $lnwwwrootSH
echo "#"                                                     >> $lnwwwrootSH
echo "# CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT"    >> $lnwwwrootSH
echo "# was "                                                >> $lnwwwrootSH
echo "# ${CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT}" >> $lnwwwrootSH
echo "# when this script was created. "                      >> $lnwwwrootSH
echo ""                                                      >> $lnwwwrootSH
echo "CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT=\${CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT:?\"not set; source csv2rdf4lod/source-me.sh\"}" >> $lnwwwrootSH
echo ""                                                      >> $lnwwwrootSH

echo "##################################################"                                           >> $lnwwwrootSH
echo "# Link all original files from the provenance_file directory structure to the web directory." >> $lnwwwrootSH
echo "# (these are from source/)"                                                                   >> $lnwwwrootSH
for sourceFileProvenance in `ls source/*.pml.ttl`; do
   sourceFile=`echo $sourceFileProvenance | sed 's/.pml.ttl$//'` 
   echo "if [ -e \"$sourceFile\" ]; then "                                 >> $lnwwwrootSH
   echo "   wwwfile=\"\$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/$sourceID/provenance_file/$datasetID/version/$datasetVersion/$sourceFile\"" >> $lnwwwrootSH
   echo "   if [ -e \$wwwfile ]; then "                                    >> $lnwwwrootSH
   echo "      rm -f \$wwwfile"                                            >> $lnwwwrootSH
   echo "   else"                                                          >> $lnwwwrootSH
   echo "      mkdir -p \`dirname \$wwwfile\`"                             >> $lnwwwrootSH
   echo "   fi"                                                            >> $lnwwwrootSH
   echo "   echo \"  \$wwwfile\""                                          >> $lnwwwrootSH
   echo "   ln \"$sourceFile\" \"\$wwwfile\""                              >> $lnwwwrootSH
   echo "else"                                                             >> $lnwwwrootSH
   echo "   echo \"  $sourceFile omitted.\""                               >> $lnwwwrootSH
   echo "fi"                                                               >> $lnwwwrootSH
   echo ""                                                                 >> $lnwwwrootSH
   echo "if [ -e \"$sourceFileProvenance\" ]; then"                        >> $lnwwwrootSH
   echo "   wwwfile=\"\$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/$sourceID/provenance_file/$datasetID/version/$datasetVersion/$sourceFileProvenance\"" >> $lnwwwrootSH
   echo "   if [ -e \"\$wwwfile\" ]; then "                                >> $lnwwwrootSH
   echo "      rm -f \$wwwfile"                                            >> $lnwwwrootSH
   echo "   else"                                                          >> $lnwwwrootSH
   echo "      mkdir -p \`dirname \"\$wwwfile\"\`"                         >> $lnwwwrootSH
   echo "   fi"                                                            >> $lnwwwrootSH
   echo "   echo \"  \$wwwfile\""                                          >> $lnwwwrootSH
   echo "   ln \"$sourceFileProvenance\" \"\$wwwfile\""                    >> $lnwwwrootSH
   echo "else"                                                             >> $lnwwwrootSH
   echo "   echo \"  $sourceFileProvenance omitted.\""                     >> $lnwwwrootSH
   echo "fi"                                                               >> $lnwwwrootSH
   echo ""                                                                 >> $lnwwwrootSH
done

echo "##################################################"                                            >> $lnwwwrootSH
echo "# Link all INPUT CSV files from the provenance_file directory structure to the web directory." >> $lnwwwrootSH
echo "# (this could be from manual/ or source/"                                                      >> $lnwwwrootSH
for inputFile in `cat $destDir/_CSV2RDF4LOD_file_list.txt` # Sorry for the semi-hack. convert.sh builds this list b/c it knows what files were converted.
do
   echo "if [ -e \"$inputFile\" ]; then "                                  >> $lnwwwrootSH
   echo "   wwwfile=\"\$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/$sourceID/provenance_file/$datasetID/version/$datasetVersion/$inputFile\"" >> $lnwwwrootSH
   echo "   if [ -e \"\$wwwfile\" ]; then "                                >> $lnwwwrootSH
   echo "      rm -f \"\$wwwfile\""                                        >> $lnwwwrootSH
   echo "   else"                                                          >> $lnwwwrootSH
   echo "      mkdir -p \`dirname \"\$wwwfile\"\`"                         >> $lnwwwrootSH
   echo "   fi"                                                            >> $lnwwwrootSH
   echo "   echo \"  \$wwwfile\""                                          >> $lnwwwrootSH
   echo "   ln \"$inputFile\" \"\$wwwfile\""                               >> $lnwwwrootSH
   echo "else"                                                             >> $lnwwwrootSH
   echo "   echo \"  $inputFile omitted.\""                                >> $lnwwwrootSH
   echo "fi"                                                               >> $lnwwwrootSH
   echo ""                                                                 >> $lnwwwrootSH
done

TEMP_file_list="_"`basename $0``date +%s`_$$.tmp
# automatic/STATE_SINGLE_PW.CSV.raw.params.ttl -> http://logd.tw.rpi.edu/source/data-gov/provenance_file/1008/version/1st-anniversary/automatic/STATE_SINGLE_PW.CSV.raw.params.ttl

find automatic -name '*.params.ttl' | sed 's/^\.\///'  > $TEMP_file_list
find manual    -name '*.params.ttl' | sed 's/^\.\///' >> $TEMP_file_list
echo "##################################################"                  >> $lnwwwrootSH
echo "# Link all raw and enhancement PARAMETERS from the provenance_file file directory structure to the web directory." >> $lnwwwrootSH
echo "#"                                                                                                                 >> $lnwwwrootSH
for paramFile in `cat $TEMP_file_list`
do
   echo "if [ -e \"$paramFile\" ]; then "                                  >> $lnwwwrootSH
   echo "   wwwfile=\"\$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/$sourceID/provenance_file/$datasetID/version/$datasetVersion/$paramFile\"" >> $lnwwwrootSH
   echo "   if [ -e \"\$wwwfile\" ]; then "                                >> $lnwwwrootSH
   echo "      rm -f \"\$wwwfile\""                                        >> $lnwwwrootSH
   echo "   else"                                                          >> $lnwwwrootSH
   echo "      mkdir -p \`dirname \"\$wwwfile\"\`"                         >> $lnwwwrootSH
   echo "   fi"                                                            >> $lnwwwrootSH
   echo "   echo \"  \$wwwfile\""                                          >> $lnwwwrootSH
   echo "   ln \"$paramFile\" \"\$wwwfile\""                               >> $lnwwwrootSH
   echo "else"                                                             >> $lnwwwrootSH
   echo "   echo \"  $paramFile omitted.\""                                >> $lnwwwrootSH
   echo "fi"                                                               >> $lnwwwrootSH
   echo ""                                                                 >> $lnwwwrootSH
done

find $sourceDir -name '*.pml.ttl'                                     > $TEMP_file_list
find $sourceDir -name '*.[Zz][Ii][Pp].pml.ttl' | sed 's/.pml.ttl$//' >> $TEMP_file_list
echo "##################################################"                               >> $lnwwwrootSH
echo "# Link all PROVENANCE files that describe how the input CSV files were obtained." >> $lnwwwrootSH
echo "#"                                                                                >> $lnwwwrootSH
for pmlFile in `cat $TEMP_file_list`
do
   echo "if [ -e \"$pmlFile\" ]; then "                                    >> $lnwwwrootSH
   echo "   wwwfile=\"\$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/$sourceID/provenance_file/$datasetID/version/$datasetVersion/$pmlFile\"" >> $lnwwwrootSH
   echo "   if [ -e \"\$wwwfile\" ]; then"                                 >> $lnwwwrootSH
   echo "      rm -f \"\$wwwfile\""                                        >> $lnwwwrootSH
   echo "   else"                                                          >> $lnwwwrootSH
   echo "      mkdir -p \`dirname \"\$wwwfile\"\`"                         >> $lnwwwrootSH
   echo "   fi"                                                            >> $lnwwwrootSH
   echo "   echo \"  \$wwwfile\""                                          >> $lnwwwrootSH
   echo "   ln \"$pmlFile\" \"\$wwwfile\""                                 >> $lnwwwrootSH
   echo "else"                                                             >> $lnwwwrootSH
   echo "   echo \"  $pmlFile omitted.\""                                  >> $lnwwwrootSH
   echo "fi"                                                               >> $lnwwwrootSH
   echo ""                                                                 >> $lnwwwrootSH
done
rm $TEMP_file_list

echo "##################################################"                                                                >> $lnwwwrootSH
echo "# Link all bundled RDF output files from the source/.../provenance_file directory structure to the web directory." >> $lnwwwrootSH
echo "#"                                                                                                                 >> $lnwwwrootSH
# Version rollup of all layers (all serializations)
for serialization in ttl nt rdf
do
   echo "dump=$sourceID-$datasetID-$datasetVersion.$serialization"                                                                              >> $lnwwwrootSH
   echo "wwwfile=\$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/$sourceID/file/$datasetID/version/$datasetVersion/conversion/\$dump" >> $lnwwwrootSH
   echo "if [ -e $publishDir/\$dump.$zip ]; then "                          >> $lnwwwrootSH 
   echo "   if [ -e \$wwwfile.$zip ]; then"                                 >> $lnwwwrootSH 
   echo "      rm -f \$wwwfile.$zip"                                        >> $lnwwwrootSH 
   echo "   else"                                                          >> $lnwwwrootSH
   echo "      mkdir -p \`dirname \$wwwfile.$zip\`"                         >> $lnwwwrootSH 
   echo "   fi"                                                            >> $lnwwwrootSH
   echo "   echo \"  \$wwwfile.$zip\""                                      >> $lnwwwrootSH 
   echo "   ln $publishDir/\$dump.$zip \$wwwfile.$zip"                       >> $lnwwwrootSH 
   echo ""                                                                 >> $lnwwwrootSH
   echo "   if [ -e \$wwwfile ]; then"                                     >> $lnwwwrootSH
   echo "      echo \"  \$wwwfile\" - removing b/c $zip available"          >> $lnwwwrootSH 
   echo "      rm -f \$wwwfile # clean up to save space"                   >> $lnwwwrootSH
   echo "   fi"                                                            >> $lnwwwrootSH
   echo "elif [ -e $publishDir/\$dump ]; then "                            >> $lnwwwrootSH
   echo "   if [ -e \$wwwfile ]; then "                                    >> $lnwwwrootSH
   echo "      rm -f \$wwwfile"                                            >> $lnwwwrootSH
   echo "   else"                                                          >> $lnwwwrootSH
   echo "      mkdir -p \`dirname \$wwwfile\`"                             >> $lnwwwrootSH
   echo "   fi"                                                            >> $lnwwwrootSH
   echo "   echo \"  \$wwwfile\""                                          >> $lnwwwrootSH
   echo "   ln $publishDir/\$dump \$wwwfile"                               >> $lnwwwrootSH
   echo "else"                                                             >> $lnwwwrootSH
   echo "   echo \"  $conversionID $serialization omitted.\""              >> $lnwwwrootSH
   echo "fi"                                                               >> $lnwwwrootSH
   echo ""                                                                 >> $lnwwwrootSH
done
# Individual layers (all serializations)
for conversionID in $conversionIDs sameas void # <---- Add root-level subsets here.
do
   for serialization in ttl nt rdf
   do
      echo "dump=$sourceID-$datasetID-$datasetVersion.$conversionID.$serialization"                                                                >> $lnwwwrootSH
      echo "wwwfile=\$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/$sourceID/file/$datasetID/version/$datasetVersion/conversion/\$dump" >> $lnwwwrootSH
      echo "if [ -e $publishDir/\$dump.$zip ]; then "                          >> $lnwwwrootSH 
      echo "   if [ -e \$wwwfile.$zip ]; then"                                 >> $lnwwwrootSH 
      echo "      rm -f \$wwwfile.$zip"                                        >> $lnwwwrootSH 
      echo "   else"                                                          >> $lnwwwrootSH
      echo "      mkdir -p \`dirname \$wwwfile.$zip\`"                         >> $lnwwwrootSH 
      echo "   fi"                                                            >> $lnwwwrootSH
      echo "   echo \"  \$wwwfile.$zip\""                                      >> $lnwwwrootSH 
      echo "   ln $publishDir/\$dump.$zip \$wwwfile.$zip"                       >> $lnwwwrootSH 
      echo ""                                                                 >> $lnwwwrootSH
      echo "   if [ -e \$wwwfile ]; then"                                     >> $lnwwwrootSH
      echo "      echo \"  \$wwwfile\" - removing b/c $zip available"          >> $lnwwwrootSH 
      echo "      rm -f \$wwwfile # clean up to save space"                   >> $lnwwwrootSH
      echo "   fi"                                                            >> $lnwwwrootSH
      echo "elif [ -e $publishDir/\$dump ]; then "                            >> $lnwwwrootSH
      echo "   if [ -e \$wwwfile ]; then "                                    >> $lnwwwrootSH
      echo "      rm -f \$wwwfile"                                            >> $lnwwwrootSH
      echo "   else"                                                          >> $lnwwwrootSH
      echo "      mkdir -p \`dirname \$wwwfile\`"                             >> $lnwwwrootSH
      echo "   fi"                                                            >> $lnwwwrootSH
      echo "   echo \"  \$wwwfile\""                                          >> $lnwwwrootSH
      echo "   ln $publishDir/\$dump \$wwwfile"                               >> $lnwwwrootSH
      echo "else"                                                             >> $lnwwwrootSH
      echo "   echo \"  $conversionID $serialization omitted.\""              >> $lnwwwrootSH
      echo "fi"                                                               >> $lnwwwrootSH
      echo ""                                                                 >> $lnwwwrootSH
      for subset in sample                     # <---- Add layer-level subsets here.
      do # ln:
         #    publish/data-gov-1008-2010-Jul-21.raw.sample.ttl
         # to:
         #    /var/www/html/logd.tw.rpi.edu/source/data-gov/file/1008/version/2010-Jul-21/conversion/data-gov-1008-2010-Jul-21.raw.sample
         # to get:
         #    http://logd.tw.rpi.edu/source/data-gov/file/1008/version/2010-Jul-21/conversion/data-gov-1008-2010-Jul-21.raw.sample
         echo "dump=$sourceID-$datasetID-$datasetVersion.$conversionID.$subset.$serialization"                                                        >> $lnwwwrootSH
         echo "wwwfile=\$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/$sourceID/file/$datasetID/version/$datasetVersion/conversion/\$dump" >> $lnwwwrootSH
         echo "if [ -e $publishDir/\$dump ]; then "                           >> $lnwwwrootSH
         echo "   if [ -e \$wwwfile ]; then "                                 >> $lnwwwrootSH
         echo "      rm -f \$wwwfile"                                         >> $lnwwwrootSH
         echo "   else"                                                       >> $lnwwwrootSH
         echo "      mkdir -p \`dirname \$wwwfile\`"                          >> $lnwwwrootSH
         echo "   fi"                                                         >> $lnwwwrootSH
         echo "   echo \"  \$wwwfile\""                                       >> $lnwwwrootSH
         echo "   ln $publishDir/\$dump \$wwwfile"                            >> $lnwwwrootSH
         echo "else"                                                          >> $lnwwwrootSH
         echo "   echo \"  $conversionID $subset $serialization omitted.\""   >> $lnwwwrootSH
         echo "fi"                                                            >> $lnwwwrootSH
         echo ""                                                              >> $lnwwwrootSH
      done
   done
   echo ""                                                                    >> $lnwwwrootSH
done

chmod +x $lnwwwrootSH

if [ ${#CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT} -gt 0 ]; then
   echo "$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT - linking dump files into web root:" | tee -a $CSV2RDF4LOD_LOG
   # Execute the script we just generated.
   $lnwwwrootSH #2> /dev/null
fi


 
#
# TDB
#
local_tdb_dir=$publishDir/tdb
TDB_DIR=${CSV2RDF4LOD_PUBLISH_TDB_DIR:-$local_tdb_dir}
josekiConfigFile=$publishDir/bin/joseki-config-anterior-${sourceID}-${datasetID}-${datasetVersion}.ttl
if [ ! -e $josekiConfigFile ]; then
   cat $CSV2RDF4LOD_HOME/bin/dup/joseki-config-ANTERIOR.ttl | awk '{gsub("__TDB__DIRECTORY__",dir);print $0}' dir=`pwd`/$TDB_DIR > $josekiConfigFile
fi
loadtdbSH="$publishDir/bin/tdbloader-${sourceID}-${datasetID}-${datasetVersion}.sh"
echo "#!/bin/bash"                                                              > $loadtdbSH
echo ""                                                                                 >> $loadtdbSH
echo 'CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh"}' >> $loadtdbSH
echo ""                                                                                 >> $loadtdbSH
echo "delete=\"\""                                                                      >> $loadtdbSH
echo "if [ ! -e $allNT ]; then"                                                         >> $loadtdbSH
echo "  delete=\"$allNT\""                                                              >> $loadtdbSH
echo "  if [ -e $allNT.$zip ]; then"                                                     >> $loadtdbSH 
#echo "    tar xzf $allNT.$zip"                                                           >> $loadtdbSH # TODO:notar
echo "    gunzip -c $allNT.$zip > $allNT"                                                 >> $loadtdbSH # TODO:notar
echo "  elif [ -e $allTTL ]; then"                                                      >> $loadtdbSH
echo "    echo \"cHuNking $allTTL into $allNT; will delete when done lod-mat'ing\""     >> $loadtdbSH
echo "    \$CSV2RDF4LOD_HOME/bin/util/bigttl2nt.sh $allTTL > $allNT"                    >> $loadtdbSH
echo "  elif [ -e $allTTL.$zip ]; then"                                                  >> $loadtdbSH 
#echo "    tar xzf $allTTL.$zip"                                                          >> $loadtdbSH # TODO:notar
echo "    gunzip -c $allTTL.$zip > $allTTL"                                               >> $loadtdbSH # TODO:notar
echo "    echo \"cHuNking $allTTL into $allNT; will delete when done lod-mat'ing\""     >> $loadtdbSH
echo "    \$CSV2RDF4LOD_HOME/bin/util/bigttl2nt.sh $allTTL > $allNT"                    >> $loadtdbSH
echo "    rm $allTTL"                                                                   >> $loadtdbSH
echo "  else"                                                                           >> $loadtdbSH
echo "    echo $allNT, $allNT.$zip, $allTTL, or $allTTL.$zip needed to lod-materialize."  >> $loadtdbSH 
echo "    delete=\"\""                                                                  >> $loadtdbSH
echo "    exit 1"                                                                       >> $loadtdbSH
echo "  fi"                                                                             >> $loadtdbSH
echo "fi"                                                                               >> $loadtdbSH
echo ""                                                                                 >> $loadtdbSH
echo "mkdir $TDB_DIR                      &> /dev/null"                                 >> $loadtdbSH
echo "rm    $TDB_DIR/*.dat $TDB_DIR/*.idn &> /dev/null"                                 >> $loadtdbSH
echo ""                                                                                 >> $loadtdbSH
echo "echo `basename $allNT` into $TDB_DIR as $graph >> $publishDir/ng.info"            >> $loadtdbSH
echo "echo \`wc -l $allNT\` triples."                                                   >> $loadtdbSH
echo ""                                                                                 >> $loadtdbSH
echo "tdbloader --loc=$TDB_DIR --graph=\`cat $allNT.graph\` $allNT"                     >> $loadtdbSH
echo ""                                                                                 >> $loadtdbSH
echo "if [ \${#delete} -gt 0 ]; then"                                                   >> $loadtdbSH
echo "   rm \$delete"                                                                   >> $loadtdbSH
echo "fi"                                                                               >> $loadtdbSH
chmod +x                                                                                   $loadtdbSH

if [ ${CSV2RDF4LOD_PUBLISH_TDB:-"."} == "true" ]; then
   echo $TDB_DIR/ | tee -a $CSV2RDF4LOD_LOG
   $loadtdbSH
else
   echo "$TDB_DIR/     - skipping; set CSV2RDF4LOD_PUBLISH_TDB=true in source-me.sh to load conversions into $TDB_DIR/." | tee -a $CSV2RDF4LOD_LOG
   echo "`echo $TDB_DIR/ | sed 's/./ /g'`     - or run $loadtdbSH." | tee -a $CSV2RDF4LOD_LOG
   echo "`echo $TDB_DIR/ | sed 's/./ /g'`     - then run \$TDBROOT/bin/rdfserver with $josekiConfigFile." | tee -a $CSV2RDF4LOD_LOG
fi



#
# 4store
#
fourstoreSH=$publishDir/bin/4store-${sourceID}-${datasetID}-${datasetVersion}.sh
fourstoreKB=${CSV2RDF4LOD_PUBLISH_4STORE_KB:-'csv2rdf4lod'}
fourstoreKBDir=/var/lib/4store/$fourstoreKB
echo "#!/bin/bash"                                                                         > $fourstoreSH
echo "#"                                                                                >> $fourstoreSH
echo "# run $fourstoreSH"                                                               >> $fourstoreSH
echo "# from ${sourceID}/$datasetID/version/$datasetVersion/"                           >> $fourstoreSH
echo ""                                                                                 >> $fourstoreSH
echo 'CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh"}' >> $fourstoreSH 
echo ""                                                                                 >> $fourstoreSH
echo "allNT=$allNT"                                                                     >> $fourstoreSH
echo "if [ ! -e \$allNT ]; then"                                                        >> $fourstoreSH
echo "   echo \"run from ${sourceID}/$datasetID/version/$datasetVersion/\""             >> $fourstoreSH
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
vloadSH=$publishDir/bin/virtuoso-load-${sourceID}-${datasetID}-${datasetVersion}.sh
vloadvoidSH=$publishDir/bin/virtuoso-load-${sourceID}-${datasetID}-${datasetVersion}-void.sh
vdeleteSH=$publishDir/bin/virtuoso-delete-${sourceID}-${datasetID}-${datasetVersion}.sh
echo "#!/bin/bash"                                                                                 > $vloadSH
echo "#"                                                                                        >> $vloadSH
echo "# run $vloadSH"                                                                           >> $vloadSH
echo "# from `pwd | sed 's/^.*source/source/'`/"                                                >> $vloadSH
echo "#"                                                                                        >> $vloadSH
echo "# graph was $graph during conversion"                                                     >> $vloadSH
echo "#"                                                                                        >> $vloadSH
echo "#"                                                                                        >> $vloadSH
echo "#                         (unversioned) Dataset       # <---- Loads this with param --unversioned" >> $vloadSH
echo "#                                 |          \   "                                                 >> $vloadSH
echo "# Loads this by default -> VersionedDataset   meta    # <---- Loads this with param --meta"        >> $vloadSH
echo "#                                 |         "                                                      >> $vloadSH
echo "#                             DatasetLayer"                                                        >> $vloadSH
echo "#                               /    \ "                                                           >> $vloadSH
echo "# Never loads this ----> [table]   DatasetLayerSample # <---- Loads this with param --sample"      >> $vloadSH
echo ""                                                                                                  >> $vloadSH
echo 'CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh"}'         >> $vloadSH
echo 'CSV2RDF4LOD_BASE_URI=${CSV2RDF4LOD_BASE_URI:?"not set; source csv2rdf4lod/source-me.sh"}' >> $vloadSH
# deviates from orig design, but more concise by making (reasonable?) assumptions:
#echo "for serialization in nt ttl rdf"                                                         >> $vloadSH
#echo "do"                                                                                      >> $vloadSH
#echo "  dump=$allNT.\$serialization"                                                           >> $vloadSH
#echo "done"                                                                                    >> $vloadSH
echo ""                                                                                         >> $vloadSH
echo "allNT=$allNT # to cite graph"                                                             >> $vloadSH
echo "graph=\"\`cat \$allNT.graph\`\""                                                          >> $vloadSH
echo "if [ \"\$1\" == \"--sample\" ]; then"                                                     >> $vloadSH
for conversionStep in $conversionSteps # <---- Add root-level subsets here.
do
   echo "   conversionStep=\"$conversionStep\""                                                 >> $vloadSH # .-todo
   echo "   sampleTTL=$SDV.`echo $conversionStep | sed 's/^.*\//e/'`.sample.ttl"                >> $vloadSH # .-todo
   echo "   sampleGraph=\"\$graph/conversion/\$conversionStep/subset/sample\""                  >> $vloadSH
   echo "   sudo /opt/virtuoso/scripts/vload ttl \$sampleTTL \$sampleGraph"                     >> $vloadSH
   echo ""                                                                                      >> $vloadSH
done
echo "   exit 1"                                                                                >> $vloadSH
echo "elif [ \"\${1:-'.'}\" == \"--meta\" -a -e $allVOID ]; then"                               >> $vloadSH
echo "   graph=\"\${CSV2RDF4LOD_BASE_URI_OVERRIDE:-\$CSV2RDF4LOD_BASE_URI}\"/vocab/Dataset"     >> $vloadSH
echo "   echo sudo /opt/virtuoso/scripts/vload ttl $allVOID \$graph"                            >> $vloadSH
echo "   sudo /opt/virtuoso/scripts/vload ttl $allVOID \$graph"                                 >> $vloadSH
echo "   exit 1"                                                                                >> $vloadSH
echo "fi"                                                                                       >> $vloadSH
echo ""                                                                                         >> $vloadSH
echo "# Modify the graph before continuing to load everything"                                  >> $vloadSH
echo "if [ \${1:-'.'} == \"--unversioned\" ]; then"                                             >> $vloadSH
echo "   # strip off version"                                                                   >> $vloadSH
echo "   graph=\"\`echo \$graph\ | perl -pe 's|/version/[^/]*$||'\`\""                          >> $vloadSH
echo "   echo populating unversioned named graph \(\$graph\) instead of versioned named graph." >> $vloadSH
echo "elif [ \$# -gt 0 ]; then"                                                                 >> $vloadSH
echo "   echo param not recognized: \$1"                                                        >> $vloadSH
echo "   echo usage: \`basename \$0\` with no parameters loads versioned dataset"               >> $vloadSH
echo "   echo usage: \`basename \$0\` --{unversioned,meta,sample}"                              >> $vloadSH
echo "   exit 1"                                                                                >> $vloadSH
echo "fi"                                                                                       >> $vloadSH
echo ""                                                                                         >> $vloadSH
echo ""                                                                                         >> $vloadSH
# http://logd.tw.rpi.edu/source/nitrd-gov/dataset/DDD/version/2011-Jan-27
# http://logd.tw.rpi.edu/source/nitrd-gov/file/DDD/version/2011-Jan-27/conversion/nitrd-gov-DDD-2011-Jan-27.ttl.gz
echo "dump=$allNT"                                                                              >> $vloadSH
echo "TEMP=\"_\"\`basename \$dump\`_tmp"                                                        >> $vloadSH
echo "url=$http_allNT"                                                                          >> $vloadSH
echo "if [ -e \$dump ]; then"                                                                   >> $vloadSH
echo "   #\${CSV2RDF4LOD_HOME}/bin/util/pvload.sh \$url -ng \$graph"                            >> $vloadSH
echo "   sudo /opt/virtuoso/scripts/vload nt \$dump \$graph"                                    >> $vloadSH
echo "   exit 1"                                                                                >> $vloadSH
echo "elif [ -e \$dump.$zip ]; then"                                                            >> $vloadSH 
echo "   #\${CSV2RDF4LOD_HOME}/bin/util/pvload.sh \$url.$zip -ng \$graph"                       >> $vloadSH
echo "   gunzip -c \$dump.$zip > \$TEMP"                                                        >> $vloadSH
echo "   sudo /opt/virtuoso/scripts/vload nt \$TEMP \$graph"                                    >> $vloadSH
echo "   rm \$TEMP"                                                                             >> $vloadSH
echo "   exit 1"                                                                                >> $vloadSH
echo "fi"                                                                                       >> $vloadSH
echo ""                                                                                         >> $vloadSH
echo "dump=$allTTL"                                                                             >> $vloadSH
echo "url=$http_allTTL"                                                                         >> $vloadSH
echo "if [ -e \$dump ]; then"                                                                   >> $vloadSH
echo "   #echo \${CSV2RDF4LOD_HOME}/bin/util/pvload.sh \$url -ng \$graph"                       >> $vloadSH
echo "   #\${CSV2RDF4LOD_HOME}/bin/util/pvload.sh \$url -ng \$graph"                            >> $vloadSH
echo "   echo sudo /opt/virtuoso/scripts/vload ttl \$dump \$graph"                              >> $vloadSH
echo "   sudo /opt/virtuoso/scripts/vload ttl \$dump \$graph"                                   >> $vloadSH
echo "   exit 1"                                                                                >> $vloadSH
echo "elif [ -e \$dump.$zip ]; then"                                                            >> $vloadSH 
echo "   #\${CSV2RDF4LOD_HOME}/bin/util/pvload.sh \$url.$zip -ng \$graph"                       >> $vloadSH
echo "   gunzip -c \$dump.$zip > \$TEMP"                                                        >> $vloadSH
echo "   echo sudo /opt/virtuoso/scripts/vload ttl \$TEMP \$graph"                              >> $vloadSH
echo "   sudo /opt/virtuoso/scripts/vload ttl \$TEMP \$graph"                                   >> $vloadSH
echo "   rm \$TEMP"                                                                             >> $vloadSH
echo "   exit 1"                                                                                >> $vloadSH
echo "fi"                                                                                       >> $vloadSH
echo ""                                                                                         >> $vloadSH
echo "dump=$allRDFXML"                                                                          >> $vloadSH
echo "url=$http_allRDFXML"                                                                      >> $vloadSH
echo "if [ -e \$dump ]; then"                                                                   >> $vloadSH
echo "   #\${CSV2RDF4LOD_HOME}/bin/util/pvload.sh \$url -ng \$graph"                            >> $vloadSH
echo "   sudo /opt/virtuoso/scripts/vload rdf \$dump \$graph"                                   >> $vloadSH
echo "   exit 1"                                                                                >> $vloadSH
echo "elif [ -e \$dump.$zip ]; then"                                                            >> $vloadSH 
echo "   #\${CSV2RDF4LOD_HOME}/bin/util/pvload.sh \$url.$zip -ng \$graph"                       >> $vloadSH
echo "   gunzip -c \$dump.$zip > \$TEMP"                                                        >> $vloadSH
echo "   sudo /opt/virtuoso/scripts/vload rdf \$TEMP \$graph"                                   >> $vloadSH
echo "   rm \$TEMP"                                                                             >> $vloadSH
echo "   exit 1"                                                                                >> $vloadSH
echo "fi"                                                                                       >> $vloadSH
chmod +x $vloadSH
cat $vloadSH | sed 's/vload [^ ]* [^^ ]* /vdelete /' | grep -v "tar xzf" | grep -v "unzip" | grep -v "rm " > $vdeleteSH # TODO:notar
chmod +x $vdeleteSH
if [ ${CSV2RDF4LOD_PUBLISH_VIRTUOSO:-"."} == "true" ]; then
   $vdeleteSH
   $vloadSH
elif [ ${CSV2RDF4LOD_PUBLISH_SUBSET_SAMPLES:-"."} == "true" ]; then # TODO: cross of publish media and subsets to publish. This violates it.
   $vdeleteSH --sample 
   $vloadSH   --sample 
fi


#
# LOD-materialize
#
local_materialization_dir=$publishDir/lod-mat

lodmat='$CSV2RDF4LOD_HOME/bin/lod-materialize/${c_lod_mat}lod-materialize.pl'
prefixDefs=`$CSV2RDF4LOD_HOME/bin/dup/prefixes2flags.sh $allTTL`        
mappingPatterns='--uripattern="/source/([^/]+)/dataset/(.*)" --filepattern="/source/\\1/file/\\2"'
mappingPatternsVocab='--uripattern="/source/([^/]+)/vocab/(.*)" --filepattern="/source/\\1/vocab_file/\\2"'
mappingPatternsProvenance='--uripattern="/source/([^/]+)/provenance/(.*)" --filepattern="/source/\\1/provenance_file/\\2"'
CSV2RDF4LOD_BASE_URI=${CSV2RDF4LOD_BASE_URI:?"not set; source csv2rdf4lod/source-me.sh"}
MATERIALIZATION_DIR=${CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT:-$local_materialization_dir}

lodmatSH=$publishDir/bin/lod-materialize-${sourceID}-${datasetID}-${datasetVersion}.sh
echo "#!/bin/bash"                                                                                              > $lodmatSH
echo "#"                                                                                                       >> $lodmatSH
echo "# run $destDir/lod-materialize-${sourceID}-${datasetID}-${datasetVersion}.sh"                            >> $lodmatSH
echo "# from ${sourceID}/$datasetID/version/$datasetVersion/"                                                  >> $lodmatSH
echo ""                                                                                                        >> $lodmatSH
echo 'CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh"}'                        >> $lodmatSH
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
echo perl $lodmat -i=ntriples $prefixDefs $mappingPatterns           \$freqParams --directoryindex=CSV2RDF4LODINDEX $allNT ${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI} $MATERIALIZATION_DIR >> $lodmatSH
echo ""                                                                                                        >> $lodmatSH
echo perl $lodmat -i=ntriples $prefixDefs $mappingPatternsVocab      \$freqParams --directoryindex=CSV2RDF4LODINDEX $allNT ${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI} $MATERIALIZATION_DIR >> $lodmatSH
echo ""                                                                                                        >> $lodmatSH
echo perl $lodmat -i=ntriples $prefixDefs $mappingPatternsProvenance \$freqParams --directoryindex=CSV2RDF4LODINDEX $allNT ${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI} $MATERIALIZATION_DIR >> $lodmatSH
echo ""                                                                                                        >> $lodmatSH
echo "if [ \${#delete} -gt 0 ]; then"                                                                          >> $lodmatSH
echo "   rm \$delete"                                                                                          >> $lodmatSH
echo "fi"                                                                                                      >> $lodmatSH
chmod +x                                                                                                          $lodmatSH

lodmatvoidSH=$publishDir/bin/lod-materialize-${sourceID}-${datasetID}-${datasetVersion}-void.sh
echo "#!/bin/bash"                                                                                                > $lodmatvoidSH
echo "#"                                                                                                       >> $lodmatvoidSH
echo "# run $destDir/lod-materialize-${sourceID}-${datasetID}-${datasetVersion}.sh"                            >> $lodmatvoidSH
echo "# from ${sourceID}/$datasetID/version/$datasetVersion/"                                                  >> $lodmatvoidSH
echo ""                                                                                                        >> $lodmatvoidSH
echo 'CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh"}'                        >> $lodmatvoidSH
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
echo perl $lodmat -i=ntriples $prefixDefs $mappingPatterns           \$freqParams --directoryindex=CSV2RDF4LODINDEX $allVOIDNT ${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI} $MATERIALIZATION_DIR >> $lodmatvoidSH
echo ""                                                                                                        >> $lodmatvoidSH
echo perl $lodmat -i=ntriples $prefixDefs $mappingPatternsVocab      \$freqParams --directoryindex=CSV2RDF4LODINDEX $allVOIDNT ${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI} $MATERIALIZATION_DIR >> $lodmatvoidSH
echo ""                                                                                                        >> $lodmatvoidSH
echo perl $lodmat -i=ntriples $prefixDefs $mappingPatternsProvenance \$freqParams --directoryindex=CSV2RDF4LODINDEX $allVOIDNT ${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI} $MATERIALIZATION_DIR >> $lodmatvoidSH
echo ""                                                                                                        >> $lodmatvoidSH
echo "if [ \$delete == \"true\" ]; then"                                                                       >> $lodmatvoidSH
echo "   rm $allVOIDNT"                                                                                        >> $lodmatvoidSH
echo "fi"                                                                                                      >> $lodmatvoidSH
chmod +x                                                                                                          $lodmatvoidSH

lodmatapacheSH=$publishDir/bin/lod-materialize-apache-${sourceID}-${datasetID}-${datasetVersion}.sh
echo "#!/bin/bash"                                                                                                > $lodmatapacheSH
echo "#"                                                                                                       >> $lodmatapacheSH
echo "# run $destDir/lod-materialize-apache-${sourceID}-${datasetID}-${datasetVersion}.sh"                     >> $lodmatapacheSH
echo "# from ${sourceID}/$datasetID/version/$datasetVersion/"                                                  >> $lodmatapacheSH
echo ""                                                                                                        >> $lodmatapacheSH
echo "                # The newer C version of lod-mat is faster."                                             >> $lodmatapacheSH
echo "c_lod_mat=\"c/\"  # It is in the directory called 'c' within the lod-materialization project."           >> $lodmatapacheSH
echo "                # The C version silently passes some parameters that the native perl version used."      >> $lodmatapacheSH
echo "if [ ! -e \$CSV2RDF4LOD_HOME/bin/lod-materialize/c/lod-materialize ]; then"                              >> $lodmatapacheSH
echo "   c_lod_mat=\"\" # If it is not available, use the older perl version."                                 >> $lodmatapacheSH
echo "   echo \"WARNING: REALLY SLOW lod-materialization going on. Run make in \$CSV2RDF4LOD_HOME/bin/lod-materialize/c/\"" >> $lodmatapacheSH
echo "fi"                                                                                                      >> $lodmatapacheSH
echo ""                                                                                                        >> $lodmatapacheSH
echo perl $lodmat -i=ntriples $mappingPatterns      --apache $allNT ${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI} $MATERIALIZATION_DIR >> $lodmatapacheSH
echo perl $lodmat -i=ntriples $mappingPatternsVocab --apache $allNT ${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI} $MATERIALIZATION_DIR >> $lodmatapacheSH
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
   $lodmatSH
else
   echo "$MATERIALIZATION_DIR/ - skipping; set CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION=true in source-me.sh to load conversions into $MATERIALIZATION_DIR/," | tee -a $CSV2RDF4LOD_LOG
   echo "`echo $MATERIALIZATION_DIR/ | sed 's/./ /g'` - or run $destDir/lod-materialize-${sourceID}-${datasetID}-${datasetVersion}.sh." | tee -a $CSV2RDF4LOD_LOG
fi

if [ -e $allTTL -a ${CSV2RDF4LOD_PUBLISH_TTL:-"."} != "true" ]; then
   rm $allTTL
fi
if [ -e $allNT -a ${CSV2RDF4LOD_PUBLISH_NT:-"."} != "true" ]; then
   rm $allNT
fi






#
# Removed the pre-tarball dump files
#
if [ ${CSV2RDF4LOD_PUBLISH_COMPRESS:-"."} == "true" ]; then
   for dumpFile in $filesToCompress ; do
      # NOTE, tarball was created earlier in this script.
      if [ -e $dumpFile.$zip ]; then
         echo "  $dumpFile - removed b/c \$CSV2RDF4LOD_PUBLISH_COMPRESS=\"true\"" | tee -a $CSV2RDF4LOD_LOG
         rm $dumpFile
      fi
   done
fi







CSV2RDF4LOD_LOG=""
echo convert-aggregate.sh done | tee -a $CSV2RDF4LOD_LOG
echo "===========================================================================================" | tee -a $CSV2RDF4LOD_LOG
#chmod -w $CSV2RDF4LOD_LOG
