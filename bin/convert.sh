# source/SSS/DDD/version/VVV/convert-DDD.sh checks that CSV2RDF4LOD_HOME is set and exits if not.

# 
# Parameters (environment variables that should be set):
#
# @param surrogate      - the base URI.
# @param sourceID       - a string identifier for the source; established by curator convention.
# @param datasetID      - a string identifier for the dataset; established by curator convention.
# @param datasetVersion - a string identifier for the dataset version; established by curator convention.
# @param eID            - a string identifier for the conversion layer.
#
# @param datafile       - the local filename of the csv.
#

eParamsDir=manual # Enhancement parameter templates are placed in manual/ b/c a human will be modifying them.

extensionlessFilename=`echo $datafile | sed 's/^\([^\.]*\)\..*$/\1/'`

graph=${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$surrogate}/source/$sourceID/dataset/$datasetID/version/$datasetVersion
echo "--------------------------------------------------------------------------------"
echo "$datafile"
#echo Dataset URI $graph | tee -a $CSV2RDF4LOD_LOG

versionDir=`pwd`

#
#
# Set up the directory structure.
#
#

if [ ! -e source ]; then
   mkdir source
fi
if [ ! -e doc/logs ]; then
   mkdir -p doc/logs
fi
if [ ! -e manual ]; then # TODO: manual should be $eParamsDir
   mkdir manual # TODO: manual should be $eParamsDir
fi
if [ ! -e automatic ]; then
   mkdir automatic
fi
if [ ! -e publish/bin ]; then
   mkdir -p publish/bin
fi

# People like to kill sample named graph loading, leaving _pvload* hanging around.

rm _pvload.sh*.ttl _pvload.sh*.nt &> /dev/null

#
#
# Decide if raw or an enhancement conversion should be performed.
#
#

runRaw=yes
runEnhancement=no
if [ -e "$destDir/$datafile.raw.ttl" -o ${CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER:-"."} == "true" ]; then
   # Raw layer has already been produced OR we just don't want the Raw layer (because it is generally less useful).
   runRaw=no
   runEnhancement=yes
   eID=${eID:?"enhancement identifier not set; re-produce convert*.sh using cr-create-convert-sh.sh, pass it an eID, or add the line: eID=\"1\""}
   CSV2RDF4LOD_LOG="doc/logs/csv2rdf4lod_log_e${eID}_`date +%Y-%m-%dT%H_%M_%S`.txt"
else
   CSV2RDF4LOD_LOG="doc/logs/csv2rdf4lod_log_raw_`date +%Y-%m-%dT%H_%M_%S`.txt"
fi

if [ ! -e "$eParamsDir/$datafile.e$eID.params.ttl" ]; then
   runEnhancement=no
fi
if [ "$destDir/$datafile.e$eID.ttl" -nt $CSV2RDF4LOD_HOME/bin/dup/csv2rdf4lod.jar ]; then                                       # Converter jar
   if [ "$destDir/$datafile.e$eID.ttl" -nt "$eParamsDir/$datafile.e$eID.params.ttl" ]; then                                     # File, version specific params
      echo "E$eID output newer than converter and params. skipping" | tee -a $CSV2RDF4LOD_LOG
      runEnhancement=no
   fi
fi

$CSV2RDF4LOD_HOME/bin/util/dateInXSDDateTime.sh > $CSV2RDF4LOD_LOG

#
#
# Prepare for creating the enhancement parameters (manual/$datafile.e1.params.ttl)
#
#

