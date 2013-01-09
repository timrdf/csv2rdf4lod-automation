#!/usr/bin/env python
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/ckan-datasets-in-group.py>;
#3>    prov:wasDerivedFrom   <https://raw.github.com/timrdf/DataFAQs/master/packages/faqt.python/faqt/faqt.py>,
#3>                          <https://github.com/timrdf/DataFAQs/raw/master/services/sadi/ckan/lift-ckan.py>;
#
# Requires: http://pypi.python.org/pypi/ckanclient
# easy_install http://pypi.python.org/packages/source/c/ckanclient/ckanclient-0.10.tar.gz

import ckanclient

def datasets_in_group(ckan_loc='http://datahub.io', group_name='lodcloud'):
   ckan = ckanclient.CkanClient(base_location=ckan_loc+'/api')
   group = ckan.group_entity_get(group_name)
   for dataset in group['packages']:
      print dataset

if __name__=='__main__':
    datasets_in_group()
