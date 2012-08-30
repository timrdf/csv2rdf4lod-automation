#!/bin/bash
#
#3> @prefix doap:    <http://usefulinc.com/ns/doap#> .
#3> @prefix dcterms: <http://purl.org/dc/terms/> .
#3> @prefix rdfs:    <http://www.w3.org/2000/01/rdf-schema#> .
#3> 
#3> <#>
#3>    a doap:Project; 
#3>    dcterms:description 
#3>      "Script to retrieve and convert a new version of the dataset.";
#3>    rdfs:seeAlso 
#3>      <https://github.com/timrdf/csv2rdf4lod-automation/wiki/Automated-creation-of-a-new-Versioned-Dataset>;
#3> .

export CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER="true"
$CSV2RDF4LOD_HOME/bin/cr-create-versioned-dataset-dir.sh cr:auto \
  'http://graves.cl/timrdf/csv2rdf4lod-automation/master/doc/examples/source/lebot/golfers/version/original/manual/golfers.xls.zip'

#3> <http://graves.cl/timrdf/csv2rdf4lod-automation/master/doc/examples/source/lebot/golfers/version/original/manual/golfers.xls.zip>
#3>   prov:wasDerivedFrom <https://github.com/timrdf/csv2rdf4lod-automation/raw/master/doc/examples/source/lebot/golfers/version/original/manual/golfers.xls.zip>;
#3>   prov:wasQuotedFrom  <https://github.com/timrdf/csv2rdf4lod-automation/raw/master/doc/examples/source/lebot/golfers/version/original/manual/golfers.xls.zip>;
#3>   prov:alternateOf    <https://github.com/timrdf/csv2rdf4lod-automation/raw/master/doc/examples/source/lebot/golfers/version/original/manual/golfers.xls.zip>;
#3>   frbr:reproductionOf <https://github.com/timrdf/csv2rdf4lod-automation/raw/master/doc/examples/source/lebot/golfers/version/original/manual/golfers.xls.zip>;
#3> .
