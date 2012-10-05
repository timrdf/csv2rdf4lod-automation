#!/usr/bin/env python
#
# Requires: http://pypi.python.org/pypi/googlemaps
# easy_install http://pypi.python.org/packages/source/g/googlemaps/googlemaps-1.0.2.tar.gz
# 
# Requires: X_GOOGLE_MAPS_API_Key environment variable.
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/secondary/cr-address-coordinates.py>;
#3>    prov:wasDerivedFrom <https://github.com/jimmccusker/twc-healthdata/tree/master/data/source/healthdata-tw-rpi-edu/address-coordinates/version>;
#3>    prov:wasAttributedTo <http://tw.rpi.edu/instances/JamesMcCusker>;
#3> .
#
# Usage:
#
# 1) Retrieve the results, and store its provenance in a separate file:
#   cr-address-coordinates.py http://healthdata.tw.rpi.edu/sparql > b.ttl
#   cr-address-coordinates.py http://healthdata.tw.rpi.edu/sparql --prov b.ttl > b.ttl.prov.ttl
#
# 2) Retrieve the results, and embed its provenance within the same file:
#   cr-address-coordinates.py http://healthdata.tw.rpi.edu/sparql > c.ttl
#   cr-address-coordinates.py http://healthdata.tw.rpi.edu/sparql --prov | awk '{print "#3> "$0}' >> c.ttl

from googlemaps import GoogleMaps, GoogleMapsError
import os, json
from datetime import *
import csv, sys, urllib, os, collections, datetime

query = '''prefix vcard: <http://www.w3.org/2006/vcard/ns#>
prefix wgs:  <http://www.w3.org/2003/01/geo/wgs84_pos#>

select distinct ?address ?streetAddress ?streetAddress2 ?locality ?region ?postalCode ?country 
where {
  ?address a vcard:Address.
  OPTIONAL { ?address vcard:street-address   ?streetAddress }
  OPTIONAL { ?address vcard:extended-address ?streetAddress2 }
  OPTIONAL { ?address vcard:locality         ?locality }
  OPTIONAL { ?address vcard:region           ?region }
  OPTIONAL { ?address vcard:postal-code      ?postalCode }
  OPTIONAL { ?address vcard:country-name     ?country }

  OPTIONAL { ?address wgs:latitude ?lat; wgs:longitude ?long }
  FILTER (!bound(?lat) && !bound(?long))
} limit 100'''

def retrieve(endpoint, api_key):
    
    gmaps = GoogleMaps(api_key)
    url = endpoint + '?' + urllib.urlencode([("query",query)]) + '&format=text%2Fcsv'
    header = None
    print >> sys.stderr, url
    
    for line in csv.reader(urllib.urlopen(url),delimiter=","):
        if header == None:
            header = line
            continue
        addressURI = line[0]
        address = ", ".join([x for x in line[1:] if x != ""])
        try:
           lat, lng = gmaps.address_to_latlng(address)
        except GoogleMapsError:
           print >> sys.stderr, 'GoogleMapsError'
        
        print '{},{},{}'.format(addressURI,lat,lng)
  
if __name__=='__main__':

    USAGE = '''usage: cr-address-coordinates.py <endpoint> [--prov <output-file>]

                     endpoint : URI of a SPARQL endpoint.
                                e.g. http://healthdata.tw.rpi.edu/sparql

         --prov <output-file> : Print the provenance about <output-file>, created by calling without --prov.
'''

    if len(sys.argv) not in [2,3,4] or sys.argv[1] == "--help":
       sys.stderr.write(USAGE+'\n')
       sys.exit(1)

    endpoint = sys.argv[1] # http://healthdata.tw.rpi.edu/sparql

    if len(sys.argv) == 2:

       api_key = os.environ['X_GOOGLE_MAPS_API_Key'] # api_key must be defined to POST/PUT.
       retrieve(endpoint, api_key)

    elif len(sys.argv) > 2 and sys.argv[2] == '--prov':
       print '''@prefix prov: <http://www.w3.org/ns/prov#> .
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@prefix xsd:  <http://www.w3.org/2001/XMLSchema#> .

<{outputfile}>
  prov:wasGeneratedBy [
    a prov:Activity, <https://raw.github.com/timrdf/csv2rdf4lod-automation/master/bin/secondary/cr-address-coordinates.py>;

    prov:qualifiedAssociation [
      a prov:Association;
      prov:hadPlan <https://raw.github.com/timrdf/csv2rdf4lod-automation/master/bin/secondary/cr-address-coordinates.py>;
    ];
    prov:used [
      prov:value """{sparql}""";
    ];
    prov:used <http://maps.googleapis.com/maps/api/geocode/>;
    prov:endedAtTime "{end}"^^xsd:dateTime;
  ];
.

<https://raw.github.com/timrdf/csv2rdf4lod-automation/master/bin/secondary/cr-address-coordinates.py> a prov:Plan;
  foaf:homepage <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/secondary/cr-address-coordinates.py> .
'''.format(outputfile=sys.argv[3] if len(sys.argv) > 3 else '', sparql=query, end=datetime.datetime.now().isoformat()) 
