#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/ping-sindice.sh>;
#3> <> prov:wasDerivedFrom   <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/ptsw.sh>;
#3>    rdfs:seeAlso          <https://github.com/timrdf/csv2rdf4lod-automation/wiki/Ping-the-Semantic-Web> .
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
#

if [[ $# -lt 1 || "$1" == "--help" ]]; then
   echo
   echo "usage: `basename $0` [-w] [-v]"
   echo "   -w : dryrun"
   echo "   -v : verbose"
   echo
   exit
fi

dryrun="true"
if [[ "$1" == "-w" || "$1" == "--write" ]]; then
   dryrun="false"
   shift
fi

verbose="false"
if [[ "$1" == "-v" || "$1" == "--verbose" ]]; then
   verbose="true"
   shift
fi

while [ $# -gt 0 ]; do
   url="$1"
   $tab
   if [ "$verbose" == "true" ]; then
      echo $url
      tab="   "
   fi
   if [[ ! -e "$url" ]]; then
      echo curl -H \"Accept: text/plain\" --data-binary \"$1\" http://sindice.com/api/v2/ping
      if [[ "$dryrun" != "true" && ! -e "$url" ]]; then
         curl -H "Accept: text/plain" --data-binary "$1" http://sindice.com/api/v2/ping
      fi
   fi
   shift
done
