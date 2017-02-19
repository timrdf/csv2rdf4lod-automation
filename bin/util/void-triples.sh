#!/bin/bash
#
# Note: taken from DataFAQs, now maintained in csv2rdf4lod-automation.

# rapper -g -c b.ttl 
# rapper: Parsing returned 17 triples

# TODO: handles large files, uses serdi when needed:
# rdf2nt.sh publish/lofd-tw-rpi-edu.nt.gz | rapper -i ntriples -c -I http://blah - 2>&1 | awk '$0~/Parsing returned/{print $4}'
# gunzip -c publish/c2tc-rl-af-mil-demo-2013-Jul-23.ttl.gz
#
# for ttl in `find automatic/ -name "*.ttl"`; do c=`void-triples.sh $ttl`; if [[ "$c" -gt 0 ]]; then echo "$c $ttl"; fi done
# 40 a.ttl
# 27 b.ttl


count=0
if [ $# -gt 0 ]; then

   while [ $# -gt 0 ]; do
      file="$1"
      if [ -e $file ]; then
         format=`guess-syntax.sh --inspect "$file" rapper`
         c=`rapper $format -c $file 2>&1 | grep "Parsing returned [^ ]* triple" | awk '{printf($4)}'`
         if [ ${#c} -gt 0 ]; then
            let "count=count+c"
         fi
      fi
      shift
   done

else
   if   [[ `is-pwd-a.sh cr:conversion-cockpit` == "yes" ]]; then

      count=`grep "void:triples" automatic/*.void.ttl | sed 's/^.*void:triples "//; s/[^0-9]*//g' | awk '{s+=$1} END {print s}'`

   else

      for possible in `find . -name "convert*.sh"`; do
         pushd `dirname $possible` > /dev/null
            c=`$0 $*` # Recursive call
            if [ ${#c} -gt 0 ]; then
               let "count=count+c"
            fi
         popd > /dev/null
      done

   fi
fi
echo $count
