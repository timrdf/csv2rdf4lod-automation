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

if [ $# -ne 1 ]; then
   echo "usage: `basename $0` source/some.{rdf,ttl,nt}"
fi

if [ ! -d publish/bin ]; then
   mkdir -p publish/bin
fi

while [ $# -gt 0 ]; do
   rdfFile="$1"
   rdfFileBase=`basename $rdfFile`

   echo "$rdfFile.graph"
   if [ ! -e $rdfFile.graph ]; then
      cr-dataset-uri.sh | grep "^h" | tail -1 > $rdfFile.graph
   else 
      echo "   WARNING: publish/$rdfFile.void.ttl existed; not replacing"
   fi

   echo "publish/$rdfFileBase.void.ttl"
   if [ ! -e publish/$rdfFileBase.void.ttl ]; then
      #replaced by rr-create-void.sh: cr-dataset-uri.sh void > publish/$rdfFileBase.void.ttl
      rr-create-void.sh $rdfFile > publish/crawl.ttl.void.ttl
   else 
      echo "   WARNING: publish/$rdfFileBase.void.ttl existed; not replacing"
   fi

   echo "publish/bin/virtuoso-load.sh"
   echo "sudo /opt/virtuoso/scripts/vload ttl $rdfFile `cat $rdfFile.graph`" > publish/bin/virtuoso-load.sh
   chmod +x publish/bin/virtuoso-load.sh

   echo "publish/bin/virtuoso-delete.sh"
   echo "sudo /opt/virtuoso/scripts/vdelete `cat $rdfFile.graph`" > publish/bin/virtuoso-delete.sh
   chmod +x publish/bin/virtuoso-delete.sh

   echo "publish/bin/virtuoso-load-metadata.sh"
   echo "sudo /opt/virtuoso/scripts/vload ttl publish/$rdfFileBase.void.ttl http://logd.tw.rpi.edu/vocab/Dataset" > publish/bin/virtuoso-load-metadata.sh
   chmod +x publish/bin/virtuoso-load-metadata.sh

   shift
done
