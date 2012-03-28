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


# # # # # # --rq # # # # # #

if [ "$1" == "--rq" ]; then

   # replaced by is-pwd-a; pwd-not-a.sh below
   #if [[ `is-pwd-a.sh cr:dataset`            == "no" && \
   #      `is-pwd-a.sh cr:conversion-cockpit` == "no"      ]]; then
   #   echo "  Working directory does not appear to be a 'DATASET' directory."
   #   echo "  Run `basename $0` from a SOURCE directory (e.g. source/SOURCE/DATASET/)"
   #   echo ""
   #   echo "  Working directory does not appear to be a conversion cockpit."
   #   echo "  Run `basename $0` from a SOURCE directory (e.g. source/SOURCE/DATASET/version/VERSION/)"
   #   exit 1
   #fi
   #sourceID=`basename \`cd ../ 2>/dev/null && pwd\``
   #datasetID=`basename \`pwd\``

   # cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
   ACCEPTABLE_PWDs="cr:dataset cr:conversion-cockpit"
   if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
      ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
      exit 1
   fi

   sourceID=`cr-source-id.sh`
   datasetID=`cr-dataset-id.sh`

   echo "Creating rq/test for dataset $sourceID $datasetID"

   # # # # #
   echo rq/test/ask/present
   mkdir -p rq/test/ask/present &> /dev/null

   present="rq/test/ask/present/a-dataset-exists.rq"
   if [ ! -e $present ]; then
      echo $present
      echo `cr-default-prefixes.sh --sparql`                            >> $present
      perl -pi -e 's/.prefix/\nprefix/g'                                   $present
      echo                                                              >> $present
      echo "ASK"                                                        >> $present
      echo "WHERE {"                                                    >> $present
      echo "   GRAPH ?g {"                                              >> $present
      echo "      ?dataset a conversion:Dataset, void:Dataset ."        >> $present
      echo "   }"                                                       >> $present
      echo "}"                                                          >> $present
   else
      echo $present already exists. Not modifying.
   fi

   # # # # #
   echo rq/test/ask/absent
   mkdir -p rq/test/ask/absent  &> /dev/null

   absent="rq/test/ask/absent/impossible.rq"
   if [ ! -e $absent ]; then
      echo $absent
      echo `cr-default-prefixes.sh --sparql`               >> $absent
      perl -pi -e 's/.prefix/\nprefix/g'                      $absent
      echo                                                 >> $absent
      echo "ASK"                                           >> $absent
      echo "WHERE {"                                       >> $absent
      echo "   GRAPH ?g {"                                 >> $absent
      echo "      twi:TimLebo owl:sameAs twi:notTimLebo ." >> $absent
      echo "   }"                                          >> $absent
      echo "}"                                             >> $absent
   else
      echo $absent already exists. Not modifying.
   fi

   # # # # #
   echo rq/test/count/greater-than-or-equal-to/1
   mkdir -p rq/test/count/greater-than-or-equal-to/1  &> /dev/null

   # OBE by links-*.rq defaults
   #count=rq/test/count/greater-than-or-equal-to/1/datasets.rq
   #if [ ! -e $count ]; then
   #   echo $count
   #   echo `cr-default-prefixes.sh --sparql`                     >> $count
   #   perl -pi -e 's/.prefix/\nprefix/g'                            $count
   #   echo                                                       >> $count
   #   echo "SELECT ?dataset"                                     >> $count
   #   echo "WHERE {"                                             >> $count
   #   echo "   GRAPH ?g {"                                       >> $count
   #   echo "      ?dataset a conversion:Dataset, void:Dataset ." >> $count
   #   echo "   }"                                                >> $count
   #   echo "}"                                                   >> $count
   #else
   #   echo $count already exists. Not modifying.
   #fi

   # # # # #
   pushd rq/test/count/greater-than-or-equal-to/1 &> /dev/null
   cr-create-lodcloud-link-queries.py | awk '{print "rq/test/count/greater-than-or-equal-to/1/"$0}'
   popd &> /dev/null

   # # # # #
   echo rq/test/count/equal-to/1
   mkdir -p rq/test/count/equal-to/1  &> /dev/null

   count=rq/test/count/equal-to/1/datasets.rq
   if [ ! -e $count ]; then
      echo $count
      echo `cr-default-prefixes.sh --sparql`                     >> $count
      perl -pi -e 's/.prefix/\nprefix/g'                            $count
      echo                                                       >> $count
      echo "SELECT ?dataset"                                     >> $count
      echo "WHERE {"                                             >> $count
      echo "   GRAPH ?g {"                                       >> $count
      echo "      ?dataset a conversion:Dataset, void:Dataset ." >> $count
      echo "   }"                                                >> $count
      echo "}"                                                   >> $count
   else
      echo $count already exists. Not modifying.
   fi

   exit
