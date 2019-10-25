#
#   Copyright 2012 Timothy Lebo
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

# _NOTE_    setup.sh (this file) is a template used by install.sh to create source-me.sh.
# _WARNING_ setup.sh (this file) should not be edited. Edit my-csv2rdf4lod-source-me.sh.
# if path of cr-vars.sh 
# is /Users/me/Desktop/csv2rdf4lod-automation/bin/cr-vars.sh
# CSV2RDF4LOD_HOME should be set (above) to /Users/me/Desktop/csv2rdf4lod-automation/

# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/setup.sh
# https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-environment-variables

# The following variables may be modified to customize csv2rdf4lod.

#
# ------- ------- CKAN options ------- -------
#

#
# Customize: 
# Variable type: Machine ? Project ? User ? Activity ?
#
# (used in mirror.py)
#
# a conversion:ProjectLevelEnvironmentVariable
export CSV2RDF4LOD_CKAN="true"
export CSV2RDF4LOD_CKAN="false"

#
# Customize: This csv2rdf4lod node is pulling datasets from a third party CKAN.
#
# Variable type: Machine ? Project ? User ? Activity ?
#
# (used in mirror.py)
#
# a conversion:ProjectLevelEnvironmentVariable
export CSV2RDF4LOD_CKAN_SOURCE="http://hub.healthdata.gov"
export CSV2RDF4LOD_CKAN_SOURCE=""

#
# Customize: This csv2rdf4lod has its own writable CKAN instance.
#
# Variable type: Machine ? Project ? User ? Activity ?
#
# (used in mirror.py)
#
# a conversion:ProjectLevelEnvironmentVariable
export CSV2RDF4LOD_CKAN_WRITABLE="http://healthdata.tw.rpi.edu/hub"
export CSV2RDF4LOD_CKAN_WRITABLE=""

#
# Customize: 
# Variable type: Machine ? Project ? User ? Activity ?
#
# (used in mirror.py)
#
# a conversion:ProjectLevelEnvironmentVariable
export X_CKAN_API_Key="https://github.com/timrdf/DataFAQs/wiki/Missing-CKAN-API-Key"
export X_CKAN_API_Key=""

#
# ------- ------- converting options ------- -------
#

#
# Customize: The converter to use.
#   Converter must accept parameters as specified at 
#   http://data-gov.tw.rpi.edu/wiki/Csv2rdf4lod
# Variable type: Machine ? Project ? User ? Activity ?
#
# If not set, defaults to 'java -Xmx3060m edu.rpi.tw.data.csv.CSVtoRDF'
#
# (used in $CSV2RDF4LOD_HOME/bin/convert.sh
#    to invoke the converter.)
#
# a conversion:ProjectLevelEnvironmentVariable
export CSV2RDF4LOD_CONVERTER=""

#
# Customize: The base URI of the final published linked data.
#
# Variable type: Machine Y Project Y User N Activity N
#
# (used in cr-create-convert-sh.sh 
#    to set variable used to create enhancement templates.)
# (used in convert-aggregate.sh)
#
# see https://github.com/timrdf/csv2rdf4lod-automation/wiki/Conversion-process-phase:-name
#
export CSV2RDF4LOD_BASE_URI="http://logd.tw.rpi.edu"
export CSV2RDF4LOD_BASE_URI="https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD_BASE_URI#"

#
# Customize: A base URI to use in place of CSV2RDF4LOD_BASE_URI
# when converting. 
# Variable type: Machine ? Project ? User ? Activity ?
#
# While CSV2RDF4LOD_BASE_URI is used as the 
# conversion:base_uri when creating conversion parameters
# and enhancement templates, CSV2RDF4LOD_BASE_URI_OVERRIDE
# will override this parameter during conversion. 
#
# This is useful when developing for one domain name and 
# testing deployment using another.
#
# (used in convert-aggregate.sh)
#
# a conversion:ActivityLevelEnvironmentVariable
export CSV2RDF4LOD_BASE_URI_OVERRIDE="http://tw2.tw.rpi.edu"
export CSV2RDF4LOD_BASE_URI_OVERRIDE=""

#
# Customize: Inspect the files (with DROID) and record 
# their formats in source/cr-droid.ttl
#
# Variable type: Machine ? Project ? User ? Activity ?
#
#
# (used in bin/cr-create-versioned-dataset-dir.sh)
#
# a conversion:
export CSV2RDF4LOD_RETRIEVE_DROID_SOURCES="false"
export CSV2RDF4LOD_RETRIEVE_DROID_SOURCES="true"

#
# Customize: The URI for the machine that is running the conversions.
# Variable type: Machine ? Project ? User ? Activity ?
#
# Used to create URIs for `whoami` user names
#
# (used in convert.sh and util/header2params2.awk)
#
# a conversion:MachineLevelEnvironmentVariable
export CSV2RDF4LOD_CONVERT_MACHINE_URI="http://tw.rpi.edu/web/inside/machine/gemini"
export CSV2RDF4LOD_CONVERT_MACHINE_URI=""

