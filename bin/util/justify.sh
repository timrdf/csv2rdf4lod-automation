#!/bin/bash
#
# Usage:
#
#   justify.sh 
#

usage_message="usage: `basename $0` /path/to/source/a.xls /path/to/destination/a.xls.csv <engine-name>" 

if [ $# -ne 3 ]; then
   echo $usage_message 
   echo "   engine-name: xls2csv, tab2comma, redelimit, file_rename, escaping_commas_redelimit etc. (URI-friendly)"
   echo "                duplicate, google_refine"
   exit 1
fi

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh"}

# md5 this script
# TODO: $CSV2RDF4LOD_HOME/bin/util/md5.sh
punzipMD5=""
if [ `which md5` ]; then
   # md5 outputs:
   # MD5 (punzip.sh) = ecc71834c2b7d73f9616fb00adade0a4
   punzipMD5="_md5_`md5 $0 | perl -pe 's/^.* = //'`"
elif [ `which md5sum` ]; then
   punzipMD5="_md5_`md5sum $0 | perl -pe 's/\s.*//'`"
else
   echo "`basename $0`: can not find md5 to md5 this script."
fi


# TODO: reimplement this using perl and its unzip module

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

alias rname="java edu.rpi.tw.string.NameFactory"
#logID=`rname`
logID=`java edu.rpi.tw.string.NameFactory`
#while [ $# -gt 0 ]; do
   antecedent="$1"
   consequent="$2"
   engine_name="xls2csv"
   engine_name="`echo $3 | awk '{print tolower($0)}'`"
   engine_nameUP="`echo $3 | awk '{print toupper($0)}'`"

   if [ ! -e $antecedent ]; then
      echo "$antecedent does not exist; no justifications asserted."
      exit 1
   fi
   if [ ! -e $consequent ]; then
      echo "$consequent does not exist; no justifications asserted."
      exit 1
   fi
   echo
   echo ---------------------------------- justify ---------------------------------------
   echo "$antecedent -> $consequent"
   if [ `man stat | grep 'BSD General Commands Manual' | wc -l` -gt 0 ]; then
      # mac version
      antecedentModDateTime=`stat -t "%Y-%m-%dT%H:%M:%S%z" $antecedent | awk '{gsub(/"/,"");print $9}' | sed 's/^\(.*\)\(..\)$/\1:\2/'`
      consequentModDateTime=`stat -t "%Y-%m-%dT%H:%M:%S%z" $consequent | awk '{gsub(/"/,"");print $9}' | sed 's/^\(.*\)\(..\)$/\1:\2/'`
   elif [ `man stat | grep '%y     Time of last modification' | wc -l` -gt 0 ]; then
      # some other unix version
      antecedentModDateTime=`stat -c "%y" $antecedent | sed -e 's/ /T/' -e 's/\..* / /' -e 's/ //' -e 's/\(..\)$/:\1/'`
      consequentModDateTime=`stat -c "%y" $consequent | sed -e 's/ /T/' -e 's/\..* / /' -e 's/ //' -e 's/\(..\)$/:\1/'`
   fi

   #usageDateTime=`date +%Y-%m-%dT%H:%M:%S%z | sed 's/^\(.*\)\(..\)$/\1:\2/'`
   usageDateTime=`$CSV2RDF4LOD_HOME/bin/util/dateInXSDDateTime.sh`
   #for file in `unzip -l "$zip" | tail -$tailParam | head -$numFiles | awk -v zip="$zip" -f $CSV2RDF4LOD_HOME/bin/util/punzip.awk`
   #do
      echo $consequent came from $antecedent
      requestID=`java edu.rpi.tw.string.NameFactory`

      # Relative paths.
      consequentURI="<`basename $consequent`>"
      sourceUsage="<sourceUsage$requestID>"
      nodeSet="<nodeSet$requestID>"
      antecedentNodeSet="<nodeSet${requestID}_antecedent>"
      userNodeSet="<nodeSet${requestID}_user>"
      userURI="<user${requestID}>"

      echo "@prefix rdfs:    <http://www.w3.org/2000/01/rdf-schema#> ."                   > $consequent.pml.ttl
      echo "@prefix xsd:     <http://www.w3.org/2001/XMLSchema#> ."                      >> $consequent.pml.ttl
      echo "@prefix foaf:    <http://xmlns.com/foaf/0.1/> ."                             >> $consequent.pml.ttl
      echo "@prefix dcterms: <http://purl.org/dc/terms/> ."                              >> $consequent.pml.ttl
      echo "@prefix sioc:    <http://rdfs.org/sioc/ns#> ."                               >> $consequent.pml.ttl
      echo "@prefix pmlp:    <http://inference-web.org/2.0/pml-provenance.owl#> ."       >> $consequent.pml.ttl
      echo "@prefix pmlj:    <http://inference-web.org/2.0/pml-justification.owl#> ."    >> $consequent.pml.ttl
      echo "@prefix conv:    <http://purl.org/twc/vocab/conversion/> ."                  >> $consequent.pml.ttl
      echo                                                                               >> $consequent.pml.ttl
      echo $consequentURI                                                                >> $consequent.pml.ttl
      echo "   a pmlp:Information;"                                                      >> $consequent.pml.ttl
      echo "   pmlp:hasModificationDateTime \"$consequentModDateTime\"^^xsd:dateTime;"   >> $consequent.pml.ttl
      #echo "   pmlp:hasReferenceSourceUsage $sourceUsage;"                               >> $consequent.pml.ttl
      echo "."                                                                           >> $consequent.pml.ttl
      echo                                                                               >> $consequent.pml.ttl
      #echo "$sourceUsage"                                                                >> $consequent.pml.ttl
      #echo "   a pmlp:SourceUsage;"                                                      >> $consequent.pml.ttl
      #echo "   pmlp:hasSource        <$antecedent>;"                                     >> $consequent.pml.ttl
      #echo "   pmlp:hasUsageDateTime \"$usageDateTime\"^^xsd:dateTime;"                  >> $consequent.pml.ttl
      #echo "."                                                                           >> $consequent.pml.ttl
      #echo                                                                               >> $consequent.pml.ttl
      echo "<../$antecedent>"                                                            >> $consequent.pml.ttl
      echo "   a pmlp:Information;"                                                      >> $consequent.pml.ttl
      echo "   pmlp:hasModificationDateTime \"$antecedentModDateTime\"^^xsd:dateTime;"   >> $consequent.pml.ttl
      echo "."                                                                           >> $consequent.pml.ttl
      echo                                                                               >> $consequent.pml.ttl
      echo $nodeSet                                                                      >> $consequent.pml.ttl
      echo "   a pmlj:NodeSet;"                                                          >> $consequent.pml.ttl
      echo "   pmlj:hasConclusion $consequentURI;"                                       >> $consequent.pml.ttl
      echo "   pmlj:isConsequentOf ["                                                    >> $consequent.pml.ttl
      echo "      a pmlj:InferenceStep;"                                                 >> $consequent.pml.ttl
      echo "      pmlj:hasIndex 0;"                                                      >> $consequent.pml.ttl
      echo "      pmlj:hasAntecedentList ( $antecedentNodeSet $userNodeSet );"           >> $consequent.pml.ttl
      #echo "      pmlj:hasSourceUsage     $sourceUsage;"                                >> $consequent.pml.ttl
      echo "      pmlj:hasInferenceEngine <$engine_name$requestID>;"                     >> $consequent.pml.ttl
      echo "      pmlj:hasInferenceRule   conv:${engine_name}_Method;"                   >> $consequent.pml.ttl
      echo "   ];"                                                                       >> $consequent.pml.ttl
      echo "."                                                                           >> $consequent.pml.ttl
      echo                                                                               >> $consequent.pml.ttl
      echo $antecedentNodeSet                                                            >> $consequent.pml.ttl
      echo "   a pmlj:NodeSet;"                                                          >> $consequent.pml.ttl
      echo "   pmlj:hasConclusion <$antecedent>;"                                        >> $consequent.pml.ttl
      echo "."                                                                           >> $consequent.pml.ttl
      echo ""                                                                            >> $consequent.pml.ttl
      echo $userNodeSet                                                                  >> $consequent.pml.ttl
      echo "   a pmlj:NodeSet;"                                                          >> $consequent.pml.ttl
      echo "   pmlp:hasConclusion $userURI;"                                             >> $consequent.pml.ttl
      echo "."                                                                           >> $consequent.pml.ttl
      echo ""                                                                            >> $consequent.pml.ttl
      echo "$userURI"                                                                    >> $consequent.pml.ttl
      echo "   foaf:accountName \"`whoami`\";"                                           >> $consequent.pml.ttl
      echo "."                                                                           >> $consequent.pml.ttl
      echo ""                                                                            >> $consequent.pml.ttl
      echo "<$engine_name$requestID>"                                                    >> $consequent.pml.ttl
      echo "   a pmlp:InferenceEngine, conv:${engine_nameUP}Engine;"                     >> $consequent.pml.ttl
      echo "   dcterms:identifier \"$engine_name$requestID\";"                           >> $consequent.pml.ttl
      echo "."                                                                           >> $consequent.pml.ttl
      echo                                                                               >> $consequent.pml.ttl
      echo "conv:${engine_nameUP}Engine rdfs:subClassOf pmlp:InferenceEngine ."          >> $consequent.pml.ttl
   #done
   echo --------------------------------------------------------------------------------
   shift
#done
