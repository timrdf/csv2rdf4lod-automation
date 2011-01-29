# NOTE: setup.sh (this file) is a template used by install.sh to create source-me.sh
# NOTE: source-me.sh should be modified, not setup.sh
# if path of dg-create-dataset-dir.sh 
# is /Users/me/Desktop/csv2rdf4lod/bin/dg-create-dataset-dir.sh
# CSV2RDF4LOD_HOME should be set (above) to /Users/me/Desktop/csv2rdf4lod/



# The following variables may be modified to customize csv2rdf4lod.


#
# ------- ------- converting options ------- -------
#

#
# Customize: The converter to use.
#   Converter must accept parameters as specified at 
#   http://data-gov.tw.rpi.edu/wiki/Csv2rdf4lod
#
# If not set, defaults to 'java -Xmx3060m edu.rpi.tw.data.csv.CSVtoRDF'
#
# (used in $CSV2RDF4LOD_HOME/bin/convert.sh
#    to invoke the converter.)
#
export CSV2RDF4LOD_CONVERTER=""

#
# Customize: The base URI of the final published linked data.
#
# (used in cr-create-convert-sh.sh 
#    to set variable used to create enhancement templates.)
# (used in convert-aggregate.sh)
#
export CSV2RDF4LOD_BASE_URI="http://logd.tw.rpi.edu"

#
# Customize: A base URI to use in place of CSV2RDF4LOD_BASE_URI
# when converting. 
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
export CSV2RDF4LOD_BASE_URI_OVERRIDE="http://tw2.tw.rpi.edu"
export CSV2RDF4LOD_BASE_URI_OVERRIDE=""

#
# Customize: The URI for the machine that is running the conversions.
#
# Used to create URIs for `whoami` user names
#
# (used in convert.sh and util/header2params2.awk)
#
export CSV2RDF4LOD_CONVERT_MACHINE_URI="http://tw.rpi.edu/web/inside/machine/gemini#"
export CSV2RDF4LOD_CONVERT_MACHINE_URI=""

#
# Customize: The URI for the person invoking the conversions.
#
# Each person running on the same machine should set this in their own environment.
#
# (used in convert.sh and util/header2params2.awk)
#
export CSV2RDF4LOD_CONVERT_PERSON_URI="http://tw.rpi.edu/instances/TimLebo"
export CSV2RDF4LOD_CONVERT_PERSON_URI=""


#
# Customize: Number of rows to include in an example subset.
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
export CSV2RDF4LOD_CONVERT_NUMBER_EXAMPLE_ROWS="100"
export CSV2RDF4LOD_CONVERT_NUMBER_EXAMPLE_ROWS="0"

#
# Customize: Omit the full conversion of the dataset.
#
# When developing the enhancement parameters, it is helpful
# to only convert the first few rows because the conversion will be
# inspected and rerun right away.
# 
# Setting this to 'true' will prevent the full conversion.
#
# See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Generating-a-sample-conversion-using-only-a-subset-of-data
#
# (used in convert.sh)
#
export CSV2RDF4LOD_CONVERT_EXAMPLE_SUBSET_ONLY="true"
export CSV2RDF4LOD_CONVERT_EXAMPLE_SUBSET_ONLY="false"

#
# Customize: Append extension to URL for void:dataDump.
#
# Parameter given to csv2rdf4lod converter (e.g., Java implementation)
#   http://logd.tw.rpi.edu/source/data-gov/file/1008/version/2010-Dec-01/conversion/data-gov-1008-2010-Dec-01.e1
#   becomes
#   http://logd.tw.rpi.edu/source/data-gov/file/1008/version/2010-Dec-01/conversion/data-gov-1008-2010-Dec-01.e1.ttl.tgz
#
# If empty, nothing will be appended to URL.
# (used in convert.sh)
#
export CSV2RDF4LOD_CONVERT_DUMP_FILE_EXTENSIONS=""
export CSV2RDF4LOD_CONVERT_DUMP_FILE_EXTENSIONS="ttl.tgz"

#
# Customize: Invoke the converter for granular (row/column) provenance.
#
# This is only done for enhancements; raw does not get provenance.
# Produces (e.g.) automatic/$datafile.e1.pml.ttl
#
# (used in convert.sh)
#
export CSV2RDF4LOD_CONVERT_PROVENANCE_GRANULAR="true"
export CSV2RDF4LOD_CONVERT_PROVENANCE_GRANULAR="false"

#
# ------- ------- publishing options ------- -------
#

