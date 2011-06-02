#!/bin/bash
#
# Script to retrieve and convert a new version of the dataset.
# See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Automated-creation-of-a-new-Versioned-Dataset

export CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER="true"
$CSV2RDF4LOD_HOME/bin/cr-create-versioned-dataset-dir.sh cr:auto                                                         \
                                                        'http://mkbergman.com/SweetTools/Sweet_Tools__v_171-slice-1.csv' \
                                                       --header-line        2                                            \
                                                       --delimiter         ','