#head -${header:-1} $data | tail -1 | awk -v conversionID="$eID" $paramsParams -f $h2p > $eParamsDir/$datafile.e$eID.params.ttl
#echo "CELL DELMITER: $cellDelimiter"
csvHeadersClasspath="edu.rpi.tw.data.csv.impl.CSVHeaders"                                                        # is in csv2rdf4lod.jar
h2p=$CSV2RDF4LOD_HOME/bin/util/header2params2.awk                                                                # process by line, not parse the first
paramsParams="-v surrogate=$surrogate -v sourceID=$sourceID -v datasetID=$datasetID"                             # NOTE: no variable values 
paramsParams="$paramsParams -v cellDelimiter=$cellDelimiter"                                                     # ONE character.
paramsParams="$paramsParams -v header=$header -v dataStart=$dataStart -v onlyIfCol=$onlyIfCol"                   # can be strings or have spaces. 
paramsParams="$paramsParams -v repeatAboveIfEmptyCol=$repeatAboveIfEmptyCol -v interpretAsNull=$interpretAsNull" # awk "bails out at line 1".
paramsParams="$paramsParams -v dataEnd=$dataEnd"
paramsParams="$paramsParams -v subjectDiscriminator=$subjectDiscriminator -v datasetVersion=$datasetVersion"
paramsParams="$paramsParams -v whoami=`whoami` -v machine_uri=$CSV2RDF4LOD_CONVERT_MACHINE_URI -v person_uri=$CSV2RDF4LOD_CONVERT_PERSON_URI"
paramsParams="$paramsParams -v nowXSD=`$CSV2RDF4LOD_HOME/bin/util/dateInXSDDateTime.sh`"
if [ ${CSV2RDF4LOD_CONVERT_DEBUG_LEVEL:-"."} == "finest" ]; then
   echo "FINEST: h2p params: $paramsParams" | tee -a $CSV2RDF4LOD_LOG
fi

csvHeadersParams="--comment-character $commentCharacter --header-line ${header:-'1'} --delimiter $cellDelimiter" # <-- TODO: causes data file to be named / 
csvHeadersParams="--header-line ${header:-'1'} --delimiter $cellDelimiter"

#
#
# Check to see if enhancement parameters match template generated.
# (IF same number of "todo:Literal"s, THEN they are the same.)
#
#

if [ $runEnhancement == "yes" ]; then 
   TMP_ePARAMS="_"`basename $0``date +%s`_$$.tmp

   # NOTE: command done below, too.
   java $csvHeadersClasspath $data $csvHeadersParams | awk -v conversionID="$eID" $paramsParams -f $h2p > $TMP_ePARAMS

   numTemplateTODOs=` grep "todo:Literal" $TMP_ePARAMS                           | wc -l` 
   numRemainingTODOs=`grep "todo:Literal" $eParamsDir/$datafile.e$eID.params.ttl | wc -l` 
   rm $TMP_ePARAMS
   if [ $numRemainingTODOs -eq $numTemplateTODOs -a ! -e ../e$eID.params.ttl -a ! -e ../$datafile.e$eID.params.ttl ]; then
      # local enhancement parameters are no different from when this script generated them
      # there is no file-version global enhancement parameters
      # there is no version global enhancement parameters
      echo "   E$eID conversion parameters file has same number of \"todo:Literal\"s as template originally generated."                  | tee -a $CSV2RDF4LOD_LOG
      echo "    - Skipping E$eID conversion b/c enhancement parameters appear very similar to the default template."                     | tee -a $CSV2RDF4LOD_LOG
      echo "    - Replace todo:Literal in E$eID conversion parameters with rdfs:Literal or rdfs:Resource to enable enhanced conversion." | tee -a $CSV2RDF4LOD_LOG
      exit 1 # Added by user request: quit asap and do not do anything.
      runEnhancement="no"
   fi
   # TODO: check to see if enhancement parameters match previous enhancement parameters (e2 same as e1). 
fi

#
#
# Prepare to run the conversion.
#
#

if [ -e $CSV2RDF4LOD_HOME/bin/logging/$CSV2RDF4LOD_CONVERT_DEBUG_LEVEL.properties ]; then
   javaprops="-Djava.util.logging.config.file=$CSV2RDF4LOD_HOME/bin/logging/$CSV2RDF4LOD_CONVERT_DEBUG_LEVEL.properties"
else
   javaprops=""
fi
csv2rdf=${CSV2RDF4LOD_CONVERTER:-"java $javaprops -Xmx3060m edu.rpi.tw.data.csv.CSVtoRDF"}

if [ $runRaw == "yes" ]; then 
   #flip -u $data # Mac-only solution
   echo "`basename $0` converting newlines of $data" | tee -a $CSV2RDF4LOD_LOG
   perl -pi -e 's/\r\n/\n/' $data
   perl -pi -e 's/\r/\n/g'  $data
fi


#
#
# Handle interpretation parameters: create raw, check for global, create template if not present.
#
#

# Regenerate raw parameters EACH TIME.
java $csvHeadersClasspath $data $csvHeadersParams | awk $paramsParams -f $h2p > $destDir/$datafile.raw.params.ttl