#
# Customize: The URI for the person invoking the conversions.
#
# Variable type: Machine N Project N User Y Activity N
#
# Each person running on the same machine should set this in their own environment.
#
# (used in convert.sh and util/header2params2.awk)
#
export CSV2RDF4LOD_CONVERT_PERSON_URI="http://tw.rpi.edu/instances/notTimLebo"
export CSV2RDF4LOD_CONVERT_PERSON_URI=""

#
# Customize: 
#
# Variable type: Machine N Project Y User Y Activity N
#
# This is '/source/' as described in "Starting a Data Directory (source/)" at 
# https://github.com/timrdf/csv2rdf4lod-automation/wiki/Conversion-process-phase:-retrieve
#
# This is ONLY required to avoid a redundant file copy when loading into Virtuoso.
# If it is not set, things will still work but we waste time and disk space.
#
# (used in
#  https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/cr-load-endpoint-metadata.sh
#  https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/virtuoso/vload)
#
export CSV2RDF4LOD_CONVERT_DATA_ROOT="/projects/lobd/data/source"
export CSV2RDF4LOD_CONVERT_DATA_ROOT=""

#
# Customize: 'git pull' the converter repository every time 
#             the conversion trigger is pulled.
#
# Variable type: Machine ? Project ? User ? Activity ?
#
# (used in convert.sh)
#
# a conversion:ProjectLevelEnvironmentVariable
# a conversion:ActivityLevelEnvironmentVariable
export CSV2RDF4LOD_CONVERT_ALWAYS_UPDATE_CONVERTER="true"
export CSV2RDF4LOD_CONVERT_ALWAYS_UPDATE_CONVERTER="false"

#
# Customize: Prevent the naive interpretation of tabular data ("raw" layer).
# Variable type: Machine ? Project ? User ? Activity ?
#
# (used in convert.sh)
#
# a conversion:ProjectLevelEnvironmentVariable
# a conversion:ActivityLevelEnvironmentVariable
export CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER="true"
export CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER="false"

#
# Customize: Number of rows to include in an example subset.
# Variable type: Machine ? Project ? User ? Activity ?
#
# Subset is stored in file(s): automatic/$datafile.raw.sample.ttl
#                              automatic/$datafile.e1.sample.ttl
#                              automatic/$datafile.e2.sample.ttl
#                              (etc.)
#
# Setting this to a number > 0 creates a small subset of the output.
#
# If 0, the sample is not computed and no file is written.
#
# (used in convert.sh)
#
# a conversion:ProjectLevelEnvironmentVariable
# a conversion:ActivityLevelEnvironmentVariable
export CSV2RDF4LOD_CONVERT_SAMPLE_NUMBER_OF_ROWS="100"
export CSV2RDF4LOD_CONVERT_SAMPLE_NUMBER_OF_ROWS="10"

#
# Customize: Omit the full conversion of the dataset.
# Variable type: Machine ? Project ? User ? Activity ?
#
# When developing the enhancement parameters, it is helpful
# to only convert the first few rows because the conversion will be
# inspected and rerun right away.
# 
# Setting this to 'true' will prevent the full conversion.
#
# See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Generating-a-sample-conversion-using-only-a-subset-of-data
#     https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD_CONVERT_EXAMPLE_SUBSET_ONLY
# (used in convert.sh)
#
# a conversion:ProjectLevelEnvironmentVariable
# a conversion:ActivityLevelEnvironmentVariable
export CSV2RDF4LOD_CONVERT_SAMPLE_SUBSET_ONLY="true"
export CSV2RDF4LOD_CONVERT_SAMPLE_SUBSET_ONLY="false"

#
# Customize: Omit the full conversion of the dataset.
# Variable type: Machine ? Project ? User ? Activity ?
#
# When developing the enhancement parameters, it is helpful
# to only convert a few hand-selected rows.
# 
# Setting this to 'true' will prevent the full conversion.
#
# See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Examples-versus-Samples
#     https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD_CONVERT_EXAMPLE_SUBSET_ONLY
#
# (used in convert.sh)
#
# a conversion:ProjectLevelEnvironmentVariable
# a conversion:ActivityLevelEnvironmentVariable
export CSV2RDF4LOD_CONVERT_EXAMPLE_SUBSET_ONLY="true"
export CSV2RDF4LOD_CONVERT_EXAMPLE_SUBSET_ONLY="false"

#
# Customize: Append extension to URL for void:dataDump.
# Variable type: Machine ? Project ? User ? Activity ?
#
# Parameter given to csv2rdf4lod converter (e.g., Java implementation)
#   http://logd.tw.rpi.edu/source/data-gov/file/1008/version/2010-Dec-01/conversion/data-gov-1008-2010-Dec-01.e1
#   becomes
#   http://logd.tw.rpi.edu/source/data-gov/file/1008/version/2010-Dec-01/conversion/data-gov-1008-2010-Dec-01.e1.ttl.tgz
# 
# (update) Use 'cr:auto' to dynamically determine the file extensions based on the requested serializations.
#
# To find file extensions that you don't like, SPARQL: 
#   [] void:dataDump ?dump_file .
#   filter(!regex(?dump_file,'.ttl.gz$'))
#
# If empty, nothing will be appended to URL.
# (used in convert.sh)
#
# a conversion:ProjectLevelEnvironmentVariable
export CSV2RDF4LOD_CONVERT_DUMP_FILE_EXTENSIONS="ttl.gz,nt.gz"
export CSV2RDF4LOD_CONVERT_DUMP_FILE_EXTENSIONS="ttl.gz"
export CSV2RDF4LOD_CONVERT_DUMP_FILE_EXTENSIONS="cr:auto"

