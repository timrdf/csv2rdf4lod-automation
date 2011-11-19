#
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/ptsw.sh
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

while [ $# -gt 0 ]; do
   url="$1"
   echo $url
   encoded=`echo $url | perl -e 'use URI::Escape; @userinput = <STDIN>; foreach (@userinput) { chomp($_); print uri_escape($_); }'`
   echo "   http://pingthesemanticweb.com/rest/?url=$encoded"
   shift
done
