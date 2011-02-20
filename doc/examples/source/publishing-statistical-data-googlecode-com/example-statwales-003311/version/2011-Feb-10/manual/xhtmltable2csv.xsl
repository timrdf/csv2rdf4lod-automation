<!-- Timothy Lebo -->
<xsl:transform version="2.0" 
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
               xmlns:x="http://www.w3.org/1999/xhtml"
               xmlns:xs="http://www.w3.org/2001/XMLSchema"  
               xmlns:xfm="transform space"
					exclude-result-prefixes="">
<xsl:output method="text"/>

<xsl:param name="include-number" select="false()"/>
<xsl:param name="include-xpath"  select="true()"/>

<!-- TODO: see http://www.w3schools.com/TAGS/tag_tbody.asp re table headers and handle -->
<!-- http://www.htmlcodetutorial.com/tables/_TD_WIDTH.html -->
<!-- http://www.htmlcodetutorial.com/tables/_TD_ALIGN.html -->
<!-- http://www.htmlcodetutorial.com/tables/index_famsupp_29.html cellpadding--> 
<!-- http://www.htmlcodetutorial.com/tables/index_famsupp_30.html -->

<xsl:include href="../../../../../../../../../../../model_integration/xutil/in.xsl"/>
<xsl:include href="../../../../../../../../../../../model_integration/xutil/trim.xsl"/>
<xsl:include href="../../../../../../../../../../../model_integration/xutil/string-variables.xsl"/>

<xsl:template match="/">
   <xsl:apply-templates select="//x:table[//x:tr[x:td[normalize-space(text()[1])='Monmouthshire']]]//x:tr" mode="csv"/>
</xsl:template>

<xsl:template match="x:tr" mode="csv">
   <xsl:value-of select="concat('',$NL)"/>
   <xsl:apply-templates select="x:td" mode="csv">
      <xsl:with-param name="indent" select="$in"/>
   </xsl:apply-templates>
</xsl:template>

<xsl:template match="x:td" mode="csv">
   <xsl:value-of select="concat(normalize-space(text()[1]),',')"/>
</xsl:template>

<xsl:template match="x:tr">
   <xsl:value-of select="concat($NL,$NL)"/>
   <xsl:variable name="pretty-path">
      <xsl:for-each select="ancestor::* | .">
         <xsl:variable name="number">
            <xsl:number select="." level="single"/>
         </xsl:variable>
         <xsl:value-of select="concat(local-name(.),if ($include-number) then concat('[',$number,']') else '', if(position()=last()) then'' else' - ')"/>
      </xsl:for-each>
   </xsl:variable>
   <xsl:variable name="path" select="if($include-xpath) then concat($NL,'/x:',replace($pretty-path,' - ','/x:')) else ''"/>
   <xsl:value-of select="concat($pretty-path,' (',count(x:*),' value',if (count(x:*) gt 1) then 's' else '',')',$path,$NL)"/>
   <xsl:apply-templates select="*">
      <xsl:with-param name="indent" select="$in"/>
   </xsl:apply-templates>
</xsl:template>

<!-- Handle arbitrary elements --> 
<xsl:template match="x:*">
   <xsl:param name="indent"/>
   <xsl:value-of select="concat($indent,'[',position(),'] ',name(.),': ')"/>
   <xsl:apply-templates select="@*"/>
   <xsl:for-each select="text()">
      <xsl:variable name="clean" select="xfm:trim(replace(replace(.,'/s',''),' ',''))"/>
      <xsl:if test="string-length($clean)">
         <xsl:value-of select="concat($DQ,xfm:trim(.),$DQ,' ')"/>
      </xsl:if>
   </xsl:for-each>
   <xsl:value-of select="$NL"/>
   <xsl:apply-templates select="* except x:tr">
      <xsl:with-param name="indent" select="concat($indent,$in)"/>
   </xsl:apply-templates>
</xsl:template>

<!-- Handle specific elements - ignore -->

<xsl:template match="x:br">
</xsl:template>

<!-- Handle specific attributes - squash to just '@' -->

<xsl:template match="@style | @cellpadding | @cellspacing | @align | @valign | @clear | @color">
   <!-- removed bgcolor from this template b/c only way to see meaning of cell. -->
   <xsl:value-of select="'@ '"/>
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
                     x:*/@id | 
                     @bgcolor">
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

<!-- Handle specific elements -->

<xsl:template match="x:a">
   <xsl:param name="indent"/>
   <xsl:variable name="display-length" select="xs:integer(100)"/>
   <xsl:variable name="length"         select="string-length(@href)"/>
   <xsl:variable name="cut-length"     select="$length - $display-length"/>
   <xsl:variable name="pad"            select="xfm:n-sp($display-length - $length + 5)"/>
   <xsl:value-of select="concat($indent,'[',position(),'] ',name(.),': ',
                                substring(@href,0,$display-length),
                                if ($length gt $display-length) 
                                   then concat('...+',$cut-length) else '',
                                $pad,
                                if (xfm:trim(text()[1]))  
                                   then concat('   ',$SQ,xfm:trim(text()[1]),$SQ,' ') else '',$NL)"/>
   <xsl:apply-templates select="* except x:tr">
      <xsl:with-param name="indent" select="concat($indent,$in)"/>
   </xsl:apply-templates>
</xsl:template>

<xsl:template match="x:img">
   <xsl:param name="indent"/>
   <xsl:variable name="display-length" select="xs:integer(500)"/>
   <xsl:variable name="length"         select="string-length(@src)"/>
   <xsl:variable name="alt"            select="if (string-length(@alt)) then concat($SQ,@alt,$SQ,' ') else ''"/>
   <xsl:variable name="t"              select="if (string-length(text())) then ' ' else ''"/>
   <xsl:value-of select="concat($indent,name(.),'[',position(),']: ',
                                $alt,text(),$t,substring(@src,0,$display-length),
                                if ($length gt $display-length) then 
                                   concat('...+',$length - $display-length) else '',$NL)"/>
   <xsl:apply-templates select="* except x:tr">
      <xsl:with-param name="indent" select="concat($indent,$in)"/>
   </xsl:apply-templates>
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

</xsl:transform>
