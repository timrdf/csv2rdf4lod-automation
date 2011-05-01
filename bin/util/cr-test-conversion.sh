#!/bin/bash

#CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh"}

for rq in rq/*.rq; do response=`tdbquery --loc publish/tdb --query $rq 2>&1 | grep -v WARN`; echo $rq $response; done
