<!--
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/tree/master/bin/util/xml2ttl.xsl>
#3>    prov:wasDerivedFrom <https://github.com/timrdf/csv2rdf4lod-automation/wiki/SDV-organization>,
#3>                        <https://github.com/timrdf/csv2rdf4lod-automation/wiki/Alternative-XML-to-RDF-converters#xsl-crib-sheet>;
#3> .
-->
<xsl:transform version="2.0" 
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:xutil="https://github.com/timrdf/vsr/blob/master/src/xsl/util/uri.xsl"
   xmlns:this="https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/xml2ttl.xsl"
   xmlns:uuid="java:java.util.UUID"
   exclude-result-prefixes="xs">

<xsl:output method="text"/>

<xsl:param name="ignore-namespaces" select="true()"/>
<xsl:param name="pretty-naming"     select="false()"/>

<xsl:variable name="prefixes">
<xsl:text><![CDATA[@prefix prov:    <http://www.w3.org/ns/prov#> .
@prefix dcterms: <http://purl.org/dc/terms/> .
@prefix rdfs:    <http://www.w3.org/2000/01/rdf-schema#> .
@prefix foaf:    <http://xmlns.com/foaf/0.1/> .
@prefix lmx:     <http://www.w3.org/XML/1998/namespace/> .
@prefix xml2ttl: <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/xml2ttl.xsl#> .
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
      <xsl:choose>
         <xsl:when test="$pretty-naming">
            <!-- it takes minutes+ on a 60MB XML file with: -->
            <xsl:number count="*[local-name(.)=$element-name] | @*[local-name(.)=$element-name]" level="any"/>
         </xsl:when>
         <xsl:otherwise>
            <!-- it takes ~15 seconds on a 60MB XML file with: -->
            <xsl:copy-of select="uuid:randomUUID()"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:variable>

   <!-- 
      The input:
         <sparql xmlns="http://www.w3.org/2005/sparql-results#">
      should return:
         <someNode> a <http://www.w3.org/2005/sparql-results#sparql> .
   -->
   <xsl:variable name="type" select="if (namespace-uri-from-QName(node-name(.))) then xutil:uri(.) else $element-name"/>
   <xsl:value-of select="concat('&lt;',$element-name,'/',$element-id,'&gt;',$NL,
                                '   a &lt;',$type,'&gt;;',$NL,
                                '   prov:atLocation ',$LT,concat($path-prefix,if ($path-prefix) then '/' else '',$element-name),$GT,';',$NL,
                                '   xml2ttl:depth ',$depth,';',$NL)"/>
   <!-- Handle "attributes" -->
   <xsl:for-each select="*[not(*|@*)] | @*">
      <!--
         <literal datatype="http://www.w3.org/2001/XMLSchema#decimal">2.22</literal>
      -->
      <xsl:variable name="predicate" select="if (namespace-uri-from-QName(node-name(.))) then xutil:uri(.) else local-name(.)"/>
      <xsl:variable name="object"    select="if ((starts-with(.,'http://') or 
                                                 starts-with(.,'https://')) and not(contains(.,' '))) 
                                             then concat($LT,.,$GT) 
                                             else concat($DQ,$DQ,$DQ,
                                                           replace(.,$DQ,concat('\\',$DQ)),
                                                         $DQ,$DQ,$DQ)"/>
      <xsl:value-of select="if (string-length(.) and not(@type='text/css')) 
                            then concat('   ',$LT,$predicate,$GT,' ',$object,';',$NL) 
                            else ''"/> <!-- this used to be local-name(.) -->
   </xsl:for-each>

   <xsl:if test="count(text()) eq 1">
      <xsl:for-each select="text()">
         <xsl:if test="string-length(.) gt 1">
            <xsl:value-of select="concat('   lmx:text ',concat($DQ,$DQ,$DQ,
                                                                  replace(.,$DQ,concat('\\',$DQ)),
                                                               $DQ,$DQ,$DQ),';',$NL)"/>
         </xsl:if>
      </xsl:for-each>
   </xsl:if>

   <!-- Handle "relations" -->
   <xsl:for-each select="*[*|@*]">
      <xsl:variable name="child-name" select="if ($ignore-namespaces) then local-name() else name()"/>
      <xsl:variable name="child-id">
         <xsl:choose>
            <xsl:when test="$pretty-naming">
               <!-- it takes minutes+ on a 60MB XML file with: -->
               <xsl:number count="*[local-name(.)=$child-name] | @*[local-name(.)=$child-name]" level="any"/>
            </xsl:when>
            <xsl:otherwise>
               <!-- it takes ~15 seconds on a 60MB XML file with: -->
               <xsl:copy-of select="uuid:randomUUID()"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:value-of select="concat('   lmx:child &lt;',$child-name,'/',$child-id,'&gt;;',$NL)"/>
   </xsl:for-each>

   <xsl:value-of select="concat('.',$NL)"/>

   <xsl:apply-templates select="*[*|@*]">
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

<xsl:function name="xutil:uri">
   <xsl:param name="node" as="node()"/>
   <xsl:value-of select="concat(namespace-uri-from-QName(node-name($node)),local-name($node))"/>
</xsl:function>

</xsl:transform>
