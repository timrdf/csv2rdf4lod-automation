<!-- 
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/tabularxml2csv.xsl> .

example input from dataset http://logd.tw.rpi.edu/source/data-gov/dataset/1294/version/2009-Dec-09:

ASSUMPTIONS:
column elements are in order
column elements are present even if no value

<lu_Condiment_Food_Table>
   <lu_Condiment_Food_Row>
      <survey_food_code>11111000</survey_food_code>
      <display_name>Whole milk</display_name>
      <condiment_portion_size>1/2  cup</condiment_portion_size>
      <condiment_portion_code>10205</condiment_portion_code>
      <condiment_grains>.00000</condiment_grains>
      <condiment_whole_grains>.00000</condiment_whole_grains>
      <condiment_vegetables>.00000</condiment_vegetables>
      <condiment_dkgreen>.00000</condiment_dkgreen>
      <condiment_orange>.00000</condiment_orange>
      <condiment_starchy_vegetables>.00000</condiment_starchy_vegetables>
      <condiment_other_vegetables>.00000</condiment_other_vegetables>
      <condiment_fruits>.00000</condiment_fruits>
      <condiment_milk>.50020</condiment_milk>
      <condiment_meat>.00000</condiment_meat>
      <condiment_soy>.00000</condiment_soy>
      <condiment_drybeans_peas>.00000</condiment_drybeans_peas>
      <condiment_oils>.00000</condiment_oils>
      <condiment_solid_fats>34.78464</condiment_solid_fats>
      <condiment_added_sugars>.00000</condiment_added_sugars>
      <condiment_alcohol>.00000</condiment_alcohol>
      <condiment_calories>73.20000</condiment_calories>
      <condiment_saturated_fats>2.26920</condiment_saturated_fats>
   </lu_Condiment_Food_Row>
   <lu_Condiment_Food_Row>
      <survey_food_code>11111000</survey_food_code>
      <display_name>Whole milk</display_name>
      <condiment_portion_size>2 Tablespoons</condiment_portion_size>
      <condiment_portion_code>30000</condiment_portion_code>
      <condiment_grains>.00000</condiment_grains>
      <condiment_whole_grains>.00000</condiment_whole_grains>
      <condiment_vegetables>.00000</condiment_vegetables>
      <condiment_dkgreen>.00000</condiment_dkgreen>
      <condiment_orange>.00000</condiment_orange>
      <condiment_starchy_vegetables>.00000</condiment_starchy_vegetables>
      <condiment_other_vegetables>.00000</condiment_other_vegetables>
      <condiment_fruits>.00000</condiment_fruits>
      <condiment_milk>.12505</condiment_milk>
      <condiment_meat>.00000</condiment_meat>
      <condiment_soy>.00000</condiment_soy>
      <condiment_drybeans_peas>.00000</condiment_drybeans_peas>
      <condiment_oils>.00000</condiment_oils>
      <condiment_solid_fats>8.69616</condiment_solid_fats>
      <condiment_added_sugars>.00000</condiment_added_sugars>
      <condiment_alcohol>.00000</condiment_alcohol>
      <condiment_calories>18.30000</condiment_calories>
      <condiment_saturated_fats>.56730</condiment_saturated_fats>
   </lu_Condiment_Food_Row>
-->
<xsl:transform version="2.0" 
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
               xmlns:lebot="l_e_b_o_t@r_p_i"
               exclude-result-prefixes="">
<xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>

<xsl:template match="/">
   <!--xsl:message select="concat(count(*/*),' nodes')"/-->
   <xsl:choose>
      <xsl:when test="*/*/* and not (*/*/*/*)">
         <!--                     table/row[cell-with-no-children] -->
         <xsl:apply-templates select="*/*[*[not(*)]][1]" mode="header"/>
         <xsl:apply-templates select="*/*[*[not(*)]]"    mode="row"/>
      </xsl:when>
      <xsl:when test="*/* and not(*/*/*)">
         <!--                     row[cell-with-no-children] -->
         <xsl:apply-templates select="*[*[not(*)]][1]" mode="header"/>
         <xsl:apply-templates select="*[*[not(*)]]"    mode="row"/>
      </xsl:when>
      <xsl:otherwise>
      </xsl:otherwise>
   </xsl:choose>
</xsl:template>

<xsl:template match="*" mode="header">
   <!-- debug xsl:value-of select="concat('header','')"/-->
   <xsl:value-of select="concat($DQ,'table',$DQ,',',$DQ,'row',$DQ)"/>
   <xsl:apply-templates select="*[not(*)]" mode="column"/>
   <xsl:value-of select="concat('',$NL)"/>
</xsl:template>

<xsl:template match="*" mode="column">
   <!-- debug xsl:value-of select="concat(' column','')"/-->
   <!-- TODO: consider adding an extra column for the namespaces of the XML elements -->
   <xsl:value-of select="concat(',',$DQ,local-name(.),$DQ)"/>
   <xsl:apply-templates select="*/*[not(*)]"/>
</xsl:template>

<xsl:template match="*" mode="row">
   <!-- debug xsl:value-of select="concat('row','')"/-->
   <xsl:value-of select="concat($DQ,local-name(..),$DQ,',',$DQ,local-name(.),$DQ)"/>
   <xsl:apply-templates select="*[not(*)]" mode="cell"/>
   <xsl:value-of select="concat('',$NL)"/>
</xsl:template>

<xsl:template match="*" mode="cell">
   <!-- debug xsl:value-of select="concat(' cell','')"/-->
   <xsl:value-of select="concat(',',$DQ,lebot:escape-DQ(text()),$DQ)"/>
</xsl:template>

<xsl:function name="lebot:escape-DQ">
   <xsl:param name="value"/>
   <xsl:value-of select="replace($value,$DQ,$escapedDQregex)"/>
</xsl:function>

<xsl:template match="@*|node()">
  <xsl:copy>
		<xsl:copy-of select="@*"/>	
	  <xsl:apply-templates/>
  </xsl:copy>
</xsl:template>

<!--xsl:template match="text()">
   <xsl:value-of select="normalize-space(.)"/>
</xsl:template-->

<xsl:variable name="NL">
<xsl:text>
</xsl:text>
</xsl:variable>

<xsl:variable name="DQ"> <xsl:text>"</xsl:text> </xsl:variable>
<xsl:variable name="escapedDQregex"> <xsl:text>\\"</xsl:text> </xsl:variable>

</xsl:transform>
