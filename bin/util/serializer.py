import simplejson
import rdflib
import mimeparse
from surf.serializer import to_json
import simplejson as json
import mimeparse
from rdflib import *
import csv
from StringIO import StringIO
from surf import *

def bindPrefixes(graph):
    graph.bind('frbr', URIRef('http://purl.org/vocab/frbr/core#'))
    graph.bind('frir', URIRef('http://purl.org/twc/ontology/frir.owl#'))
    graph.bind('pexp', URIRef('tag:tw.rpi.edu,2011:Expression:'))
    graph.bind('pmanif', URIRef('tag:tw.rpi.edu,2011:Manifestation:'))
    graph.bind('pitem', URIRef('tag:tw.rpi.edu,2011:Item:'))
    graph.bind('nfo', URIRef('http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#'))
    graph.bind('irw', URIRef('http://www.ontologydesignpatterns.org/ont/web/irw.owl#'))
    graph.bind('dc', URIRef('http://purl.org/dc/terms/'))
    graph.bind('prov', URIRef('http://dvcs.w3.org/hg/prov/raw-file/tip/ontology/ProvenanceOntology.owl#'))
    graph.bind('xsd', URIRef('http://www.w3.org/2001/XMLSchema#'))
    graph.bind('http', URIRef("http://www.w3.org/2011/http#"))
    graph.bind('header', URIRef("http://www.w3.org/2011/http-headers#"))
    graph.bind('method', URIRef("http://www.w3.org/2011/http-methods#"))
    graph.bind('status', URIRef("http://www.w3.org/2011/http-statusCodes#"))

class CSVSerializer:
    def __init__(self,delimiter=","):
        self.delimiter = delimiter
    def serialize(self,graph):
        return None # Not implemented
    def deserialize(self, graph, content):
        reader = csv.reader(StringIO(content),delimiter=self.delimiter)
        rowNum = 1
        for row in reader:
            rowURI = URIRef('row:'+str(rowNum))
            colNum = 1
            for value in row:
                colURI = URIRef('column:'+str(colNum))
                #if len(value) > 0:
                graph.add((rowURI,colURI,Literal(value)))
                colNum += 1
            rowNum += 1
        return ns.FRIR['TabularDigest']

class DefaultSerializer:
    def __init__(self,format):
        self.format = format
    def serialize(self,graph):
        bindPrefixes(graph)
        return graph.serialize(format=self.format)
    def deserialize(self,graph, content):
        f = self.format
        if f == 'turtle':
            f = 'n3'
        graph.parse(StringIO(content),format=f)

class JSONSerializer:
    def serialize(self,graph):
        return to_json(modelGraph)
    
    def getResource(self, r, bnodes):
        result = None
        if r.startswith("_:"):
            if r in bnodes:
                result = bnodes[r]
            else:
                result = BNode()
                bnodes[r] = result
        else:
            result = URIRef(r)
        return result

    def deserialize(self,graph, content):
        if json.loads(content):
            data = json.load(StringIO(content))
            bnodes = {}
            for s in data.keys():
                subject = self.getResource(s, bnodes)
                for p in data[s].keys():
                    predicate = self.getResource(p, bnodes)
                    o = data[s][p]
                    obj = None
                    if o['type'] == 'literal':
                        datatype = None
                        if 'datatype' in o:
                            datatype = URIRef(o['datatype'])
                        lang = None
                        if 'lang' in o:
                            lang = o['lang']
                        value = o['value']
                        obj = Literal(value, lang, datatype)
                    else:
                        obj = self.getResource(o['value'])
                    graph.add(subject, predicate, obj)

contentTypes = {
    None:DefaultSerializer('xml'),
    "application/rdf+xml":DefaultSerializer('xml'),
    'text/turtle':DefaultSerializer('turtle'),
    'application/x-turtle':DefaultSerializer('turtle'),
    'text/plain':DefaultSerializer('nt'),
    'text/n3':DefaultSerializer('n3'),
    'text/rdf+n3':DefaultSerializer('n3'),
    'text/csv':CSVSerializer(','),
    'text/comma-separated-values':CSVSerializer(','),
    'text/tab-separated-values':CSVSerializer('\t'),
    'application/json':JSONSerializer()
}

extensions = {
    "owl":"application/rdf+xml",
    "rdf":"application/rdf+xml",
    "ttl":"text/turtle",
    "n3":"text/n3",
    "ntp":"text/plain",
    'csv':'text/csv',
    'tsv':'text/tab-separated-values'
    }

typeExtensions = {
    "xml":'rdf',
    "turtle":'ttl',
    "n3":"n3",
    "nt":"ntp"
    }

def getFormat(contentType):
    if contentType == None: return [ "application/rdf+xml",serializeXML]
    type = mimeparse.best_match([x for x in contentTypes.keys() if x != None],contentType)
    if type != None: return [type,contentTypes[type]]
    else: return [ "application/rdf+xml",serializeXML]

def serialize(graph, accept):
    format = getFormat(accept)
    return format[0],format[1].serialize(graph)

def deserialize(graph, content, mimetype):
    format = getFormat(mimetype)
    #print 'Foo'
    #print format
    format[1].deserialize(graph,content)

