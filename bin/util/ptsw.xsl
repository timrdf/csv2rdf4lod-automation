<!-- 
The <pingthesemanticwebUpdate> element

Each export file contain a single pingthesemanticwebUpdate element. It has two attributes: version, updated; and any number of rdfdocuments sub-elements.

    version is a number. It is the version of the current export file format.
    updated is a string, it indicates when export file was requested/created.

The <rdfdocument> element

rdfdocument has four attributes: url, created, updated and topics:

    url is a string; it is the URL of an updated RDF document.
    created is a date; it is the time when this document as been pinging to PingtheSemanticWeb.com for the first time
    updated is a date; it is the time it have been updated for the last time.
    serialization is a string; it is a string that tell which serialization method is used to write the document; this variable can have the value "xml" or "n3".
    ns is a string; it is a list of space (%20) separeted namespace(s). If a namespace appears in this list, this mean that a resource has been typed (rdf:type) with a class defined in that ontology. 
 -->
<xsl:transform version="2.0" 
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
							 exclude-result-prefixes="">
<xsl:output method="text"/>

<!-- http://stackoverflow.com/questions/1384802/java-how-to-indent-xml-generated-by-transformer -->

<xsl:template match="/">
   <xsl:value-of select="concat('@prefix     xsd: &lt;http://www.w3.org/2001/XMLSchema#> .',$NL)"/>
   <xsl:value-of select="concat('@prefix dcterms: &lt;http://purl.org/dc/terms/> .',$NL)"/>
   <xsl:value-of select="concat('@prefix    void: &lt;http://rdfs.org/ns/void#> .',$NL)"/>
   <xsl:value-of select="concat('@prefix formats: &lt;http://www.w3.org/ns/formats/> .',$NL,$NL)"/>
   <xsl:apply-templates select="//rdfdocument"/>
</xsl:template>

<xsl:template match="rdfdocument">
   <xsl:value-of select="concat('&lt;',@url,'>',$NL)"/>
   <xsl:value-of select="concat($indent,'a void:Dataset;',$NL)"/>
   <xsl:apply-templates select="@* except @url"/>
   <xsl:value-of select="concat($indent,'void:dataDump &lt;',@url,'>;',$NL)"/>
   <xsl:value-of select="concat('.',$NL)"/>
</xsl:template>

<xsl:template match="rdfdocument/@created">
   <xsl:value-of select="concat($indent,'dcterms:created ',$DQ,replace(.,' ','T'),$DQ,'^^xsd:dateTime;',$NL)"/>
</xsl:template>

<xsl:template match="rdfdocument/@updated">
   <xsl:value-of select="concat($indent,'dcterms:modified ',$DQ,replace(.,' ','T'),$DQ,'^^xsd:dateTime;',$NL)"/>
</xsl:template>

<xsl:template match="rdfdocument/@serialization">
   <xsl:if test=". = 'xml'">
      <xsl:value-of select="concat($indent,'formats:media_type formats:RDF_XML;',$NL)"/>
   </xsl:if>
   <xsl:if test=". = 'n3'">
      <xsl:value-of select="concat($indent,'formats:media_type formats:N3;',$NL)"/>
   </xsl:if>
</xsl:template>

<xsl:template match="rdfdocument/@ns">
   <xsl:for-each select="tokenize(.,'\s+')">
      <xsl:if test="string-length(.) gt 0">
         <xsl:value-of select="concat($indent,'void:vocabulary &lt;',.,'>;',$NL)"/>
      </xsl:if>
   </xsl:for-each>
</xsl:template>

<!--xsl:template match="@*|node()">
  <xsl:copy>
		<xsl:copy-of select="@*"/>	
	  <xsl:apply-templates/>
  </xsl:copy>
</xsl:template-->

<!--xsl:template match="text()">
   <xsl:value-of select="normalize-space(.)"/>
</xsl:template-->

<xsl:variable name="indent">
<xsl:text>   </xsl:text>
</xsl:variable>

<xsl:variable name="NL">
<xsl:text>
</xsl:text>
</xsl:variable>

<xsl:variable name="DQ">
<xsl:text>"</xsl:text>
</xsl:variable>

</xsl:transform>
