#!/usr/bin/env python

from rdflib import *
from surf import *

import re, os, sys
from stat import *

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
ns.register(pwork="hash:Work/")
ns.register(pexp="hash:Expression/")
ns.register(pmanif="hash:Manifestation/")
ns.register(pitem="hash:Item/")
ns.register(nfo="http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#")
ns.register(irw='http://www.ontologydesignpatterns.org/ont/web/irw.owl#')
ns.register(hash="hash:")
ns.register(uuid="uuid:")
ns.register(void="http://rdfs.org/ns/void#")
ns.register(ov="http://open.vocab.org/terms/")
ns.register(file="file://"+str(uuid.uuid1()))

serializers = {Literal:lambda x: '"'+x+'"@'+str(x.language)+'^^'+str(x.datatype),
               URIRef:lambda x: '<'+str(x)+'>',
               BNode:lambda x: '['+str(x)+']'}

class RDFGraphDigest:

    rawAllowedProps = set([
        ns.DCTERMS['isReferencedBy'],
        ns.VOID['inDataset'],
        ns.RDFS['label'],
        ns.RDF['type'],
        ns.RDFS['range'],
        ns.OV['csvCol'],
        ns.OV['csvHeader'],
        ns.OV['csvRow']
        ])

    rawRequiredColAnnotations = set([
        ns.OV['csvCol'],
        ns.OV['csvHeader'],
    ])

    rawRequiredRowAnnotations = set([
        ns.OV['csvRow']
    ])

    csvCol = ns.OV['csvCol']
    csvHeader = ns.OV['csvHeader']
    csvRow = ns.OV['csvRow']

    def __init__(self):
        self.total = 0
        self.rawtotal = 0
        self.isRaw = True
        self.algorithm = 'GRAPH_SHA256'
        self.type = ns.FRIR['RDFGraphDigest']

    def hashPredicates(self, graph):
        predicates = graph.predicates()
        result = set([])
        row = URIRef("row:1")
        for p in predicates:
            if p in RDFGraphDigest.rawAllowedProps:
                continue
            a = set(graph.predicates(subject=p))
            if a >= RDFGraphDigest.rawRequiredColAnnotations and a <= RDFGraphDigest.rawAllowedProps:
                col = URIRef("column:"+str(graph.value(p,RDFGraphDigest.csvCol)))
                value = graph.value(p, RDFGraphDigest.csvHeader)
                self.updateStatement((row,col,value),'raw')
                result.add(p)
            else:
                self.isRaw = False
                return None
        return result

    def hashSubjects(self, graph, predicates):
        predicates = graph.predicates()
        triples = set([])
        for stmt in graph:
            if stmt[1] in RDFGraphDigest.rawAllowedProps or stmt[0] in RDFGraphDigest.rawAllowedProps:
                continue
            if stmt[1] in predicates:
                row = graph.value(stmt[0],RDFGraphDigest.csvRow)
                if row == None:
                    self.isRaw = False
                    return
                row = URIRef("row:"+str(row))
                col = URIRef("column:"+str(graph.value(stmt[1],RDFGraphDigest.csvCol)))
                value = stmt[2]
                self.updateStatement((row,col,value), 'raw')
            else:
                self.isRaw = False
                return


    def loadAndUpdate(self,content, filename = None, mimetype = None):
        store = Store(reader='rdflib',
                      writer='rdflib',
                      rdflib_store = 'IOMemory')
        #print mimetype
        session = Session(store)
        try:
            t = deserialize(store.reader.graph, content, mimetype)
            if t != None:
                self.type = t
        except:
            try:
                if filename != None:
                    extension = filename.split('.')[-1]
                    #print extension
                    serializer = contentTypes[extensions[extension]]
                    t = serializer.deserialize(store.reader.graph, content)
                    if len(store.reader.graph) == 0:
                        raise Exception()
                    if t != None:
                        self.type = t
            except:
                #print "Using Manifestation"
                manifHash =  createManifestationHash(content)
                self.algorithm = manifHash[0]
                self.total = int(manifHash[1],16)
                self.type = manifHash[2]
                self.isRaw = False
                return

        graph = store.reader.graph
        self.update(graph)

    def update(self, graph):
        self.triples = set([])
        if self.isRaw:
            predicates = self.hashPredicates(graph)
            if self.isRaw:
                self.hashSubjects(graph,predicates)
                if self.isRaw:
                    return
        for stmt in graph:
            self.updateStatement(stmt)

    def updateStatement(self, stmt, hashType="graph"):
        s = ' '.join([serializers[type(x)](x) for x in stmt])
        m = hashlib.sha256()
        m.update(s.encode('utf-8'))
        stmtDigest = int(m.hexdigest(),16)
        if stmtDigest in self.triples:
            return
        self.triples.add(stmtDigest)
        if hashType == 'graph':
            self.total += stmtDigest
            #print "total", self.total
        else:
            self.rawtotal += stmtDigest
            #print "raw total", stmtDigest

    def getDigest(self):
        if self.isRaw:
            return [self.algorithm,'%x'%self.rawtotal,ns.FRIR['TabularDigest']]
        else:
            return [self.algorithm,'%x'%self.total,self.type]


