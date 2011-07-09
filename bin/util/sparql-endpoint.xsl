<xsl:transform version="2.0" 
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
               xmlns:xs="http://www.w3.org/2001/XMLSchema#"
               xmlns:xd="http://www.pnp-software.com/XSLTdoc"
               xmlns:s="http://www.w3.org/2005/sparql-results#"
               xmlns:hash="java:java.util.HashMap"
               xmlns:string="java:java.lang.String"
               xmlns:pmm="java:edu.rpi.tw.string.pmm.PrefixMappings"
               xmlns:vsr="https://github.com/timrdf/vsr/wiki/xsl_"
   				exclude-result-prefixes="">

<!--xsl:output method="text"/-->
<!--xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/-->

<xsl:key name="value-of"      match="s:binding/*" use="../@name"/>

<!-- 
- This template demonstrates how to query a variety of endpoints.
-->
<xsl:template match="/" priority="-1">

   <!-- virtuoso, sesame, joseki -->
   <xsl:variable name="endpoints" select="('http://dbpedia.org/sparql',
                                           'http://localhost:8080/openrdf-sesame/repositories/ses-whoi',
                                           'http://localhost:2020/sparql',
                                           'http://localhost:8080/openrdf-sesame/repositories/visual')"/>

   <xsl:variable name="queries">
      <query><![CDATA[select * where{<http://dbpedia.org/resource/DSV_Alvin> ?p ?o}]]></query>
      <query><![CDATA[
         select * where { 
            ?vent a <http://escience.rpi.edu/schemas/whoi_vents.owl#VentField> . 
         }
      ]]></query>
      <query><![CDATA[
         select * where { 
            ?cruise a <http://escience.rpi.edu/schemas/whoi_vents.owl#Cruise> . 
         }
      ]]></query>
      <query><![CDATA[
         select distinct ?p
         where { 
            graph ?g { ?s ?p ?o } . 
         }
      ]]></query>
   </xsl:variable>

   <xsl:variable name="selection" select="1"/>
   <xsl:variable name="request">
      <xsl:choose>
         <xsl:when test="$selection = 1">
            <xsl:copy-of select="vsr:virtuoso($endpoints[$selection],$queries/*[$selection])"/>
         </xsl:when>
         <xsl:when test="$selection = (2,4)">
            <xsl:copy-of select="vsr:sesame($endpoints[$selection],$queries/*[$selection])"/>
         </xsl:when>
         <xsl:when test="$selection = 3">
            <xsl:copy-of select="vsr:joseki($endpoints[$selection],$queries/*[$selection])"/>
         </xsl:when>
         <xsl:otherwise>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:variable>
   <xsl:value-of select="$request"/>
   <xsl:variable name="response" select="doc($request)"/>
   <xsl:apply-templates select="$response/*"/>
   <!--xsl:value-of select="vsr:virtuoso($endpoints[$selection],$queries/*[$selection])"/-->
</xsl:template>

<!-- -->

<xd:doc>The query</xd:doc>
<xsl:function name="vsr:situate-query">
   <xsl:param name="query"/>       <!-- -->
   <xsl:param name="named-graph"/> <!-- e.g. http://logd.tw.rpi.edu/source/epa-gov-mcmahon-ethan/dataset/environmental-reports/version/2011-Jan-12 -->
   <xsl:param name="dataset"/>     <!-- e.g. http://logd.tw.rpi.edu/source/epa-gov-mcmahon-ethan/dataset/environmental-reports/enviro-reports-and-indicators -->
   <xsl:value-of select="replace(vsr:situate-query($query,$named-graph),
                                 '\?:DATASET',$dataset)"/>
</xsl:function>

<xsl:function name="vsr:situate-query">
   <xsl:param name="query"/>       <!-- -->
   <xsl:param name="named-graph"/> <!-- e.g. http://logd.tw.rpi.edu/source/epa-gov-mcmahon-ethan/dataset/environmental-reports/version/2011-Jan-12 -->
   <xsl:value-of select="replace($query,'\?:NAMED_GRAPH',$named-graph)"/>
</xsl:function>

<xsl:function name="vsr:bind-variable">
   <xsl:param name="query"/>    <!-- The query to modify -->
   <xsl:param name="variable"/> <!-- The variable to replace -->
   <xsl:param name="value"/>    <!-- The value to replace the variable with -->
   <xsl:value-of select="replace($query,concat('\?:',$variable),$value)"/>
</xsl:function>

<xsl:function name="vsr:resource">
   <xsl:param name="value"/>
   <xsl:value-of select="concat('&lt;',$value,'>')"/>
</xsl:function>

<xsl:function name="vsr:literal">
   <xsl:param name="value"/>
   <xsl:value-of select="concat($DQ,$value,$DQ)"/>
</xsl:function>

<xsl:function name="vsr:limit-offset">
   <xsl:param name="query"/>
   <xsl:param name="limit"/>
   <xsl:param name="offset"/>
   <xsl:value-of select="concat($query,' limit ',$limit,' offset ',$offset)"/>
</xsl:function>

<!-- constants -->
<xsl:variable name="queryLanguage" select="('sparql','serql')"/>
<xsl:variable name="mime-types"    select="('','application/rdf+xml','application/sparql-results+xml')"/>

<!-- functions 
-    
-->

<xsl:function name="vsr:sesame">
   <xsl:param name="endpoint"/>
   <xsl:param name="query"   />
   <xsl:call-template name="sesame">
      <xsl:with-param name="endpoint" select="$endpoint"/>
      <xsl:with-param name="query"    select="$query"/>
   </xsl:call-template>
</xsl:function>

<xsl:function name="vsr:virtuoso">
   <xsl:param name="endpoint"/>
   <xsl:param name="query"   />
   <xsl:call-template name="virtuoso">
      <xsl:with-param name="endpoint" select="$endpoint"/>
      <xsl:with-param name="query"    select="$query"/>
   </xsl:call-template>
</xsl:function>

<xsl:function name="vsr:joseki">
   <xsl:param name="endpoint"/>
   <xsl:param name="query"   />
   <xsl:call-template name="joseki">
      <xsl:with-param name="endpoint" select="$endpoint"/>
      <xsl:with-param name="query"    select="$query"/>
   </xsl:call-template>
</xsl:function>

<xsl:function name="vsr:endpoint"> <!-- This is a generic endpoint -->
   <xsl:param name="endpoint"/>
   <xsl:param name="query"   />
   <xsl:value-of select="concat($endpoint,'?',
                               'query=',   encode-for-uri($query)
                               )"/>
</xsl:function>

<!-- templates --> 

<xsl:template name="sesame">
   <xsl:param name="endpoint" required="yes"/>
   <xsl:param name="query"    required="yes"/>
   <xsl:param name="queryLn"  select="$queryLanguage[1]"/> <!-- 'serql' -->
   <xsl:param name="accept"   select="$mime-types[3]"/>
   <xsl:value-of select="concat($endpoint,'?',
                               'query=',   encode-for-uri($query),   '&amp;',
                               'queryLn=', encode-for-uri($queryLn), '&amp;',
                               'Accept=',  encode-for-uri($accept)
                               )"/>

