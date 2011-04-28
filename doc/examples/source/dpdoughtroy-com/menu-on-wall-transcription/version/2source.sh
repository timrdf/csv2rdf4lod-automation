#!/bin/bash
#
# This script will set up a new version of the dpdoughtroy-com / menu-on-wall-transcription dataset 
# by retrieving the Google Spreadsheet at:
# https://spreadsheets.google.com/spreadsheet/ccc?pli=1&hl=en&key=t7_5xgxUiHibGpbWFPtVQLA&hl=en#gid=0
#
# and applying the enhancement parameters at:
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/doc/examples/source/dpdoughtroy-com/menu-on-wall-transcription/version/menu-on-wall-transcription.csv.e1.params.ttl
#
# to produce RDF.

export CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER=true
google2source.sh -w t7_5xgxUiHibGpbWFPtVQLA auto