#
# Customize: Invoke the converter for granular (row/column) provenance.
# Variable type: Machine ? Project ? User ? Activity ?
#
# This is only done for enhancements; raw does not get provenance.
# Produces (e.g.) automatic/$datafile.e1.pml.ttl
#
# (used in convert.sh)
#
# a conversion:ProjectLevelEnvironmentVariable
export CSV2RDF4LOD_CONVERT_PROVENANCE_GRANULAR="true"
export CSV2RDF4LOD_CONVERT_PROVENANCE_GRANULAR="false"

#
# Customize: Capture FRBR stacks as part of the provenance.
# NOTE: This slows things down b/c it computs digests.
#
# Variable type: Machine ? Project ? User ? Activity ?
#
# Produces (e.g.) automatic/$datafile.e1.pml.ttl
#
# (used in convert.sh)
#
# a conversion:ProjectLevelEnvironmentVariable
export CSV2RDF4LOD_CONVERT_PROVENANCE_FRBR="true"
export CSV2RDF4LOD_CONVERT_PROVENANCE_FRBR="false"

#
# Customize: Enable debugging within the Java CSVtoRDF
# Variable type: Machine ? Project ? User ? Activity ?
# (used in convert.sh)
#
export CSV2RDF4LOD_CONVERT_DEBUG_LEVEL="fine"
export CSV2RDF4LOD_CONVERT_DEBUG_LEVEL="finer"
export CSV2RDF4LOD_CONVERT_DEBUG_LEVEL="finest"
export CSV2RDF4LOD_CONVERT_DEBUG_LEVEL=""

#
# ------- ------- publishing options ------- -------
#

#
# Customize: Publish files into publish/
# Variable type: Machine ? Project ? User ? Activity ?
#
# This is a misnomer - it should be AGGREGATE.
#
# AGGREGATE should mean to concatenate automatic/*.ttl into the ONE publish/dataset.ttl
# PUBLISH should mean to put those triples into an accessible endpoint or on the web in some form.
#
# (done in convert-aggregate.sh)
# This is only used at the very beginning of convert-aggregate.sh when it is deciding
# if it should execute or not. It decides to execute b/c the conversion trigger invokes it
# every time it runs AND the publish/bin/publish.sh script invokes it when publish.sh is 
# manually invoked.
#
export CSV2RDF4LOD_PUBLISH="false"
export CSV2RDF4LOD_PUBLISH="true"

#
# Customize: If not 'false', publish the given URL as the version control 
#            repository that this project uses to maintain its metadata and triggers.
#
# See https://github.com/timrdf/prizms/wiki/VoID#prizms-node-dataset-as-a-doapproject
#
# Variable type: Machine ? Project ? User ? Activity ?
#
# (done in )
#
export CSV2RDF4LOD_PUBLISH_VC_REPOSITORY="https://github.com/timrdf/ieeevis.git"
export CSV2RDF4LOD_PUBLISH_VC_REPOSITORY=""


#
# Customize: Aggregate and publish with just raw conversion or 
#            wait until we have usefully-enhanced conversion?
# Variable type: Machine ? Project ? User ? Activity ?
#
# (done in convert-aggregate.sh)
#
export CSV2RDF4LOD_PUBLISH_DELAY_UNTIL_ENHANCED="false"
export CSV2RDF4LOD_PUBLISH_DELAY_UNTIL_ENHANCED="true"

#
# Customize: compress all serializations of the dump files, 
#            deleting the uncompressed versions.
# Variable type: Machine ? Project ? User ? Activity ?
#
# (done in convert-aggregate.sh)
#
export CSV2RDF4LOD_PUBLISH_COMPRESS="false"
export CSV2RDF4LOD_PUBLISH_COMPRESS="true"

#
# Customize: If CSV2RDF4LOD_PUBLISH_COMPRESS == true,
#            delete automatic/* after creating publish/*
#
# Variable type: Machine ? Project ? User ? Activity ?
#
# (done in convert-aggregate.sh)
#
export CSV2RDF4LOD_PUBLISH_PURGE_AUTODIR="true"
export CSV2RDF4LOD_PUBLISH_PURGE_AUTODIR="false"


#
# Customize: Specify the source_identifier 
#            (in the csv2rdf4lod conversion's source/dataset/version scheme)
# Variable type: Machine ? Project ? User ? Activity ?
#
# This is used when archiving the metadata into a versioned dataset.
#
# (done in cr-publish-void-to-endpoint.sh)
#
export CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID="twc-rpi-edu"
export CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID=""

#
# Customize: Specify the "base" conversion_identifier
#            (in the csv2rdf4lod conversion's source/dataset/version scheme)
#            "base" because the automation will append some tokens to create
#            a variety of datasets.
# Variable type: Machine ? Project ? User ? Activity ?
#
# This is used when archiving the metadata into a versioned dataset.
#
# (done in cr-publish-void-to-endpoint.sh)
#
export CSV2RDF4LOD_PUBLISH_OUR_DATASET_ID="dataset-conversion"

