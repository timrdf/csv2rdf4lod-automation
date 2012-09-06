#!/bin/bash
#
# Note taken from DataFAQs, now maintained in csv2rdf4lod-automation.

# rapper -g -c b.ttl 
# rapper: Parsing returned 17 triples

count=0
while [ $# -gt 0 ]; do
   file="$1"
   if [ -e $file ]; then
      c=`rapper -g -c $file 2>&1 | grep "Parsing returned [^ ]* triples" | awk '{printf($4)}'`
      if [ ${#c} -gt 0 ]; then
         let "count=count+c"
      fi
   fi
   shift
done
echo $count
