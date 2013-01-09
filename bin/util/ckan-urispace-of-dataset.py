#!/usr/bin/env python
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/ckan-urispace-of-dataset.py>;
#3>    prov:wasDerivedFrom   <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/ckan-datasets-in-group.py>;
#
# Requires: http://pypi.python.org/pypi/ckanclient
# easy_install http://pypi.python.org/packages/source/c/ckanclient/ckanclient-0.10.tar.gz

import sys, ckanclient

def urispace_of_dataset(ckan_loc='http://datahub.io', dataset_name='2000-us-census-rdf'):
   ckan = ckanclient.CkanClient(base_location=ckan_loc+'/api')
   dataset = ckan.package_entity_get(dataset_name)

   # u'extras': {u'namespace': u'http://www.rdfabout.com/rdf/usgov/geo/'

   if 'extras' in dataset:
      if 'namespace' in dataset['extras']:
         print dataset['extras']['namespace']

if __name__=='__main__':
   if len(sys.argv) == 1:
      urispace_of_dataset()
   elif len(sys.argv) == 2:
      urispace_of_dataset(dataset_name=sys.argv[1])
   elif len(sys.argv) == 3:
      urispace_of_dataset(ckan_loc=sys.argv[1], dataset_name=sys.argv[2])