# Generate the enhancement parameters only when not present.
global=""
if [ -e ../../../e$eID.params.ttl ]; then # There are enhancement parameters that apply to ALL files of ALL versions of ALL datasets.
   global="global."
   if [ ! -e manual/$datafile.e$eID.params.ttl ]; then # No enhancement parameters have been specified for THIS file. # TODO: manual should be $eParamsDir
      # Link to dataset-INDEPENDENT file-INDEPENDENT global params file (instead of making a new one)
      echo "NOTE: global parameters found; linking manual/$datafile.e$eID.params.ttl to ../$datafile.e$eID.params.ttl -- editing it edits the global parameters." | tee -a $CSV2RDF4LOD_LOG
      ln ../../../e$eID.params.ttl manual/$datafile.e$eID.params.ttl # TODO: manual should be $eParamsDir
   fi
   if [ ! -e $eParamsDir/$datafile.global.e$eID.params.ttl -o ../../../e$eID.params.ttl -nt $eParamsDir/$datafile.global.e$eID.params.ttl ]; then
      # The file-specific copy doesn't exist or is older than the file-INDEPENDENT parameters.
      echo "constructing $eParamsDir/$datafile.${global}e$eID.params.ttl from dataset-independent file-independent global params ../../../e$eID.params.ttl" | tee -a $CSV2RDF4LOD_LOG
      chmod +w $eParamsDir/$datafile.global.e$eID.params.ttl 2> /dev/null
      echo "#"                                                                                        > $eParamsDir/$datafile.global.e$eID.params.ttl
      echo "#"                                                                                       >> $eParamsDir/$datafile.global.e$eID.params.ttl
      echo "#"                                                                                       >> $eParamsDir/$datafile.global.e$eID.params.ttl
      echo "#"                                                                                       >> $eParamsDir/$datafile.global.e$eID.params.ttl
      echo "# WARNING: do not edit these; they are automatically generated from ../e$eID.params.ttl" >> $eParamsDir/$datafile.global.e$eID.params.ttl
      echo "#"                                                                                       >> $eParamsDir/$datafile.global.e$eID.params.ttl
      echo "#"                                                                                       >> $eParamsDir/$datafile.global.e$eID.params.ttl
      echo "#"                                                                                       >> $eParamsDir/$datafile.global.e$eID.params.ttl
      echo "#"                                                                                       >> $eParamsDir/$datafile.global.e$eID.params.ttl
      cat ../../../e$eID.params.ttl | awk -f $CSV2RDF4LOD_HOME/bin/util/update-e-params-subject-discrim.awk baseURI="$CSV2RDF4LOD_BASE_URI" sourceID=$sourceID dataset_identifier=$datasetID datasetVersion=$datasetVersion layerID="$eID" subjectDiscriminator=$subjectDiscriminator >> $eParamsDir/$datafile.global.e$eID.params.ttl 
      chmod -w $eParamsDir/$datafile.global.e$eID.params.ttl
      runEnhancement="yes"
   fi