fi


# # # # # # --catalog # # # # # #

if [ "$1" == "--catalog" ]; then

   if [[ `is-pwd-a.sh cr:data-root` == "yes" ]]; then
      for rq in `find . -type d -name rq | sed 's/^\.\///'`; do
         if [[ -d $rq/test ]]; then
            pushd `dirname $rq` &> /dev/null
               $0 $* # recursive call
            popd &> /dev/null
         fi
      done
      exit
   elif [[ -d rq/test ]]; then
      rq="."
      list="rq/test/list"
      echo `cr-pwd.sh`/$list.ttl
   elif [[ `is-pwd-a.sh cr:conversion-cockpit` == "yes" && -d ../../rq/test ]]; then
      rq="../../rq/test"
      list="../../rq/test/list"
      echo `pushd ../../ &>/dev/null; cr-pwd.sh; popd &>/dev/null`/rq/test/list.ttl
   else
      echo $0 $* 
      pwd-not-a.sh cr:data-root cr:dataset cr:conversion-cockpit 
      exit
   fi

   if [[ "$2" == "-w" ]]; then
      echo "@prefix earl: <http://www.w3.org/ns/earl#> ."  > $list.ttl
      echo ""                                             >> $list.ttl
   fi
   for test in `find $rq -name "*.rq" | sed 's/^\.\///'`; do
      if [[ "$2" == "-w" ]]; then
         echo "<$test> a earl:TestCase ."                 >> $list.ttl
      else
         echo "    $test"
      fi
   done 
   exit
fi



# # # # # # --show-catalog # # # # # #