#
# ------- ------- serialization options ------- -------
#

#
# Customize: Concatenate raw and e* into a single file.
# Variable type: Machine ? Project ? User ? Activity ?
#
# If false, publish/*.raw.ttl and publish/*.e*.ttl are the only files
# that represent the dataset.
#
# (done in convert-aggregate.sh)
#
export CSV2RDF4LOD_PUBLISH_TTL="false"
export CSV2RDF4LOD_PUBLISH_TTL="true"

#
# Customize: Concatenate raw and e* into a single file.
# Variable type: Machine ? Project ? User ? Activity ?
#
# If false, publish/*.raw.ttl and publish/*.e*.ttl are the only files
# that represent the dataset.
#
# (done in convert-aggregate.sh)
#
export CSV2RDF4LOD_PUBLISH_TTL_LAYERS="false"
export CSV2RDF4LOD_PUBLISH_TTL_LAYERS="true"

#
# Customize: include N-Triples as a serialization when publishing
# Variable type: Machine ? Project ? User ? Activity ?
#
# (done in convert-aggregate.sh)
#
export CSV2RDF4LOD_PUBLISH_NT="true"
export CSV2RDF4LOD_PUBLISH_NT="false"

#
# Customize: include RDF/XML as a serialization when publishing
# Variable type: Machine ? Project ? User ? Activity ?
#
# (done in convert-aggregate.sh)
#
export CSV2RDF4LOD_PUBLISH_RDFXML="true"
export CSV2RDF4LOD_PUBLISH_RDFXML="false"

#
# ------- ------- subset options ------- -------
#

#
# Customize: Publish the full conversion of the dataset.
# Variable type: Machine ? Project ? User ? Activity ?
#
#
# (done in convert-aggregate.sh)
#
export CSV2RDF4LOD_PUBLISH_FULL_CONVERSIONS="false"
export CSV2RDF4LOD_PUBLISH_FULL_CONVERSIONS="true"

#
# Customize: include subset of conversion that describes the 
# dataset created. This allows you to publish the description
# of the dataset without loading the entire (potentially large)
# dataset.
# Variable type: Machine ? Project ? User ? Activity ?
#
# (done in convert-aggregate.sh)
#
export CSV2RDF4LOD_PUBLISH_SUBSET_VOID="false"
export CSV2RDF4LOD_PUBLISH_SUBSET_VOID="true"

#
# Customize: The named graph to place all conversion metadata (void, pml, etc).
# Variable type: Machine ? Project ? User ? Activity ?
#
# 'auto' will expand to $CSV2RDF4LOD_BASE_URI/vocab/Dataset (or $CSV2RDF4LOD_BASE_URI_OVERRIDE if set)
#
# (done in populate-to-endpoint.sh)
#
export CSV2RDF4LOD_PUBLISH_SUBSET_VOID_NAMED_GRAPH="http://logd.tw.rpi.edu/vocab/Dataset"
export CSV2RDF4LOD_PUBLISH_SUBSET_VOID_NAMED_GRAPH="auto"

#
# Customize: The named graph to place all datasets whose contents describe datasets.
# Variable type: Machine ? Project ? User ? Activity ?
#
# 'auto' will expand to http://purl.org/twc/vocab/conversion/MetaDataset
#
# (done in convert-aggregate.sh)
#
export CSV2RDF4LOD_PUBLISH_METADATASET_GRAPH_NAME="http://purl.org/twc/vocab/conversion/MetaDataset"
export CSV2RDF4LOD_PUBLISH_METADATASET_GRAPH_NAME="auto"

#
# Customize: TODO
# Variable type: Machine ? Project ? User ? Activity ?
#
# Datasets whose data is about other Datasets (e.g. data.gov's 92)
#
# (done in populate-to-endpoint.sh)
#
export CSV2RDF4LOD_PUBLISH_TODO="http://purl.org/twc/vocab/conversion/MetaDataset"

#
# Customize: include subset of conversion: ?s owl:sameAs ?o .
# Variable type: Machine ? Project ? User ? Activity ?
#
# This allows dataset interconnectivity analysis without loading
# the entire dataset.
#
# (done in convert-aggregate.sh)
#
export CSV2RDF4LOD_PUBLISH_SUBSET_SAMEAS="false"
export CSV2RDF4LOD_PUBLISH_SUBSET_SAMEAS="true"

#
# Customize: The named graph to place all owl:sameAs triples.
# Variable type: Machine ? Project ? User ? Activity ?
#
# 'auto' will expand to http://purl.org/twc/vocab/conversion/SameAsDataset
#
# (done in populate-to-endpoint.sh)
#
export CSV2RDF4LOD_PUBLISH_SUBSET_SAMEAS_NAMED_GRAPH="http://purl.org/twc/vocab/conversion/SameAsDataset"
export CSV2RDF4LOD_PUBLISH_SUBSET_SAMEAS_NAMED_GRAPH="auto"

