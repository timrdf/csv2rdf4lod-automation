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

if [ "$1" == "--rq" ]; then

   if [[ `is-pwd-a.sh cr:dataset`            == "no" && \
         `is-pwd-a.sh cr:conversion-cockpit` == "no"      ]]; then
      echo "  Working directory does not appear to be a 'DATASET' directory."
      echo "  Run `basename $0` from a SOURCE directory (e.g. source/SOURCE/DATASET/)"
      echo ""
      echo "  Working directory does not appear to be a conversion cockpit."
      echo "  Run `basename $0` from a SOURCE directory (e.g. source/SOURCE/DATASET/version/VERSION/)"
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
   exit
fi


# # # # # # End of --rq # # # # # #


if [ "$1" == "--catalog" ]; then

   if [[ `is-pwd-a.sh cr:data-root` == "yes" ]]; then
      for rq in `find . -type d -name rq | sed 's/^\.\///'`; do
         if [[ -d $rq/test ]]; then
            pushd `dirname $rq` &> /dev/null
               $0 $* # recursive call
            popd &> /dev/null
         fi
      done
   elif [[ -d rq/test ]]; then
      rq=`pwd`
      echo `cr-pwd.sh`/rq/test/list.ttl
      echo $*
      pushd $rq/test &> /dev/null
         if [[ "$2" == "-w" ]]; then
            echo writing from `pwd`...
            echo "@prefix earl: <http://www.w3.org/ns/earl#> ."  > list.ttl
            echo ""                                             >> list.ttl
         fi
         for test in `find . -name "*.rq" | sed 's/^\.\///'`; do
            if [[ "$2" == "-w" ]]; then
               echo "<$test> a earl:TestCase ." >> list.ttl
            else
               echo "    $test"
            fi
         done 
      popd &> /dev/null
   else
      pwd-not-a.sh cr:data-root cr:dataset cr:conversion-cockpit 
   fi
   exit
   # for list in `cr-test-conversion.sh --catalog | grep "^s"`; do path=${list#`cr-pwd.sh`}; echo $path; cat $path | sed 's/^/   /'; done
fi


# # # # # # End of --catalog # # # # # #


if [ "$1" == "--setup" ]; then
   shift
   export CSV2RDF4LOD_PUBLISH="true"
   if [[ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh cr:conversion-cockpit` == "yes" ]]; then
      # publish/bin/tdbloader-data-gov-au-catalog-2011-Jun-27.sh
      tdbloader="publish/bin/tdbloader-`${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh cr:conversion-cockpit s-d-v`.sh"
      if [[ ! -e $tdbloader ]]; then
         if [[ ! -e publish/bin/publish.sh ]]; then
            ./convert*.sh
         fi
         publish/bin/publish.sh
      fi
      $tdbloader
   else
      echo "https://github.com/timrdf/csv2rdf4lod-automation/issues/171"
   fi
fi


# # # # # # End of --setup # # # # # #


if [ ${1-"."} == "--help" ]; then
   echo "usage: `basename $0` [--verbose | -v]" # TODO: parameterize the rq directory.
fi

CSV2RDF4LOD_PUBLISH=true

# publish/bin/publish.sh
# publish/bin/tdbloader-test-source-delimits-object.sh

if [[ ! -e publish/tdb && ${#CSV2RDF4LOD_PUBLISH_TDB_DIR} == 0 ]]; then
   echo ""
   echo "`basename $0` can test from a conversion cockpit."
   echo "   but..."
   if [ `is-pwd-a.sh cr:conversion-cockpit` == "no" ]; then
      echo "   the current directory is not a conversion cockpit; see https://github.com/timrdf/csv2rdf4lod-automation/wiki/Conversion-cockpit"
   else
      echo "   publish/tdb does not exist and \$CSV2RDF4LOD_PUBLISH_TDB_DIR not set."
      echo "   export CSV2RDF4LOD_PUBLISH=true; export CSV2RDF4LOD_PUBLISH_TDB=true; publish/bin/publish.sh"
   fi
   echo ""
   echo "`basename $0` can test against any TDB directory."
   echo "   but..."
   echo "   \$CSV2RDF4LOD_PUBLISH_TDB_DIR is not set."
   echo ""
   echo "`basename $0` can run --rq from source/DDD/ or within a conversion cockpit."
   echo "   See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Script:-cr-test-conversion.sh"
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
