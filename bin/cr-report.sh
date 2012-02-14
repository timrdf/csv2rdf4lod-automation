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

back_one=`cd .. 2>/dev/null && pwd`
ANCHOR_SHOULD_BE_SOURCE=`basename $back_one`
if [ $ANCHOR_SHOULD_BE_SOURCE != "source" ]; then
   echo "  Working directory does not appear to be a SOURCE directory."
   echo "  Run `basename $0` from a SOURCE directory (e.g. csv2rdf4lod/data/source/SOURCE/)"
   exit 1
fi

source=`basename \`pwd\`` 
echo source: $source

exit 1

#find data.gov                                                          > automatic-reports/find-boulder-all.txt
#find ../boulder-svn/datagov/data.gov -name "*.e1.params.ttl"           > automatic-reports/find-boulder-svn-datagov-e1params.txt
#find ../boulder-svn/datagov/data.gov                                   > automatic-reports/find-boulder-svn-datagov.txt
#find ../boulder-svn/datagov-versioned/data.gov                         > automatic-reports/find-boulder-svn-versioned-datagov.txt
#find ../boulder-svn/datagov-versioned/data.gov -name "*.e1.params.ttl" > automatic-reports/find-boulder-svn-versioned-datagov-e1params.txt

echo "===== data url types ====="

# data.gov/997/urls.txt -> 997
find data.gov/* -name urls.txt -exec cat '{}' \; | sed -e 's/^.*\///' | sort -u

echo "===== reported ====="
grep "csv"  data.gov/*/urls.txt | sed -e 's/^data.gov.//' -e 's/\/.*$//' | sort -n > automatic-reports/datasets-reported-as-csv.csv
grep "xls"  data.gov/*/urls.txt | sed -e 's/^data.gov.//' -e 's/\/.*$//' | sort -n > automatic-reports/datasets-reported-as-xls.csv
grep "esri" data.gov/*/urls.txt | sed -e 's/^data.gov.//' -e 's/\/.*$//' | sort -n > automatic-reports/datasets-reported-as-esri.csv
grep "kml"  data.gov/*/urls.txt | sed -e 's/^data.gov.//' -e 's/\/.*$//' | sort -n > automatic-reports/datasets-reported-as-kml.csv
grep "xml"  data.gov/*/urls.txt | sed -e 's/^data.gov.//' -e 's/\/.*$//' | sort -n > automatic-reports/datasets-reported-as-xml.csv

wc -l automatic-reports/datasets-reported-as*.csv

echo "===== returning results ====="
find data.gov/*/version/*/source -name "*.[Cc][Ss][Vv]"     | awk -F/ '{print $2}' | sort -n -u > automatic-reports/datasets-returning-csv.csv
find data.gov/*/version/*/source -name "*.[Tt][Xx][Tt]"     | awk -F/ '{print $2}' | sort -n -u > automatic-reports/datasets-returning-txt.csv
find data.gov/*/version/*/source -name "*.[Xx][Ll][Ss]"     | awk -F/ '{print $2}' | sort -n -u > automatic-reports/datasets-returning-xls.csv
find data.gov/*/version/*/source -name "*.[Ee][Ss][Rr][Ii]" | awk -F/ '{print $2}' | sort -n -u > automatic-reports/datasets-returning-esri.csv
find data.gov/*/version/*/source -name "*.[Kk][Mm][Ll]"     | awk -F/ '{print $2}' | sort -n -u > automatic-reports/datasets-returning-kml.csv
find data.gov/*/version/*/source -name "*.[Xx][Mm][Ll]"     | awk -F/ '{print $2}' | sort -n -u > automatic-reports/datasets-returning-xml.csv
find data.gov/*/version/*/source -name "*.[Ee][Xx][Ee]"     | awk -F/ '{print $2}' | sort -n -u > automatic-reports/datasets-returning-exe.csv

wc -l automatic-reports/datasets-returning*.csv

echo "===== file extensions returned ====="
find data.gov/*/version/*/source -name "*.pml.ttl" | sed -e 's/\// /g' | awk '{file=$6;gsub(/.pml.ttl/,"",file); print $2,file}'| sed -e 's/\.\([^\.]*\)$/ \1/' | sort -n | awk '{if(NF==2)print $1,"-----",$2; else  print}' > automatic-reports/dataset-returned-extensions.csv