elif [ -e ../e$eID.params.ttl ]; then # There are enhancement parameters that apply to ALL files of ALL versions.
   global="global."
   if [ ! -e manual/$datafile.e$eID.params.ttl ]; then # No enhancement parameters have been specified for THIS file. # TODO: manual should be $eParamsDir
      # Link to file-INDEPENDENT global params file (instead of making a new one)
      echo "NOTE: global parameters found; linking manual/$datafile.e$eID.params.ttl to ../$datafile.e$eID.params.ttl -- editing it edits the global parameters." | tee -a $CSV2RDF4LOD_LOG
      ln ../e$eID.params.ttl manual/$datafile.e$eID.params.ttl # TODO: manual should be $eParamsDir
   fi
   if [ ! -e $eParamsDir/$datafile.global.e$eID.params.ttl -o ../e$eID.params.ttl -nt $eParamsDir/$datafile.global.e$eID.params.ttl ]; then
      # The file-specific copy doesn't exist or is older than the file-INDEPENDENT parameters.
      echo "constructing $eParamsDir/$datafile.${global}e$eID.params.ttl from file-independent global params ../e$eID.params.ttl" | tee -a $CSV2RDF4LOD_LOG
      chmod +w $eParamsDir/$datafile.global.e$eID.params.ttl 2> /dev/null
      echo "#"                                                                                        > $eParamsDir/$datafile.global.e$eID.params.ttl
      echo "#"                                                                                       >> $eParamsDir/$datafile.global.e$eID.params.ttl
      echo "#"                                                                                       >> $eParamsDir/$datafile.global.e$eID.params.ttl
      echo "#"                                                                                       >> $eParamsDir/$datafile.global.e$eID.params.ttl
      echo "# WARNING: do not edit these; they are automatically generated from ../e$eID.params.ttl" >> $eParamsDir/$datafile.global.e$eID.params.ttl
      echo "#"                                                                                       >> $eParamsDir/$datafile.global.e$eID.params.ttl
      echo "#"                                                                                       >> $eParamsDir/$datafile.global.e$eID.params.ttl
      echo "#"                                                                                       >> $eParamsDir/$datafile.global.e$eID.params.ttl
      echo "#"                                                                                       >> $eParamsDir/$datafile.global.e$eID.params.ttl
      cat ../e$eID.params.ttl | awk -f $CSV2RDF4LOD_HOME/bin/util/update-e-params-subject-discrim.awk baseURI="$CSV2RDF4LOD_BASE_URI" sourceID=$sourceID dataset_identifier=$datasetID datasetVersion=$datasetVersion layerID="$eID" subjectDiscriminator=$subjectDiscriminator >> $eParamsDir/$datafile.global.e$eID.params.ttl 
      chmod -w $eParamsDir/$datafile.global.e$eID.params.ttl
      runEnhancement="yes"
   fi
elif [ -e ../$datafile.e$eID.params.ttl ]; then # There are enhancement parameters that apply to ALL versions of THIS file.
   global="global."
   if [ ! -e manual/$datafile.e$eID.params.ttl ]; then # TODO: manual should be $eParamsDir
      # Link to file-SPECIFIC global params file (instead of making a new one)
      echo "NOTE: global parameters found; linking manual/$datafile.e$eID.params.ttl to ../$datafile.e$eID.params.ttl -- editing it edits the global parameters." | tee -a $CSV2RDF4LOD_LOG
      ln ../$datafile.e$eID.params.ttl manual/$datafile.e$eID.params.ttl # TODO: manual should be $eParamsDir
   fi
   if [ ! -e $eParamsDir/$datafile.global.e$eID.params.ttl -o ../$datafile.e$eID.params.ttl -nt $eParamsDir/$datafile.global.e$eID.params.ttl ]; then
      # The file-specific copy doesn't exist or is older than the file-SPECIFIC parameters.
      echo "constructing $eParamsDir/$datafile.global.e$eID.params.ttl from file-dependent global params ../$datafile.e$eID.params.ttl" | tee -a $CSV2RDF4LOD_LOG
      chmod +w $eParamsDir/$datafile.global.e$eID.params.ttl 2> /dev/null
      echo "#"                                                                                                  > $eParamsDir/$datafile.global.e$eID.params.ttl
      echo "#"                                                                                                 >> $eParamsDir/$datafile.global.e$eID.params.ttl
      echo "#"                                                                                                 >> $eParamsDir/$datafile.global.e$eID.params.ttl
      echo "#"                                                                                                 >> $eParamsDir/$datafile.global.e$eID.params.ttl
      echo "# WARNING: do not edit these; they are automatically generated from ../$datafile.e$eID.params.ttl" >> $eParamsDir/$datafile.global.e$eID.params.ttl
      echo "#"                                                                                                 >> $eParamsDir/$datafile.global.e$eID.params.ttl
      echo "#"                                                                                                 >> $eParamsDir/$datafile.global.e$eID.params.ttl
      echo "#"                                                                                                 >> $eParamsDir/$datafile.global.e$eID.params.ttl
      echo "#"                                                                                                 >> $eParamsDir/$datafile.global.e$eID.params.ttl
      cat ../$datafile.e$eID.params.ttl | awk -f $CSV2RDF4LOD_HOME/bin/util/update-e-params-subject-discrim.awk baseURI="$CSV2RDF4LOD_BASE_URI" sourceID=$sourceID dataset_identifier=$datasetID datasetVersion=$datasetVersion layerID="$eID" subjectDiscriminator=$subjectDiscriminator >> $eParamsDir/$datafile.global.e$eID.params.ttl 
      chmod -w $eParamsDir/$datafile.global.e$eID.params.ttl
      runEnhancement="yes"
   fi
