#!/bin/bash
#
# Script to retrieve and convert a new version of the dataset.
# See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Automated-creation-of-a-new-Versioned-Dataset

export CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER="true"
$CSV2RDF4LOD_HOME/bin/cr-create-versioned-dataset-dir.sh cr:auto                                         \
                                                        'http://explore.data.gov/download/5gah-bvex/CSV' \
                                                       --comment-character '#'                           \
                                                       --header-line        1                            \
                                                       --delimiter         ','