</xsl:template>

<xsl:template name="virtuoso">
   <xsl:param name="endpoint"          required="yes"/>
   <xsl:param name="query"             required="yes"/>
   <xsl:param name="default-graph-uri" select="''"/> <!--http://dbpedia.org'"/-->
   <xsl:param name="should-sponge"     select="''"/>
   <xsl:param name="format"            select="'rdf/xml'"/> <!-- '' -->
   <xsl:param name="debug"             select="'on'"/>
   <xsl:param name="timeout"           select="''"/>

   <xsl:value-of select="concat($endpoint,'?',
                               'default-graph-uri=', encode-for-uri($default-graph-uri), '&amp;', 
                               'should-sponge=',     encode-for-uri($should-sponge),     '&amp;', 
                               'query=',             encode-for-uri($query),             '&amp;',
                               'format=',            encode-for-uri($format),            '&amp;', 
                               'debug=',             encode-for-uri($debug),             '&amp;', 
                               'timeout=',           encode-for-uri($timeout)
                               )"/>
</xsl:template>

<xsl:template name="joseki">
   <xsl:param name="endpoint"          required="yes"/>
   <xsl:param name="query"             required="yes"/>
   <xsl:param name="default-graph-uri" select="''"/>
   <xsl:param name="stylesheet"        select="'/xml-to-html.xsl'"/>

   <xsl:value-of select="concat($endpoint,'?',
                               'query=',             encode-for-uri($query),             '&amp;', 
                               'default-graph-uri=', encode-for-uri($default-graph-uri), '&amp;', 
                               'stylesheet=',        encode-for-uri($stylesheet)            
                               )"/>