#
# Customize: include subset of conversion: 
#            first $CSV2RDF4LOD_CONVERT_SAMPLE_NUMBER_OF_ROWS
# Variable type: Machine ? Project ? User ? Activity ?
#
# if true, invokes:
#   publish/bin/virtuoso-load-${sourceID}-${datasetID}-${datasetVersion}.sh --sample
# 
# (done in convert-aggregate.sh)
#
export CSV2RDF4LOD_PUBLISH_SUBSET_SAMPLES="true"
export CSV2RDF4LOD_PUBLISH_SUBSET_SAMPLES="false"

#
# ------- ------- conversion parameters ------- -------
#

#
# Customize: The named graph to place all conversion parameters.
# Variable type: Machine ? Project ? User ? Activity ?
#
# (instance data from http://purl.org/twc/vocab/conversion vocabulary)
#
# (done in populate-to-endpoint.sh)
#
export CSV2RDF4LOD_PUBLISH_CONVERSION_PARAMS_NAMED_GRAPH="http://purl.org/twc/vocab/conversion/ConversionProcess"
export CSV2RDF4LOD_PUBLISH_CONVERSION_PARAMS_NAMED_GRAPH="auto"


#
# ------- ------- lod-mat options ------- -------
#

#
# Customize: number of processes to spawn
#  used by lod-materialization.
#  could be used by dg-create-dataset-dir.sh
# Variable type: Machine ? Project ? User ? Activity ?
#
# (done in convert-aggregate.sh)
#
export CSV2RDF4LOD_CONCURRENCY="8"
export CSV2RDF4LOD_CONCURRENCY="2"

#
# Customize: Upload files into an AWS S3 bucket.
#
# (done in bin/cr-s3.sh)
#
export CSV2RDF4LOD_PUBLISH_AWS_S3_BUCKET="s3://my-bucket-name"
export CSV2RDF4LOD_PUBLISH_AWS_S3_BUCKET=""

#
# Customize: ln publish/*.ttl into a corresponding directory in
#            /var/www directory ($CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT)
#            to publish on web. The void:Datasets point to these void:dataDumps.
#
# Variable type: Machine ? Project ? User ? Activity ?
#
# (done in convert-aggregate.sh and publish/bin/ln-*.sh)
#
export CSV2RDF4LOD_PUBLISH_VARWWW_DUMP_FILES="true"
export CSV2RDF4LOD_PUBLISH_VARWWW_DUMP_FILES="false"

#
# Customize: The path to the htdocs directory, to host files on the web.
#    See https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD_PUBLISH_VARWWW_ROOT
#
# Variable type: Machine ? Project ? User ? Activity ?
#
# (done in convert-aggregate.sh and publish/bin/ln-*.sh)
#
export CSV2RDF4LOD_PUBLISH_VARWWW_ROOT=""
export CSV2RDF4LOD_PUBLISH_VARWWW_ROOT="/var/www"

#
# Customize: use ln or ln -s when linking from the conversion root
#            directory to the /var/www directory to publish on web.
#
# Variable type: Machine ? Project ? User ? Activity ?
#
# (done in convert-aggregate.sh and publish/bin/ln-*.sh)
#
export CSV2RDF4LOD_PUBLISH_VARWWW_LINK_TYPE="soft"
export CSV2RDF4LOD_PUBLISH_VARWWW_LINK_TYPE="hard"
export CSV2RDF4LOD_PUBLISH_VARWWW_LINK_TYPE=""

#
# Customize: populate publish/lod-mat/ with a file for each URI
# mentioned within the conversion output and within the internal 
# namespace
# Variable type: Machine ? Project ? User ? Activity ?
#
# (done in convert-aggregate.sh)
#
export CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION="true"
export CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION="false"

#
# Customize: populate a directory OTHER THAN publish/lod-mat/ 
#            when lod-materializing. This prevents the need to move files
#            around to get them from the conversion directory to the
#            www directory.
# Variable type: Machine ? Project ? User ? Activity ?
#
# No trailing slash.
#
# To populate publish/lod-mat/, leave this variable empty "".
#
# NOTE: CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION needs to be "true" for
#       this to take effect.
#
# DEPRECATED: use CSV2RDF4LOD_PUBLISH_VARWWW_ROOT for general htdocs publishing.
#
# (done in convert-aggregate.sh)
#
export CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT=""

#
# Customize: Number of triples to process before writing all results to disk.
# Variable type: Machine ? Project ? User ? Activity ?
#
# NOTE: CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION needs to be "true" for
#       this to take effect.
#
# (done in convert-aggregate.sh)
#
export CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WRITE_FREQUENCY="1000000"

#
# Customize: Frequency to report progress during lod-materialization.
# Output, e.g. "405773T / 36974F / 36974N". 
# Shows the number of triples processed, 
# the number of files matched from those triples, and 
# the number of files written to during /this/ invocation. 
# When rerunning with identical params, output
# will be something like: "405773T / 36974F / 0N".
# Variable type: Machine ? Project ? User ? Activity ?
#
# If 0: Do not report status.
# If 1: Report status for every triple.
# If N > 1: Report every Nth triple.
#
# NOTE: CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION needs to be "true" for
#       this to take effect.
#
# NOTE: If this is > 1, the final output will not be completely accurate.
#       Reports are for human reassurance only.
#
# (done in convert-aggregate.sh)
#
export CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_REPORT_FREQUENCY="0"
export CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_REPORT_FREQUENCY="1000"

