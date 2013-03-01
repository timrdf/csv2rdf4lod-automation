<!--
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/tree/master/bin/util/grddl.xsl>;
#3>    rdfs:seeAlso <http://www.w3.org/TR/grddl-primer/#spreadsheets-section>;
#3> .
-->

<xsl:transform version="2.0" 
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:grddl="http://www.w3.org/2003/g/data-view#">
<xsl:output method="text"/>

<xsl:template match="/">
   <xsl:for-each-group select="//*/@grddl:transformation" group-by=".">
      <xsl:value-of select="concat(.,'&#xa;')"/>
   </xsl:for-each-group>
</xsl:template>

</xsl:transform>