</xsl:template>

<xsl:template match="@*|node()">
  <xsl:copy>
		<xsl:copy-of select="@*"/>	
	  <xsl:apply-templates/>
  </xsl:copy>
</xsl:template>

<xsl:function name="vsr:cached-label">
   <xsl:param name="resource"/>    <!-- e.g. http://logd.tw.rpi.edu/source/epa-gov-mcmahon-ethan/dataset/environmental-reports/enviro-reports-and-indicators/typed/report/report_16 -->
   <xsl:param name="label-cache"/> <!-- java:java.util.HashMap -->
   <xsl:param name="named-graph"/> <!-- e.g. http://logd.tw.rpi.edu/source/epa-gov-mcmahon-ethan/dataset/environmental-reports/version/2011-Jan-12-->
   <xsl:param name="endpoint"/>    <!-- e.g. http://logd.tw.rpi.edu:8890/sparql-->
   <xsl:param name="pmap"/>        <!-- java:edu.rpi.tw.string.pmm.PrefixMappings -->

   <xsl:variable name="resource-string" select="string($resource)"/>
   <xsl:choose>
      <xsl:when test="hash:containsKey($label-cache,$resource-string)">
         <xsl:value-of select="hash:get($label-cache,$resource-string)"/>
      </xsl:when>
      <xsl:otherwise>
         <xsl:variable name="query" select="concat('SELECT ?id WHERE { GRAPH &lt;',$named-graph,'> { &lt;',$resource,'> &lt;http://purl.org/dc/terms/identifier> ?id } } limit 1')"/> 
         <xsl:variable name="request"  select="vsr:virtuoso($endpoint,$query)"/>
         <!--doc($request)//s:binding/*/text()    hash:size($label-cache) -->
         <xsl:variable name="web-label" select="string(doc($request)/s:sparql/s:results/s:result[1]/s:binding[@name='id']/s:literal/text())"/>
         <xsl:variable name="label">
            <xsl:choose>
               <xsl:when test="string-length($web-label)">
                  <xsl:value-of select="$web-label"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="pmm:bestLabelFor($pmap,string($resource))"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:variable>
         <xsl:value-of select="if(hash:put($label-cache,$resource-string,string($label))) then 'impossible' else hash:get($label-cache,$resource-string)"/>
      </xsl:otherwise>
   </xsl:choose>
</xsl:function>


<xsl:variable name="SQ">'</xsl:variable>
<xsl:variable name="DQ">"</xsl:variable>
<xsl:variable name="DAPOS">"</xsl:variable>
<xsl:variable name="LT">&lt;</xsl:variable>

<xsl:variable name="IN">
   <xsl:value-of select="'   '"/>
</xsl:variable>

<xsl:variable name="NL">
<xsl:text>
</xsl:text>
</xsl:variable>

</xsl:transform>