#
# Customize: Publish files into publish/
#
# This is a misnomer - it should be AGGREGATE.
#
# AGGREGATE should mean to concatenate automatic/*.ttl into the ONE publish/dataset.ttl
# PUBLISH should mean to put those triples into an accessible endpoint or on the web in some form.
#
# (done in convert-aggregate.sh)
#
export CSV2RDF4LOD_PUBLISH="false"
export CSV2RDF4LOD_PUBLISH="true"

#
# Customize: Aggregate and publish with just raw conversion or 
#            wait until we have usefully-enhanced conversion?
#
# (done in convert-aggregate.sh)
#
export CSV2RDF4LOD_PUBLISH_DELAY_UNTIL_ENHANCED="false"
export CSV2RDF4LOD_PUBLISH_DELAY_UNTIL_ENHANCED="true"

#
# Customize: compress all serializations of the dump files, 
#            deleting the uncompressed versions.
#
# (done in convert-aggregate.sh)
#
export CSV2RDF4LOD_PUBLISH_COMPRESS="false"
export CSV2RDF4LOD_PUBLISH_COMPRESS="true"

#
# Customize: Specify the source_identifier 
#            (in the csv2rdf4lod conversion's source/dataset/version scheme)
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
# (done in convert-aggregate.sh)
#
export CSV2RDF4LOD_PUBLISH_NT="false"
export CSV2RDF4LOD_PUBLISH_NT="true"

#
# Customize: include RDF/XML as a serialization when publishing
# (done in convert-aggregate.sh)
#
export CSV2RDF4LOD_PUBLISH_RDFXML="true"
export CSV2RDF4LOD_PUBLISH_RDFXML="false"

#
# ------- ------- subset options ------- -------
#

#
# Customize: include subset of conversion that describes the 
# dataset created. This allows you to publish the description
# of the dataset without loading the entire (potentially large)
# dataset.
#
# (done in convert-aggregate.sh)
#
export CSV2RDF4LOD_PUBLISH_SUBSET_VOID="false"
export CSV2RDF4LOD_PUBLISH_SUBSET_VOID="true"

#
# Customize: The named graph to place all conversion metadata (void, pml, etc).
#
# 'auto' will expand to $CSV2RDF4LOD_BASE_URI/vocab/Dataset (or $CSV2RDF4LOD_BASE_URI_OVERRIDE if set)
#
# (done in populate-to-endpoint.sh)
#
export CSV2RDF4LOD_PUBLISH_SUBSET_VOID_NAMED_GRAPH="http://logd.tw.rpi.edu/vocab/Dataset"
export CSV2RDF4LOD_PUBLISH_SUBSET_VOID_NAMED_GRAPH="auto"

#
# Customize: TODO
#
# Datasets whose data is about other Datasets (e.g. data.gov's 92)
#
# (done in populate-to-endpoint.sh)
#
export CSV2RDF4LOD_PUBLISH_TODO="http://purl.org/twc/vocab/conversion/MetaDataset"


#
# Customize: include subset of conversion: ?s owl:sameAs ?o .
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
#
# 'auto' will expand to http://purl.org/twc/vocab/conversion/SameAsDataset
#
# (done in populate-to-endpoint.sh)
#
export CSV2RDF4LOD_PUBLISH_SUBSET_SAMEAS_NAMED_GRAPH="http://purl.org/twc/vocab/conversion/SameAsDataset"
export CSV2RDF4LOD_PUBLISH_SUBSET_SAMEAS_NAMED_GRAPH="auto"

#
# Customize: include subset of conversion: 
#               first $CSV2RDF4LOD_CONVERT_NUMBER_EXAMPLE_ROWS
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
#
# (done in convert-aggregate.sh)
#
export CSV2RDF4LOD_CONCURRENCY="8"
export CSV2RDF4LOD_CONCURRENCY="2"

#
# Customize: populate publish/lod-mat/ with a file for each URI
# mentioned within the conversion output and within the internal 
# namespace
# (done in convert-aggregate.sh)
#
export CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION="true"
export CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION="false"

#
# Customize: populate a directory OTHER THAN publish/lod-mat/ 
# when lod-materializing. This prevents the need to move files
# around to get them from the conversion directory to the
# www directory.
#
# To populate publish/lod-mat/, leave this variable empty "".
#
# NOTE: CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION needs to be "true" for
#       this to take effect.
#
# (done in convert-aggregate.sh)
#
export CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT=""

