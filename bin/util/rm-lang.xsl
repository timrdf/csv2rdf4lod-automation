<!-- Timothy Lebo -->
<xsl:transform version="2.0" 
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
							 exclude-result-prefixes="">
<xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>

<xsl:param name="language-tags-to-remove" select="'en de'"/>

<xsl:variable name="remove">
   <xsl:for-each select="tokenize($language-tags-to-remove,' ')">
      <!-- For some reason, this is just making a string and not a list :-( -->
      <xsl:copy-of select="."/> 
   </xsl:for-each>
</xsl:variable>

<!-- Not working b/c $remove is not a list :-( 
 xsl:template match="*[@xml:lang = $remove]"-->
<xsl:template match="*[@xml:lang and contains($language-tags-to-remove, @xml:lang)]"> <!-- <- a hack -->
  <!--xsl:message select="concat('REMOVING @ ',@xml:lang,' -',$remove,'- ',count(@*),' ',count(@* except @xml:lang))"/-->
  <xsl:copy>
		<xsl:copy-of select="@* except @xml:lang"/>	
	  <xsl:apply-templates/>
  </xsl:copy>
</xsl:template>

<xsl:template match="@*|node()">
  <xsl:copy>
		<xsl:copy-of select="@*"/>	
	  <xsl:apply-templates/>
  </xsl:copy>
</xsl:template>

</xsl:transform>
