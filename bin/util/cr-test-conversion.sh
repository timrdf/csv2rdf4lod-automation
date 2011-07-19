#!/bin/bash
#
# See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Script:-cr-test-conversion.sh
#
# Run from a https://github.com/timrdf/csv2rdf4lod-automation/wiki/Conversion-cockpit
#
# Requires the following structure in an rq/ directory:
#
# rq
# rq/test
# rq/test/ask
# rq/test/ask/absent
# rq/test/ask/absent/9-to-7.rq (the filename is up to you)
# rq/test/ask/present
# rq/test/ask/present/0-to-2.rq (the filename is up to you)
# rq/test/ask/present/2-to-3.rq (the filename is up to you)
#
# This script assumes a particular syntactic structure to abbreviate the query when showing execution output:
# (use this same capitalization and indenting)
#
# ...
# ASK
# WHERE {
#    GRAPH ?g {
#       ...
#    }
# }
#
# Script assumes the publish/tdb/ directory is already with the data to test.
# This can be done by running publish/bin/publish.sh
# and then publish/bin/tdbloader-*.sh

#CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

if [ ${1-"."} == "--help" ]; then
   echo "usage: `basename $0` [--verbose | -v]" # TODO: parameterize the rq directory.
fi

CSV2RDF4LOD_PUBLISH=true

# publish/bin/publish.sh
# publish/bin/tdbloader-test-source-delimits-object.sh

if [[ ! -e publish/tdb && ${#CSV2RDF4LOD_PUBLISH_TDB_DIR} == 0 ]]; then
   echo "publish/tdb does not exist and \$CSV2RDF4LOD_PUBLISH_TDB_DIR not set."
   echo "export CSV2RDF4LOD_PUBLISH=true; export CSV2RDF4LOD_PUBLISH_TDB=true; publish/bin/publish.sh"
   exit 1
fi

verbose="false"
if [ ${1-"."} == "--verbose" -o ${1-"."} == "-v" ]; then
   verbose="true"
fi

rq_dir="rq/test"
if [ ! -d $rq_dir -a -d '../../rq/test' ]; then
   rq_dir="../../rq/test"
fi

let "passed = 0"
let "total  = 0"
for rq in `find $rq_dir -name "*.rq"`; do 

   let "total = total + 1"

   response=`tdbquery --loc publish/tdb --query $rq 2>&1 | grep -v WARN` # TODO: parameterize the tdb directory

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
