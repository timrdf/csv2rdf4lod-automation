<!-- https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/spo2nt.xsl -->
<xsl:stylesheet version="1.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:sr="http://www.w3.org/2005/sparql-results#">

<xsl:output method="text"/>

<xsl:template match="/">
   <xsl:apply-templates select="sr:sparql/sr:results/sr:result"/>
</xsl:template>

<xsl:template match="sr:result">
   <xsl:variable name="sp" select="concat('&lt;',normalize-space(sr:binding[@name='s']/sr:uri),'> ',
                                          '&lt;',normalize-space(sr:binding[@name='p']/sr:uri),'> ')"/>
   <xsl:choose>
      <xsl:when test="sr:binding[@name='o']/sr:uri">
         <xsl:value-of select="concat($sp,'&lt;',normalize-space(sr:binding[@name='o']/sr:uri),'> .',$NL)"/>
      </xsl:when>
      <xsl:otherwise>
         <xsl:value-of select="concat($sp,$DQ,normalize-space(sr:binding[@name='o']),$DQ,' .',$NL)"/>
      </xsl:otherwise>
   </xsl:choose>
</xsl:template>

<xsl:variable name="NL">
<xsl:text>
</xsl:text>
</xsl:variable>

<xsl:variable name="DQ">
<xsl:text>"</xsl:text>
</xsl:variable>

</xsl:stylesheet>