def createItemURI(filename):
    m = hashlib.sha256()
    m.update(str(uuid.getnode()))
    m.update(str(os.stat(filename)[ST_MTIME]))
    hostAndModTime = m.hexdigest()
    absolutePath = os.path.abspath(filename)
    dirname = os.path.dirname(absolutePath)
    basename = os.path.basename(absolutePath)
    m = hashlib.sha256()
    m.update(dirname)
    pathDigest = '-'.join(['SHA256',m.hexdigest()])
    return "filed://"+hostAndModTime+'/'+pathDigest+'/'+basename

def fstack(fd, filename=None, workuri=None, pStore = None, mimetype=None, addPaths=True):
    if workuri != None:
        workuri = URIRef(workuri)

    if pStore == None:
        pStore = Store(reader="rdflib", writer="rdflib",
                       rdflib_store='IOMemory')
    pSession = Session(pStore)

    Thing = pSession.get_class(ns.OWL['Thing'])
    ContentDigest = pSession.get_class(ns.FRIR['ContentDigest'])
    Item = pSession.get_class(ns.FRBR['Item'])
    Manifestation = pSession.get_class(ns.FRBR['Manifestation'])
    Expression = pSession.get_class(ns.FRBR['Expression'])
    Work = pSession.get_class(ns.FRBR['Work'])

    fileURI = None
    if filename != None:
        fileURI = createItemURI(filename)

    content = fd.read()
    
    manifestationHashValue = createManifestationHash(content)

    if fileURI == None:
        fileURI = ns.PITEM['-'.join(manifestationHashValue)]

    timestamp = datetime.utcnow()

    itemHashValue = manifestationHashValue
    item = Item(fileURI)
    item.nfo_hasHash.append(createHashInstance(itemHashValue,Thing))
    if addPaths and filename != None:
        item.nfo_fileUrl.append(URIRef('file:///'+os.path.abspath(filename)))
        item.nfo_fileUrl.append(URIRef(filename))
    item.dcterms_modified = datetime.fromtimestamp(os.stat(filename)[ST_MTIME])
    item.dcterms_date = timestamp

    manifestation = Manifestation(ns.PMANIF['-'.join(manifestationHashValue[:-1])])
    manifestation.nfo_hasHash.append(createHashInstance(manifestationHashValue,Thing))
        
    item.frbr_exemplarOf.append(manifestation)

    manifestation.save()
    item.save()
    
    expressionHashValue = createExpressionHash(filename, content, mimetype)
    expression = Expression(ns.PEXP['-'.join(expressionHashValue[:-1])])
    expression.nfo_hasHash.append(createHashInstance(expressionHashValue,ContentDigest))

    manifestation.frbr_embodimentOf.append(expression)
    manifestation.save()
    expression.save()

    if workuri != None:
        work = Work(workuri)
    else:
        work = Work(ns.PWORK['-'.join(expressionHashValue[:-1])])

    expression.frbr_realizationOf.append(work)
    expression.save()
    work.save()

    pSession.commit()
    
    return pStore, item

def createItemHash(workURI, response, content):
    m = hashlib.sha256()
    m.update(workURI+'\n')
    m.update(''.join(response.msg.headers))
    m.update(content)
    return ['SHA256',m.hexdigest(), ns.NFO['FileHash']]

