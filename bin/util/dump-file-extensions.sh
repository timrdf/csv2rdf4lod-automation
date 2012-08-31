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
# Determine the file extensions that should be used based on the serializations that will be produced.
# This avoids needing to manually determine and set it.

if [[ "$CSV2RDF4LOD_CONVERT_DUMP_FILE_EXTENSIONS" != "cr:auto" && "$1" != "--auto" ]]; then # and?
   echo $CSV2RDF4LOD_CONVERT_DUMP_FILE_EXTENSIONS
   exit
fi

gz=""
if [ "$CSV2RDF4LOD_PUBLISH_COMPRESS" == "true" ]; then
   gz=".gz" # NOTE: needs to sync with bin/convert-aggregate.sh (was .tgz)
fi

extensions="ttl$gz"

if [ "$CSV2RDF4LOD_PUBLISH_RDFXML" == "true" ]; then
   extensions="$extensions,rdf$gz"
fi

if [ "$CSV2RDF4LOD_PUBLISH_NT" == "true" ]; then
   extensions="$extensions,nt$gz"
fi

echo $extensions
