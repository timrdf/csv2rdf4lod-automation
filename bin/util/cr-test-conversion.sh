#!/bin/bash
#
# Run from https://github.com/timrdf/csv2rdf4lod-automation/wiki/Conversion-cockpit
#
# Example for how to set up rq/:
#
# rq
# rq/test
# rq/test/ask
# rq/test/ask/absent
# rq/test/ask/absent/9-to-7.rq
# rq/test/ask/present
# rq/test/ask/present/0-to-2.rq
# rq/test/ask/present/2-to-3.rq
# rq/test/ask/present/3-to-5.rq
# rq/test/ask/present/3-to-7.rq
# rq/test/ask/present/5-to-1.rq
# rq/test/ask/present/7-to-5.rq

#CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh"}

if [ ${1-"."} == "--help" ]; then
   echo "usage: `basename $0` [--verbose]"
fi

verbose="false"
if [ ${1-"."} == "--verbose" -o ${1-"."} == "-v" ]; then
   verbose="true"
fi

let "passed = 0"
let "total  = 0"
for rq in `find rq/test -name "*.rq"`; do 

   let "total = total + 1"

   response=`tdbquery --loc publish/tdb --query $rq 2>&1 | grep -v WARN` 

   if [[ $rq =~ rq/test/ask/present.* && $response =~ .*Yes.*   ||   $rq =~ rq/test/ask/absent.* && $response =~ .*No.* ]]; then
      passedB="true"
      let "passed = passed + 1"
   else
      passedB="false"
   fi

   if [ $verbose == "true" ]; then

      if [ $passedB = "true" ]; then
         fail=""
         echo "................................................................................"
      else
         fail="          - - - FAIL - - -"
         echo "-\-!-*-!-!-!-*-!-*-!-!-!-*-!-*-!-!-!-*-!-*-!-!-!-*-!-*-!-!-!-*-!-*-!-!-!-*-!-!-/ $fail $fail $fail"
      fi

      echo "$rq ($response)"
      echo
      query=`cat $rq | grep -v "^prefix" | grep -v "^ASK" | grep -v "^WHERE" | grep -v "^ *GRAPH" | grep -v "^ *} *$" | grep -v "^ *$"`
      echo "$query"
      echo

   else
      echo $rq $response
   fi

done

echo "--------------------------------------------------------------------------------"
echo "$passed of $total passed"
