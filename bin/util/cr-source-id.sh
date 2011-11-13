#!/bin/bash
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/cr-source-id.sh
#
# Return the source identifier, based on
# https://github.com/timrdf/csv2rdf4lod-automation/wiki/Directory-Conventions
${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh cr:bone --id-of source
