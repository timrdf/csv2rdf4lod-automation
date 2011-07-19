#!/bin/bash
#
# See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Script:-cr-test-conversion.sh

ANCHOR_SHOULD_BE_A_DATASET=`basename \`cd ../../ 2>/dev/null && pwd\``
if [ $ANCHOR_SHOULD_BE_A_DATASET != "source" ]; then
   echo "  Working directory does not appear to be a 'DATASET' directory."
   echo "  Run `basename $0` from a SOURCE directory (e.g. csv2rdf4lod/data/source/SOURCE/DDD/)"
   exit 1
fi
sourceID=`basename \`cd ../ 2>/dev/null && pwd\``
datasetID=`basename \`pwd\``

echo "Creating rq/test for dataset $sourceID $datasetID"

# Convention:
echo rq/test/ask/present
mkdir -p rq/test/ask/present &> /dev/null

#
# Sample queries:
#

present="rq/test/ask/present/a-dataset-exists.rq"
if [ ! -e $present ]; then
   echo $present
   echo "prefix rdfs:       <http://www.w3.org/2000/01/rdf-schema#>" > $present
   echo "prefix void:       <http://rdfs.org/ns/void#>"              >> $present
   echo "prefix conversion: <http://purl.org/twc/vocab/conversion/>" >> $present
   echo ""                                                           >> $present
   echo "ASK"                                                        >> $present
   echo "WHERE {"                                                    >> $present
   echo "   GRAPH ?g {"                                              >> $present
   echo "      ?dataset a conversion:Dataset, void:Dataset ."        >> $present
   echo "   }"                                                       >> $present
   echo "}"                                                          >> $present
else
   echo $present already exists. Not modifying.
fi

echo rq/test/ask/absent
mkdir -p rq/test/ask/absent  &> /dev/null

absent="rq/test/ask/absent/impossible.rq"
if [ ! -e $absent ]; then
   echo $absent
   echo "prefix owl: <http://www.w3.org/2002/07/owl#>"   > $absent
   echo "prefix twi: <http://tw.rpi.edu/instances/>"    >> $absent
   echo ""                                              >> $absent
   echo "ASK"                                           >> $absent
   echo "WHERE {"                                       >> $absent
   echo "   GRAPH ?g {"                                 >> $absent
   echo "      twi:TimLebo owl:sameAs twi:notTimLebo ." >> $absent
   echo "   }"                                          >> $absent
   echo "}"                                             >> $absent
else
   echo $absent already exists. Not modifying.
fi