elif [ ! -e $eParamsDir/$datafile.e$eID.params.ttl ]; then # No global enhancement parameters present (neither file-independent nor file-specific)
   # Create local file-specific enhancement parameters file.
   let prevEID=$eID-1
   if [ -e $eParamsDir/$datafile.e$prevEID.params.ttl ]; then 
      # Use the PREVIOUS enhancement parameters as a starting point.
      echo "E$eID enhancement parameters missing; creating template from E$prevEID enhancement parameters. Edit $eParamsDir/$datafile.e$eID.params.ttl and rerun to produce E$eID enhancement" | tee -a $CSV2RDF4LOD_LOG
      cat $eParamsDir/$datafile.e$prevEID.params.ttl | awk -f $CSV2RDF4LOD_HOME/bin/util/e-params-increment.awk eID=$eID > $eParamsDir/$datafile.e$eID.params.ttl
   else
      # Start fresh directly from the CSV headers.
      echo "E$eID enhancement parameters missing; creating default template. Edit $eParamsDir/$datafile.e$eID.params.ttl and rerun to produce E$eID enhancement." | tee -a $CSV2RDF4LOD_LOG

      # NOTE: command also done above (when checking if e params are different from template provided).
      java $csvHeadersClasspath $data $csvHeadersParams | awk -v conversionID="$eID" $paramsParams -f $h2p > $eParamsDir/$datafile.e$eID.params.ttl
   fi
fi

#
#
# Track down the provenance of the converter implementation.
#
#

