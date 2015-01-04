<!--
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/tix.xsl>;
#3>   a doap:Project;
#3>   dcterms:description "GRDDL script to extract Turtle from XML comments.";
#3>   rdfs:seeAlso <https://github.com/timrdf/csv2rdf4lod-automation/wiki/tic-turtle-in-comments>,
#3>                <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/tic.sh>;
#3> .
-->

<xsl:transform version="2.0" 
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   exclude-result-prefixes="">
<xsl:output method="text"/>

<!-- Taken from https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/cr-default-prefixes.sh 
     to follow suit with https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/tic.sh -->
<xsl:variable name="cr-default-prefixes"><![CDATA[
@prefix rdf:        <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs:       <http://www.w3.org/2000/01/rdf-schema#> .
@prefix xsd:        <http://www.w3.org/2001/XMLSchema#> .
@prefix owl:        <http://www.w3.org/2002/07/owl#> .
@prefix wgs:        <http://www.w3.org/2003/01/geo/wgs84_pos#> .
@prefix dcterms:    <http://purl.org/dc/terms/> .
@prefix doap:       <http://usefulinc.com/ns/doap#> .
@prefix foaf:       <http://xmlns.com/foaf/0.1/> .
@prefix skos:       <http://www.w3.org/2004/02/skos/core#> .
@prefix sioc:       <http://rdfs.org/sioc/ns#> .
@prefix dcat:       <http://www.w3.org/ns/dcat#> .
@prefix void:       <http://rdfs.org/ns/void#> .
@prefix ov:         <http://open.vocab.org/terms/> .
@prefix frbr:       <http://purl.org/vocab/frbr/core#> .
@prefix qb:         <http://purl.org/linked-data/cube#> .
@prefix sd:         <http://www.w3.org/ns/sparql-service-description#> .
@prefix moby:       <http://www.mygrid.org.uk/mygrid-moby-service#> .
@prefix conversion: <http://purl.org/twc/vocab/conversion/> .
@prefix datafaqs:   <http://purl.org/twc/vocab/datafaqs#> .
@prefix dbpedia:    <http://dbpedia.org/resource/> .
@prefix prov:       <http://www.w3.org/ns/prov#> .
@prefix nfo:        <http://www.semanticdesktop.org/ontologies/nfo/#> .
@prefix nfod:       <http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#> .
@prefix sio:        <http://semanticscience.org/resource/> .
@prefix org:        <http://www.w3.org/ns/org#> .
@prefix vsr:        <http://purl.org/twc/vocab/vsr#> .
@prefix cogs:       <http://vocab.deri.ie/cogs#> .
@prefix pml:        <http://provenanceweb.org/ns/pml#> .
@prefix twi:        <http://tw.rpi.edu/instances/> .]]>
</xsl:variable>

<xsl:template match="/">
   <xsl:if test="not(//comment()[contains(.,'@prefix')])">
      <xsl:value-of select="$cr-default-prefixes"/>
   </xsl:if>
   <xsl:apply-templates select="//comment()[contains(.,'#3>')]"/>
</xsl:template>

<xsl:template match="comment()">
   <xsl:value-of select="replace(.,'#3> ?','')"/>
</xsl:template>

<xsl:variable name="NL" select="'&#xa;'"/>
<xsl:variable name="DQ" select="'&#x22;'"/>

</xsl:transform>