#
# Customize: Number of triples to process before writing all results to disk.
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
#
# (done in convert-aggregate.sh)
#
export CSV2RDF4LOD_PUBLISH_TDB="true"
export CSV2RDF4LOD_PUBLISH_TDB="false" 

#
# Customize: Instead of loading the triples into publish/tdb/,
# load them into the tdb directory CSV2RDF4LOD_PUBLISH_TDB_OVERRIDE.
#
# (done in convert-aggregate.sh)
#
export CSV2RDF4LOD_PUBLISH_TDB_DIR="/path/to/global/tdb/"
export CSV2RDF4LOD_PUBLISH_TDB_DIR=""

#
# Customize: setup tdb directory for individual conversions?
# Intended for development and debugging only; not for publication.
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
#
# This is done by invoking:
#   publish/bin/virtuoso-load-${sourceID}-${datasetID}-${datasetVersion}.sh
#
# (done in convert-aggregate.sh)
#
export CSV2RDF4LOD_PUBLISH_VIRTUOSO="true"
export CSV2RDF4LOD_PUBLISH_VIRTUOSO="false" 

#
# ------- ------- query caching options ------- -------
#

#
# Customize: SPARQL endpoint that should be queried when caching results.
#            This is the URL of the endpoint that gets populated with conversion results.
#
# (done in populate-to-endpoint.sh)
#
export CSV2RDF4LOD_PUBLISH_SPARQL_ENDPOINT="http://logd.tw.rpi.edu/sparql" 
export CSV2RDF4LOD_PUBLISH_SPARQL_ENDPOINT="" 

#
# Customize: Directory where SPARQL query files exist 
#            and should be cached with cache-queries.sh.
#
# (done in populate-to-endpoint.sh)
#
export CSV2RDF4LOD_PUBLISH_SPARQL_RESULTS_DIRECTORY="/var/www/html/logd.tw.rpi.edu/query" 
export CSV2RDF4LOD_PUBLISH_SPARQL_RESULTS_DIRECTORY="" 






#
# ------- ------- data.gov options ------- -------
#

#
# Customize: If true, download the data referenced by data.gov/details/xx.
# If false, just get the headers.
#
# (done in dg-create-dataset-dir.sh)
#
export DG_RETRIEVAL_REQUEST_DATA="false"
export DG_RETRIEVAL_REQUEST_DATA="true"

#
# Customize: If true, perform raw conversion of any csvs found in 
#            download immediately after downloading it.
#
# It can be useful to get all of the data as soon as possible and convert later.
# If false, the raw conversion can be performed cr-rerun-convert.sh.
#
# (done in dg-create-dataset-dir.sh)
#
export DG_RETRIEVAL_CONVERT_RAW="true" 
export DG_RETRIEVAL_CONVERT_RAW="false" 






# # # # # # # These variables should not be modified # # # # # #
#
export formats=$CSV2RDF4LOD_HOME/bin/dup/formats # TODO: @deprecated.
#
PATH=$PATH:$CSV2RDF4LOD_HOME/bin:$CSV2RDF4LOD_HOME/bin/util
PATH=$PATH:$CSV2RDF4LOD_HOME/bin:$CSV2RDF4LOD_HOME/bin/dup
PATH=$PATH:/opt/local/bin/ # This is for perl
PATH=$PATH:/usr/local/bin/ # This is for rapper
export PATH
#
CLASSPATH=$CLASSPATH:$CSV2RDF4LOD_HOME/bin/dup/csv2rdf4lod.jar
CLASSPATH=$CLASSPATH:$CSV2RDF4LOD_HOME/bin/dup/openrdf-sesame-2.3.1-onejar.jar
CLASSPATH=$CLASSPATH:$CSV2RDF4LOD_HOME/bin/dup/slf4j-api-1.5.6.jar
CLASSPATH=$CLASSPATH:$CSV2RDF4LOD_HOME/bin/dup/slf4j-nop-1.5.6.jar
CLASSPATH=$CLASSPATH:$CSV2RDF4LOD_HOME/bin/lib/javacsv2.0/javacsv.jar
export CLASSPATH
#
export saxon9=$CSV2RDF4LOD_HOME/bin/dup/saxonb9-1-0-8j.jar 
#
alias csv2rdf4lod='java edu.rpi.tw.data.csv.CSVtoRDF'
# # # # # # # These variables should not be modified # # # # # # 
cr-vars.sh
echo "(run cr-vars.sh to see all environment variables that CSV2RDF4LOD uses control execution flow)"
