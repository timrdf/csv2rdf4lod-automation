<!--
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/id.xsl>;
#3>    rdfs:seeAlso <https://en.wikipedia.org/wiki/Identity_transform>;
#3> .
-->
<xsl:transform version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>

<xsl:template match="@*|node()">
  <xsl:copy>
      <xsl:copy-of select="@*"/>   
      <xsl:apply-templates/>
  </xsl:copy>
</xsl:template>

</xsl:transform>