converterJarPath=""
# Find the first csv2rdf4lod.jar that exists. This will be the jar that contains the converter.
# This was done for provenance, and is not an ideal solution.
for jarPath in `echo $CLASSPATH | sed 's/:/ /g' | awk '{for(i=1;i<=NF;i++)print $i}' | grep csv2rdf4lod.jar`
do
   if [ -e $jarPath -a ${#converterJarPath} -gt 0 ]; then
      converterJarPath="$jarPath"
   fi
done
# If none were found, hard code to the expected place.
if [ ${#converterJarPath} -eq 0 ]; then
   converterJarPath=$CSV2RDF4LOD_HOME/bin/dup/csv2rdf4lod.jar
fi

converterJarMD5="csv2rdf4lod_`$CSV2RDF4LOD_HOME/bin/util/md5.sh $converterJarPath`"

#
#
# We still want to convert; override URI and log all data files converted.
#
#

if [ $runRaw == "yes" -o $runEnhancement == "yes" ]; then
   echo "`wc -l $data | awk '{print $1}'` rows in $data" | tee -a $CSV2RDF4LOD_LOG
   if [ ${#CSV2RDF4LOD_BASE_URI_OVERRIDE} -gt 0 ]; then
      echo "`basename $0` overriding conversion:base_uri in parameters file with $CSV2RDF4LOD_BASE_URI_OVERRIDE" | tee -a $CSV2RDF4LOD_LOG
      overrideBaseURI="-surrogateNS $CSV2RDF4LOD_BASE_URI_OVERRIDE"
   else
      overrideBaseURI=""
   fi
   
   # Keep track of the files we processed, so we can ln to the public www directory in convert-aggregate.sh.
   TMP_list="_csv2rdf4lod_file_list_"`basename $0``date +%s`_$$.tmp
   cat $destDir/_CSV2RDF4LOD_file_list.txt > $TMP_list 2> /dev/null
   echo $data >> $TMP_list
   cat $TMP_list | sort -u > $destDir/_CSV2RDF4LOD_file_list.txt
   rm $TMP_list
fi

#
#
# Convert!
#
#

sampleN="-sample ${CSV2RDF4LOD_CONVERT_NUMBER_SAMPLE_ROWS:-"2"}"
dumpExtensions="-VoIDDumpExtensions ${CSV2RDF4LOD_CONVERT_DUMP_FILE_EXTENSIONS}"
if [ ${#CSV2RDF4LOD_CONVERT_DUMP_FILE_EXTENSIONS} -eq 0 ]; then
   dumpExtensions=""
fi

#
# Raw conversion?
#
if [ $runRaw == "yes" ]; then
   echo "RAW CONVERSION" | tee -a $CSV2RDF4LOD_LOG

   # Sample ------------------------------
   if [ ${CSV2RDF4LOD_CONVERT_NUMBER_SAMPLE_ROWS:-"2"} -gt 0 ]; then
      $csv2rdf $data $sampleN -ep $destDir/$datafile.raw.params.ttl $overrideBaseURI $dumpExtensions -w $destDir/$datafile.raw.sample.ttl  -id $converterJarMD5 2>&1 | tee -a $CSV2RDF4LOD_LOG
      echo "Finished converting $sampleN sample rows."                                                                                                          2>&1 | tee -a $CSV2RDF4LOD_LOG
   fi

   # Full ------------------------------
   #if [ ${CSV2RDF4LOD_CONVERT_EXAMPLE_SUBSET_ONLY:='.'} == 'true' ]; then
   #   # Would require eparams - which are not available in raw.
   #   #$csv2rdf $data   -ego   -ep $destDir/$datafile.raw.params.ttl $overrideBaseURI $dumpExtensions -w $destDir/$datafile.raw.example.ttl -id $converterJarMD5 2>&1 | tee -a $CSV2RDF4LOD_LOG
   #   echo "OMITTING FULL CONVERSION b/c CSV2RDF4LOD_CONVERT_EXAMPLE_SUBSET_ONLY=='true'"                                                                       2>&1 | tee -a $CSV2RDF4LOD_LOG
   if [ ${CSV2RDF4LOD_CONVERT_SAMPLE_SUBSET_ONLY:='.'} == 'true' ]; then
      echo "OMITTING FULL CONVERSION b/c CSV2RDF4LOD_CONVERT_SAMPLE_SUBSET_ONLY=='true'"                                                                        2>&1 | tee -a $CSV2RDF4LOD_LOG
   else
      $csv2rdf $data          -ep $destDir/$datafile.raw.params.ttl $overrideBaseURI $dumpExtensions -w $destDir/$datafile.raw.ttl         -id $converterJarMD5 2>&1 | tee -a $CSV2RDF4LOD_LOG
      # Parse out meta from full
      $CSV2RDF4LOD_HOME/bin/util/grep-tail.sh $destDir/$datafile.raw.ttl > $destDir/$datafile.raw.void.ttl    # .-todo
   fi
fi

#
# Enhancement conversion?
#
if [ $runEnhancement == "yes" ]; then
   echo "E$eID CONVERSION" | tee -a $CSV2RDF4LOD_LOG

   # Sample ------------------------------
   if [ ${CSV2RDF4LOD_CONVERT_NUMBER_SAMPLE_ROWS:-"2"} -gt 0 -a ${CSV2RDF4LOD_CONVERT_EXAMPLE_SUBSET_ONLY:='.'} != 'true' ]; then
      $csv2rdf $data $sampleN -ep $eParamsDir/$datafile.${global}e$eID.params.ttl $overrideBaseURI $dumpExtensions -w $destDir/$datafile.e$eID.sample.ttl  -id $converterJarMD5 2>&1 | tee -a $CSV2RDF4LOD_LOG
      echo "Finished converting $sampleN sample rows."                                                                                                                          2>&1 | tee -a $CSV2RDF4LOD_LOG
   fi

   # Full ------------------------------
   if [ ${CSV2RDF4LOD_CONVERT_EXAMPLE_SUBSET_ONLY:='.'} == 'true' ]; then
      # TODO: add .example back in. took out so it'd get into the publish/tdb/ for testing.
      $csv2rdf $data    -ego  -ep $eParamsDir/$datafile.${global}e$eID.params.ttl $overrideBaseURI $dumpExtensions -w $destDir/$datafile.e$eID.ttl -id $converterJarMD5 2>&1 | tee -a $CSV2RDF4LOD_LOG
      echo "OMITTING FULL CONVERSION b/c CSV2RDF4LOD_CONVERT_SAMPLE_SUBSET_ONLY=='true'"                                                                                        2>&1 | tee -a $CSV2RDF4LOD_LOG
   elif [ ${CSV2RDF4LOD_CONVERT_SAMPLE_SUBSET_ONLY:='.'} == 'true' ]; then
      echo "OMITTING FULL CONVERSION b/c CSV2RDF4LOD_CONVERT_EXAMPLE_SUBSET_ONLY=='true'"                                                                                       2>&1 | tee -a $CSV2RDF4LOD_LOG
   else
      $csv2rdf $data          -ep $eParamsDir/$datafile.${global}e$eID.params.ttl $overrideBaseURI $dumpExtensions -w $destDir/$datafile.e$eID.ttl         -id $converterJarMD5 2>&1 | tee -a $CSV2RDF4LOD_LOG
      # Parse out meta from full
      $CSV2RDF4LOD_HOME/bin/util/grep-tail.sh $destDir/$datafile.e$eID.ttl > $destDir/$datafile.e$eID.void.ttl # .-todo
   fi

fi

#
# Provenance
#
#provenance=`ls source/$extensionlessFilename*.pml.ttl | head -1 2> /dev/null`
#provenance=`find source -name "$extensionlessFilename*.pml.ttl" | wc -l`
#if [ ${#provenance} -a -f $provenance ]; then
if [ -f $data.pml.ttl -a ${CSV2RDF4LOD_CONVERT_PROVENANCE_GRANULAR:-"."} == "true" ]; then
   prov="-prov `pwd`/$data.pml.ttl"
   echo "E$eID (PROV) $prov" | tee -a $CSV2RDF4LOD_LOG
   #$csv2rdf `pwd`/$data -ep `pwd`/$eParamsDir/$datafile.e$eID.params.ttl $prov > $destDir/$extensionlessFilename.e$eID.pml.ttl
   # LATEST, but makes a semi-verbatim copy of e1... 
   #$csv2rdf `pwd`/$data -ep `pwd`/$eParamsDir/$datafile.e$eID.params.ttl $prov $overrideBaseURI -id $converterJarMD5 > $destDir/$datafile.e$eID.pml.ttl
   echo $destDir/$datafile.e$eID.ttl.pml.ttl
   $csv2rdf $data        -ep $eParamsDir/$datafile.${global}e$eID.params.ttl $prov $overrideBaseURI $dumpExtensions -w $destDir/$datafile.e$eID.ttl.pml.ttl -id $converterJarMD5 > $destDir/$datafile.e$eID.ttl.pml.ttl # 2>&1 | tee -a $CSV2RDF4LOD_LOG
else
   echo "Skipping provenance pass: $data.pml.ttl and $CSV2RDF4LOD_CONVERT_PROVENANCE_GRANULAR"
fi




#
#
# This is very much fading code.
#
#
if [ ${CSV2RDF4LOD_LOAD_TDB_INDIV:-"."} == "true" ]; then
   # Loading individual raw/enhancements into separate tdb directories is helpful for debugging, 
   # demonstration of raw v e$eID, and provenance fragment construction. It is not intended for final publication.
   if [ `which tdbloader` ]; then
      # Load into TDB

      POPULATE_INDIV_TDB="NO"                 
      RAW_TDB_DIR=$destDir/$datafile.raw.ttl.tdb
      ENHANCE_TDB_DIR=$destDir/$datafile.e$eID.ttl.tdb

      if [ $runRaw == "yes" -a $POPULATE_INDIV_TDB == "yesNO" -a ! -e $RAW_TDB_DIR ]; then
         mkdir $RAW_TDB_DIR 
      fi
      if [ $runEnhancement == "yes" -a $POPULATE_INDIV_TDB == "yes" -a ! -e $ENHANCE_TDB_DIR ]; then
         mkdir $ENHANCE_TDB_DIR 
      fi

      echo $graph | tee -a $CSV2RDF4LOD_LOG
      if [ $runRaw == "yes" -a $POPULATE_INDIV_TDB == "yesNO" ]; then
         echo $destDir/$datafile.raw.ttl into $RAW_TDB_DIR as $graph/raw | tee -a $CSV2RDF4LOD_LOG
         echo $destDir/$datafile.raw.ttl into $RAW_TDB_DIR as $graph/raw >> $destDir/ng.info | tee -a $CSV2RDF4LOD_LOG
         tdbloader --loc=$RAW_TDB_DIR --graph=$graph/raw     $destDir/$datafile.raw.ttl # For debugging purposes
         #java jena.rdfcopy $destDir/$datafile.raw.ttl TURTLE RDF/XML > $destDir/$datafile.raw.ttl.rdf
      fi
      if [ $runEnhancement == "yes" -a $POPULATE_INDIV_TDB == "yes" ]; then
         # Clean up previous
         if [ `ls $ENHANCE_TDB_DIR 2> /dev/null | wc -l` -gt 0 ]; then
            echo WIPING $ENHANCE_TDB_DIR | tee -a $CSV2RDF4LOD_LOG
            rm $ENHANCE_TDB_DIR/*
         fi
         echo $destDir/$datafile.e$eID.ttl into $ENHANCE_TDB_DIR as $graph/enrichment/1 | tee -a $CSV2RDF4LOD_LOG
         echo $destDir/$datafile.e$eID.ttl into $ENHANCE_TDB_DIR as $graph/enrichment/1 >> $destDir/ng.info 
         tdbloader --loc=$ENHANCE_TDB_DIR --graph=$graph/enrichment/$eID $destDir/$datafile.e$eID.ttl  # For debugging purposes
         #java jena.rdfcopy $destDir/$datafile.e$eID.ttl  TURTLE RDF/XML      > $destDir/$datafile.e$eID.ttl.rdf 
      fi
      #tdbloader --loc=$destDir/$datafile.tdb --graph=$graph/             $destDir/$datafile.raw.ttl # Both raw and enriched go into the same named graph
      #tdbloader --loc=$destDir/$datafile.tdb --graph=$graph/             $destDir/$datafile.e$eID.ttl
   else
      echo "WARNING: tdbloader not on PATH; could not load individual conversion into tdb directory" | tee -a $CSV2RDF4LOD_LOG
   fi
fi

publishDir=publish
if [ ! -e joseki-config-${sourceID}-${datasetID}-anterior.ttl -a "n" == "y" ]; then
   configTemplate=$CSV2RDF4LOD_HOME/bin/dup/joseki-config-ANTERIOR.ttl
   configFilename=$publishDir/joseki-config-${sourceID}-${datasetID}-${subjectDiscriminator}-anterior.ttl
   cat $configTemplate | awk '{gsub("__TDB__DIRECTORY__",dir);print $0}' dir=`pwd`/$publishDir/$datafile.tdb/ > $configFilename
fi 
# END of very much fading code. TODO: Complete MOLST Form.



#
#
# Create publish/bin/aggregate.sh, giving it all of the variables it needs when it runs.
#
#

echo '#!/bin/bash'                                                                       > $publishDir/bin/publish.sh
echo 'CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}' >> $publishDir/bin/publish.sh
echo "surrogate=\"$surrogate\""                                                         >> $publishDir/bin/publish.sh
echo "sourceID=\"$sourceID\""                                                           >> $publishDir/bin/publish.sh
echo "datasetID=\"$datasetID\""                                                         >> $publishDir/bin/publish.sh
echo "datasetVersion=\"$datasetVersion\""                                               >> $publishDir/bin/publish.sh
echo "versionID=\"$datasetVersion\""                                                    >> $publishDir/bin/publish.sh # Note: this is replacing datasetVersion.
echo "eID=\"$eID\""                                                                     >> $publishDir/bin/publish.sh
echo ""                                                                                 >> $publishDir/bin/publish.sh
echo "sourceDir=\"$sourceDir\""                                                         >> $publishDir/bin/publish.sh
echo "destDir=\"$destDir\""                                                             >> $publishDir/bin/publish.sh
echo ""                                                                                 >> $publishDir/bin/publish.sh
echo "graph=\"$graph\""                                                                 >> $publishDir/bin/publish.sh
echo "publishDir=\"$publishDir\""                                                       >> $publishDir/bin/publish.sh
echo ""                                                                                 >> $publishDir/bin/publish.sh
echo "export CSV2RDF4LOD_FORCE_PUBLISH=\"true\""                                        >> $publishDir/bin/publish.sh
echo 'source $CSV2RDF4LOD_HOME/bin/convert-aggregate.sh'                                >> $publishDir/bin/publish.sh
echo "export CSV2RDF4LOD_FORCE_PUBLISH=\"false\""                                       >> $publishDir/bin/publish.sh
chmod +x                                                                                   $publishDir/bin/publish.sh

echo "   convert.sh done" | tee -a $CSV2RDF4LOD_LOG

# NOTE: this script (convert.sh) does NOT call convert-aggregate.sh directly.
#       convert-aggregate.sh is called by convert-DDD.sh /after/ it has called convert.sh (potentially) several times.