#
# ------- ------- TDB options ------- -------
#

#
# Customize: If true, load all triples into publish/tdb/
# (or CSV2RDF4LOD_PUBLISH_TDB_DIR, if set).
# Variable type: Machine ? Project ? User ? Activity ?
#
# (done in convert-aggregate.sh)
#
export CSV2RDF4LOD_PUBLISH_TDB="true"
export CSV2RDF4LOD_PUBLISH_TDB="false" 

#
# Customize: Instead of loading the triples into publish/tdb/,
# load them into the tdb directory CSV2RDF4LOD_PUBLISH_TDB_OVERRIDE.
# Variable type: Machine ? Project ? User ? Activity ?
#
# (done in convert-aggregate.sh)
#
export CSV2RDF4LOD_PUBLISH_TDB_DIR="/path/to/global/tdb/"
export CSV2RDF4LOD_PUBLISH_TDB_DIR=""

#
# Customize: setup tdb directory for individual conversions?
# Intended for development and debugging only; not for publication.
# Variable type: Machine ? Project ? User ? Activity ?
#
# (done in convert.sh)
#
export CSV2RDF4LOD_PUBLISH_TDB_INDIV="true"
export CSV2RDF4LOD_PUBLISH_TDB_INDIV="false"

#
# ------- ------- 4store options ------- -------
#

#
# Customize: If true, load all triples into /var/lib/4store/csv2rdf4lod
# Variable type: Machine ? Project ? User ? Activity ?
# see http://4store.org/trac/wiki/Install
#
# /var/lib/4store/csv2rdf4lod can be changed to /var/lib/4store/YYYY
# by setting CSV2RDF4LOD_PUBLISH_4STORE_KB="YYYY"
#
# (done in convert-aggregate.sh)
#
export CSV2RDF4LOD_PUBLISH_4STORE="true"
export CSV2RDF4LOD_PUBLISH_4STORE="false" 

#
# Customize: Instead of loading the triples into /var/lib/4store/csv2rdf4lod,
# Variable type: Machine ? Project ? User ? Activity ?
# load them into /var/lib/4store/$CSV2RDF4LOD_PUBLISH_4STORE_KB.
#
# (done in convert-aggregate.sh)
#
export CSV2RDF4LOD_PUBLISH_4STORE_KB="csv2rdf4lod"
export CSV2RDF4LOD_PUBLISH_4STORE_KB=""

#
# ------- ------- virtuoso options ------- -------
#

#
# Customize: If true, load all triples into virtuoso triple store.
# Variable type: Machine ? Project ? User ? Activity ?
#
# This is done by invoking:
#   publish/bin/virtuoso-load-${sourceID}-${datasetID}-${datasetVersion}.sh
#
# (done in convert-aggregate.sh)
#
export CSV2RDF4LOD_PUBLISH_VIRTUOSO="true"
export CSV2RDF4LOD_PUBLISH_VIRTUOSO="false" 

#
# Customize: 
#
# Variable type: Machine ? Project ? User ? Activity ?
#
# (done in)
#
# See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Publishing-conversion-results-with-a-Virtuoso-triplestore
#
export CSV2RDF4LOD_PUBLISH_VIRTUOSO_HOME="/opt/virtuoso" 
export CSV2RDF4LOD_PUBLISH_VIRTUOSO_HOME="" 

#
# Customize: 
#
# Variable type: Machine ? Project ? User ? Activity ?
#
# (done in )
#
# See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Publishing-conversion-results-with-a-Virtuoso-triplestore
#
export CSV2RDF4LOD_PUBLISH_VIRTUOSO_ISQL_PATH="/opt/virtuoso/bin/isql" 
export CSV2RDF4LOD_PUBLISH_VIRTUOSO_ISQL_PATH="" 

#
# Customize: 
#
# Variable type: Machine ? Project ? User ? Activity ?
#
# (done in )
#
# See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Publishing-conversion-results-with-a-Virtuoso-triplestore
#
export CSV2RDF4LOD_PUBLISH_VIRTUOSO_PORT="1111"
export CSV2RDF4LOD_PUBLISH_VIRTUOSO_PORT="" 

#
# Customize: 
#
# Variable type: Machine ? Project ? User ? Activity ?
#
# (done in )
#
# See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Publishing-conversion-results-with-a-Virtuoso-triplestore
#
export CSV2RDF4LOD_PUBLISH_VIRTUOSO_USERNAME="dba"
export CSV2RDF4LOD_PUBLISH_VIRTUOSO_USERNAME="" 

#
# Customize: 
#
# Variable type: Machine ? Project ? User ? Activity ?
#
# (done in )
#
# See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Publishing-conversion-results-with-a-Virtuoso-triplestore
#
export CSV2RDF4LOD_PUBLISH_VIRTUOSO_PASSWORD="dba"
export CSV2RDF4LOD_PUBLISH_VIRTUOSO_PASSWORD="" 


