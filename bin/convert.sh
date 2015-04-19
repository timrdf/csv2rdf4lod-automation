#3> <> prov:specializationOf <https://raw.github.com/timrdf/csv2rdf4lod-automation/master/bin/convert.sh> .
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
if [[ "$CSV2RDF4LOD_CONVERT_DEBUG_LEVEL" == 'finest' ]]; then
   echo "VERY BEGINNING: $CLASSPATH"
fi

see='https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set'
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $see"}
export PATH=$PATH`$CSV2RDF4LOD_HOME/bin/util/cr-situate-paths.sh`
export CLASSPATH=$CLASSPATH`$CSV2RDF4LOD_HOME/bin/util/cr-situate-classpaths.sh`

if [[ "$CSV2RDF4LOD_CONVERT_DEBUG_LEVEL" == 'finest' ]]; then
   echo "AFTER SITUATE: $CLASSPATH"
fi

if [ `cr-pwd-type.sh` != 'cr:conversion-cockpit' ]; then # aka ${0#./} != `basename $0`
   pushd `dirname $0`
fi

# https://github.com/timrdf/csv2rdf4lod-automation/issues/323
if [ -e ../../../../csv2rdf4lod-source-me.sh ]; then
   # Include project-specific https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-environment-variables
   echo "source ../../../../csv2rdf4lod-source-me.sh" | tee -a $CSV2RDF4LOD_LOG
   source ../../../../csv2rdf4lod-source-me.sh
else
   see='https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-environment-variables-(considerations-for-a-distributed-workflow)'
   echo "#3> <> rdfs:seeAlso <$see> ." > ../../../../csv2rdf4lod-source-me.sh
fi
if [ -f ../../csv2rdf4lod-source-me.sh ]; then
   # Include source-specific https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-environment-variables
   echo "source ../../csv2rdf4lod-source-me.sh" | tee -a $CSV2RDF4LOD_LOG
   source ../../csv2rdf4lod-source-me.sh
fi
if [ -f ../csv2rdf4lod-source-me.sh ]; then
   # Include dataset-specific https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-environment-variables
   echo "source ../csv2rdf4lod-source-me.sh" | tee -a $CSV2RDF4LOD_LOG
   source ../csv2rdf4lod-source-me.sh
fi

if [[ "$CSV2RDF4LOD_CONVERT_DEBUG_LEVEL" == 'finest' ]]; then
   echo "AFTER source ../*../: $CLASSPATH"
fi

if [[ "$CSV2RDF4LOD_CONVERT_ALWAYS_UPDATE_CONVERTER" == "true" ]]; then
   pushd `which cr-vars.sh | sed 's/\/bin\/cr-vars.sh//'` &> /dev/null
   if [[ -e .git ]]; then
      echo "NOTE: updating csv2rdf4lod-automation because \$CSV2RDF4LOD_CONVERT_ALWAYS_UPDATE_CONVERTER is 'true'" 
      git pull
   fi
   popd &> /dev/null
fi

eParamsDir=manual # Enhancement parameter templates are placed in manual/ b/c a human will be modifying them.

extensionlessFilename=`echo $datafile | sed 's/^\([^\.]*\)\..*$/\1/'`

graph=${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$surrogate}/source/$sourceID/dataset/$datasetID/version/$datasetVersion
echo "--------------------------------------------------------------------------------"
echo "$datafile"
#echo Dataset URI $graph | tee -a $CSV2RDF4LOD_LOG


# Deal with filenames such as the string containing asterisks, e.g. '*.csv'
if [[ "$datafile" !=  "${datafile/\*/}" ]]; then
   echo "[WARNING] Requested conversion of data file \"$datafile\"; files must be cited explicitly."
   echo "[WARNING] Consider rerunning cr-create-convert-sh.sh; it is structured poorly -- ESPECIALLY if you are converting only one file."
   echo "[WARNING] https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-create-convert-sh.sh"
   exit 1 
fi

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
if [ -e "$destDir/$datafile.raw.ttl" -o "$CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER" == "true" ]; then
   # Raw layer has already been produced OR we just don't want the Raw layer (because it is generally less useful).
   runRaw=no
   runEnhancement=yes
   eID=${eID:?"enhancement identifier not set; re-produce convert*.sh using cr-create-convert-sh.sh, pass it an eID, or add the line: eID=\"1\""}
   CSV2RDF4LOD_LOG="doc/logs/csv2rdf4lod_log_e${eID}_`date +%Y-%m-%dT%H_%M_%S`.txt"
   if [[ "$CSV2RDF4LOD_CONVERT_DEBUG_LEVEL" == "fine" ]]; then
      echo "INFO: runRaw=no; runE=yes b/c auto/raw.ttl exists or OMIT RAW is true ($CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER)"
   fi
