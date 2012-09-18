#!/usr/bin/env python
#3> <> prov:wasRevisionOf 
#3>    <https://github.com/jimmccusker/twc-healthdata/blob/master/ckan/mirror.py> .
#
# Invoke from a cr:source directory, e.g. source/hub-healthdata-gov
#   % cr-pwd.sh 
#     source/hub-healthdata-gov
#   % cr-create-dataset-dirs-from-ckan.py http://healthdata.tw.rpi.edu/hub/api http://purl.org/twc/health
#   % find . -name dcat.ttl | xargs git add -f

import sys, os, re, json, uuid

import ckanclient  # see README at https://github.com/okfn/ckanclient
# Get latest download URL \/ from http://pypi.python.org/pypi/ckanclient#downloads
# sudo easy_install http://pypi.python.org/packages/source/c/ckanclient/ckanclient-0.10.tar.gz

# See also https://github.com/timrdf/DataFAQs/wiki/CKAN
#    section "Automatically publish dataset on CKAN"

if len(sys.argv) <= 2:
   print
   print "usage: %s <ckan-api>" % os.path.basename(sys.argv[0])
   print
   print "  <ckan-api>:             The API URL for the CKAN instance, e.g. http://healthdata.tw.rpi.edu/hub/api"
   print "  <CSV2RDF4LOD_BASE_URI>: The base URI of the VoID datasets that will be created from CKAN, e.g. http://purl.org/twc/health"
   print
   sys.exit(1)

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                                     # http://hub.healthdata.gov/api
ckanAPI              = sys.argv[1]                   # http://healthdata.tw.rpi.edu/hub/api
CSV2RDF4LOD_BASE_URI = sys.argv[2]                   # http://purl.org/twc/health
sourceID             = os.path.basename(os.getcwd()) # hub-healthdata-gov
#TARGET_CKAN          = 'http://healthdata.tw.rpi.edu' # Can assume this?

# Formats seen on healthdata.gov: 
#    CSV Text XLS XML Feed Query API Widget RDF
desiredFormats = ['CSV', 'XLS']
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#print "ckan-api:  " + ckanAPI
#print "SOURCE-ID: " + sourceID
#print "BASE_URI:  " + CSV2RDF4LOD_BASE_URI
#sys.exit(1)

ckan = ckanclient.CkanClient(base_location=ckanAPI)
#api_key = os.environ['X_CKAN_API_Key'] # api_key must be defined to POST/PUT.

indent = '    '
for name in ckan.package_register_get():
   
   ckan.package_entity_get(name) # Get the dataset description.
   dataset = ckan.last_message

   URL = ''
   desiredFormat = False
   for resource in dataset['resources']:
      if (not desiredFormat and 
         'url' in resource and len(str(resource['url'])) > 0 and 
         'format' in resource and resource['format'] in desiredFormats):
         desiredFormat = True
         URL = resource['url']
         #print indent + 'resource:     ' + resource['format'] + ' ' + resource['url']
   #if 'download_url' in dataset:
   #   print indent + 'download_url: ' + dataset['download_url']
   #if 'url' in dataset:
   #   print indent + 'url:          ' + dataset['url']
   #print json.dumps(dataset,sort_keys=True, indent=4)

   if desiredFormat:
      replacements = {
         'CSV2RDF4LOD_BASE_URI' : CSV2RDF4LOD_BASE_URI,
         'SOURCE_ID'            : sourceID,
         'DATASET_ID'           : dataset['name'],
         'UUID'                 : str(uuid.uuid4()),
         'SOURCE_CKAN'          : ckanAPI.replace('/api',''),
         'SOURCE_AGENT'         : re.sub('(http://[^/]*)/.*$','\\1',ckanAPI),
         'DIST_URL'             : URL
      }

#         'TARGET_CKAN'          : TARGET_CKAN,
#<TARGET_CKAN/dataset/DATASET_ID>
#   a dcat:Dataset;
#   prov:alternateOf <SOURCE_CKAN/dataset/DATASET_ID>;
#.

      template='''@prefix rdfs:       <http://www.w3.org/2000/01/rdf-schema#> .
@prefix conversion: <http://purl.org/twc/vocab/conversion/> .
@prefix dcat:       <http://www.w3.org/ns/dcat#> .
@prefix void:       <http://rdfs.org/ns/void#> .
@prefix prov:       <http://www.w3.org/ns/prov#> .
@prefix :           <CSV2RDF4LOD_BASE_URI/id/> .

<CSV2RDF4LOD_BASE_URI/source/SOURCE_ID/dataset/DATASET_ID>
   a void:Dataset;
   conversion:source_identifier  "SOURCE_ID";
   conversion:dataset_identifier "DATASET_ID";
   prov:wasDerivedFrom :as_a_csv_UUID;
.

:as_a_csv_UUID
   a dcat:Distribution;
   dcat:downloadURL <DIST_URL>;
.

<SOURCE_CKAN/dataset/DATASET_ID>
   a dcat:Dataset;
   dcat:distribution :as_a_csv_UUID;
   prov:wasAttributedTo <SOURCE_AGENT>;
.
'''
      for search in replacements.keys():
         template = template.replace(search,replacements[search])

      filename = dataset['name']+'/dcat.ttl'
      if not os.path.exists(dataset['name']):
         os.makedirs(dataset['name'])
      print filename
      f = open(filename, 'w')
      f.write(template)
      f.close()
