#!/bin/bash
#
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/too-big-for-rapper.sh
#
# Return "yes" if any of the files listed are too big for rapper's 2GB limit.
# Otherwise, return "no".
#
# https://github.com/timrdf/csv2rdf4lod-automation/wiki/Dealing-with-rapper%27s-2GB-limitation

if [ $# -lt 1 ]; then
   echo "usage: `basename $0` a.ttl b.ttl ..."
   exit 1
fi

too_big="no"
while [ $# -gt 0 ];do
   ttl="$1"
   for big in `find \`dirname $ttl\` -size +1900M -name \`basename $ttl\``; do
      too_big="yes"
   done
   shift
done
echo $too_big