else
   if [[ "$CSV2RDF4LOD_CONVERT_DEBUG_LEVEL" == "fine" ]]; then
      echo "INFO: runRaw=yes; runE=no b/c auto/raw.ttl does not exist or OMIT RAW is not true ($CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER)"
   fi
   CSV2RDF4LOD_LOG="doc/logs/csv2rdf4lod_log_raw_`date +%Y-%m-%dT%H_%M_%S`.txt"
fi

if [ ! -e "$eParamsDir/$datafile.e$eID.params.ttl" ]; then
   runEnhancement=no
   if [[ "$CSV2RDF4LOD_CONVERT_DEBUG_LEVEL" == "fine" ]]; then
      echo "INFO: runE=no b/c eparams does not exist."
   fi
fi
if [[ "$destDir/$datafile.e$eID.ttl" -nt "$eParamsDir/$datafile.e$eID.params.ttl" ]]; then             # File, version specific params
   if [[ "$cr_justdoit" == "yes" ]]; then
      echo "E$eID output $destDir/$datafile.e$eID.ttl is newer than enhancement parameters $eParamsDir/$datafile.e$eID.params.ttl, but you --force'd so we'll do it anyway."
   elif [[ "0" == "1" && "$destDir/$datafile.e$eID.ttl" -nt $CSV2RDF4LOD_HOME/lib/csv2rdf4lod.jar ]]; then  # Converter jar TODO
      echo "E$eID output $destDir/$datafile.e$eID.ttl newer than converter and enhancement parameters $eParamsDir/$datafile.e$eID.params.ttl; skipping." | tee -a $CSV2RDF4LOD_LOG
      runEnhancement=no
   else 
      echo "E$eID output $destDir/$datafile.e$eID.ttl newer than enhancement parameters $eParamsDir/$datafile.e$eID.params.ttl; skipping." | tee -a $CSV2RDF4LOD_LOG
      runEnhancement=no
   fi
fi

$CSV2RDF4LOD_HOME/bin/util/dateInXSDDateTime.sh > $CSV2RDF4LOD_LOG

function find_tab_based_global_eparams {
   datafile_lowercase=`echo "$1" | awk '{print tolower($0)}'`
   matches=''
   let numMatches=0
   for tab in `find .. -maxdepth 1 -name "*.e$eID.params.ttl"`; do
      tag=`basename $tab | sed 's/.e1.params.ttl$//; s/-/./g' | awk '{print tolower($0)}'`
      # e.g. user.following
      #      user.profile
      #
      # to match $datafile whose path is one of:
      #
      #   manual/Sample_PoC_Schema_DataSet_0810.xls_Courses.csv
      #   manual/Sample_PoC_Schema_DataSet_0810.xls_User_Following.csv
      #   manual/Sample_PoC_Schema_DataSet_0810.xls_Group_Member.csv
      #   manual/Sample_PoC_Schema_DataSet_0810.xls_User_Learning.csv
      #   manual/Sample_PoC_Schema_DataSet_0810.xls_Group_Owner.csv
      #   manual/Sample_PoC_Schema_DataSet_0810.xls_User_Profile.csv
      if [[ `echo $datafile_lowercase | awk -v pattern=$tag '$0 ~ pattern {print "yes"}'` == 'yes' ]]; then
         let 'numMatches=numMatches+1'
         matches="$matches $tab"
      fi
   done
   if [[ "$numMatches" -eq 1 ]]; then
      echo $matches
   elif [[ "$numMatches" -gt 1 ]]; then
      echo "NOTE: Could not determine tab-based global enhancement parameters b/c too many matches: $matches" >&2
   fi
}

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
# Check to see if enhancement parameters provide useful enhancements (and is more than just the template generated).
#
#