#
# Customize: 
#
# Variable type: Machine Y Project Y User ? Activity ?
#
# (done in )
#
# See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Publishing-conversion-results-with-a-Virtuoso-triplestore
#
export CSV2RDF4LOD_PUBLISH_VIRTUOSO_INI_PATH=""

#
# Customize: Set the path of the local script used to load/delete data from
#            the Virtuoso SPARQL endpoint.
# Variable type: Machine ? Project ? User ? Activity ?
#
# /opt/virtuoso/scripts/vload
# usage: "vload [rdf|ttl|nt|nq] [data_file] [graph_uri]"
#
# (done in convert-aggregate.sh, publish/bin/virtuoso-{load,delete}*.sh)
#
export CSV2RDF4LOD_PUBLISH_VIRTUOSO_SCRIPT_PATH="/opt/virtuoso/scripts/vload"
export CSV2RDF4LOD_PUBLISH_VIRTUOSO_SCRIPT_PATH="" 

#
# Customize: The publicly accessible SPARQL endpoint service.
# Variable type: Machine ? Project ? User ? Activity ?
#
# Used to describe provenance of loading a file into the endpoint's named graph.
# (done in pvload.sh)
#
export CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT="http://logd.tw.rpi.edu/sparql"
export CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT=""


#
# ------- ------- query caching options ------- -------
#

#
# Customize: SPARQL endpoint that should be queried when caching results.
#            This is the URL of the endpoint that gets populated with conversion results.
# Variable type: Machine ? Project ? User ? Activity ?
#
# (done in populate-to-endpoint.sh)
#
export CSV2RDF4LOD_PUBLISH_SPARQL_ENDPOINT="http://logd.tw.rpi.edu/sparql" 
export CSV2RDF4LOD_PUBLISH_SPARQL_ENDPOINT="" 

#
# Customize: Load the provenance of SPARQL endpoint named graph 
#            loads into a separate named graph, instead of the one being loaded.
#            See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Script:-pvload.sh
# Variable type: Machine ? Project ? User ? Activity ?
#
# (done in )
#
export CSV2RDF4LOD_PUBLISH_SPARQL_ENDPOINT_SEPARATE_NG_PROVENANCE="false" 
export CSV2RDF4LOD_PUBLISH_SPARQL_ENDPOINT_SEPARATE_NG_PROVENANCE="true" 

#
# Customize: Directory where SPARQL query files exist 
#            and should be cached with cache-queries.sh.
# Variable type: Machine ? Project ? User ? Activity ?
#
# (done in populate-to-endpoint.sh)
#
export CSV2RDF4LOD_PUBLISH_SPARQL_RESULTS_DIRECTORY="/var/www/html/logd.tw.rpi.edu/query" 
export CSV2RDF4LOD_PUBLISH_SPARQL_RESULTS_DIRECTORY="" 

#
# Customize: Publish metadata about this csv2rdf4lod node to http://datahub.io/
#            
# Variable type: Machine ? Project ? User ? Activity ?
#
# (done in )
#
export CSV2RDF4LOD_PUBLISH_DATAHUB_METADATA="false" 
export CSV2RDF4LOD_PUBLISH_DATAHUB_METADATA="true" 

#
# Customize: CKAN identifier for our bubble, e.g. twc-logd
#   (which is http://datahub.io/dataset/twc-logd)
#            
# Variable type: Machine ? Project ? User ? Activity ?
#
# (done in bin/secondary/cr-linksets.sh)
#
export CSV2RDF4LOD_PUBLISH_DATAHUB_METADATA_OUR_BUBBLE_ID="twc-logd" 
export CSV2RDF4LOD_PUBLISH_DATAHUB_METADATA_OUR_BUBBLE_ID="" 

#
# Customize: Notify Ping The Semantic Web about all published datasets.
#
#    Note that your machine IP must be registered at http://pingthesemanticweb.com
#    see https://github.com/timrdf/csv2rdf4lod-automation/wiki/Ping-the-Semantic-Web
#
# Variable type: Machine ? Project ? User ? Activity ?
#
# (used in bin/convert-aggregate.sh)
# (done in bin/aggregate-source-rdf.sh)
#
export CSV2RDF4LOD_PUBLISH_ANNOUNCE_TO_SINDICE="true" 
export CSV2RDF4LOD_PUBLISH_ANNOUNCE_TO_SINDICE="false" 

#
# Customize: Notify Sindice about all published datasets.
#            
#    see https://github.com/timrdf/csv2rdf4lod-automation/wiki/Ping-the-Semantic-Web
#
# Variable type: Machine ? Project ? User ? Activity ?
#
# (used in bin/convert-aggregate.sh)
# (done in bin/aggregate-source-rdf.sh)
#
export CSV2RDF4LOD_PUBLISH_ANNOUNCE_TO_PTSW="true" 
export CSV2RDF4LOD_PUBLISH_ANNOUNCE_TO_PTSW="false" 

