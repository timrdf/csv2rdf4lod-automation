<!-- Timothy Lebo -->
<xsl:transform version="2.0" 
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
               xmlns:x="http://www.w3.org/1999/xhtml"
               xmlns:xs="http://www.w3.org/2001/XMLSchema"  
               xmlns:xfm="transform space"
					exclude-result-prefixes="">
<xsl:output method="text"/>

<xsl:param name="include-number" select="false()"/>

<!-- TODO: see http://www.w3schools.com/TAGS/tag_tbody.asp re table headers and handle -->
<!-- http://www.htmlcodetutorial.com/tables/_TD_WIDTH.html -->
<!-- http://www.htmlcodetutorial.com/tables/_TD_ALIGN.html -->
<!-- http://www.htmlcodetutorial.com/tables/index_famsupp_29.html cellpadding--> 
<!-- http://www.htmlcodetutorial.com/tables/index_famsupp_30.html -->

<xsl:template match="/">
   <!--xsl:apply-templates select="/x:html/x:body/x:div/x:div/x:div/x:div/x:div/x:table/x:tbody/x:tr/x:td/x:a[contains(@href,'download')]" mode="file-link"/-->
   <xsl:apply-templates select="//x:tr/x:td/x:a[contains(@href,'download')]" mode="file-link"/>
</xsl:template>

<xsl:template match="x:tr">
   <xsl:value-of select="concat($NL,$NL)"/>
   <xsl:for-each select="ancestor::* | .">
      <xsl:variable name="number">
         <xsl:number select="." level="single"/>
      </xsl:variable>
      <xsl:value-of select="concat(local-name(.),if ($include-number) then concat('[',$number,']') else '',' - ')"/>
   </xsl:for-each>
   <xsl:value-of select="concat(' (',count(x:*),' value',if (count(x:*) gt 1) then 's' else '',')',$NL)"/>
   <xsl:apply-templates select="*">
      <xsl:with-param name="ind" select="$in"/>
   </xsl:apply-templates>
</xsl:template>

<xsl:template match="x:a" mode="file-link">
   <xsl:value-of select="concat('http://www.data.gov',@href,$NL)"/>
</xsl:template>

<!-- Handle arbitrary elements --> 
<xsl:template match="x:*">
   <xsl:param name="ind"/>
   <xsl:value-of select="concat($ind,'[',position(),'] ',name(.),': ')"/>
   <xsl:apply-templates select="@*"/>
   <xsl:for-each select="text()">
      <xsl:variable name="clean" select="xfm:trim(replace(replace(.,'/s',''),' ',''))"/>
      <xsl:if test="string-length($clean)">
         <xsl:value-of select="concat($DQ,xfm:trim(.),$DQ,' ')"/>
      </xsl:if>
   </xsl:for-each>
   <xsl:value-of select="$NL"/>
   <xsl:apply-templates select="* except x:tr">
      <xsl:with-param name="ind" select="concat($ind,$in)"/>
   </xsl:apply-templates>
</xsl:template>

<!-- Handle specific elements -->

<xsl:template match="x:a">
   <xsl:param name="ind"/>
   <xsl:variable name="display-length" select="xs:integer(100)"/>
   <xsl:variable name="length"         select="string-length(@href)"/>
   <xsl:variable name="cut-length"     select="$length - $display-length"/>
   <xsl:variable name="pad"            select="xfm:n-sp($display-length - $length + 5)"/>
   <xsl:value-of select="concat($ind,'[',position(),'] ',name(.),': ',
                                substring(@href,0,$display-length),
                                if ($length gt $display-length) 
                                   then concat('...+',$cut-length) else '',
                                $pad,
                                if (xfm:trim(text()[1]))  
                                   then concat('   ',$SQ,xfm:trim(text()[1]),$SQ,' ') else '',$NL)"/>
   <xsl:apply-templates select="* except x:tr">
      <xsl:with-param name="ind" select="concat($ind,$in)"/>
   </xsl:apply-templates>
</xsl:template>

