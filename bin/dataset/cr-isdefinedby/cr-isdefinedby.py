#!/usr/bin/env python
#
# Usage:
#

from datetime import *
import sys, os, urllib, csv, re

USAGE = '''usage: '''+os.path.basename(sys.argv[0])+''' endpoint

   endpoint : URI of a SPARQL endpoint.
              e.g. http://logd.tw.rpi.edu/sparql'''

def ns(term):
   hashBased = re.sub('#.*$','#',term)
   if hashBased is not term:
      return hashBased
   else:
      return re.sub('^(.*/)[^/]*$','\\1',term)

def domain(term):
   if re.match('(http://purl.org/[^/]*)/.*$',term):
      return re.sub('(http://purl.org/[^/]*/).*$','\\1',term)
   else:
      return re.sub('(http://[^/]*/).*$','\\1',term)

def retrieve(endpoint, pattern):

   limit    = 1000
   offset   = 0

   nonempty = True
   while nonempty:

      query = pattern+" limit "+str(limit)+" offset "+str(offset) 
      datasetURL = endpoint + "?" + urllib.urlencode([("query",query)]) + "&format=text%2Fcsv&timeout=0&debug=on"
      print >> sys.stderr, str(limit) + " " + str(offset) + " " + datasetURL

      for line in csv.reader(urllib.urlopen(datasetURL),delimiter=","):
         term = line[0]
         if term is 'p' or term is 'c':
            nonempty = False
         else:
            print '<{0}> <http://www.w3.org/2000/01/rdf-schema#isDefinedBy> <{1}> .'.format(term,ns(term))
            print '<{0}> <http://www.w3.org/ns/prov#wasAttributedTo>        <{1}> .'.format(term,domain(term))
            nonempty = True

      offset += limit

if __name__=='__main__':

   if len(sys.argv) is not 2 or sys.argv[1] == "--help":
      sys.stderr.write(USAGE+'\n')
      sys.exit(1)

   prefixes = 'prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> '

   #optional = 'optional {?p rdfs:isDefinedBy ?def} filter(!bound(?def))' # SPARQL 1.0
   optional = 'filter not exists { ?p rdfs:isDefinedBy [] } '             # SPARQL 1.1
   retrieve(sys.argv[1], prefixes + 'select distinct ?p where { graph ?g { [] ?p [] } ' + optional + '}')

   #optional = 'optional {?c rdfs:isDefinedBy ?def} filter(!bound(?def))' # SPARQL 1.0
   optional = 'filter not exists { ?c rdfs:isDefinedBy [] } '             # SPARQL 1.1
   retrieve(sys.argv[1], prefixes + 'select distinct ?c where { graph ?g { [] a ?c } ' + optional + '}')
