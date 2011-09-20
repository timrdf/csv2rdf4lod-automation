#!/usr/bin/env python

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
ns.register(pexp="hash:Expression/")
ns.register(pmanif="hash:Manifestation/")
ns.register(pitem="hash:Item/")
ns.register(nfo="http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#")
ns.register(irw='http://www.ontologydesignpatterns.org/ont/web/irw.owl#')
ns.register(hash="hash:")
ns.register(prov="http://dvcs.w3.org/hg/prov/raw-file/tip/ontology/ProvenanceOntology.owl#")
    

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

    #work = originalWork
    workURI = str(work.subject)
    FileHash = work.session.get_class(ns.NFO['FileHash'])
    ContentDigest = work.session.get_class(ns.FRIR['ContentDigest'])
    Item = work.session.get_class(ns.FRBR['Item'])
    Result = work.session.get_class(ns.FRIR['HTTP_1_1_Result'])
    Get = work.session.get_class(ns.FRIR['HTTP_1_1_GET'])
    Manifestation = work.session.get_class(ns.FRBR['Manifestation'])
    Expression = work.session.get_class(ns.FRBR['Expression'])
    ProcessExecution = work.session.get_class(ns.PROV['ProcessExecution'])
    #httpGetURI = "http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html#sec9.3"

    o = urlparse(str(workURI))
    filename = o.path.split("/")[-1]

    f = open(filename,"wb+")
    f.write(content)
    f.close()

    pStore, localItem = fstack(open(filename,'rb+'),filename,url,pStore,response.msg.dict['content-type'])
    #localItem = Item(localItem.subject)

    itemHashValue = createItemHash(url, response, content)

    item = Result(ns.PITEM['-'.join(itemHashValue)])
    item.frir_hasHeader = ''.join(response.msg.headers)
    item.nfo_hasHash.append(createHashInstance(itemHashValue,FileHash))
    item.dcterms_date = dateutil.parser.parse(response.msg.dict['date'])
    item.frbr_exemplarOf = localItem.frbr_exemplarOf

    provF = open(filename+".prov.ttl","wb+")

    localItem.frbr_reproductionOf.append(item)

    getPE = Get()
    getPE.dcterms_date = localItem.dcterms_date
    getPE.prov_used.append(ns.FRIR['HTTP_1_1_GET'])
    getPE.prov_wasControlledBy = controller
    getPE.prov_used.append(item)
    localItem.prov_wasGeneratedBy = getPE
    
    item.save()
    localItem.save()
    getPE.save()
    
    bindPrefixes(pStore.reader.graph)
    provF.write(pStore.reader.graph.serialize(format="turtle"))

def usage():
    print '''usage: pcurl.py [--help|-h] [--format|-f xml|turtle|n3|nt] [url ...]

Download a URL and compute Functional Requirements for Bibliographic Resources
(FRBR) stacks using cryptograhic digests for the resulting content.

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
