#!/usr/bin/env python
#
#3> <> rdfs:seeAlso <https://github.com/timrdf/csv2rdf4lod-automation/wiki/tic-turtle-in-comments> .
#3>
#3> <#> a doap:Project;
#3>   dcterms:description "Download a URL and compute Functional Requirements for Bibliographic Resources (FRBR) stacks using cryptograhic digests for the resulting content.";
#3>   doap:developer <http://tw.rpi.edu/instances/JamesMcCusker>;
#3>   doap:helper    <http://purl.org/twc/id/person/TimLebo>;
#3>   rdfs:seeAlso <https://github.com/timrdf/csv2rdf4lod-automation/wiki/Script:-pcurl.py>;
#3> .

from rdflib import *
from surf import *

from fstack import *
import re, os

import rdflib
import hashlib
import httplib
from urlparse import urlparse, urlunparse
import dateutil.parser

import subprocess
import platform

from serializer import *

from StringIO import StringIO

# These are the namespaces we are using.  They need to be added in
# order for the Object RDF Mapping tool to work.
ns.register(frbr="http://purl.org/vocab/frbr/core#")
ns.register(frir="http://purl.org/twc/ontology/frir.owl#")
ns.register(pexp="tag:tw.rpi.edu,2011:expression:")
ns.register(pmanif="tag:tw.rpi.edu,2011:manifestation:")
ns.register(pitem="tag:tw.rpi.edu,2011:item:")
ns.register(nfo="http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#")
ns.register(irw='http://www.ontologydesignpatterns.org/ont/web/irw.owl#')
ns.register(hash="di:")
ns.register(prov="http://www.w3.org/ns/prov#")
ns.register(http="http://www.w3.org/2011/http#")
ns.register(header="http://www.w3.org/2011/http-headers#")
ns.register(method="http://www.w3.org/2011/http-methods#")
ns.register(status="http://www.w3.org/2011/http-statusCodes#")

def call(command):
    p = subprocess.Popen(command,shell=True,stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    result = p.communicate()
    return result

def getController(Agent):
    return Agent(call('$CSV2RDF4LOD_HOME/bin/util/user-account.sh --cite')[0][1:-2])

connections = {'http':httplib.HTTPConnection,
               'https':httplib.HTTPSConnection}

def getResponse(url):
    o = urlparse(str(url))
    #print o
    connection = connections[o.scheme](o.netloc)
    fullPath = urlunparse([None,None,o.path,o.params,o.query,o.fragment])
    connection.request('GET',fullPath)
    return connection.getresponse()

def pcurl(url):
    ns.register(workurl=url+'#')
    pStore = Store(reader="rdflib", writer="rdflib",
                       rdflib_store='IOMemory')
    pSession = Session(pStore)
    Work = pSession.get_class(ns.FRBR['Work'])

    Agent = pSession.get_class(ns.PROV['Agent'])
    Entity = pSession.get_class(ns.PROV['Entity'])

    controller = getController(Agent)
    
    work = Work(url)
    works = set([url])
    response = getResponse(url)
    content = response.read()
    originalWork = work

    while response.status >= 300 and response.status < 400:
        newURL = response.msg.dict['location']
        if newURL in works:
            raise Exception("Redirect loop")
        works.add(newURL)
        newWork = Work(newURL)
        newWork.save()
        work.irw_redirectsTo.append(newWork)
        work.save()
        work = newWork
        response = getResponse(work.subject)
        content = response.read()
    if response.status != 200:
        raise Exception(response.reason)
    pSession.commit()

    #work = originalWork
    workURI = str(work.subject)
    FileHash = work.session.get_class(ns.NFO['FileHash'])
    ContentDigest = work.session.get_class(ns.FRIR['ContentDigest'])
    Item = work.session.get_class(ns.FRBR['Item'])
    Request = work.session.get_class(ns.HTTP['Request'])
    RequestHeader = work.session.get_class(ns.HTTP['RequestHeader'])
    Response = work.session.get_class(ns.HTTP['Response'])
    ResponseHeader = work.session.get_class(ns.HTTP['ResponseHeader'])
    Method = work.session.get_class(ns.HTTP["Method"])
    GET = Method(ns.METHOD["GET"])
    GET.rdfs_label = "HTTP 1.1 GET"
    Manifestation = work.session.get_class(ns.FRBR['Manifestation'])
    Expression = work.session.get_class(ns.FRBR['Expression'])
    ProcessExecution = work.session.get_class(ns.PROV['Activity'])

    o = urlparse(str(workURI))
    filename = [f for f in o.path.split("/") if len(f) > 0][-1]
    #print filename
    
    f = open(filename,"wb+")
    f.write(content)
    f.close()

    mimetype = response.msg.dict['content-type']
    pStore, localItem = fstack(open(filename,'rb+'),filename,workURI,pStore,mimetype)
    #localItem = Item(localItem.subject)

    itemHashValue = createItemHash(url, response, content)

    item = Response(ns.PITEM['-'.join(itemHashValue[:2])])
    item.http_httpVersion = '1.1'
    for field in response.msg.dict.keys():
        header = ResponseHeader()
        header.http_fieldName = field
        header.http_fieldValue = response.msg.dict[field]
        header.http_hdrName = ns.HEADER[field.lower()]
        header.save()
        item.http_headers.append(header)
    item.nfo_hasHash.append(createHashInstance(itemHashValue,FileHash))
    item.dcterms_date = dateutil.parser.parse(response.msg.dict['date'])
    item.frbr_exemplarOf = localItem.frbr_exemplarOf

    provF = open(filename+".prov.ttl","wb+")

    localItem.frbr_reproductionOf.append(item)

    getPE = Request()
    getPE.http_methd = GET
    getPE.http_requestURI = workURI
    getPE.dcterms_date = localItem.dcterms_date
    getPE.prov_hadPlan.append(GET)
    getPE.prov_wasAttributedTo = controller
    getPE.prov_used.append(item)
    getPE.http_resp = item
    localItem.prov_wasGeneratedBy = getPE
    
    item.save()
    localItem.save()
    getPE.save()

    pSession.commit()
    bindPrefixes(pStore.reader.graph)
    provF.write(pStore.reader.graph.serialize(format="turtle"))

def usage():
    print '''usage: pcurl.py [--help|-h] [--format|-f xml|turtle|n3|nt] [url ...]

Download a URL and compute Functional Requirements for Bibliographic Resources
(FRBR) stacks using cryptograhic digests for the resulting content.

Refer to http://purl.org/twc/pub/mccusker2012parallel
for more information and examples.

optional arguments:
 url            url to compute a FRBR stack for.
 -h, --help     Show this help message and exit,
 -f, --format   File format for FRBR stacks. One of xml, turtle, n3, or nt.
'''

if __name__ == "__main__":
    urls = []
    i = 1
    fileFormat = 'turtle'
    extension = 'ttl'

    if '-h' in sys.argv or '--help' in sys.argv:
        usage()
        quit()
    while i < len(sys.argv):
        if sys.argv[i] == '-f' or sys.argv[i] == '--format':
            fileFormat = sys.argv[i+1]
            try:
                extension = typeExtensions[fileFormat]
            except:
                usage()
                quit(1)
            i += 1
        else:
            try:
                o = urlparse(str(sys.argv[i]))
                urls.append(sys.argv[i])
            except:
                usage()
                quit(1)
                
        i += 1

    for arg in urls:
        pcurl(arg)
