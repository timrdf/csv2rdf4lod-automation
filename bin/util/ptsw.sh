#
# <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/ptsw.sh>;
#    rdfs:seeAlso          <https://github.com/timrdf/csv2rdf4lod-automation/wiki/Ping-the-Semantic-Web> .
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
# http://pingthesemanticweb.com/api.php:
# Setting up a REST Client
# PingtheSemanticWeb.com accepts form-based HTTP POST and GET requests for non-extended pings. For example, the following is a valid HTTP GET ping request:
# 
# URL: http://pingthesemanticweb.com/rest/?url=[url]
# 
# Where [url] have to be replaced by the escaped URL of the FOAF or SIOC document to update.
# 
# Note: You have to escape the reserved characters: {";" | "/" | "?" | ":" | "@" | "&" | "=" | "+" | "$" | ","}
# Example HTTP GET request:
# http://pingthesemanticweb.com/rest/?url=http%3A//apassant.net/blog/sioc.php
# ; %3B
# / %2F
# ? %3F
# : %3A
# @ %40
# & %26
# = %3D
# + %2B
# $ %24
# , %2C

if [[ $# -lt 1 || "$1" == "--help" ]]; then
   echo
   echo "usage: `basename $0` [-v]"
   echo "   -v : verbose"
   echo
   exit
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
   encoded=`echo $url | perl -e 'use URI::Escape; @userinput = <STDIN>; foreach (@userinput) { chomp($_); print uri_escape($_); }'`
   echo "${tab}http://pingthesemanticweb.com/rest/?url=$encoded"
   shift
done
