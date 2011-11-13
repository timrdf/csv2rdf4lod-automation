#!/bin/bash
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/cr-dataset-id.sh
#
# Return the source identifier, based on
# https://github.com/timrdf/csv2rdf4lod-automation/wiki/Directory-Conventions

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh cr:bone --id-of dataset
