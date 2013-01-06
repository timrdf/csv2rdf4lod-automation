#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/too-big-for-rapper.sh>;
#3>    rdfs:seeAlso <https://github.com/timrdf/csv2rdf4lod-automation/wiki/Dealing-with-rapper%27s-2GB-limitation> .
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
# Return "yes" if any of the files listed are too big for rapper's 2GB limit.
# Otherwise, return "no".
#
# This logic is also in:
#
#    bin/convert-aggregate.sh
#    bin/util/pvload.sh
#    bin/util/rdf2nt.sh (to avoid csv2rdf4lod dependencies)


if [ $# -lt 1 ]; then
   echo "usage: `basename $0` a.ttl b.ttl ..."
   exit 1
fi
# TODO: This should have been done directly in bigttl2nt.sh with a flag like --is-too-big
too_big="no"
while [ $# -gt 0 ];do
   ttl="$1"
   for big in `find \`dirname $ttl\` -size +1900M -name \`basename $ttl\``; do
      too_big="yes"
   done
   shift
done
echo $too_big
