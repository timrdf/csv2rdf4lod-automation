#!/bin/bash
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

# Create a shell script to automate the conversion and publishing of the given csv filenames.
# Running the created script once will produce the raw conversion; 
# running it a second time will produce the enhanced conversion.                                                      
#
#       \./ source-id                                      
#        |
#        |       \./ dataset-id
#        |        |           
#        |        |         .-- version-id
#        |        |         |
# source/data-gov/9/version/2010-Jun-9
#
# source/nci-nih-gov/popscigrid-nhis-2000-2005/version/2010-Jun-9
#        ^           ^                                 ^
#        ^^ source   ^                                 ^
#                    ^^ dataset                        ^
#                                                      ^^ version  
if [[ $# -lt 1 || "$1" == "--help" ]]; then
   echo "usage: `basename $0` [-w] [--comment-character char] [--header-line row] [--delimiter delimiter] a.csv [another.csv ...]"
   echo
   echo " (run from conversion cockpit, e.g. csv2rdf4lod/data/source/SSS/version/VVV/)"
   echo " (see https://github.com/timrdf/csv2rdf4lod-automation/wiki/Conversion-cockpit)"
   echo
   echo "parameters:"
   echo "   -w : write the conversion trigger to disk instead of printing to stdout"
   echo "   --comment-character : "
   echo "   --header-line       : "
   echo '   --delimiter         : , or tab or \\t'
   echo ""
   echo "   deprecated params:"
   echo "   -s sourceIdentifier  : override the source-identifier."
   echo "   -d datasetIdentifier : override the dataset-identifier."
   echo "   -v versionIdentifier : override the version-identifier."
   exit 1
fi

if [ -e ../../../../csv2rdf4lod-source-me.sh ]; then
   # Include project-specific https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-environment-variables
   source ../../../../csv2rdf4lod-source-me.sh
else
   see='https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-environment-variables-(considerations-for-a-distributed-workflow)'
   echo "#3> <> rdfs:seeAlso <$see> ." > ../../../../csv2rdf4lod-source-me.sh
fi

if [ "$1" == "-w" ]; then
   writeSH=yes
   shift
else 
   writeSH=no
fi

commentCharacter=""
if [ "$1" == "--comment-character" ]; then
   if [ $# -gt 2 -a $2 != "--delimiter" ]; then
      commentCharacter="$2"
      shift 2
   else
      shift
      echo "WARNING: did not recognize --comment-character"
   fi
fi

headerRow=""
if [ "$1" == "--header-line" ]; then
   if [ $# -gt 2 -a $2 != "--delimiter" ]; then
      headerRow="$2"
      shift 2
   else
      shift
      echo "WARNING: did not recognize --header-line"
   fi
fi

cellDelimiter=","
if [ "$1" == "--delimiter" -a $# -gt 2 ]; then
   cellDelimiter="$2"
   if [ $cellDelimiter == 'tab' ]; then
      cellDelimiter='\\t'
   fi
   shift 2
fi

#
if [ "$1" == "-s" -a $# -ge 2 ]; then
   sourceID="$2"
   explainSourceID="Came from -s parameter to `basename $0`"
   shift 2
else 
   back_three=`cd ../../.. 2>/dev/null && pwd`
   sourceID=`basename $back_three` # Use the names from the canonical directory structure
   explainSourceID="Came from directory name ../../../ (see https://github.com/timrdf/csv2rdf4lod-automation/wiki/Directory-Conventions)"
fi
if [ $sourceID == "data.gov" ]; then
   sourceID="data-gov"
fi

#
if [ "$1" == "-d" -a $# -ge 2 ]; then
   datasetID="$2"
   explainDatasetID="Came from -d parameter to `basename $0`"
   shift 2
else 
   back_two=`cd ../.. 2>/dev/null && pwd`
   datasetID=`basename $back_two` # Use the names from the canonical directory structure
   explainDatasetID="Came from directory name ../../ (see https://github.com/timrdf/csv2rdf4lod-automation/wiki/Directory-Conventions)"
fi

#
if [ "$1" == "-v" -a $# -ge 2 ]; then
   versionID="$2"
   explainVersionID="Came from -v parameter to `basename $0`"
   shift 2
else 
   datasetDir=`pwd`
   versionID=`basename $datasetDir` # Use the names from the canonical directory structure
   explainVersionID="Came from directory name ../ (see https://github.com/timrdf/csv2rdf4lod-automation/wiki/Directory-Conventions)"
fi

see='https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set'
CSV2RDF4LOD_BASE_URI=${CSV2RDF4LOD_BASE_URI:?"not set; source my-csv2rdf4lod-source-me.sh or see $see"}

TMP_SH=`date +%s`_$$.sh.tmp

echo "#!/bin/bash"                                                                                                       > $TMP_SH
echo "#"                                                                                                                >> $TMP_SH
echo "#3 <#> a <http://purl.org/twc/vocab/conversion/ConversionTrigger> ;"                                              >> $TMP_SH
echo "#3     rdfs:seeAlso <https://github.com/timrdf/csv2rdf4lod-automation/wiki/Conversion-trigger>,"                  >> $TMP_SH
echo "#3                  <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-create-convert-sh.sh> ." >> $TMP_SH
echo "#"                                                                                                                >> $TMP_SH
echo "# datasetID versionID (lastModDate):"                                                                             >> $TMP_SH
echo "# $datasetID $versionID ($lastModDate)"                                                                           >> $TMP_SH

echo "#--------------------------------------------------------------"                                                  >> $TMP_SH
echo ""                                                                                                                 >> $TMP_SH
echo 'see="https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"'                                  >> $TMP_SH
echo 'CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source my-csv2rdf4lod-source-me.sh or see \$see"}'                 >> $TMP_SH
echo ""                                                                                                                 >> $TMP_SH
echo "# The identifiers used to name the dataset that will be converted."                                               >> $TMP_SH
echo "#            (see https://github.com/timrdf/csv2rdf4lod-automation/wiki/Conversion-process-phase:-name)"          >> $TMP_SH
echo "surrogate=\"$CSV2RDF4LOD_BASE_URI\" # Came from \$CSV2RDF4LOD_BASE_URI when `basename $0` created this script."   >> $TMP_SH
echo "sourceID=\"$sourceID\"               # $explainSourceID"                                                          >> $TMP_SH
echo "datasetID=\"$datasetID\"             # $explainDatasetID"                                                         >> $TMP_SH
echo "datasetVersion=\"$versionID\"        # DEPRECATED"                                                                >> $TMP_SH
echo "versionID=\"$versionID\"             # $explainVersionID renaming datasetVersion (deprecating datasetVersion)"    >> $TMP_SH
echo "eID=\"1\"                             # enhancement identifier"                                                   >> $TMP_SH
echo "if [[ \"\$1\" == \"-e\" && \$# -ge 2 ]]; then"                                                                    >> $TMP_SH
echo "   eID=\"\$2\" # see https://github.com/timrdf/csv2rdf4lod-automation/wiki/Generating-enhancement-parameters"     >> $TMP_SH
echo "   shift 2"                                                                                                       >> $TMP_SH
echo "fi"                                                                                                               >> $TMP_SH
echo ""                                                                                                                 >> $TMP_SH
echo "cr_justdoit=\"no\""                                                                                               >> $TMP_SH
echo "if [[ \"\$1\" == \"--force\" ]]; then"                                                                            >> $TMP_SH
echo "   cr_justdoit=\"yes\" # see https://github.com/timrdf/csv2rdf4lod-automation/wiki/Conversion-trigger#--force"    >> $TMP_SH
echo "   shift"                                                                                                         >> $TMP_SH
echo "fi"                                                                                                               >> $TMP_SH
echo ""                                                                                                                 >> $TMP_SH
echo "if [ -d doc/logs ]; then"                                                                                         >> $TMP_SH
echo "   dateInXSDDateTime.sh > doc/logs/conversion-trigger-last-pulled"                                                >> $TMP_SH
echo "fi"                                                                                                               >> $TMP_SH
echo ""                                                                                                                 >> $TMP_SH
#echo "# $1"                                                                                                            >> $TMP_SH
#echo "sourceDir=\"`dirname "$1"`\"                  # if converting data directly (unmodified) from source organization, 'source'; if manual manipulations were required, 'manual'." >> $TMP_SH
echo "destDir=\"automatic\"                 # convention has led to always be 'automatic'; the directory where the converted RDF is put." >> $TMP_SH
echo "#--------------------------------------------------------------"                                                  >> $TMP_SH

if [ $# -gt 1 ]; then
   includeDiscriminator="yes"
else
   includeDiscriminator="no"
fi

while [ $# -gt 0 ]; do
   artifact="$1"

   echo ""                                                                                                                  >> $TMP_SH
   echo ""                                                                                                                  >> $TMP_SH
   echo "#-----------------------------------"                                                                              >> $TMP_SH
   echo "# $1"                                                                                                              >> $TMP_SH
   echo "sourceDir=\"`dirname "$artifact"`\""                                                                               >> $TMP_SH
   echo "datafile=\"`basename "$artifact"`\""                                                                               >> $TMP_SH
   echo "data=\"\$sourceDir/\$datafile\""                                                                                   >> $TMP_SH
   echo "# Bootstrap conversion parameters (see https://github.com/timrdf/csv2rdf4lod-automation/wiki/Conversion-trigger):" >> $TMP_SH
   subjectDiscriminator=""
   if [ $includeDiscriminator == "yes" ]; then
      extensionlessFilename=`basename $artifact | sed 's/^\([^\.]*\)\..*$/\1/'` # failed to cast 'ce.supersector.csv' to 'ce.supersector'
      extensionlessFilename=`basename $artifact | sed 's/\.[^.]*$//'`
      for extension in csv txt; do
         extensionlessFilename=${extensionlessFilename%.$extension}
      done
      # clean up %20 by replacing with underscore.
      subjectDiscriminator=`echo $extensionlessFilename | sed 's/%20/-/g; s/_/-/g' | awk '{print tolower($0)}'`
   fi
   echo "subjectDiscriminator=\"$subjectDiscriminator\"             # Additional part of URI for subjects created; must be URI-ready (e.g., no spaces)." >> $TMP_SH
   echo "commentCharacter=\"$commentCharacter\"                 # ONLY one character; complain to http://sourceforge.net/projects/javacsv/ otherwise."   >> $TMP_SH
   echo "cellDelimiter=\"$cellDelimiter\"                   # ONLY one character; complain to http://sourceforge.net/projects/javacsv/ otherwise."       >> $TMP_SH
   echo "header=$headerRow                             # Line that header is on; only needed if not '1'. '0' means no header."                           >> $TMP_SH
   echo "dataStart=                          # Line that data starts; only needed if not immediately after header."                                      >> $TMP_SH
   echo "repeatAboveIfEmptyCol=              # 'Fill in' value from row above for this column."                                                          >> $TMP_SH
   echo "onlyIfCol=                          # Do not process if value in this column is empty"                                                          >> $TMP_SH
   echo "interpretAsNull=                    # NO SPACES"                                                                                                >> $TMP_SH
   echo "dataEnd=                            # Line on which data stops; only needed if non-data bottom matter (legends, footnotes, etc)."               >> $TMP_SH
   echo "source \$CSV2RDF4LOD_HOME/bin/convert.sh"                                                                                                       >> $TMP_SH

   shift
done

echo ""                                                                            >> $TMP_SH
echo ""                                                                            >> $TMP_SH
echo "#-----------------------------------"                                        >> $TMP_SH
echo "source \$CSV2RDF4LOD_HOME/bin/convert-aggregate.sh"                          >> $TMP_SH
echo "# ^^ Note, this step can also be done manually using publish/bin/publish.sh" >> $TMP_SH

if [ $writeSH == "yes" ]; then
   mv $TMP_SH convert-$datasetID.sh
   chmod +x convert-$datasetID.sh
else
   cat $TMP_SH
   rm $TMP_SH
fi
