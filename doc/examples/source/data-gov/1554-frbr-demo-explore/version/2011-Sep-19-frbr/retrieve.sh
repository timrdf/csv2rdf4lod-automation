#!/bin/bash
# 
# see http://purl.org/twc/pub/mccusker2012parallel for discussion of the use case that this script reproduces.

if [[ "$1" == "clean" ]]; then
   rm -f    source/us_economic_assistance.csv          #               Source data file (Use Case Event 1)
   rm -f    source/us_economic_assistance.csv.prov.ttl # Provenance of ^
   rm -rf automatic/*
   clean="clean"
fi

touch .use_case_started


# Retrieve

pushd source/ 2>&1 > /dev/null
   if [[ ! -e us_economic_assistance.csv || ! -e us_economic_assistance.csv.prov.ttl ]]; then
      rm -f us_economic_assistance.csv us_economic_assistance.csv.prov.ttl

      # Use Case Event 1: Data Integrator E retrieves http://explore.data.gov/download/5gah-bvex/CSV

      echo "Retrieving http://explore.data.gov/download/5gah-bvex/CSV"
      pcurl.py "http://explore.data.gov/download/5gah-bvex/CSV"
      cp us_economic_assistance.csv.prov.ttl ../doc/at_event_1.ttl
   fi
popd 2>&1 > /dev/null


# Use Case Event 2: Data Integrator W retrieves http://www.data.gov/download/1554/csv

if [ ! -d ../../../1554-frbr-demo-www/version/2011-Sep-19-frbr ]; then
   echo "need ../../../1554-frbr-demo-www/version/2011-Sep-19-frbr"
   echo "  git pull https://github.com/timrdf/csv2rdf4lod-automation/tree/master/doc/examples/source/data-gov/1554-frbr-demo-www/version/2011-Sep-19-frbr"
   echo "FAILED"
   exit 1 
fi
pushd ../../../1554-frbr-demo-www/version/2011-Sep-19-frbr 2>&1 > /dev/null
   touch .use_case_started
   ./retrieve.sh $clean
   touch .use_case_finished
popd > /dev/null


# Convert

if [[ ! -e automatic/us_economic_assistance.csv.raw.ttl || ! -e automatic/us_economic_assistance.csv.raw.void.ttl ]]; then

   # Use Case Event 3: Data Integrator E converts its local us_economic_assistance.csv to raw RDF

   ./convert-1554-frbr-demo-explore.sh # Perform the raw conversion
   grep-tail.sh -p "#-fstack raw yes"    source/us_economic_assistance.csv.prov.ttl      > doc/at_event_3.ttl
   grep-tail.sh -p "#-fstack raw yes" automatic/us_economic_assistance.csv.raw.void.ttl >> doc/at_event_3.ttl

   # Use Case Event 4: Data Integrator E reserializes the raw RDF from Turtle to RDF/XML syntax.

   rapper -g -o rdfxml automatic/us_economic_assistance.csv.raw.ttl     > automatic/us_economic_assistance.csv.raw.ttl.rdf
   fstack.py  --stdout automatic/us_economic_assistance.csv.raw.ttl.rdf > automatic/us_economic_assistance.csv.raw.ttl.rdf.prov.ttl
                                                                       cp automatic/us_economic_assistance.csv.raw.ttl.rdf.prov.ttl doc/at_event_4.ttl
fi

if [[ ! -e automatic/us_economic_assistance.csv.e1.ttl || ! -e automatic/us_economic_assistance.csv.e1.void.ttl ]]; then

   # Use Case Event 5: Data Integrator E converts its local us_economic_assistance.csv to enhanced RDF

   ./convert-1554-frbr-demo-explore.sh # Perform the enhanced conversion with ../e1.params.ttl
   grep-tail.sh -p "#-fstack raw no"    source/us_economic_assistance.csv.prov.ttl     > doc/at_event_5.ttl
   grep-tail.sh -p "#-fstack raw no" automatic/us_economic_assistance.csv.e1.void.ttl >> doc/at_event_5.ttl
fi

# Use Case Event 6: Both Data Integrators (E and W) publish their results on the web.

# Use Case Event 7: Data Consumer C must choose from among the seven data products. 



# Test the FRBR provenance produced.

rm -f publish/tdb/*
#tdbloader --loc=publish/tdb --graph=test    source/us_economic_assistance.csv.prov.ttl     # d/l + raw conversion input + e1 conversion input
#tdbloader --loc=publish/tdb --graph=test automatic/us_economic_assistance.csv.raw.void.ttl # raw      output + prov:wasDerivedFrom csv
#tdbloader --loc=publish/tdb --graph=test automatic/us_economic_assistance.csv.e1.void.ttl  # enhanced output + prov:wasDerivedFrom csv
tdbloader --loc=publish/tdb --graph=test doc/at_event*.ttl ../../../1554-frbr-demo-www/version/2011-Sep-19-frbr/doc/at_event*.ttl
cr-test-conversion.sh -v

touch .use_case_finished
echo "Files affected during use case:"
find . -newer .use_case_started -not -newer .use_case_finished | grep -v "^\.$" | grep -v ".use_case_finished" | sed 's/^\.\///' | grep -v "^publish" | grep -v "^doc/logs" | grep -v "_CSV2RDF4LOD_file_list.txt" | grep -v "^publish/bin"

# Data Integrator E's CSV vs. Data Integrator W's
event_2="../../../1554-frbr-demo-www/version/2011-Sep-19-frbr/doc/at_event_2.ttl"
rapper -g -o ntriples doc/at_event_1.ttl 2> /dev/null | awk -f doc/filter.awk  > doc/compare-events-1-2.nt
rapper -g -o ntriples $event_2           2> /dev/null | awk -f doc/filter.awk >> doc/compare-events-1-2.nt
rapper -g -o rdfxml                                                              doc/compare-events-1-2.nt   2> /dev/null > doc/compare-events-1-2.rdf
                                                                              rm doc/compare-events-1-2.nt

# Downloaded CSV vs. Raw RDF
rapper -g -o ntriples doc/at_event_1.ttl 2> /dev/null | awk -f doc/filter.awk  > doc/compare-events-1-3.nt
rapper -g -o ntriples doc/at_event_3.ttl 2> /dev/null | awk -f doc/filter.awk >> doc/compare-events-1-3.nt
rapper -g -o rdfxml                                                              doc/compare-events-1-3.nt   2> /dev/null > doc/compare-events-1-3.rdf
                                                                              rm doc/compare-events-1-3.nt

# Raw in Turtle vs. Raw in RDF/XML
rapper -g -o ntriples doc/at_event_3.ttl 2> /dev/null | awk -f doc/filter.awk  > doc/compare-events-3-4.nt
rapper -g -o ntriples doc/at_event_4.ttl 2> /dev/null | awk -f doc/filter.awk >> doc/compare-events-3-4.nt
rapper -g -o rdfxml                                                              doc/compare-events-3-4.nt   2> /dev/null > doc/compare-events-3-4.rdf
                                                                              rm doc/compare-events-3-4.nt

# Downloaded CSV, Raw RDF, and Enhanced RDF
rapper -g -o ntriples doc/at_event_1.ttl 2> /dev/null | awk -f doc/filter.awk  > doc/compare-events-1-3-5.nt
rapper -g -o ntriples doc/at_event_3.ttl 2> /dev/null | awk -f doc/filter.awk >> doc/compare-events-1-3-5.nt
rapper -g -o ntriples doc/at_event_5.ttl 2> /dev/null | awk -f doc/filter.awk >> doc/compare-events-1-3-5.nt
rapper -g -o rdfxml                                                              doc/compare-events-1-3-5.nt 2> /dev/null > doc/compare-events-1-3-5.rdf
                                                                              rm doc/compare-events-1-3-5.nt


 
