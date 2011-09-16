#!/usr/bin/env python

from rdflib import *
from surf import *

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
ns.register(pexp="http://sparql.tw.rpi.edu/services/frbr/instances/Expression/")
ns.register(pmanif="http://sparql.tw.rpi.edu/services/frbr/instances/Manifestation/")
ns.register(pitem="http://sparql.tw.rpi.edu/services/frbr/instances/Item/")
ns.register(nfo="http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#")
ns.register(irw='http://www.ontologydesignpatterns.org/ont/web/irw.owl#')
ns.register(hash="hash:")
ns.register(prov="http://w3.org/ProvenanceOntology.owl#")


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
    print o
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

    work = originalWork
    workURI = str(work.subject)
    FileHash = work.session.get_class(ns.NFO['FileHash'])
    Item = work.session.get_class(ns.FRBR['Item'])
    Manifestation = work.session.get_class(ns.FRBR['Manifestation'])
    Expression = work.session.get_class(ns.FRBR['Expression'])
    ProcessExecution = work.session.get_class(ns.PROV['ProcessExecution'])
    httpGetURI = "http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html#sec9.3"

    itemHashValue = createItemHash(workURI, response,content)
    item = Item(ns.WORKURL['item-'.join(itemHashValue)])
    item.nfo_hasHash.append(createHashInstance(itemHashValue,FileHash))
    item.dc_date = dateutil.parser.parse(response.msg.dict['date'])

    o = urlparse(str(url))
    filename = o.path.split("/")[-1]
    dirname = os.getcwd()
    absFileName = dirname+os.sep+filename

    f = open(absFileName,"wb+")
    provF = open(absFileName+".prov.ttl","wb+")
    f.write(content)
    f.close()
    
    hostname = platform.uname()[1]
    path = absFileName
    if os.sep == '\\':
        path = '/'+absFileName.replace('\\','/').replace(':','|')
    localURI = 'file://'+hostname+path
    
    manifestationHashValue = createManifestationHash(workURI, response,content)

    localItemHashValue = manifestationHashValue
    localItem = Item(localURI+"#item-"+'-'.join(localItemHashValue))
    localItem.nfo_hasHash.append(createHashInstance(localItemHashValue,FileHash))
    localItem.dc_date = dateutil.parser.parse(response.msg.dict['date'])

    manifestation = Manifestation(ns.WORKURL['manifestation-'.join(manifestationHashValue)])
    manifestation.nfo_hasHash.append(createHashInstance(manifestationHashValue,FileHash))
        
    manifestation.frbr_exemplar.append(item)
    item.frbr_exemplarOf.append(manifestation)
    manifestation.frbr_exemplar.append(localItem)
    localItem.frbr_exemplarOf.append(manifestation)

    localItem.frbr_reproductionOf.append(item)

    getPE = ProcessExecution()
    getPE.dc_date = localItem.dc_date
    getPE.rdf_type = URIRef(httpGetURI)
    getPE.prov_used.append(URIRef(httpGetURI))
    getPE.prov_wasControlledBy = controller
    getPE.prov_used.append(item)
    localItem.prov_wasGeneratedBy = getPE
    
    manifestation.save()
    item.save()
    localItem.save()
    getPE.save()
        
    expressionHashValue = createExpressionHash(workURI, response,content)
    expression = Expression(ns.WORKURL['expression-'.join(expressionHashValue)])
    expression.nfo_hasHash.append(createHashInstance(expressionHashValue,FileHash))

    expression.frbr_embodiment.append(manifestation)
    manifestation.frbr_embodimentOf.append(expression)
    manifestation.save()
    expression.save()

    work.frbr_realization.append(expression)
    expression.frbr_realizationOf.append(work)
    expression.save()
    work.save()
    
    provF.write(pStore.reader.graph.serialize(format="turtle"))
    
def createItemHash(workURI, response, content):
    m = hashlib.sha256()
    m.update(workURI+'\n')
    m.update(''.join(response.msg.headers))
    m.update(content)
    return ['SHA256',m.hexdigest()]

def createManifestationHash(workURI,response, content):
    m = hashlib.sha256()
    # TODO: should the hash include these elements?
    #m.update(workURI+'\n')
    #m.update('Content Type: '+response.msg.dict['content-type']+'\n')
    m.update(content)
    return ['SHA256',m.hexdigest()]

def createExpressionHash(workURI, response, content):
    store = Store(reader='rdflib',
                  writer='rdflib',
                  rdflib_store = 'IOMemory')
        
    session = Session(store)
    try:
        deserialize(store, content, response.msg.dict['content-type'])
    except:
        try:
            extension = workURI.split('.')[-1]
            store.reader.graph.parse(StringIO(content),
                                     extensions[extension])
        except:
            return createManifestationHash(workURI,response, content)
    graph = store.reader.graph

    serializers = {Literal:lambda x: '"'+x+'"@'+str(x.language)+'^^'+str(x.datatype),
                   URIRef:lambda x: '<'+str(x)+'>',
                   BNode:lambda x: '['+str(x)+']'}
    total = 0
    for stmt in graph:
        s = ' '.join([serializers[type(x)](x) for x in stmt])
        m = hashlib.sha256()
        m.update(s)
        total += int(m.hexdigest(),16)
    return ['GRAPH_SHA256','%x'%total]

def createHashInstance(h, FileHash):
    hsh = FileHash(ns.HASH['-'.join(h)])
    hsh.nfo_hashAlgorithm = h[0]
    hsh.nfo_hasValue = h[1]
    hsh.save()
    return hsh

if __name__ == "__main__":
    for arg in sys.argv[1:]:
        pcurl(arg)