if [ $runEnhancement == "yes" ]; then 

   if [ "" == "https://github.com/timrdf/csv2rdf4lod-automation/issues/267" ]; then
      # @@ DEPRECATED
      # @@ DEPRECATED - this whole block.
      # @@ DEPRECATED
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
         #exit 1 # Added by user request: quit asap and do not do anything. https://github.com/timrdf/csv2rdf4lod-automation/issues/128
         runEnhancement="no"
      fi
   else
      if [ `valid-rdf.sh "$eParamsDir/$datafile.e$eID.params.ttl"` == "no" ]; then
         echo
         echo "WARNING; invalid RDF syntax in $eParamsDir/$datafile.e$eID.params.ttl"
         echo
      fi
      useful=`java edu.rpi.tw.data.csv.impl.UsefulEnhancements "$eParamsDir/$datafile.e$eID.params.ttl" 2> /dev/null`
      if [ "$useful" == "false" -a ! -e ../e$eID.params.ttl -a ! -e "../$datafile.e$eID.params.ttl" ]; then
         # local enhancement parameters are not useful
         # there is no file-version global enhancement parameters
         # there is no version global enhancement parameters
         echo "   Skipping E$eID conversion b/c enhancement parameters do not provide any useful enhancements: ($eParamsDir/$datafile.e$eID.params.ttl)" | tee -a $CSV2RDF4LOD_LOG
         #exit 1 # Added by user request: quit asap and do not do anything. https://github.com/timrdf/csv2rdf4lod-automation/issues/128
         runEnhancement="no"
      fi
   fi
   # TODO: check to see if enhancement parameters match previous enhancement parameters (e2 same as e1). 
fi

#
#
# Prepare to run the conversion.
#
#

if [ -e $CSV2RDF4LOD_HOME/bin/logging/${CSV2RDF4LOD_CONVERT_DEBUG_LEVEL:-none}.properties ]; then
   javaprops="-Djava.util.logging.config.file=$CSV2RDF4LOD_HOME/bin/logging/${CSV2RDF4LOD_CONVERT_DEBUG_LEVEL:-none}.properties"
else
   javaprops=""
fi
csv2rdf=${CSV2RDF4LOD_CONVERTER:-"java $javaprops -Xmx3060m edu.rpi.tw.data.csv.CSVtoRDF"}

if [ $runRaw == "yes" -a "decide if" == "this is still needed" ]; then 
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

if [[ "$runRaw" == 'yes' ]]; then
   # Regenerate raw parameters EACH TIME we create raw.
   java $csvHeadersClasspath "$data" $csvHeadersParams | awk $paramsParams -f $h2p > "$destDir/$datafile.raw.params.ttl"
fi

