#!/bin/bash
#
# Homepage:
#   https://github.com/timrdf/csv2rdf4lod-automation/blob/master/doc/examples/source/iodp-org/publications/version/2source.sh
#
# Script to retrieve and convert a new version of the dataset.
# See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Automated-creation-of-a-new-Versioned-Dataset

export CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER="true"
$CSV2RDF4LOD_HOME/bin/cr-create-versioned-dataset-dir.sh cr:auto                                                 \
                                                        'http://dl.dropbox.com/u/20026306/IODPPubs/ODP_Pubs.csv' \
                                                       --header-line        1                                    \
                                                       --delimiter         ','
