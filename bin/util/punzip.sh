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
#
# Usage:
#
# punzip.sh                            US-44-009-result.zip --> data.csv             and data.csv.prov.ttl
# punzip.sh -n US-44-009-result -e csv US-44-009-result.zip --> US-44-009-result.csv and US-44-009-result.csv.prov.ttl
# punzip.sh                     -e csv US-44-009-result.zip --> data.csv.csv         and data.csv.csv.prov.ttl 
# punzip.sh -n US-44-009-result        US-44-009-result.zip --> US-44-009-result     and US-44-009-result.prov.ttl

usage_message="usage: `basename $0` [-n filename] [-e file_extension] .zip [.zip ...]" 
if [[ $# -lt 1 || "$1" == "--help" ]]; then
   echo $usage_message 
   echo "  -n: filename to name every file coming out of the zip."
   echo "  -e: extension to use for every file coming out of the zip."
   exit 1
fi

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}


outfile_override=""
if [[ $1 == "-n" ]]; then
   outfile_override="$2" 
   echo "`basename $0` will use \"$outfile_override\" to name every file from the zip."
   shift 2
fi

outfile_extension_override=""
if [[ $1 == "-e" ]]; then
   outfile_extension_override="$2" 
   echo "`basename $0` will append \"$outfile_extension_override\" to every file from the zip."
   shift 2
fi

# TODO: reimplement this using perl and its unzip module.

# bash-3.2$ unzip -l state_combined_ak.zip
# Archive:  state_combined_ak.zip
#   Length     Date   Time    Name
#  --------    ----   ----    ----
#    995758  06-17-10 22:46   AK_ALTERNATIVE_NAME_FILE.CSV
#   1428574  06-17-10 22:47   AK_CONTACT_FILE.CSV
#   2234225  06-17-10 22:46   AK_ENVIRONMENTAL_INTEREST_FILE.CSV
#   3249731  06-17-10 22:46   AK_FACILITY_FILE.CSV
#   1342920  06-17-10 22:47   AK_MAILING_ADDRESS_FILE.CSV
#    312308  06-17-10 22:46   AK_NAICS_FILE.CSV
#   1841847  06-17-10 22:46   AK_ORGANIZATION_FILE.CSV
#    748588  06-17-10 22:46   AK_SIC_FILE.CSV
#    368039  06-17-10 22:47   AK_SUPP_INTEREST_FILE.CSV
#    286881  04-20-10 13:25   Facility State File Documentation 0401 2010.pdf
#  --------                   -------
#  12808871                   10 files

ZIP_LIST_HEADER_LENGTH=3
ZIP_LIST_FOOTER_LENGTH=2

logID=`resource-name.sh`
while [ $# -gt 0 ]; do

   zip="$1"
   if [ ! -e $zip ]; then
      echo "$zip does not exist"
      shift
      continue
   fi

   unzipper="unzip"
   if [[ $zip =~ (\.gz$) ]]; then # NOTE: alternative: ${zip#*.} == "gz"
      unzipper="gunzip"
   elif [[ $zip =~ .*\.tar$ ]]; then
      unzipper="tar"
   fi 
      myMD5=`${CSV2RDF4LOD_HOME}/bin/util/md5.sh $0`
   unzipMD5=`${CSV2RDF4LOD_HOME}/bin/util/md5.sh \`which $unzipper\``
   #echo "punzip.sh's md5: $myMD5"
   #echo "$unzipper's md5: $unzipMD5 (`which $unzipper`)"
   
   echo
   echo '/////------------------------------ punzip.sh  ------------------------------\\\\\'

   if [ `man stat | grep 't timefmt' | wc -l` -gt 0 ]; then
      # mac version
      zipModDateTime=`stat -t "%Y-%m-%dT%H:%M:%S%z" $zip | awk '{gsub(/"/,"");print $9}' | sed 's/^\(.*\)\(..\)$/\1:\2/'`
   elif [ `man stat | grep '%y     Time of last modification' | wc -l` -gt 0 ]; then
      # some other unix version
      zipModDateTime=`stat -c "%y" $zip | sed -e 's/ /T/' -e 's/\..* / /' -e 's/ //' -e 's/\(..\)$/:\1/'`
   fi

   usageDateTime=`dateInXSDDateTime.sh`

   files=""
   if [ $unzipper == "unzip" ]; then
      listLength=`unzip -l "$zip" | wc -l`
      let tailParam="$listLength-$ZIP_LIST_HEADER_LENGTH"
      let numFiles="$listLength-5"

      # NOTE: the line below ACTUALLY uncompresses the file(s)
      files=`unzip -l "$zip" | tail -$tailParam | head -$numFiles | awk -v zip="$zip" -v file_name="$outfile_override" -v file_extension="$outfile_extension_override" -f $CSV2RDF4LOD_HOME/bin/util/punzip.awk`
   elif [ $unzipper == "gunzip" ]; then
      files=${zip%.*}
   elif [ $unzipper == "tar" ]; then
      files=`tar -tf $zip` 
      # NOTE: the line below ACTUALLY uncompresses the file(s)
      tar -tf $zip
   else
      echo "WARNING: no files processed b/c "
   fi

   for file in $files; do

      if [ $unzipper == "gunzip" ]; then
         usageDateTime=`dateInXSDDateTime.sh`
         gunzip -c $zip > $file
      elif [ $unzipper == "tar" ]; then
         usageDateTime=`dateInXSDDateTime.sh`
         tar --file $zip --extract $file
      fi

      echo $file came from $zip
      requestID=`resource-name.sh`
      extractedFileMD5=`$CSV2RDF4LOD_HOME/bin/util/md5.sh $file`

      # Relative paths.
      fileURI="<$file>"
      sourceUsage="<sourceUsage$requestID>"
      nodeSet="<nodeSet$requestID>"
      zipNodeSet="<nodeSet${requestID}_zip_antecedent>"

      echo "@prefix rdfs:       <http://www.w3.org/2000/01/rdf-schema#> ."                       > $file.prov.ttl
      echo "@prefix xsd:        <http://www.w3.org/2001/XMLSchema#> ."                          >> $file.prov.ttl
      echo "@prefix dcterms:    <http://purl.org/dc/terms/> ."                                  >> $file.prov.ttl
      echo "@prefix nfo:        <http://www.semanticdesktop.org/ontologies/nfo/#> ."            >> $file.prov.ttl
      echo "@prefix pmlp:       <http://inference-web.org/2.0/pml-provenance.owl#> ."           >> $file.prov.ttl
      echo "@prefix pmlj:       <http://inference-web.org/2.0/pml-justification.owl#> ."        >> $file.prov.ttl
      echo "@prefix conv:       <http://purl.org/twc/vocab/conversion/> ."                      >> $file.prov.ttl
      echo "@prefix foaf:       <http://xmlns.com/foaf/0.1/> ."                                 >> $file.prov.ttl
      echo "@prefix sioc:       <http://rdfs.org/sioc/ns#> ."                                   >> $file.prov.ttl
      echo "@prefix oboro:      <http://obofoundry.org/ro/ro.owl#> ."                           >> $file.prov.ttl
      echo "@prefix prov:       <http://www.w3.org/ns/prov#>."                                  >> $file.prov.ttl
      echo "@prefix oprov:      <http://openprovenance.org/ontology#> ."                        >> $file.prov.ttl
      echo "@prefix hartigprov: <http://purl.org/net/provenance/ns#> ."                         >> $file.prov.ttl
      echo                                                                                      >> $file.prov.ttl
      $CSV2RDF4LOD_HOME/bin/util/user-account.sh                                                >> $file.prov.ttl
      echo                                                                                      >> $file.prov.ttl
      echo $fileURI                                                                             >> $file.prov.ttl
      echo "   a pmlp:Information, prov:Entity;"                                                >> $file.prov.ttl
      echo "   prov:wasQuotedFrom <$zip>;"                                                      >> $file.prov.ttl
      echo "   pmlp:hasReferenceSourceUsage $sourceUsage;"                                      >> $file.prov.ttl
      echo "."                                                                                  >> $file.prov.ttl
      $CSV2RDF4LOD_HOME/bin/util/nfo-filehash.sh "$file"                                        >> $file.prov.ttl
      echo                                                                                      >> $file.prov.ttl
      echo "$sourceUsage"                                                                       >> $file.prov.ttl
      echo "   a pmlp:SourceUsage;"                                                             >> $file.prov.ttl
      echo "   pmlp:hasSource        <$zip>;"                                                   >> $file.prov.ttl
      echo "   pmlp:hasUsageDateTime \"$usageDateTime\"^^xsd:dateTime;"                         >> $file.prov.ttl
      echo "."                                                                                  >> $file.prov.ttl
      echo                                                                                      >> $file.prov.ttl
      echo "<$zip>"                                                                             >> $file.prov.ttl
      echo "   a prov:Entity, pmlp:Source;"                                                     >> $file.prov.ttl
      if [ ${#zipModDateTime} -gt 0 ]; then
      echo "   pmlp:hasModificationDateTime \"$zipModDateTime\"^^xsd:dateTime;"                 >> $file.prov.ttl
      fi
      echo "."                                                                                  >> $file.prov.ttl
      echo                                                                                      >> $file.prov.ttl
      echo $nodeSet                                                                             >> $file.prov.ttl
      echo "   a pmlj:NodeSet;"                                                                 >> $file.prov.ttl
      echo "   pmlj:hasConclusion $fileURI;"                                                    >> $file.prov.ttl
      echo "   pmlj:isConsequentOf ["                                                           >> $file.prov.ttl
      echo "      a pmlj:InferenceStep;"                                                        >> $file.prov.ttl
      echo "      pmlj:hasIndex 0;"                                                             >> $file.prov.ttl
      echo "      pmlj:hasAntecedentList ( $zipNodeSet );"                                      >> $file.prov.ttl
      echo "      pmlj:hasSourceUsage     $sourceUsage;"                                        >> $file.prov.ttl
      echo "      pmlj:hasInferenceEngine conv:unzip_sh_md5_$myMD5;"                            >> $file.prov.ttl
      echo "      pmlj:hasInferenceRule   conv:spaceless_unzip;"                                >> $file.prov.ttl
      echo "      oboro:has_agent          `$CSV2RDF4LOD_HOME/bin/util/user-account.sh --cite`;">> $file.prov.ttl
      echo "      hartigprov:involvedActor `$CSV2RDF4LOD_HOME/bin/util/user-account.sh --cite`;">> $file.prov.ttl
      echo "   ];"                                                                              >> $file.prov.ttl
      echo "."                                                                                  >> $file.prov.ttl
      echo                                                                                      >> $file.prov.ttl
      echo $zipNodeSet                                                                          >> $file.prov.ttl
      echo "   a pmlj:NodeSet;"                                                                 >> $file.prov.ttl
      echo "   pmlj:hasConclusion <$zip>;"                                                      >> $file.prov.ttl
      echo "."                                                                                  >> $file.prov.ttl
      echo                                                                                      >> $file.prov.ttl
      echo "conv:unzip_sh_md5_$myMD5"                                                           >> $file.prov.ttl
      echo "   a pmlp:InferenceEngine, conv:Unzip_sh;"                                          >> $file.prov.ttl
      echo "   dcterms:identifier \"md5_$myMD5\";"                                              >> $file.prov.ttl
      echo "."                                                                                  >> $file.prov.ttl
      echo                                                                                      >> $file.prov.ttl
      echo "conv:Unzip_sh rdfs:subClassOf pmlp:InferenceEngine ."                               >> $file.prov.ttl
      echo                                                                                      >> $file.prov.ttl
      echo "conv:unzip_md5_$myMD5"                                                              >> $file.prov.ttl
      echo "   a pmlp:InferenceEngine, conv:Unzip;"                                             >> $file.prov.ttl
      echo "   dcterms:identifier \"md5_$unzipMD5\";"                                           >> $file.prov.ttl
      echo "   nfo:hasHash <md5_$unzipMD5>;"                                                    >> $file.prov.ttl
      echo "   dcterms:description \"\"\"`$unzipper --version 2>&1`\"\"\";"                     >> $file.prov.ttl
      echo "."                                                                                  >> $file.prov.ttl
      echo                                                                                      >> $file.prov.ttl
      echo "<md5_$unzipMD5>"                                                                    >> $file.prov.ttl
      echo "   a nfo:FileHash; "                                                                >> $file.prov.ttl
      echo "   nfo:hashAlgorithm \"md5\";"                                                      >> $file.prov.ttl
      echo "   nfo:hasHash \"$unzipMD5\";"                                                      >> $file.prov.ttl
      echo "."                                                                                  >> $file.prov.ttl
      echo                                                                                      >> $file.prov.ttl
      echo "conv:Unzip rdfs:subClassOf pmlp:InferenceEngine ."                                  >> $file.prov.ttl
      echo                                                                                      >> $file.prov.ttl
      if [[ $file =~ .*.tar ]]; then
         echo "Recursively uncompressing $file"
         $0 $file 
      fi
   done
   echo '\\\\\------------------------------ punzip.sh  ------------------------------/////'
   shift
done