# Generate the enhancement parameters only when not present.
tag_based_eparams=`find_tab_based_global_eparams $datafile`
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
elif [ -e "../$datafile.e$eID.params.ttl" ]; then # There are enhancement parameters that apply to ALL versions of THIS file.
   global="global."
   if [ ! -e "manual/$datafile.e$eID.params.ttl" ]; then # TODO: manual should be $eParamsDir
      # Link to file-SPECIFIC global params file (instead of making a new one)
      echo "NOTE: global parameters found; linking manual/$datafile.e$eID.params.ttl to ../$datafile.e$eID.params.ttl -- editing it edits the global parameters." | tee -a $CSV2RDF4LOD_LOG
      ln "../$datafile.e$eID.params.ttl" "manual/$datafile.e$eID.params.ttl" # TODO: manual should be $eParamsDir
   fi
   if [ ! -e "$eParamsDir/$datafile.global.e$eID.params.ttl" -o "../$datafile.e$eID.params.ttl" -nt "$eParamsDir/$datafile.global.e$eID.params.ttl" ]; then
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
elif [ -e ../e$eID.params.ttl ]; then # There are enhancement parameters that apply to ALL files of ALL versions.
   global="global."
   if [ ! -e "manual/$datafile.e$eID.params.ttl" ]; then # No enhancement parameters have been specified for THIS file. # TODO: manual should be $eParamsDir
      # Link to file-INDEPENDENT global params file (instead of making a new one)
      echo "NOTE: global parameters found; linking manual/$datafile.e$eID.params.ttl to ../$datafile.e$eID.params.ttl -- editing it edits the global parameters." | tee -a $CSV2RDF4LOD_LOG
      ln ../e$eID.params.ttl manual/$datafile.e$eID.params.ttl # TODO: manual should be $eParamsDir
   fi
   if [ ! -e "$eParamsDir/$datafile.global.e$eID.params.ttl" -o "../e$eID.params.ttl" -nt "$eParamsDir/$datafile.global.e$eID.params.ttl" ]; then
      # The file-specific copy doesn't exist or is older than the file-INDEPENDENT parameters.
      echo "constructing "$eParamsDir/$datafile.${global}e$eID.params.ttl" from file-independent global params ../e$eID.params.ttl" | tee -a $CSV2RDF4LOD_LOG
      chmod +w "$eParamsDir/$datafile.global.e$eID.params.ttl" 2> /dev/null
      echo "#"                                                                                        > "$eParamsDir/$datafile.global.e$eID.params.ttl"
      echo "#"                                                                                       >> "$eParamsDir/$datafile.global.e$eID.params.ttl"
      echo "#"                                                                                       >> "$eParamsDir/$datafile.global.e$eID.params.ttl"
      echo "#"                                                                                       >> "$eParamsDir/$datafile.global.e$eID.params.ttl"
      echo "# WARNING: do not edit these; they are automatically generated from ../e$eID.params.ttl" >> "$eParamsDir/$datafile.global.e$eID.params.ttl"
      echo "#"                                                                                       >> "$eParamsDir/$datafile.global.e$eID.params.ttl"
      echo "#"                                                                                       >> "$eParamsDir/$datafile.global.e$eID.params.ttl"
      echo "#"                                                                                       >> "$eParamsDir/$datafile.global.e$eID.params.ttl"
      echo "#"                                                                                       >> "$eParamsDir/$datafile.global.e$eID.params.ttl"
      cat ../e$eID.params.ttl | awk -f $CSV2RDF4LOD_HOME/bin/util/update-e-params-subject-discrim.awk baseURI="$CSV2RDF4LOD_BASE_URI" sourceID=$sourceID dataset_identifier=$datasetID datasetVersion=$datasetVersion layerID="$eID" subjectDiscriminator=$subjectDiscriminator >> "$eParamsDir/$datafile.global.e$eID.params.ttl"
      chmod -w "$eParamsDir/$datafile.global.e$eID.params.ttl"
      runEnhancement="yes"
   fi
elif [ -e "$tag_based_eparams" ]; then                       # Global enhancement parameters found via filename substring.
   global="global."
   if [ ! -e "manual/$datafile.e$eID.params.ttl" ]; then # No enhancement parameters have been specified for THIS file. # TODO: manual should be $eParamsDir
      # Link to file-INDEPENDENT global params file (instead of making a new one)
      echo "NOTE: global parameters found via filename substring; linking manual/$datafile.e$eID.params.ttl to $tag_based_eparams -- editing it edits the global parameters." | tee -a $CSV2RDF4LOD_LOG
      ln $tag_based_eparams $eParamsDir/$datafile.e$eID.params.ttl # TODO: manual should be $eParamsDir
   fi
   if [ ! -e "$eParamsDir/$datafile.global.e$eID.params.ttl" -o "$tag_based_eparams" -nt "$eParamsDir/$datafile.global.e$eID.params.ttl" ]; then
      # The file-specific copy doesn't exist or is older than the file-INDEPENDENT parameters.
      echo "constructing "$eParamsDir/$datafile.${global}e$eID.params.ttl" from tag-based global params $tag_based_eparams" | tee -a $CSV2RDF4LOD_LOG
      chmod +w "$eParamsDir/$datafile.global.e$eID.params.ttl" 2> /dev/null
      echo "#"                                                                                       > "$eParamsDir/$datafile.global.e$eID.params.ttl"
      echo "#"                                                                                      >> "$eParamsDir/$datafile.global.e$eID.params.ttl"
      echo "#"                                                                                      >> "$eParamsDir/$datafile.global.e$eID.params.ttl"
      echo "#"                                                                                      >> "$eParamsDir/$datafile.global.e$eID.params.ttl"
      echo "# WARNING: do not edit these; they are automatically generated from $tag_based_eparams" >> "$eParamsDir/$datafile.global.e$eID.params.ttl"
      echo "#"                                                                                      >> "$eParamsDir/$datafile.global.e$eID.params.ttl"
      echo "#"                                                                                      >> "$eParamsDir/$datafile.global.e$eID.params.ttl"
      echo "#"                                                                                      >> "$eParamsDir/$datafile.global.e$eID.params.ttl"
      echo "#"                                                                                      >> "$eParamsDir/$datafile.global.e$eID.params.ttl"
      cat $tag_based_eparams | awk -f $CSV2RDF4LOD_HOME/bin/util/update-e-params-subject-discrim.awk \
                               baseURI="$CSV2RDF4LOD_BASE_URI"                                       \
                               sourceID=$sourceID                                                    \
                               dataset_identifier=$datasetID                                         \
                               datasetVersion=$datasetVersion                                        \
                               layerID="$eID"                                                        \
                               subjectDiscriminator=$subjectDiscriminator >> "$eParamsDir/$datafile.global.e$eID.params.ttl"
      chmod -w "$eParamsDir/$datafile.global.e$eID.params.ttl"
      runEnhancement="yes"
   fi
