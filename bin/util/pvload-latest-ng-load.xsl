<xsl:transform version="2.0" 
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
               xmlns:vsr="https://github.com/timrdf/vsr/wiki/xsl_"
               exclude-result-prefixes="">

<!--xsl:param name="endpoint"    select="'http://logd.tw.rpi.edu/sparql'"/ SparqlProxy is inadequate as usual-->
<xsl:param name="endpoint"    select="'http://logd.tw.rpi.edu:8890/sparql'"/>
<xsl:param name="named-graph" select="'http://purl.org/twc/id/person/TimLebo'"/>

<xsl:include href="sparql-endpoint.xsl"/>

<xsl:output method="text"/>

<xsl:template match="/">
   <xsl:variable name="queries">
      <query><![CDATA[
         PREFIX dcterms: <http://purl.org/dc/terms/>
         PREFIX skos:    <http://www.w3.org/2004/02/skos/core#>
         PREFIX pmlj:    <http://inference-web.org/2.0/pml-justification.owl#>
         PREFIX sd:      <http://www.w3.org/ns/sparql-service-description#>
         SELECT ?justification ?modified
         WHERE {
           GRAPH ?:NAMED_GRAPH {
             ?justification
                pmlj:hasConclusion [ skos:broader [ sd:name ?:NAMED_GRAPH ] ];
                pmlj:isConsequentOf [];
                dcterms:created ?modified .
           }
         } ORDER BY DESC(?modified) LIMIT 1
      ]]></query>
      <query><![CDATA[
      ]]></query>
   </xsl:variable>
   <xsl:variable name="dimensions-request"  select="vsr:virtuoso($endpoint,vsr:situate-query($queries/*[1],vsr:resource($named-graph)))"/>
   <xsl:variable name="dimensions-response" select="doc($dimensions-request)"/>
   <xsl:value-of                            select="key('value-of','justification',$dimensions-response)"/>
</xsl:template>

</xsl:transform>
