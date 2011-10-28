#!/bin/bash
#
#3> @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
#3> <>
#3> rdfs:comment 
#3> "Script to retrieve and convert a new version of the dataset.";
#3> rdfs:seeAlso 
#3> <https://github.com/timrdf/csv2rdf4lod-automation/wiki/Automated-creation-of-a-new-Versioned-Dataset>,
#3> <https://github.com/timrdf/csv2rdf4lod-automation/wiki/tic-turtle-in-comments>;
#3> .

export CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER="true"
google2source.sh -w 0ArTeDpS4-nUDdGFQcDU4YVhMYmtWQjFyenlsQnhYWkE auto