elif [ ! -e "$eParamsDir/$datafile.e$eID.params.ttl" ]; then # No global enhancement parameters present (neither file-independent nor file-specific)
   # Create local file-specific enhancement parameters file.
   let prevEID=$eID-1
   if [ -e "$eParamsDir/$datafile.e$prevEID.params.ttl" ]; then 
      # Use the PREVIOUS enhancement parameters as a starting point.
      echo "E$eID enhancement parameters missing; creating template from E$prevEID enhancement parameters." | tee -a $CSV2RDF4LOD_LOG
      echo "Edit $eParamsDir/$datafile.e$eID.params.ttl and rerun to produce E$eID enhancement"             | tee -a $CSV2RDF4LOD_LOG
      cat "$eParamsDir/$datafile.e$prevEID.params.ttl" | awk -f $CSV2RDF4LOD_HOME/bin/util/e-params-increment.awk eID=$eID > $eParamsDir/$datafile.e$eID.params.ttl
   else
      # Start fresh directly from the CSV headers.
      echo "E$eID enhancement parameters missing; creating default template."                    | tee -a $CSV2RDF4LOD_LOG
      echo "Edit $eParamsDir/$datafile.e$eID.params.ttl and rerun to produce E$eID enhancement." | tee -a $CSV2RDF4LOD_LOG

      # NOTE: command also done above (when checking if e params are different from template provided).
      java $csvHeadersClasspath "$data" $csvHeadersParams | awk -v conversionID="$eID" $paramsParams -f $h2p > "$eParamsDir/$datafile.e$eID.params.ttl"
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
   converterJarPath=$CSV2RDF4LOD_HOME/lib/csv2rdf4lod.jar
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
   cat $destDir/._CSV2RDF4LOD_file_list.txt > $TMP_list 2> /dev/null
   echo $data >> $TMP_list
   cat $TMP_list | sort -u > $destDir/._CSV2RDF4LOD_file_list.txt
   rm $TMP_list
fi

#
#
# Convert!
#
#

