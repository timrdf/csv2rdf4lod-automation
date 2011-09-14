self.contentTypes = {
    None:DefaultSerializer('xml'),
    "application/rdf+xml":DefaultSerializer('xml'),
    'text/turtle':DefaultSerializer('turtle'),
    'application/x-turtle':DefaultSerializer('turtle'),
    'text/plain':DefaultSerializer('nt'),
    'text/n3':DefaultSerializer('n3'),
    'text/rdf+n3':DefaultSerializer('n3'),
    'application/json':JSONSerializer(),
    }

class DefaultSerializer:
    def __init__(self,format):
        self.format = format
    def serialize(self,graph):
        return graph.serialize(format=format)
    def deserialize(self,graph, content):
        graph.parse(StringIO(content),format)

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

    def getFormat(self, contentType):

        if contentType == None: return [ "application/rdf+xml",serializeXML]
        type = mimeparse.best_match(contentTypes.keys(),contentType)
        if type != None: return [type,contentTypes[type]]
        else: return [ "application/rdf+xml",serializeXML]

    def serialize(self, graph, accept):
        format = self.getFormat(accept)
        return format[0],format[1].serialize(graph)

    def deserialize(self, graph, content, mimetype):
        format = self.getFormat(mimetype)
        format[1].deserialize(graph,content)

    def serialize(self, graph, accept):
        format = self.getFormat(accept)

