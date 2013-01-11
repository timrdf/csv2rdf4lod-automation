<xsl:transform version="2.0" 
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:sr="http://www.w3.org/2005/sparql-results#"
   xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
   exclude-result-prefixes="sr">
<xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>

<!-- http://sindice.com/developers/publishing -->

<xsl:template match="/">
   <urlset>
      <xsl:apply-templates select="sr:sparql/sr:results/sr:result"/>
   </urlset>
</xsl:template>

<xsl:template match="sr:result">
   <url>
      <loc><xsl:value-of select="sr:binding[@name='versioned']/*/text()"/></loc>
      <lastmod><xsl:value-of select="sr:binding[@name='modified']/*/text()"/></lastmod>
   </url>
</xsl:template>

</xsl:transform>
