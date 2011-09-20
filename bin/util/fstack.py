#!/usr/bin/env python

from rdflib import *
from surf import *

import re, os

import rdflib
import hashlib
import httplib
from urlparse import urlparse, urlunparse
import dateutil.parser
from datetime import datetime

import subprocess
import platform

import uuid

from serializer import *

from StringIO import StringIO

import fileinput


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
ns.register(uuid="uuid:")
ns.register(file="file://"+str(uuid.uuid1()))
ns.register(prov="http://w3.org/ProvenanceOntology.owl#")

def fstack(fd, filename=None, workuri=None, pStore = None, mimetype=None):
    if workuri == None:
        workuri = ns.UUID[str(uuid.uuid4())]
    else:
        workuri = URIRef(workuri)
    if pStore == None:
        pStore = Store(reader="rdflib", writer="rdflib",
                       rdflib_store='IOMemory')
    pSession = Session(pStore)
    Work = pSession.get_class(ns.FRBR['Work'])
    
    work = Work(workuri)
    workURI = str(work.subject)

    FileHash = work.session.get_class(ns.NFO['FileHash'])
    ContentDigest = work.session.get_class(ns.FRIR['ContentDigest'])
    Item = work.session.get_class(ns.FRBR['Item'])
    Manifestation = work.session.get_class(ns.FRBR['Manifestation'])
    Expression = work.session.get_class(ns.FRBR['Expression'])

    fileURI = None
    if filename != None:
        fileURI = ns.FILE[os.path.abspath(filename)]

    content = fd.read()
    
    manifestationHashValue = createManifestationHash(content)

    if fileURI == None:
        fileURI = ns.PITEM['-'.join(manifestationHashValue)]

    timestamp = datetime.utcnow()

    itemHashValue = manifestationHashValue
    item = Item(fileURI)
    item.nfo_hasHash.append(createHashInstance(itemHashValue,FileHash))
    item.dc_date = timestamp

    manifestation = Manifestation(ns.PMANIF['-'.join(manifestationHashValue)])
    manifestation.nfo_hasHash.append(createHashInstance(manifestationHashValue,FileHash))
        
    item.frbr_exemplarOf.append(manifestation)

    manifestation.save()
    item.save()
    
    expressionHashValue = createExpressionHash(filename, content, mimetype)
    expression = Expression(ns.PEXP['-'.join(expressionHashValue)])
    expression.nfo_hasHash.append(createHashInstance(expressionHashValue,ContentDigest))

    manifestation.frbr_embodimentOf.append(expression)
    manifestation.save()
    expression.save()

    expression.frbr_realizationOf.append(work)
    expression.save()
    work.save()

    return pStore, item

def createItemHash(workURI, response, content):
    m = hashlib.sha256()
    m.update(workURI+'\n')
    m.update(''.join(response.msg.headers))
    m.update(content)
    return ['SHA256',m.hexdigest()]

def createManifestationHash(content):
    m = hashlib.sha256()
    m.update(content)
    return ['SHA256',m.hexdigest()]

def createExpressionHash(filename, content, mimetype=None):
    store = Store(reader='rdflib',
                  writer='rdflib',
                  rdflib_store = 'IOMemory')
        
    session = Session(store)
    try:
        deserialize(store, content, mimetype)
    except:
        try:
            if filename != None:
                extension = filename.split('.')[-1]
                store.reader.graph.parse(StringIO(content),
                                         extensions[extension])
        except:
            return createManifestationHash(content)
    graph = store.reader.graph

    serializers = {Literal:lambda x: '"'+x+'"@'+str(x.language)+'^^'+str(x.datatype),
                   URIRef:lambda x: '<'+str(x)+'>',
                   BNode:lambda x: '['+str(x)+']'}
    total = 0
    for stmt in graph:
        s = ' '.join([serializers[type(x)](x) for x in stmt])
        m = hashlib.sha256()
        m.update(s.encode('utf-8'))
        total += int(m.hexdigest(),16)
    return ['GRAPH_SHA256','%x'%total]

def createHashInstance(h, Hash):
    hsh = Hash(ns.HASH['-'.join(h)])
    hsh.nfo_hashAlgorithm = h[0]
    hsh.nfo_hashValue = h[1]
    hsh.save()
    return hsh

def usage():
    print '''usage: fstack.py [--help|-h] [--stdout|-c] [--format|-f xml|turtle|n3|nt] [-] [file ...]

Compute Functional Requirements for Bibliographic Resources (FRBR) stacks using cryptograhic digests.

optional arguments:
 file           file to compute a FRBR stack for.
 -              read content from stdin and print FRBR stack to stdout.
 -h, --help     Show this help message and exit,
 -c, --stdout   Print frbr stacks to stdout.
 -f, --format   File format for FRBR stacks. One of xml, turtle, n3, or nt.
'''

if __name__ == "__main__":
    files = []
    i = 1
    stdout = False
    fileFormat = 'turtle'
    extension = 'ttl'

    if '-h' in sys.argv or '--help' in sys.argv:
        usage()
        quit()
    while i < len(sys.argv):
        if sys.argv[i] == '-c' or sys.argv[i] == '--stdout':
            stdout = True
        elif sys.argv[i] == '-f' or sys.argv[i] == '--format':
            fileFormat = sys.argv[i+1]
            try:
                extension = typeExtensions[fileFormat]
            except:
                usage()
                quit(1)
            i += 1
        else:
            files.append(sys.argv[i])

        i += 1

    for line in fileinput.input(files):
        store = None
        if fileinput.isstdin():
            store = fstack(StringIO(line))
            bindPrefixes(store[0].reader.graph)
            print store[0].reader.graph.serialize(format=fileFormat)
        else:
            store = fstack(StringIO(line),fileinput.filename())
            bindPrefixes(store[0].reader.graph)
            store[0].reader.graph.serialize(open(fileinput.filename()+".prov."+extension,'wb+'),format=fileFormat)
