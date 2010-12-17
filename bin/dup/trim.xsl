<xsl:transform version="2.0" 
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
               xmlns:xfm="transform space"
               exclude-result-prefixes="">

<xsl:function name="xfm:trim">
   <xsl:param name="string"/>
   <xsl:value-of select="normalize-space($string)"/>
</xsl:function>

</xsl:transform>
