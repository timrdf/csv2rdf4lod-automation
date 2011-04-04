#!/bin/bash
#
# Create a shell script to automate the conversion and publishing of the given csv filenames.
# Running the created script once will produce the raw conversion; 
# running it a second time will produce the enhanced conversion.                                                      
#
#        \/ source                                      
#        |       \/ dataset                         
#        |        |          version  
#        |        |         \/
# source/data-gov/9/version/2010-Jun-9
#
# source/nci-nih-gov/popscigrid-nhis-2000-2005/version/2010-Jun-9
#        ^           ^                                 ^
#        ^^ source   ^                                 ^
#                    ^^ dataset                        ^
#                                                      ^^ version  
if [ $# -lt 1 ]; then
   echo "usage: `basename $0` [-w] [-d delimiter] [-s sourceIdentifier] [-d datasetIdentifier] [-v versionIdentifier] a.csv [another.csv ...]\\n
run from csv2rdf4lod/data/source/SSS/version/VVV/"
   exit 1
fi


if [ "$1" == "-w" ]; then
   writeSH=yes
   shift
else 
   writeSH=no
fi

cellDelimiter=","
if [ ${1:-"."} == "-d" -a $# -gt 2 ]; then
   cellDelimiter="$2"
   shift 2
fi
if [ ${1:-"."} == "--delimiter" -a $# -gt 2 ]; then # Sorry, bash compound conditionals are obtuse...
   cellDelimiter="$2"
   shift 2
fi

#
if [ "$1" == "-s" -a $# -ge 2 ]; then
   sourceID="$2"
   shift 2
else 
   back_three=`cd ../../.. 2>/dev/null && pwd`
   sourceID=`basename $back_three` # Use the names from the canonical directory structure
fi
if [ $sourceID == "data.gov" ]; then
   sourceID="data-gov"
fi

#
if [ "$1" == "-d" -a $# -ge 2 ]; then
   datasetID="$2"
   shift 2
else 
   back_two=`cd ../.. 2>/dev/null && pwd`
   datasetID=`basename $back_two` # Use the names from the canonical directory structure
fi

#
if [ "$1" == "-v" -a $# -ge 2 ]; then
   versionID="$2"
   shift 2
else 
   datasetDir=`pwd`
   versionID=`basename $datasetDir` # Use the names from the canonical directory structure
fi

CSV2RDF4LOD_BASE_URI=${CSV2RDF4LOD_BASE_URI:?"not set; source csv2rdf4lod/source-me.sh"}

TMP_SH=`date +%s`_$$.sh.tmp

echo "#!/bin/bash"                                                        > $TMP_SH
echo "# $datasetID $versionID ($lastModDate)"                          >> $TMP_SH

echo "#--------------------------------------------------------------" >> $TMP_SH
echo ""                                                                >> $TMP_SH
echo 'CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh"}' >> $TMP_SH
echo ""                                                                >> $TMP_SH
echo "surrogate=\"$CSV2RDF4LOD_BASE_URI\" # Came from \$CSV2RDF4LOD_BASE_URI when `basename $0` created this script." >> $TMP_SH
echo "sourceID=\"$sourceID\""                                          >> $TMP_SH
echo "datasetID=\"$datasetID\""                                        >> $TMP_SH
echo "datasetVersion=\"$versionID\"        # NO SPACES; Use curl -I -L http://www.data.gov/download/$datasetID/csv | grep "Last-Modified:" | awk '{printf("%s-%s-%s",$3,$4,$5)}'" >> $TMP_SH
echo "versionID=\"$versionID\"        # renaming datasetVersion (deprecating datasetVersion)"       >> $TMP_SH
echo "eID=\"1\"                             # enhancement identifier"  >> $TMP_SH
echo "if [ \$# -ge 2 ]; then"                                          >> $TMP_SH
echo "   if [ \$1 == \"-e\" ]; then"                                   >> $TMP_SH
echo "     eID=\"\$2\" "                                               >> $TMP_SH
echo "   fi"                                                           >> $TMP_SH
echo "fi"                                                              >> $TMP_SH
echo ""                                                                >> $TMP_SH
echo ""                                                                >> $TMP_SH
echo "# $1"                                                            >> $TMP_SH
echo "sourceDir=\"`dirname "$1"`\"                  # if directly from source, 'source'; if manual manipulations of source were required, 'manual'." >> $TMP_SH
echo "destDir=\"automatic\"                 # always 'automatic'"      >> $TMP_SH
echo "#--------------------------------------------------------------" >> $TMP_SH

if [ $# -gt 1 ]; then
   includeDiscriminator="yes"
else
   includeDiscriminator="no"
fi

while [ $# -gt 0 ]; do
   artifact="$1"

   echo ""                                                             >> $TMP_SH
   echo ""                                                             >> $TMP_SH
   echo "#-----------------------------------"                         >> $TMP_SH
   echo "datafile=\"`basename "$artifact"`\""                          >> $TMP_SH
   echo "data=\"\$sourceDir/\$datafile\""                              >> $TMP_SH
   if [ $includeDiscriminator == "yes" ]; then
      extensionlessFilename=`basename $artifact | sed 's/^\([^\.]*\)\..*$/\1/'` # failed to cast 'ce.supersector.csv' to 'ce.supersector'
      extensionlessFilename=`basename $artifact | sed 's/\.[^.]*$//'`
      # clean up %20 by replacing with underscore.
      echo "subjectDiscriminator=\"`echo $extensionlessFilename | sed 's/%20/-/g; s/_/-/g' | awk '{print tolower($0)}'`\" # Additional part of URI for subjects created; must be URI-ready (e.g., no spaces)." >> $TMP_SH
   else
      echo "subjectDiscriminator=               # Additional part of URI for subjects created; must be URI-ready (e.g., no spaces)." >> $TMP_SH
   fi
   echo "cellDelimiter=\"$cellDelimiter\"                   # ONLY one character; complain to http://sourceforge.net/projects/javacsv/ otherwise." >> $TMP_SH
   echo "header=                             # Line that header is on; only needed if not '1'. '0' means no header." >> $TMP_SH
   echo "dataStart=                          # Line that data starts; only needed if not immediately after header." >> $TMP_SH
   echo "repeatAboveIfEmptyCol=              # 'Fill in' value from row above for this column."                     >> $TMP_SH
   echo "onlyIfCol=                          # Do not process if value in this column is empty"                     >> $TMP_SH
   echo "interpretAsNull=                    # NO SPACES"              >> $TMP_SH
   echo "dataEnd=                            # Line on which data stops; only needed if non-data bottom matter (legends, footnotes, etc)." >> $TMP_SH
   #echo "source \$formats/csv/bin/convert.sh"                         >> $TMP_SH
   echo "source \$CSV2RDF4LOD_HOME/bin/convert.sh"                     >> $TMP_SH

   shift
done

echo ""                                                                >> $TMP_SH
echo ""                                                                >> $TMP_SH
echo "#-----------------------------------"                            >> $TMP_SH
#echo "source \$formats/csv/bin/convert-aggregate.sh"                  >> $TMP_SH
echo "source \$CSV2RDF4LOD_HOME/bin/convert-aggregate.sh"              >> $TMP_SH

if [ $writeSH == "yes" ]; then
   mv $TMP_SH convert-$datasetID.sh
   chmod +x convert-$datasetID.sh
else
   cat $TMP_SH
   rm $TMP_SH
fi
