<!--
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/tree/master/bin/util/xml2ttl.xsl>
#3>    prov:wasDerivedFrom <https://github.com/timrdf/csv2rdf4lod-automation/wiki/SDV-organization>,
#3>                        <https://github.com/timrdf/csv2rdf4lod-automation/wiki/Alternative-XML-to-RDF-converters#xsl-crib-sheet>;
#3> .
-->
<xsl:transform version="2.0" 
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:this="https://github.com/timrdf/pvcs/blob/master/src/xsl/xsl2ttl.xsl"
   exclude-result-prefixes="xs">

<xsl:output method="text"/>

<xsl:variable name="ignore-namespaces" select="true()"/>

<xsl:variable name="prefixes">
<xsl:text><![CDATA[@prefix prov:    <http://www.w3.org/ns/prov#> .
@prefix dcterms: <http://purl.org/dc/terms/> .
@prefix rdfs:    <http://www.w3.org/2000/01/rdf-schema#> .
@prefix foaf:    <http://xmlns.com/foaf/0.1/> .
@prefix lmx:     <http://www.w3.org/XML/1998/namespace/> .
@prefix xml2ttl: <https://github.com/timrdf/pvcs/blob/master/src/xsl/xml2ttl.xsl#> .
]]></xsl:text>
</xsl:variable>

<xsl:param name="cr-base-uri"   select="'http://my.com'"/>
<xsl:param name="cr-source-id"  select="'epa-gov'"/>
<xsl:param name="cr-dataset-id" select="'some-dataset'"/>
<xsl:param name="cr-version-id" select="'latest'"/>
<xsl:param name="cr-portion-id" select="''"/>

<xsl:variable name="abstract"   select="concat($cr-base-uri,'/source/',$cr-source-id,'/dataset/',$cr-dataset-id)"/>
<xsl:variable name="sdv"        select="concat($cr-base-uri,'/source/',$cr-source-id,'/dataset/',$cr-dataset-id,'/version/',$cr-version-id)"/>

<xsl:template match="/">
   <xsl:value-of select="concat($prefixes,$NL,
                                '@base &lt;',$sdv,'/&gt; .',$NL,$NL)"/>
   <xsl:apply-templates select="*"/>
</xsl:template>

<xsl:template match="*">
   <xsl:param name="path-prefix"/>
   <xsl:param name="depth" select="1"/>

   <xsl:variable name="element-name" select="if ($ignore-namespaces) then local-name() else name()"/>

   <xsl:variable name="element-id">
      <xsl:number count="*[local-name(.)=$element-name] | @*[local-name(.)=$element-name]" level="any"/>
   </xsl:variable>

   <xsl:value-of select="concat('&lt;',$element-name,'/',$element-id,'&gt;',$NL,
                                '   a &lt;',$element-name,'&gt;;',$NL,
                                '   prov:atLocation ',$LT,concat($path-prefix,$element-name),$GT,';',$NL,
                                '   xml2ttl:depth ',$depth,';',$NL)"/>
   <!-- Handle "attributes" -->
   <xsl:for-each select="*[not(*)] | @*">
      <xsl:variable name="predicate" select="concat($LT,local-name(.),$GT)"/>
      <xsl:variable name="object"    select="if (starts-with(.,'http://') or 
                                                 starts-with(.,'https://')) 
                                             then concat($LT,.,$GT) 
                                             else concat($DQ,.,$DQ)"/>
      <xsl:value-of select="if (string-length(.)) 
                            then concat('   ',$predicate,' ',$object,';',$NL) 
                            else ''"/>
   </xsl:for-each>

   <!-- Handle "relations" -->
   <xsl:for-each select="*[*|@*]">
      <xsl:variable name="child-name" select="if ($ignore-namespaces) then local-name() else name()"/>
      <xsl:variable name="child-id">
         <xsl:number count="*[local-name(.)=$child-name] | @*[local-name(.)=$child-name]" level="any"/>
      </xsl:variable>
      <xsl:value-of select="concat('   lmx:child &lt;',$child-name,'/',$child-id,'&gt;;',$NL)"/>
   </xsl:for-each>

   <xsl:value-of select="concat('.',$NL)"/>

   <xsl:apply-templates select="*[*]">
      <xsl:with-param name="path-prefix" select="concat($path-prefix,
                                                        if (string-length($path-prefix)) then '/' else '',
                                                        $element-name)"/>
      <xsl:with-param name="depth" select="$depth + 1"/>
   </xsl:apply-templates>
</xsl:template>

<xsl:variable name="NL" select="'&#xa;'"/>
<xsl:variable name="DQ" select="'&#x22;'"/>
<xsl:variable name="LT" select="'&lt;'"/>
<xsl:variable name="GT" select="'&gt;'"/>

</xsl:transform>