def createManifestationHash(content):
    m = hashlib.sha256()
    m.update(content)
    return ['SHA256',m.hexdigest(), ns.NFO['FileHash']]

def createExpressionHash(filename, content, mimetype=None):
    digest = RDFGraphDigest()
    digest.loadAndUpdate(content,filename,mimetype)
    return digest.getDigest()

def createHashInstance(h, Hash):
    hsh = Hash(ns.HASH['-'.join(h[:-1])])
    hsh.nfo_hashAlgorithm = h[0]
    hsh.nfo_hashValue = h[1]
    if len(h) > 2:
        hsh.rdf_type.append(h[2])
    hsh.save()
    return hsh

def usage():
    print '''usage: fstack.py [--help|-h] [--stdout|-c] [--format|-f xml|turtle|n3|nt] [--print-item] [--print-manifesation] [--print-expression] [--print-work] [-] [file ...]

Compute Functional Requirements for Bibliographic Resources (FRBR)
stacks using cryptograhic digests.

Refer to http://purl.org/twc/pub/mccusker2012parallel
for more information and examples.

optional arguments:
 file                  File to compute a FRBR stack for.
 -                     Read content from stdin and print FRBR stack to stdout.
 -h, --help            Show this help message and exit,
 -c, --stdout          Print frbr stacks to stdout.
 --no-paths            Only output path hashes, not actual paths.
 -f, --format          File format for FRBR stacks. xml, turtle, n3, or nt.
--print-item           Print URI of the Item and quit.
--print-manifestation  Print URI of the Manifestation and quit.
--print-expression     Print URI of the Expression and quit.
--print-work           Print URI of the Work and quit.
'''

if __name__ == "__main__":
    files = set([])
    i = 1
    stdout = False
    fileFormat = 'turtle'
    extension = 'ttl'
    addPaths = True
    printItems = False
    printManifestations = False
    printExpressions = False
    printWorks = False

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
        elif sys.argv[i] == '--no-paths':
            addPaths = False
        elif sys.argv[i] == '--print-item':
            printItems = True
        elif sys.argv[i] == '--print-manifestation':
            printManifestations = True
        elif sys.argv[i] == '--print-expression':
            printExpressions = True
        elif sys.argv[i] == '--print-work':
            printWorks = True
        else:
            files.add(sys.argv[i])

        i += 1

    if len(files) == 0:
        files.add('-')
        
    for f in files:
        store = None
        if f == '-':
            store = fstack(sys.stdin,addPaths=addPaths)
            bindPrefixes(store[0].reader.graph)
            if printItems or printManifestations or printExpressions or printWorks:
                session = Session(store[0])
                if printItems:
                    Item = session.get_class(ns.FRBR['Item'])
                    for i in Item.all():
                        print i.subject
                if printManifestations:
                    Manifestation = session.get_class(ns.FRBR['Manifestation'])
                    for i in Manifestation.all():
                        print i.subject
                if printExpressions:
                    Expression = session.get_class(ns.FRBR['Expression'])
                    for i in Expression.all():
                        print i.subject
                if printWorks:
                    Work = session.get_class(ns.FRBR['Work'])
                    for i in Work.all():
                        print i.subject
            else:
                print store[0].reader.graph.serialize(format=fileFormat)
        else:
            store = fstack(open(f,'rb+'),f,addPaths=addPaths)
            bindPrefixes(store[0].reader.graph)
            if printItems or printManifestations or printExpressions or printWorks:
                session = Session(store[0])
                if printItems:
                    Item = session.get_class(ns.FRBR['Item'])
                    for i in Item.all():
                        print i.subject
                if printManifestations:
                    Manifestation = session.get_class(ns.FRBR['Manifestation'])
                    for i in Manifestation.all():
                        print i.subject
                if printExpressions:
                    Expression = session.get_class(ns.FRBR['Expression'])
                    for i in Expression.all():
                        print i.subject
                if printWorks:
                    Work = session.get_class(ns.FRBR['Work'])
                    for i in Work.all():
                        print i.subject
            else:
                if stdout:
                    print store[0].reader.graph.serialize(format=fileFormat)
                else:
                    store[0].reader.graph.serialize(open(f+".prov."+extension,'wb+'),format=fileFormat)
