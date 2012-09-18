#!/usr/bin/env python
#3> <> prov:wasRevisionOf 
#3>    <https://github.com/jimmccusker/twc-healthdata/blob/master/ckan/mirror.py> .
#
# Invoke from a cr:source directory, e.g. source/hub-healthdata-gov
#   % cr-pwd.sh 
#     source/hub-healthdata-gov
#   % cr-create-dataset-dirs-from-ckan.py http://healthdata.tw.rpi.edu/hub/api http://purl.org/twc/health http://hub.healthdata.gov/dataset/
#   % find . -name dcat.ttl | xargs git add -f

import sys, os, re, json, uuid

import ckanclient  # see README at https://github.com/okfn/ckanclient
# Get latest download URL \/ from http://pypi.python.org/pypi/ckanclient#downloads
# sudo easy_install http://pypi.python.org/packages/source/c/ckanclient/ckanclient-0.10.tar.gz

# See also https://github.com/timrdf/DataFAQs/wiki/CKAN
#    section "Automatically publish dataset on CKAN"

if len(sys.argv) <= 2:
   print
   print "usage: %s <ckan-api> <CSV2RDF4LOD_BASE_URI>: [mirrored-ckan]" % os.path.basename(sys.argv[0])
   print
   print "  <ckan-api>:             The API URL for the CKAN instance, e.g. http://healthdata.tw.rpi.edu/hub/api"
   print "  <CSV2RDF4LOD_BASE_URI>: The base URI of the VoID datasets that will be created from CKAN,   e.g. http://purl.org/twc/health"
   print "  [mirrored-ckan]:        The dataset base for the CKAN instance being mirrored by <ckan-api> e.g. http://hub.healthdata.gov/dataset/"
   print
   sys.exit(1)

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                                                # http://hub.healthdata.gov/api
ckanAPI              = sys.argv[1]                              # http://healthdata.tw.rpi.edu/hub/api
CSV2RDF4LOD_BASE_URI = sys.argv[2]                              # http://purl.org/twc/health
mirroredCKAN         = sys.argv[3] if len(sys.argv) > 3 else '' # http://hub.healthdata.gov/dataset/
sourceID             = os.path.basename(os.getcwd())            # hub-healthdata-gov

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
         'DIST_URL'             : URL,
         'MIRRORED_CKAN'        : mirroredCKAN,
         'MIRRORED_AGENT'       : re.sub('(http://[^/]*)/.*$','\\1',mirroredCKAN),
      }

      template='''@prefix rdfs:       <http://www.w3.org/2000/01/rdf-schema#> .
@prefix conversion: <http://purl.org/twc/vocab/conversion/> .
@prefix dcat:       <http://www.w3.org/ns/dcat#> .
@prefix void:       <http://rdfs.org/ns/void#> .
@prefix prov:       <http://www.w3.org/ns/prov#> .
@prefix datafaqs:   <http://purl.org/twc/vocab/datafaqs#> .
@prefix :           <CSV2RDF4LOD_BASE_URI/id/> .

<CSV2RDF4LOD_BASE_URI/source/SOURCE_ID/dataset/DATASET_ID>
   a void:Dataset, dcat:Dataset;
   conversion:source_identifier  "SOURCE_ID";
   conversion:dataset_identifier "DATASET_ID";
   prov:wasDerivedFrom :as_a_csv_UUID;
.

:as_a_csv_UUID
   a dcat:Distribution;
   dcat:downloadURL <DIST_URL>;
.

<SOURCE_CKAN/dataset/DATASET_ID>
   a dcat:Dataset, datafaqs:CKANDataset;
   dcat:distribution :as_a_csv_UUID;
   prov:wasAttributedTo <SOURCE_AGENT>;
.
'''
      if len(mirroredCKAN) > 0:
         template = template + '''
<SOURCE_CKAN/dataset/DATASET_ID> 
   prov:alternateOf <MIRRORED_CKAN/dataset/DATASET_ID>;
.

<MIRRORED_CKAN/dataset/DATASET_ID>
   a dcat:Dataset, datafaqs:CKANDataset;
   prov:alternateOf <SOURCE_CKAN/dataset/DATASET_ID>;
   prov:wasAttributedTo <MIRRORED_AGENT>;
.
'''
      template = template + '''
#3> <> prov:wasGeneratedBy [ 
#3>    a prov:Activity; 
#3>    prov:qualifiedAssociation [ 
#3>       a prov:Association;
#3>       prov:hadPlan <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-create-dataset-dirs-from-ckan.py>;
#3>    ];
#3>    rdfs:seeAlso <https://github.com/jimmccusker/twc-healthdata/wiki/Accessing-CKAN-listings>;
#3> ] .
#3> <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-create-dataset-dirs-from-ckan.py>
#3>    a prov:Plan;
#3>    dcterms:title "'''+os.path.basename(sys.argv[0])+'''" ;
#3> .
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