<xsl:template match="x:img">
   <xsl:param name="ind"/>
   <xsl:variable name="display-length" select="xs:integer(500)"/>
   <xsl:variable name="length"         select="string-length(@src)"/>
   <xsl:variable name="alt"            select="if (string-length(@alt)) then concat($SQ,@alt,$SQ,' ') else ''"/>
   <xsl:variable name="t"              select="if (string-length(text())) then ' ' else ''"/>
   <xsl:value-of select="concat($ind,name(.),'[',position(),']: ',
                                $alt,text(),$t,substring(@src,0,$display-length),
                                if ($length gt $display-length) then 
                                   concat('...+',$length - $display-length) else '',$NL)"/>
   <xsl:apply-templates select="* except x:tr">
      <xsl:with-param name="ind" select="concat($ind,$in)"/>
   </xsl:apply-templates>
</xsl:template>

<!-- Handle specific elements - ignore -->

<xsl:template match="x:br">
</xsl:template>

<!-- Handle generic attributes - just show attribute name -->

<xsl:template match="@*">
   <xsl:value-of select="concat('@',local-name(.),' ')"/>
</xsl:template>

<!-- Handle specific attributes - generically show value -->

<xsl:template match="x:td/@class   | x:table/@class | x:span/@class | x:*/@class |
                     x:td/@width   | x:table/@width | 
                     x:table/@cols | 
                     x:span/@title | x:*/@title |
                     x:*/@id">
   <xsl:value-of select="concat('@',local-name(.),'=',.,' ')"/>
</xsl:template>

<xsl:template match="x:td/@rowspan | x:td/@colspan">
   <xsl:variable name="name" select="if (local-name(.)='rowspan') then 'r' else 'c'"/>
   <xsl:if test="xs:integer(.) gt 1">
      <xsl:value-of select="concat('#',$name,'=',.,' ')"/>
   </xsl:if>
</xsl:template>

<!-- Handle specific attributes-->

<xsl:template match="x:title">
   <xsl:value-of select="concat(local-name(.),': ',.,' ',$NL)"/>
</xsl:template>

<xsl:template match="x:link">
   <xsl:value-of select="concat(@type,' @ ',@href,$NL)"/>
</xsl:template>

<!-- Handle specific attributes - squash to just '@' -->

<xsl:template match="@style | @cellpadding | @cellspacing | @align | @valign | @clear | @color | @bgcolor">
   <xsl:value-of select="'@ '"/>
</xsl:template>


<!-- TODO: need template that will get all/"the" "useful" strings out of a x:td  -->
<xsl:template match="x:td" mode="no">
   <!-- elements under x:td that can contain the 'actual' string -->
   <xsl:value-of select="x:strong"/>
   <xsl:value-of select="x:a"/>
   <xsl:value-of select="x:b"/>
   <xsl:value-of select="x:font/text()"/>
   <xsl:value-of select="x:span/@title"/>
   <xsl:value-of select="x:span/text()"/>
   <xsl:value-of select="x:a/x:span/text()"/>
   <xsl:value-of select="text()"/>
   <xsl:value-of select="x:title"/>
</xsl:template>


<!-- Functions -->


<!-- Print n spaces, or zero if n < 0. -->
<xsl:function name="xfm:n-sp">
   <xsl:param name="n" as="xs:integer"/>
   <xsl:choose>
      <xsl:when test="$n gt 0">
         <xsl:value-of select="concat(' ',xfm:n-sp($n - 1))"/>
      </xsl:when>
      <xsl:otherwise>
         <xsl:value-of select="''"/>
      </xsl:otherwise>
   </xsl:choose>
</xsl:function>



<!-- copied from $xutil/*.xsl -->

<xsl:variable name="in">
<xsl:text>   </xsl:text>
</xsl:variable>

<xsl:function name="xfm:trim">
   <xsl:param name="string"/>
   <xsl:value-of select="normalize-space($string)"/>
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

<xsl:function name="xfm:printNspaces">
   <xsl:param name="n" as="xs:integer"/>
   <xsl:choose>
      <xsl:when test="$n = 0">
         <xsl:value-of select="' '"/>
      </xsl:when>
      <xsl:when test="$n > 0">
         <xsl:value-of select="concat(' ',xfm:printNspaces($n - 1))"/>
      </xsl:when>
      <xsl:otherwise>
      </xsl:otherwise>
   </xsl:choose>
</xsl:function>
</xsl:transform>
