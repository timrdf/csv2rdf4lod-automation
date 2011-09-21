#!/bin/bash
# 
# see http://purl.org/twc/pub/mccusker2012parallel for discussion of the use case that this script reproduces.

if [[ "$1" == "clean" ]]; then
   rm -f source/us_economic_assistance.csv          #               Source data file (Use Case Event 1)
   rm -f source/us_economic_assistance.csv.prov.ttl # Provenance of ^
fi

# (Use Case Event 1 is the other data integrator retrieving http://explore.data.gov/download/5gah-bvex/CSV)

# Retrieve

pushd source/ 2>&1 > /dev/null
   if [[ ! -e us_economic_assistance.csv || ! -e us_economic_assistance.csv.prov.ttl ]]; then
      rm -f us_economic_assistance.csv us_economic_assistance.csv.prov.ttl
      echo "Retrieving http://www.data.gov/download/1554/csv"
      # Use Case Event 2:
      pcurl.py "http://www.data.gov/download/1554/csv"
      cp us_economic_assistance.csv.prov.ttl ../doc/at_event_2.ttl
   fi
pushd 2>&1 > /dev/null
