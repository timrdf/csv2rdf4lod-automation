#!/usr/bin/env python
#
# Invoke from a cr:source directory, e.g. source/hub-healthdata-gov

#3> <> prov:wasRevisionOf 
#3>    <https://github.com/jimmccusker/twc-healthdata/blob/master/ckan/mirror.py> .

import os, json, uuid

import ckanclient  # see https://github.com/okfn/ckanclient README
# Get latest download URL from http://pypi.python.org/pypi/ckanclient#downloads --\/
# sudo easy_install http://pypi.python.org/packages/source/c/ckanclient/ckanclient-0.10.tar.gz

# See also https://github.com/timrdf/DataFAQs/wiki/CKAN
#    section "Automatically publish dataset on CKAN"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
CSV2RDF4LOD_BASE_URI = 'http://purl.org/twc/health'
SOURCE_ID            = 'hub-healthdata-gov'
TARGET_CKAN          = 'http://healthdata.tw.rpi.edu'

#source = 'http://aquarius.tw.rpi.edu/projects/healthdata/api'
source = 'http://hub.healthdata.gov/api'
# Formats seen on healthdata.gov: 
#    CSV Text XLS XML Feed Query API Widget RDF
desiredFormats = ['CSV', 'XLS']
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

ckan = ckanclient.CkanClient(base_location=source)
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
         'SOURCE_ID'            : SOURCE_ID,
         'DATASET_ID'           : dataset['name'],
         'UUID'                 : str(uuid.uuid4()),
         'SOURCE_CKAN'          : source.replace('/api',''),
         'TARGET_CKAN'          : TARGET_CKAN,
         'DIST_URL'             : URL
      }

      template='''@prefix rdfs:       <http://www.w3.org/2000/01/rdf-schema#> .
@prefix conversion: <http://purl.org/twc/vocab/conversion/> .
@prefix dcat:       <http://www.w3.org/ns/dcat#> .
@prefix void:       <http://rdfs.org/ns/void#> .
@prefix prov:       <http://www.w3.org/ns/prov#> .
@prefix :           <CSV2RDF4LOD_BASE_URI/id/> .

<CSV2RDF4LOD_BASE_URI/source/SOURCE-ID/dataset/DATASET-ID>
   a void:Dataset;
   conversion:source_identifier  "SOURCE_ID";
   conversion:dataset_identifier "DATASET_ID";
   prov:wasDerivedFrom :as_a_csv_UUID;
.

<TARGET_CKAN/dataset/DATASET-ID>
   a dcat:Dataset;
   dcat:distribution :as_a_csv_UUID;
   prov:alternateOf <SOURCE_CKAN/dataset/DATASET-ID>;
.

:as_a_csv_UUID
   a dcat:Distribution;
   dcat:downloadURL <DIST_URL>;
.

<SOURCE_CKAN/dataset/DATASET_ID>
   a dcat:Dataset;
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
