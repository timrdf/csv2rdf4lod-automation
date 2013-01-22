#3> <#> a <http://purl.org/twc/vocab/conversion/CSV2RDF4LOD_environment_variables> ;
#3>     rdfs:seeAlso 
#3>     <http://purl.org/twc/page/csv2rdf4lod/distributed_env_vars>,
#3>     <https://github.com/timrdf/csv2rdf4lod-automation/wiki/Script:-source-me.sh> .

export CSV2RDF4LOD_CKAN="true"
export CSV2RDF4LOD_CKAN_SOURCE="http://hub.healthdata.gov"
export CSV2RDF4LOD_CKAN_WRITABLE="http://healthdata.tw.rpi.edu/hub"
source /srv/twc-healthdata/config/ckan/csv2rdf4lod-source-me-for-ckan-api-key.sh # for X_CKAN_API_Key
