#!/usr/bin/python
#
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/cr-create-lodcloud-link-queries.py

import os

bubbles = {}
bubbles['dbpedia']               = 'http://dbpedia.org/resource'
bubbles['geonames-semantic-web'] = 'http://sws.geonames.org'
bubbles['govtrack']              = 'http://www.rdfabout.com/rdf/usgov'

for shorthand in bubbles.keys():
   filename = 'links-'+shorthand+'.rq'
   if not(os.path.exists(filename)):
      print filename
      query_file = open(filename, 'w')
      query_file.write('prefix owl: <http://www.w3.org/2002/07/owl#>\n\
\n\
select distinct ?o\n\
where {\n\
   graph ?g {\n\
      ?s owl:sameAs ?o\n\
   }\n\
   filter(regex(str(?o),"^')
      query_file.write(bubbles[shorthand])
      query_file.write('*"))\n\
}\n')
      query_file.close()
   else:
      print filename + " already exists. Not modifying."
