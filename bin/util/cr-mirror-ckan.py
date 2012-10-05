#!/usr/bin/env python
#
#3> <> prov:wasDerivedFrom 
#3>    <https://github.com/jimmccusker/twc-healthdata/blob/master/ckan/mirror.py>;
#3>    prov:specializationOf 
#3>    <https://github.com/timrdf/csv2rdf4lod-automation/tree/master/bin/util> .

import os, sys, json

import ckanclient  # see https://github.com/okfn/ckanclient README
# Get latest download URL from http://pypi.python.org/pypi/ckanclient#downloads --\/
# sudo easy_install http://pypi.python.org/packages/source/c/ckanclient/ckanclient-0.10.tar.gz

# See also https://github.com/timrdf/DataFAQs/wiki/CKAN
#    section "Automatically publish dataset on CKAN"

def mirror_ckan(source, target, api_key, dryrun, update):

   sourceCKAN = ckanclient.CkanClient(base_location=source)
   targetCKAN = ckanclient.CkanClient(base_location=target, api_key=api_key)

   indent = '    '
   for name in sourceCKAN.package_register_get():
      
      #if name == 'hospital-compare':

      sourceCKAN.package_entity_get(name) # Get the dataset description.
      dataset = sourceCKAN.last_message

      altID   = source.replace('/api','') + '/dataset/' + dataset['id']
      altName = source.replace('/api','') + '/dataset/' + dataset['name']
      dataset['extras']['prov_alternateOf'] = altName
      # Would like to assert two alternates, but their model is limiting.

      if not dryrun: del dataset['id']     # DELETING
      print name + ' ' + dataset['name']
      if 'download_url' in dataset:
         print indent + 'download_url: ' + dataset['download_url']
      if 'url' in dataset:
         print indent + 'url:          ' + dataset['url']
      for resource in dataset['resources']:
         if not dryrun: del resource['id'] # DELETING
         if 'url' in resource:
            print indent + 'resource:     ' + resource['url']
            print indent + 'format:       ' + resource['format']
            # Formats seen on healthdata.gov: 
            #    CSV Text XLS XML Feed Query API Widget RDF
      #print json.dumps(dataset,sort_keys=True, indent=4)
      if not dryrun:
         try: # See if dataset is listed in targetCKAN
            targetCKAN.package_entity_get(dataset['name'])
            if update: 
               # Update target's existing entry from source's
               targetCKAN.package_entity_put(dataset) 
            else:
               print ('NOTE: skipping ' + dataset['name'] + ' ' +
                     'b/c already listed at ' + target)

            #update = targetCKAN.last_message
            #update['notes'] = 'Updated.'
            #targetCKAN.package_entity_put(update)

         except ckanclient.CkanApiNotFoundError:
            # Dataset is not listed on this CKAN
            print 'INFO: adding ' + dataset['name'] + ' to ' + target
            try:
               targetCKAN.package_register_post(dataset) # POST
            except ckanclient.CkanApiConflictError:
               print ('WARNING: '+
                     'Conflict error when trying to POST ' + dataset['name'])

   #new_dataset = {
   # 'name':  'test-dataset-3',
   # 'notes': 'automatic submission',
   #}

if __name__=='__main__':

   if len(sys.argv) < 3 or sys.argv[1] == '--help':
      print "Usage: cr-mirror-ckan.py source target [--api-key key] [--dryrun] [--update-if-exists]"
      print "              source: the URL of the CKAN to replicate."
      print "                      e.g. http://hub.healthdata.gov/api"
      print "              target: the URL of the writable CKAN that should replicate 'source'."
      print "                      e.g. http://aquarius.tw.rpi.edu/projects/healthdata/api"
      print "           --api-key: the API key to 'target' (if omitted, will access X_CKAN_API_Key environment variable)."
      print "            --dryrun: do NOT modify 'target'; just print a description of what would happen."
      print "  --update-if-exists: if not a dryrun, update the entry in 'target' if it already exists."
      sys.exit(1)
   
   source = sys.argv[1] # e.g. http://hub.healthdata.gov/api
   target = sys.argv[2] # e.g. http://aquarius.tw.rpi.edu/projects/healthdata/api

   api_key = '' # api_key must be defined to POST/PUT.
   if len(sys.argv) > 4 and sys.argv[3] == '--api-key':
      api_key = sys.argv[4] 
      sys.argv.remove('--api-key')
      sys.argv.remove(api_key)
   else:
      api_key = os.environ['X_CKAN_API_Key']

   dryrun = False
   if len(sys.argv) > 3 and sys.argv[3] == '--dryrun':
      dryrun = True 
      sys.argv.remove('--dryrun')

   update = not dryrun and len(sys.argv) > 3 and sys.argv[3] == '--update-if-exists'

   mirror_ckan(source, target, api_key, dryrun, update) 

# ./mirror.py S T
# S T api-key-in-envvars False False
# 
# ./mirror.py S T --update-if-exists
# S T api-key-in-envvars False True
# 
# ./mirror.py S T --api-key my-key! --update-if-exists
# S T my-key! False True
# 
# ./mirror.py S T --api-key my-key! --dryrun --update-if-exists
# S T my-key! True False
# 
# ./mirror.py S T --api-key my-key! --dryrun
# S T my-key! True False