if [ "$1" == "--show-catalog" ]; then
   for list in `cr-test-conversion.sh --catalog | grep "^s"`; do 
      echo ""
      echo $list; 
      echo ""
      path=${list#`cr-pwd.sh`}; 
      cat $path | sed 's/^/   /'; 
   done
   exit
fi

#if [ "$1" == "--cat-catalog" ]; then
#   for list in `cr-test-conversion.sh --catalog | grep "^s"`; do 
#      echo ""
#      echo $list; 
#      echo ""
#      path=${list#`cr-pwd.sh`}; 
#      cat $path | sed "s/^ *</$path/"; 
#   done
#   exit
#fi


# # # # # #  --setup # # # # # #

if [ "$1" == "--setup" ]; then
   shift
   export CSV2RDF4LOD_PUBLISH="true"
   if [[ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh cr:conversion-cockpit` == "yes" ]]; then
      # publish/bin/tdbloader-data-gov-au-catalog-2011-Jun-27.sh
      tdbloader="publish/bin/tdbloader-`${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh cr:conversion-cockpit --id-of s-d-v`.sh"
      if [[ ! -e $tdbloader ]]; then
         if [[ ! -e publish/bin/publish.sh ]]; then
            ./convert*.sh
         fi
         publish/bin/publish.sh
      fi
      # Make sure conversions are published.
      published="no"
      # error on other OS: "find: paths must precede expression: 0": for ttl in `find publish -depth 0 -name "*.ttl"`; do echo $ttl; published="yes"; done
      for ttl in `find publish -maxdepth 1 -name "*.ttl"`; do echo $ttl; published="yes"; done
      if [[ "$published" == "no" ]]; then
         echo "`basename $0` rerunning publish/bin/publish.sh b/c no publish/*.ttl"
         publish/bin/publish.sh
      fi
      # Make sure the published conversions are newer than the unpublished conversions.
      latestAutomaticTTL=`ls -lt automatic/*.ttl | grep ttl | head -1`
      latestPublishedTTL=`ls -lt   publish/*.ttl | grep ttl | head -1`
      if [[ $latestPublishedTTL -ot $latestAutomaticTTL ]]; then
         echo "`basename $0` rerunning publish/bin/publish.sh b/c publish/*.ttl older than automatic/*.ttl"
         publish/bin/publish.sh
      fi
      echo "[INFO] `basename $0` --setup with $tdbloader"
      $tdbloader
      echo "[INFO] `basename $0` --setup done with $tdbloader"
   else
      echo "https://github.com/timrdf/csv2rdf4lod-automation/issues/171"
   fi
fi


# # # # # # --help # # # # # #

if [ ${1-"."} == "--help" ]; then
   echo "usage: `basename $0`" # TODO: parameterize the rq directory.
   echo " --rq                   : Create initial rq/test/ask/{present,absent}/*.rq directory structure."
   echo " --setup                : Run tests, populate the tdb/ beforehand."
   echo " --setup {--verbose, -v}: Run tests, populate the tdb/ beforehand, and show query contents."
   echo "                        : Run tests. Needs rq/test or ../../rq/test and publish/tdb/."
   echo " {--verbose, -v}        : Run tests. Needs same as above. Shows the query contents while testing."
   echo " --catalog -w           : Find all rq/test and create rq/test/list.ttl rdf:typing them to earl:TestCase."
   echo " --catalog              : Show dryrun of finding all rq/test; print hypothetical contents of rq/test/list.ttl."
   echo " --show-catalog         : Show all rq/test/list.ttl"
   exit
fi



# # # # # # no parameters; run the tests # # # # # #

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

   # TODO: parameterize the tdb directory
   if [[ $rq =~ rq/test/ask/present.* || \
         $rq =~ rq/test/ask/absent.*  ]]; then
      response=`tdbquery --loc publish/tdb --query $rq 2>&1 | grep -v WARN`
   elif [[ $rq =~ rq/test/count/greater-than-or-equal-to.* || \
           $rq =~ rq/test/count/equal-to.*                 ]]; then
      response=`tdbquery --loc publish/tdb --query=$rq --results=XML 2>&1 | grep -v WARN | grep "<result>" | wc -l | sed 's/^[^0-9]*//'`
   fi

   if [[ $rq =~ rq/test/ask/present.* && $response =~ .*Yes.* || \
         $rq =~ rq/test/ask/absent.*  && $response =~ .*No.*  ]]; then
      result="passed"
      let "passed = passed + 1"
   elif [[ $rq =~ ../../rq/test/count/greater-than-or-equal-to.* ]]; then
      #            e.g. rq/test/count/greater-than-or-equal-to/1/datasets.rq
      threshold=`echo $rq | sed 's/^.*greater-than-or-equal-to\///; s/\/.*$//'` # Get the number
      if (( $response >= $threshold )); then
         result="passed"
         let "passed = passed + 1"
      else
         result="FAILED"
      fi
      response="$response >= $threshold"
   elif [[ $rq =~ ../../rq/test/count/equal-to.* ]]; then
      #            e.g. rq/test/count/equal-to/1/datasets.rq
      threshold=`echo $rq | sed 's/^.*equal-to\///; s/\/.*$//'` # Get the number
      if (( $response == $threshold )); then
         result="passed"
         let "passed = passed + 1"
      else
         result="FAILED"
      fi
      response="$response == $threshold"
   else
      result="FAILED"
   fi

   if [ $verbose == "true" ]; then

      if [ $result = "passed" ]; then
         fail=""
         echo "................................................................................"
      else
         fail="          \ \ \ FAIL / / /"
         echo "-\-!-*-!-!-!-*-!-*-!-!-!-*-!-*-!-!-!-*-!-*-!-!-!-*-!-*-!-!-!-*-!-*-!-!-!-*-!-!-/ $fail $fail $fail"
      fi

      echo "$rq ($response)"
      echo
      query=`cat $rq | grep -v -i "^prefix" | grep -v -i "^ASK" | grep -v -i "^WHERE" | grep -v -i "^ *GRAPH" | grep -v "^ *} *$" | grep -v "^ *$"`
      echo "$query"
      echo

   else
      report="                 "
      if [ $result != "passed" ]; then
         report=" ~ ~ ~ FAIL ~ ~ ~"
      fi
      echo "$report $rq $response"
   fi

done

echo "--------------------------------------------------------------------------------"
echo "$passed of $total passed"
