<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:str="http://xsltsl.org/string" version="1.0">
  
  <xsl:output method="html"/>
  
  <!-- Alert block -->
  
  <xsl:template match="current_observation">

  <html>
    <head>
     <title>National Weather Service : Latest Observation for : <xsl:value-of select="location/text()"/> </title>
     <link rel="stylesheet" type="text/css" href="/main.css" />
    </head>
    <style type="text/css">
      .label { font-weight: bold; vertical-align: text-top; text-align: right;}
      .xsllocation { font-size: 18px; color: white; font-weight: bold; font-family: Verdana, Geneva, Arial, Helvetica, sans-serif; }
    </style>
    <body bgcolor="#ffffff" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0" background="/images/background1.gif">
    <!-- start banner -->
    <div style="height: 120px; padding: 0; margin: 0;">
    <!-- first div is the top line that contains the skip graphic -->
     <div style="position: relative; top: 0; left: 0; height: 19px; width: 100%; background-image: url(/images/topbanner.jpg); background-repeat: no-repeat;">
      <div style="float: right; border: 0"><a href="#contents"><img src="/images/skipgraphic.gif" alt="Skip Navigation Links" width="1" height="1" border="0" /></a> <a href="/"><span class="nwslink">weather.gov</span></a>&#160;</div>
     </div>

    <!-- second div is the main part of the banner with the noaa and nws logos as well as the page name whether it be a WFO or national page -->
     <div style="clear: right; position: relative; top: -1px; left: 0; height: 78px; width: 100%; background-image: url(/images/wfo_bkgrnd.jpg); background-repeat: repeat;">
      <div style="float: right; width: 85px; height: 78px;"><a href="http://www.weather.gov"><img src="/images/nwsright.jpg" alt="NWS logo-Select to go to the NWS homepage" width="85" height="78" border="0" /></a></div>
      <div style="position: absolute; padding: 0; margin: 0; border: 0;"><a href="http://www.noaa.gov"><img src="/images/noaaleft.jpg" alt="NOAA logo-Select to go to the NOAA homepage" width="85" height="78" border="0" /></a></div>
      <div style="position: absolute; padding: 0; margin: 0 0 0 85px; background-image: url(/officenames/blank_title.jpg); width: 500px; height: 20px; border: 0; text-align: center;"><div class="source">Latest Observation for</div></div>
      <div style="position: absolute; padding: 0; margin: 20px 0 0 85px; background-image: url(/officenames/blank_name.jpg); width: 500px; height: 58px; border: 0; text-align: center;"><div class="location"><xsl:value-of select="location/text()"/></div></div>
     </div>

    <!-- third div is the horizontal navigation that contains a link to the Site Map, News, Organization and search box -->
     <div style="clear: right; position: relative; top: -1px; left: 0; height: 23px; width: 100%; background-image: url(/images/navbkgrnd.gif); background-repeat: repeat;">
      <div style="position: absolute; margin: 0 24px 1px 150px; width: 75%; white-space: nowrap;">
       <ul style="padding: 0; margin: 0 auto;" id="menuitem">
        <li style="display: inline; list-style-type: none; padding-right: 15%;" class="nav"><a href="/sitemap.php">Site Map</a></li>
        <li style="display: inline; list-style-type: none; padding-right: 10%;" class="nav"><a href="/pa/">News</a></li>
        <li style="display: inline; list-style-type: none; padding-right: 15%;" class="nav"><a href="/organization.php">Organization</a></li>
        <li style="display: inline; list-style-type: none;" class="nav">
         <form method="get" action="http://usasearch.gov/search" style="display: inline; white-space: nowrap;">
           <input type="hidden" name="v:project" value="firstgov" />
           <label for="query" class="yellow">Search&#160;&#160;</label>
           <input type="text" name="query" id="query" size="10"/>
           <input type="radio" name="affiliate" checked="checked" value="nws.noaa.gov" id="nws" />
           <label for="nws" class="yellow">NWS</label>
           <input type="radio" name="affiliate" value="noaa.gov" id="noaa" />
           <label for="noaa" class="yellow">All NOAA</label>
           <input type="submit" value="Go" />
         </form>
        </li>
       </ul>
      </div>
      <div style="float: right; border: 0; background-image: url(/images/navbarendcap.jpg); background-repeat: no-repeat; width: 24px; height: 23px;"></div>
      <div style="border: 0; background-image: url(/images/navbarleft.jpg); background-repeat: no-repeat; width: 94px; height: 23px;"></div>
     </div>
    </div>
    <!-- end banner -->

      <table width="700" border="0" cellspacing="0">
        <tr>
          <td width="119" valign="top">
            <!-- start leftmenu -->
            <xsl:variable name="leftmenu" select="document('/includes/leftmenu.php')"/>
            <xsl:copy-of select="$leftmenu"/>
            <!-- end leftmenu -->
          </td>
          <td width="525" valign="top">
            <table cellspacing="2" cellpadding="0" border="0">
              <tr valign="top">
                <td>&#160;&#160;&#160;&#160;&#160;&#160;&#160;</td>
                <td width="100%" align="center"><a name="contents" id="contents"></a>
                  <h2 style="text-align: center;">
                   <xsl:value-of select="location/text()"/><br />
                   (<xsl:value-of select="station_id/text()"/>)&#160;
                   <xsl:variable name="lat"> <xsl:value-of select="latitude/text()"/> </xsl:variable>
                   <xsl:if test="$lat &gt; 0">
                     <xsl:copy-of select="$lat"/> <xsl:text>N </xsl:text>
                   </xsl:if>
                   <xsl:if test="$lat &lt; 0">
                     <xsl:value-of select="substring($lat,2)"/> <xsl:text>S </xsl:text>
                   </xsl:if>
                   <xsl:variable name="lon"> <xsl:value-of select="longitude/text()"/> </xsl:variable>
                   <xsl:if test="$lon &gt; 0">
                     <xsl:copy-of select="$lon"/> <xsl:text>E </xsl:text>
                   </xsl:if>
                   <xsl:if test="$lon &lt; 0">
                     <xsl:value-of select="substring($lon,2)"/> <xsl:text>W </xsl:text>
                   </xsl:if>
                 </h2>
                 <xsl:variable name="history">
                   <xsl:value-of select="two_day_history_url/text()"/>
                 </xsl:variable>
                 <xsl:if test="$history != ''">
                 <p style="text-align: center;">
                   <xsl:element name="a">
                    <xsl:attribute name="href">
                      <xsl:value-of select="two_day_history_url/text()"/>
                    </xsl:attribute>
                    <xsl:text>2 Day History</xsl:text>
                   </xsl:element>
                 </p>
                 </xsl:if>
                 <xsl:variable name="base">
                   <xsl:value-of select="icon_url_base/text()"/><xsl:value-of select="icon_url_name/text()"/>
                 </xsl:variable>
                 <xsl:if test="$base != ''">
                 <p style="float: left; text-align: center;">
                   <xsl:element name="img">
                    <xsl:attribute name="alt">
                      <xsl:value-of select="weather/text()"/>
                    </xsl:attribute>
                    <xsl:attribute name="src">
                      <xsl:value-of select="icon_url_base/text()"/><xsl:value-of select="icon_url_name/text()"/>
                    </xsl:attribute>
                   </xsl:element>
                  <br /><xsl:value-of select="temp_f/text()"/> &#176;F
                 </p>
                 </xsl:if> 
                 <table style="margin-left: 10px;" align="left">
                   <tr>
                     <td class="label">Last Updated:</td>
                     <td> <xsl:value-of select="substring(observation_time/text(),17)"/><br />
                      <xsl:value-of select="observation_time_rfc822/text()"/></td>
                   </tr>
           
                   <xsl:variable name="wx">
                     <xsl:value-of select="weather/text()"/>
                   </xsl:variable>
                   <xsl:if test="$wx != 'NA' and $wx != ''">
                   <tr> 
                     <td class="label">Weather:</td>
                     <td> <xsl:copy-of select="$wx" /> </td>
                   </tr>
                   </xsl:if>
           
                   <xsl:variable name="tmp">
                     <xsl:value-of select="temp_f/text()"/>
                   </xsl:variable>
                   <xsl:if test="$tmp != 'NA' and $tmp != ''">
                   <tr> 
                     <td class="label">Temperature:</td>
                     <td> <xsl:copy-of select="$tmp" /> &#176;F (<xsl:value-of select="temp_c/text()"/> &#176;C) </td>
                   </tr>
                   </xsl:if>
           
                   <xsl:variable name="dew">
                     <xsl:value-of select="dewpoint_f/text()"/>
                   </xsl:variable>
                   <xsl:if test="$dew != 'NA' and $dew != ''">
                   <tr> 
                     <td class="label">Dewpoint:</td>
                     <td> <xsl:copy-of select="$dew" /> &#176;F (<xsl:value-of select="dewpoint_c/text()"/> &#176;C) </td>
                   </tr>
                   </xsl:if>
           
                   <xsl:variable name="rh">
                     <xsl:value-of select="relative_humidity/text()"/>
                   </xsl:variable>
                   <xsl:if test="$rh != 'NA' and $rh != ''">
                   <tr> 
                     <td class="label">Relative Humidity:</td>
                     <td> <xsl:copy-of select="$rh"/> %</td>
                   </tr>
                   </xsl:if>
           
                   <xsl:variable name="hi">
                    <xsl:value-of select="heat_index_string/text()"/> 
                   </xsl:variable>
                   <xsl:if test="$hi != 'NA' and $hi != ''">
                   <tr> 
                     <td class="label">Heat Index:</td>
                     <td> <xsl:copy-of select="$hi"/> </td>
                   </tr>
                   </xsl:if>
           
                   <xsl:variable name="wind">
                     <xsl:value-of select="wind_string/text()"/>
                   </xsl:variable>
                   <xsl:if test="$wind != 'NA' and $wind != ''">
                   <tr> 
                     <td class="label">Wind:</td>
                     <td> <xsl:copy-of select="$wind"/> </td>
                   </tr>
                   </xsl:if>
           
                   <xsl:variable name="wc">
                    <xsl:value-of select="windchill_string/text()"/> 
                   </xsl:variable>
                   <xsl:if test="$wc != 'NA' and $wc != ''">
                   <tr> 
                     <td class="label">Wind Chill:</td>
                     <td> <xsl:copy-of select="$wc"/> </td>
                   </tr>
                   </xsl:if>
           
                   <xsl:variable name="vis">
                    <xsl:value-of select="visibility_mi/text()"/> 
                   </xsl:variable>
                   <xsl:if test="$vis != 'NA' and $vis != ''">
                   <tr> 
                     <td class="label">Visibility:</td>
                     <td> <xsl:copy-of select="$vis"/> miles</td>
                   </tr>
                   </xsl:if>
           
                   <xsl:variable name="pres">
                    <xsl:value-of select="pressure_mb/text()"/> 
                   </xsl:variable>
                   <xsl:if test="$pres != 'NA' and $pres != ''">
                   <tr> 
                     <td class="label">MSL Pressure:</td>
                     <td> <xsl:copy-of select="$pres"/> mb</td>
                   </tr>
                   </xsl:if>
           
                   <xsl:variable name="alti">
                    <xsl:value-of select="pressure_in/text()"/> 
                   </xsl:variable>
                   <xsl:if test="$alti != 'NA' and $alti != ''">
                   <tr> 
                     <td class="label">Altimeter:</td>
                     <td> <xsl:copy-of select="$alti"/> in Hg</td>
                   </tr>
                   </xsl:if>
           
           <!-- Marine specific data -->
           
                   <xsl:variable name="wtmp">
                    <xsl:value-of select="water_temp_f/text()"/> 
                   </xsl:variable>
                   <xsl:if test="$wtmp != 'NA' and $wtmp != ''">
                   <tr> 
                     <td class="label">Water Temperature:</td>
                     <td> <xsl:copy-of select="$wtmp"/> &#176;F (<xsl:value-of select="water_temp_c/text()"/> &#176;C)</td>
                   </tr>
                   </xsl:if>
           
                   <xsl:variable name="whgt">
                    <xsl:value-of select="wave_height_m/text()"/> 
                   </xsl:variable>
                   <xsl:if test="$whgt != 'NA' and $whgt != ''">
                   <tr> 
                     <td class="label">Wave Height:</td>
                     <td> <xsl:copy-of select="$whgt"/> m (<xsl:value-of select="wave_height_ft/text()"/> ft)</td>
                   </tr>
                   </xsl:if>
           
                   <xsl:variable name="dper">
                    <xsl:value-of select="dominant_period_sec/text()"/> 
                   </xsl:variable>
                   <xsl:if test="$dper != 'NA' and $dper != ''">
                   <tr> 
                     <td class="label">Dominant Period:</td>
                     <td> <xsl:copy-of select="$dper"/> sec</td>
                   </tr>
                   </xsl:if>
           
                   <xsl:variable name="aper">
                    <xsl:value-of select="average_period_sec/text()"/> 
                   </xsl:variable>
                   <xsl:if test="$aper != 'NA' and $aper != ''">
                   <tr> 
                     <td class="label">Average Period:</td>
                     <td> <xsl:copy-of select="$aper"/> sec</td>
                   </tr>
                   </xsl:if>
         
                   <xsl:variable name="mwve">
                    <xsl:value-of select="mean_wave_degrees/text()"/> 
                   </xsl:variable>
                   <xsl:if test="$mwve != 'NA' and $mwve != ''">
                   <tr> 
                     <td class="label">Mean Wave Direction:</td>
                     <td> <xsl:value-of select="mean_wave_dir/text()"/> (<xsl:copy-of select="$mwve"/> &#176;) </td>
                   </tr>
                   </xsl:if>
         
                   <xsl:variable name="tide">
                    <xsl:value-of select="tide_ft/text()"/> 
                   </xsl:variable>
                   <xsl:if test="$tide != 'NA' and $tide != ''">
                   <tr> 
                     <td class="label">Tide:</td>
                     <td> <xsl:copy-of select="$tide"/> ft </td>
                   </tr>
                   </xsl:if>
           
                   <xsl:variable name="step">
                    <xsl:value-of select="steepness/text()"/> 
                   </xsl:variable>
                   <xsl:if test="$step != 'NA' and $step != ''">
                   <tr> 
                     <td class="label">Steepness:</td>
                     <td> <xsl:copy-of select="$step"/> </td>
                   </tr>
                   </xsl:if>
           
                   <xsl:variable name="wcht">
                    <xsl:value-of select="water_column_height/text()"/> 
                   </xsl:variable>
                   <xsl:if test="$wcht != 'NA' and $wcht != ''">
                   <tr> 
                     <td class="label">Water Column Height:</td>
                     <td> <xsl:copy-of select="$wcht"/> </td>
                   </tr>
                   </xsl:if>
         
                   <xsl:variable name="sfht">
                    <xsl:value-of select="surf_height_ft/text()"/> 
                   </xsl:variable>
                   <xsl:if test="$sfht != 'NA' and $sfht != ''">
                   <tr> 
                     <td class="label">Surf Height:</td>
                     <td> <xsl:copy-of select="$sfht"/> ft </td>
                   </tr>
                   </xsl:if>
           
                   <xsl:variable name="swdr">
                    <xsl:value-of select="swell_dir/text()"/> 
                   </xsl:variable>
                   <xsl:if test="$swdr != 'NA' and $swdr != ''">
                   <tr> 
                     <td class="label">Swell Direction:</td>
                     <td> <xsl:copy-of select="$swdr"/> (<xsl:value-of select="swell_degrees/text()"/> &#176;) </td>
                   </tr>
                   </xsl:if>
           
                   <xsl:variable name="sper">
                    <xsl:value-of select="swell_period/text()"/> 
                   </xsl:variable>
                   <xsl:if test="$sper != 'NA' and $sper != ''">
                   <tr> 
                     <td class="label">Swell Period:</td>
                     <td> <xsl:copy-of select="$sper"/> sec </td>
                   </tr>
                   </xsl:if>
      
                   <xsl:variable name="raw">
                    <xsl:value-of select="ob_url/text()"/> 
                   </xsl:variable>
                   <xsl:if test="$raw != 'NA' and $raw != ''">
                   <tr>
                     <td></td>
                     <td>
                      <xsl:element name="a">
                       <xsl:attribute name="href">
                         <xsl:value-of select="ob_url/text()"/>
                       </xsl:attribute>
                       <xsl:text>Latest Raw Observation</xsl:text>
                      </xsl:element>
                     </td>
                   </tr>
                   </xsl:if>
                 </table>
               </td>
             </tr>
           </table>
           <xsl:variable name="footer" select="document('/includes/footer.php')"/> 
           <xsl:copy-of select="$footer"/>
         </td>
       </tr>
     </table>
    </body>
  </html>
  </xsl:template>
  
  <!-- Ignore anything else -->
  <xsl:template match="*"></xsl:template>
  
</xsl:stylesheet>
