#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/gzipped.sh>;
#3>    prov:wasDerivedFrom   <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/too-big-for-rapper.sh> .
#
# Return "yes" if any of the files listed gzipped.
# Otherwise, return "no".
#
# This logic is also in:
#    bin/util/rdf2nt.sh - was done before, can switch to this.

if [ $# -lt 1 ]; then
   echo "usage: `basename $0` a.ttl b.ttl ..."
   exit 1
fi

gzipped="no"
while [ $# -gt 0 ];do
   file="$1"
   if [ ! -f $file ]; then
      continue
   fi
   gunzip --test $file &> /dev/null
   if [ $? -eq 0 ]; then
      gzipped="yes"
   else
      gzipped="no"
   fi
   shift
done
echo $gzipped