sampleN="-sample ${CSV2RDF4LOD_CONVERT_SAMPLE_NUMBER_OF_ROWS:-"2"}"
dumpExtensions=`dump-file-extensions.sh`
if [ ${#dumpExtensions} -gt 0 ]; then
   dumpExtensions="-VoIDDumpExtensions $dumpExtensions"
fi
# FRBR-stacks. Takes a while. Could be optimized to not do when no change.
if [[ ( $runRaw == "yes" || $runEnhancement == "yes" ) && \
      ${CSV2RDF4LOD_CONVERT_PROVENANCE_FRBR:-"."} == "true" && `which fstack.py` ]]; then
   echo "Calculating FRBR Stack of tabular input; set CSV2RDF4LOD_CONVERT_PROVENANCE_FRBR=='false' to prevent FRBR stacks." 2>&1 | tee -a $CSV2RDF4LOD_LOG
   echo "#-fstack raw $runRaw enhancement $runEnhancement $data `dateInXSDDateTime.sh`" >> $data.prov.ttl
   fstack.py --stdout $data                     >> $data.prov.ttl
   prov="-prov `pwd`/$data.prov.ttl"
else
   prov=""
fi

#
# Raw conversion?
#
if [ $runRaw == "yes" ]; then
   echo "RAW CONVERSION" | tee -a $CSV2RDF4LOD_LOG

   # Sample ------------------------------
   if [ ${CSV2RDF4LOD_CONVERT_SAMPLE_NUMBER_OF_ROWS:-"2"} -gt 0 ]; then
      #echo $csv2rdf $data $prov $sampleN -ep $destDir/$datafile.raw.params.ttl $overrideBaseURI $dumpExtensions -w $destDir/$datafile.raw.sample.ttl  -id $converterJarMD5 >&2
      $csv2rdf $data $prov $sampleN -ep $destDir/$datafile.raw.params.ttl $overrideBaseURI $dumpExtensions -w $destDir/$datafile.raw.sample.ttl  -id $converterJarMD5 2>&1 | tee -a $CSV2RDF4LOD_LOG
      if [ "$?" -eq 3 ]; then exit 3; fi # Invalid RDF syntax in conversion parameters.
      echo "Finished converting $sampleN sample rows."                                                                                                          2>&1 | tee -a $CSV2RDF4LOD_LOG
   fi

   # Full ------------------------------
   #if [ ${CSV2RDF4LOD_CONVERT_EXAMPLE_SUBSET_ONLY:='.'} == 'true' ]; then
   #   # Would require eparams - which are not available in raw.
   #   #$csv2rdf $data   -ego   -ep $destDir/$datafile.raw.params.ttl $overrideBaseURI $dumpExtensions -w $destDir/$datafile.raw.example.ttl -id $converterJarMD5 2>&1 | tee -a $CSV2RDF4LOD_LOG
   #   echo "OMITTING FULL CONVERSION b/c CSV2RDF4LOD_CONVERT_EXAMPLE_SUBSET_ONLY=='true'"                                                                       2>&1 | tee -a $CSV2RDF4LOD_LOG
   if [ "$CSV2RDF4LOD_CONVERT_SAMPLE_SUBSET_ONLY" == 'true' ]; then
      echo "OMITTING FULL CONVERSION b/c CSV2RDF4LOD_CONVERT_SAMPLE_SUBSET_ONLY=='true'"                                                                        2>&1 | tee -a $CSV2RDF4LOD_LOG
   else
      #echo $csv2rdf $data $prov -ep $destDir/$datafile.raw.params.ttl $overrideBaseURI $dumpExtensions -w $destDir/$datafile.raw.ttl -wm $destDir/$datafile.raw.void.ttl -id $converterJarMD5 >&2
      $csv2rdf $data $prov -ep $destDir/$datafile.raw.params.ttl $overrideBaseURI $dumpExtensions -w $destDir/$datafile.raw.ttl -wm $destDir/$datafile.raw.void.ttl -id $converterJarMD5 2>&1 | tee -a $CSV2RDF4LOD_LOG
      if [ "$?" -eq 3 ]; then exit 3; fi # Invalid RDF syntax in conversion parameters.
      if [[ ${CSV2RDF4LOD_CONVERT_PROVENANCE_FRBR:-"."} == "true" && `which fstack.py` ]]; then
         echo "Calculating FRBR Stack of output RDF; set CSV2RDF4LOD_CONVERT_PROVENANCE_FRBR=='false' to prevent FRBR stacks."                                                           2>&1 | tee -a $CSV2RDF4LOD_LOG
         item_i=`fstack.py --print-item $data`
         #item_p=`fstack.py --print-item $destDir/$datafile.raw.params.ttl`
         item_o=`fstack.py --print-item $destDir/$datafile.raw.ttl`
         echo "#-fstack raw $runRaw enhancement $runEnhancement $destDir/$datafile.raw.ttl @ `dateInXSDDateTime.sh`" >> $destDir/$datafile.raw.void.ttl
         fstack.py --stdout $destDir/$datafile.raw.ttl                                                               >> $destDir/$datafile.raw.void.ttl # TODO: incorporate into java directly.
         echo "@prefix prov: <http://dvcs.w3.org/hg/prov/raw-file/tip/ontology/ProvenanceOntology.owl#> ."           >> $destDir/$datafile.raw.void.ttl
         #echo "<#csv2rdf4lod_invocation`bin/convert.sh`>"                                                           >> $destDir/$datafile.raw.void.ttl
         #echo "   a prov:ProcessExecution;"                                                                         >> $destDir/$datafile.raw.void.ttl
         #echo "   prov:used      <$item_i>;"                                                                        >> $destDir/$datafile.raw.void.ttl
         #echo "   prov:used      <$item_p>;"                                                                        >> $destDir/$datafile.raw.void.ttl
         #echo "   prov:generated <$item_o>;"                                                                        >> $destDir/$datafile.raw.void.ttl
         #echo "   prov:wasControlledBy `user-account.sh --cite`;"                                                   >> $destDir/$datafile.raw.void.ttl
         #echo "   prov:used      <#$converterJarMD5>;"                                                              >> $destDir/$datafile.raw.void.ttl
         #echo "."                                                                                                   >> $destDir/$datafile.raw.void.ttl
         echo                                                                                                        >> $destDir/$datafile.raw.void.ttl
         echo "<$item_o> prov:wasDerivedFrom <$item_i> ."                                                            >> $destDir/$datafile.raw.void.ttl
         echo                                                                                                        >> $destDir/$datafile.raw.void.ttl
         #user-account.sh                                                                                            >> $destDir/$datafile.raw.void.ttl
      fi
   fi
fi

#
# Enhancement conversion?
#
if [ $runEnhancement == "yes" ]; then
   echo "E$eID CONVERSION" | tee -a $CSV2RDF4LOD_LOG

   # Sample ------------------------------
   if [ ${CSV2RDF4LOD_CONVERT_SAMPLE_NUMBER_OF_ROWS:-"2"} -gt 0 -a "$CSV2RDF4LOD_CONVERT_EXAMPLE_SUBSET_ONLY" != 'true' ]; then
      $csv2rdf $data $prov $sampleN -ep $eParamsDir/$datafile.${global}e$eID.params.ttl $overrideBaseURI $dumpExtensions -w $destDir/$datafile.e$eID.sample.ttl  -id $converterJarMD5 2>&1 | tee -a $CSV2RDF4LOD_LOG
      if [ "$?" -eq 3 ]; then exit 3; fi # Invalid RDF syntax in conversion parameters.
      echo "Finished converting $sampleN sample rows."                                                                                                                          2>&1 | tee -a $CSV2RDF4LOD_LOG
   fi

   # Full ------------------------------
   if [ "$CSV2RDF4LOD_CONVERT_EXAMPLE_SUBSET_ONLY" == 'true' ]; then
      # TODO: add .example back in. took out so it'd get into the publish/tdb/ for testing.
      $csv2rdf $data    -ego  -ep $eParamsDir/$datafile.${global}e$eID.params.ttl $overrideBaseURI $dumpExtensions -w $destDir/$datafile.e$eID.ttl -id $converterJarMD5 2>&1 | tee -a $CSV2RDF4LOD_LOG
      if [ "$?" -eq 3 ]; then exit 3; fi # Invalid RDF syntax in conversion parameters.
      echo "OMITTING FULL CONVERSION b/c CSV2RDF4LOD_CONVERT_SAMPLE_SUBSET_ONLY=='true'"                                                                                2>&1 | tee -a $CSV2RDF4LOD_LOG
   elif [ ${CSV2RDF4LOD_CONVERT_SAMPLE_SUBSET_ONLY:='.'} == 'true' ]; then
      echo "OMITTING FULL CONVERSION b/c CSV2RDF4LOD_CONVERT_EXAMPLE_SUBSET_ONLY=='true'"                                                                               2>&1 | tee -a $CSV2RDF4LOD_LOG
   else
      $csv2rdf $data $prov -ep $eParamsDir/$datafile.${global}e$eID.params.ttl $overrideBaseURI $dumpExtensions -w $destDir/$datafile.e$eID.ttl -wm $destDir/$datafile.e$eID.void.ttl -id $converterJarMD5 2>&1 | tee -a $CSV2RDF4LOD_LOG
      if [ "$?" -eq 3 ]; then exit 3; fi # Invalid RDF syntax in conversion parameters.
      if [[ "$CSV2RDF4LOD_CONVERT_PROVENANCE_FRBR" == "true" && `which fstack.py` ]]; then
         echo "Calculating FRBR Stack of output RDF; set CSV2RDF4LOD_CONVERT_PROVENANCE_FRBR=='false' to prevent FRBR stacks."                                          2>&1 | tee -a $CSV2RDF4LOD_LOG
         echo "#-fstack  no enhancement $runEnhancement $destDir/$datafile.e$eID.ttl @ `dateInXSDDateTime.sh`" >> $destDir/$datafile.e$eID.void.ttl
         item_i=`fstack.py --print-item $data`
         item_o=`fstack.py --print-item $destDir/$datafile.e$eID.ttl`
         fstack.py --stdout $destDir/$datafile.e$eID.ttl                                                       >> $destDir/$datafile.e$eID.void.ttl # TODO: incorporate into java directly.
         echo                                                                                                  >> $destDir/$datafile.e$eID.void.ttl
         echo "@prefix prov: <http://dvcs.w3.org/hg/prov/raw-file/tip/ontology/ProvenanceOntology.owl#> ."     >> $destDir/$datafile.e$eID.void.ttl
         echo "<$item_o> prov:wasDerivedFrom <$item_i> ."                                                      >> $destDir/$datafile.e$eID.void.ttl
         echo                                                                                                  >> $destDir/$datafile.e$eID.void.ttl
      fi
   fi
fi

#
# Provenance
#
#provenance=`ls source/$extensionlessFilename*.pml.ttl | head -1 2> /dev/null`
#provenance=`find source -name "$extensionlessFilename*.pml.ttl" | wc -l`
#if [ ${#provenance} -a -f $provenance ]; then
if [ -f "$data.pml.ttl" -a "$CSV2RDF4LOD_CONVERT_PROVENANCE_GRANULAR" == "true" ]; then
   prov="-prov `pwd`/$data.pml.ttl"
   echo "E$eID (PROV) $prov" | tee -a $CSV2RDF4LOD_LOG
   #$csv2rdf `pwd`/$data -ep `pwd`/$eParamsDir/$datafile.e$eID.params.ttl $prov > $destDir/$extensionlessFilename.e$eID.pml.ttl
   #   if [ "$?" -eq 3 ]; then exit 3; fi # Invalid RDF syntax in conversion parameters.
   # LATEST, but makes a semi-verbatim copy of e1... 
   #$csv2rdf `pwd`/$data -ep `pwd`/$eParamsDir/$datafile.e$eID.params.ttl $prov $overrideBaseURI -id $converterJarMD5 > $destDir/$datafile.e$eID.pml.ttl
   #if [ "$?" -eq 3 ]; then exit 3; fi # Invalid RDF syntax in conversion parameters.
   echo "$destDir/$datafile.e$eID.ttl.pml.ttl"
   $csv2rdf "$data"     -ep $eParamsDir/$datafile.${global}e$eID.params.ttl $prov $overrideBaseURI $dumpExtensions -w $destDir/$datafile.e$eID.ttl.pml.ttl -id $converterJarMD5 > $destDir/$datafile.e$eID.ttl.pml.ttl # 2>&1 | tee -a $CSV2RDF4LOD_LOG
   if [ "$?" -eq 3 ]; then exit 3; fi # Invalid RDF syntax in conversion parameters.
#else
#   echo "Skipping provenance pass. ($data.pml.ttl and CSV2RDF4LOD_CONVERT_PROVENANCE_GRANULAR=$CSV2RDF4LOD_CONVERT_PROVENANCE_GRANULAR)"
fi




#
#
# This is very much fading code.
#
#
if [ "$CSV2RDF4LOD_LOAD_TDB_INDIV" == "true" ]; then
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
echo ""                                                                                 >> $publishDir/bin/publish.sh
echo 'CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}' >> $publishDir/bin/publish.sh
echo "#sourceID=\"$sourceID\""                                                          >> $publishDir/bin/publish.sh
echo "#datasetID=\"$datasetID\""                                                        >> $publishDir/bin/publish.sh
echo "#versionID=\"$datasetVersion\""                                                   >> $publishDir/bin/publish.sh
echo "eID=\"$eID\""                                                                     >> $publishDir/bin/publish.sh
echo ""                                                                                 >> $publishDir/bin/publish.sh
echo "#graph=\"$graph\""                                                                >> $publishDir/bin/publish.sh
echo ""                                                                                 >> $publishDir/bin/publish.sh
echo "export CSV2RDF4LOD_FORCE_PUBLISH=\"true\""                                        >> $publishDir/bin/publish.sh
echo 'source $CSV2RDF4LOD_HOME/bin/convert-aggregate.sh'                                >> $publishDir/bin/publish.sh
echo "export CSV2RDF4LOD_FORCE_PUBLISH=\"false\""                                       >> $publishDir/bin/publish.sh
chmod +x                                                                                   $publishDir/bin/publish.sh

echo "   convert.sh done" | tee -a $CSV2RDF4LOD_LOG


# NOTE: this script (convert.sh) does NOT call convert-aggregate.sh directly.
#       convert-aggregate.sh is called by convert-DDD.sh /after/ it has called convert.sh (potentially) several times.

if [ `cr-pwd-type.sh` != 'cr:conversion-cockpit' ]; then
   popd `dirname $0`
fi
