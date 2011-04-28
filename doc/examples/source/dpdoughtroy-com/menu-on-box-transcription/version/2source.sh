#!/bin/bash
#
# This script will set up a new version of the dpdoughtroy-com / menu-on-box-transcription dataset 
# by retrieving the Google Spreadsheet at:
# https://spreadsheets.google.com/spreadsheet/ccc?pli=1&hl=en&key=t5up1fIZHQWCl8A2frpfC_w&hl=en#gid=0
#
# and applying the enhancement parameters at:
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/doc/examples/source/dpdoughtroy-com/menu-on-box-transcription/version/2source.sh
#
# to produce RDF.

export CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER=true
google2source.sh -w t5up1fIZHQWCl8A2frpfC_w auto