#
# Customize: Only Notify PTSW or Sindice if the published dataset is Enhanced (omit raw conversions).
#            
# NOTE: This setting has no affect on for aggregate-source-rdf.sh.
#       It WILL apply when publishing data that we've converted from tables.
#
#    If true, will NOT publish raw, but will publish enhanced.
#    If false, will publish BOTH raw and enhanced.
#
# Variable type: Machine ? Project ? User ? Activity ?
#
# (used in bin/convert-aggregate.sh - NOT bin/convert-aggregate.sh)
#
export CSV2RDF4LOD_PUBLISH_ANNOUNCE_ONLY_ENHANCED="true" 
export CSV2RDF4LOD_PUBLISH_ANNOUNCE_ONLY_ENHANCED="false" 

#
# ------- ------- Post-conversion derivations ------- -------
#

#
# Customize: 
#
# Variable type: Machine ? Project ? User ? Activity ?
#
# (done in )
#
export X_GOOGLE_MAPS_API_Key=""

#
# ------- ------- data.gov options ------- -------
#

#
# Customize: If true, download the data referenced by data.gov/details/xx.
# If false, just get the headers.
#
# Variable type: Machine ? Project ? User ? Activity ?
#
# (done in dg-create-dataset-dir.sh)
#
export DG_RETRIEVAL_REQUEST_DATA="false"
export DG_RETRIEVAL_REQUEST_DATA="true"

#
# Customize: If true, perform raw conversion of any csvs found in 
#            download immediately after downloading it.
# Variable type: Machine ? Project ? User ? Activity ?
#
# It can be useful to get all of the data as soon as possible and convert later.
# If false, the raw conversion can be performed cr-rerun-convert.sh.
#
# (done in dg-create-dataset-dir.sh)
#
export DG_RETRIEVAL_CONVERT_RAW="true" 
export DG_RETRIEVAL_CONVERT_RAW="false" 

# End of CSV2RDF4LOD_ variables




# # # # # # # These variables should not be modified # # # # # #
#
PATH="${PATH}:${CSV2RDF4LOD_HOME}/bin:${CSV2RDF4LOD_HOME}/bin/util"
PATH="${PATH}:${CSV2RDF4LOD_HOME}/bin:${CSV2RDF4LOD_HOME}/bin/dup"
PATH="${PATH}:${CSV2RDF4LOD_HOME}/bin:${CSV2RDF4LOD_HOME}/bin/util/virtuoso"
PATH="${PATH}:/opt/local/bin/" # This is for perl
PATH="${PATH}:/usr/local/bin/" # This is for rapper
export PATH
#
# TODO: NOTE: cygwin needs formatting with quotes and semicolons such as:  CLASSPATH="$CLASSPATH;$CSV2RDF4LOD_HOME/bin/dup/csv2rdf4lod.jar"
#CLASSPATH="${CLASSPATH}:${CSV2RDF4LOD_HOME}/bin/dup/csv2rdf4lod.jar"                                     # DEPRECATED: moved to bin/convert.sh
#CLASSPATH="${CLASSPATH}:${CSV2RDF4LOD_HOME}/bin/dup/openrdf-sesame-2.3.1-onejar.jar"                     # DEPRECATED: moved to bin/convert.sh
#CLASSPATH="${CLASSPATH}:${CSV2RDF4LOD_HOME}/bin/dup/slf4j-api-1.5.6.jar"                                 # DEPRECATED: moved to bin/convert.sh
#CLASSPATH="${CLASSPATH}:${CSV2RDF4LOD_HOME}/bin/dup/slf4j-nop-1.5.6.jar"                                 # DEPRECATED: moved to bin/convert.sh
#CLASSPATH="${CLASSPATH}:${CSV2RDF4LOD_HOME}/bin/dup/datadigest-1.0-SNAPSHOT.jar"                         # DEPRECATED: moved to bin/convert.sh
#CLASSPATH="${CLASSPATH}:${CSV2RDF4LOD_HOME}/bin/lib/javacsv2.0/javacsv.jar"                              # DEPRECATED: moved to bin/convert.sh
#CLASSPATH="${CLASSPATH}:${CSV2RDF4LOD_HOME}/bin/lib/commons-validator-1.3.1/commons-validator-1.3.1.jar" # DEPRECATED: moved to bin/convert.sh
export CLASSPATH
#
export saxon9="${CSV2RDF4LOD_HOME}/bin/dup/saxonb9-1-0-8j.jar"
#
alias csv2rdf4lod='java edu.rpi.tw.data.csv.CSVtoRDF'
# # # # # # # These variables should not be modified # # # # # # 
echo "(run cr-vars.sh to see all environment variables that CSV2RDF4LOD uses to control execution flow)"


# Machine-level  variables:
#   Variables that are specific to the machine on which development is performed.
#   (conversion:MachineLevelEnvironmentVariable)
#   
# Project-level  variables:
#   Variables that are specific to the project.
#   (conversion:ProjectLevelEnvironmentVariable)
#
# User-level     variables:
#   Variables that are specific to the user.
#   (conversion:UserLevelEnvironmentVariable)
#
# Activity-level variables:
#   Variables that change depending on the activity of the user, e.g. enhancement development, deployment, etc.
#   (conversion:ActivityLevelEnvironmentVariable)
#
# Documentation below:
#   "Variable type: Machine Y Project Y User N Activity ?"
# indicates that the variable is, is not, or unknown to be of the corresponding type.
