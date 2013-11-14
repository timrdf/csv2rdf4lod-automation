#!/bin/bash
#
#3> <> a conversion:RetrievalTrigger, conversion:Idempotent;
#3>    prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/secondary/cr-sitemap.sh>;
#3>    prov:wasDerivedFrom   <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/secondary/cr-linksets.sh>;
#3>    rdfs:seeAlso          <http://sindice.com/developers/publishing> .
#
# This script sets up a new version of a dataset when given a URL to a tabular file and some options
# describing its structure (comment character, header line, and delimter).
#
# If you have a non-tabular file, or custom software to retrieve data, then this script can be 
# used as a template for the retrieve.sh that is placed in the version directory.
#
# See:
# https://github.com/timrdf/csv2rdf4lod-automation/wiki/Automated-creation-of-a-new-Versioned-Dataset
#

[ -n "`readlink $0`" ] && this=`readlink $0` || this=$0
HOME=$(cd ${this%/*/*} && echo ${PWD%/*})
export PATH=$PATH`$HOME/bin/util/cr-situate-paths.sh`
export CLASSPATH=$CLASSPATH`$HOME/bin/util/cr-situate-classpaths.sh`

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:data-root cr:source cr:dataset cr:directory-of-versions cr:conversion-cockpit"
if [ `is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

if [[ "$1" == "--help" ]]; then
   section='#aggregation-39-dataset-conversion-metadata-prov-o-dcterms-void'
   echo "usage: `basename $0` [-n] [version-identifier]"
   echo ""
   echo "Create a dataset from the aggregation of all csv2rdf4lod conversion parameter files."
   echo ""
   echo "                   -n : perform dry run only."
   echo "   version-identifier : the version identifier to use for the dataset to be created."
   echo
   echo "see https://github.com/timrdf/csv2rdf4lod-automation/wiki/Aggregating-subsets-of-converted-datasets$section"
   echo
   exit 1
fi

if [[ `is-pwd-a.sh                                                                                      cr:conversion-cockpit` == "yes" ]]; then

   versionID=`cr-version-id.sh`
   pushd ../ &> /dev/null
      $this $versionID
   popd &> /dev/null

elif [[ `is-pwd-a.sh                                                            cr:directory-of-versions` == "yes" ]]; then

   CSV2RDF4LOD_BASE_URI=${CSV2RDF4LOD_BASE_URI:?"not set; source csv2rdf4lod/source-me.sh or see $see"}
   baseURI=${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}
   CSV2RDF4LOD_PUBLISH_SPARQL_ENDPOINT=${CSV2RDF4LOD_PUBLISH_SPARQL_ENDPOINT:?"not set; source csv2rdf4lod/source-me.sh or see $see"}

   #-#-#-#-#-#-#-#-#
   sourceID=`cr-source-id.sh` # Should be same as $CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID
   version="$1"
   version_reason=""
   url="$2"
   url="${baseURI}/source/$sourceID/file/cr-full-dump/version/latest/conversion/$sourceID-cr-full-dump-latest.ttl.gz"
   if [[ "$1" == "cr:auto" && ${#url} -gt 0 ]]; then
      version=`urldate.sh $url`
      #echo "Attempting to use URL modification date to name version: $version"
      version_reason="(URL's modification date)"
   fi
   if [ ${#version} -ne 11 -a "$1" == "cr:auto" ]; then # 11!?
      version=`cr-make-today-version.sh 2>&1 | head -1`
      #echo "Using today's date to name version: $version"
      version_reason="(Today's date)"
   fi
   if [ "$1" == "cr:today" ]; then
      version=`cr-make-today-version.sh 2>&1 | head -1`
      #echo "Using today's date to name version: $version"
      version_reason="(Today's date)"
   fi
   if [ ${#version} -gt 0 -a `echo $version | grep ":" | wc -l | awk '{print $1}'` -gt 0 ]; then
      echo "Version identifier invalid."
      exit 1
   fi
   shift 2

   #-#-#-#-#-#-#-#-#
   commentCharacter="#"
   if [ "$1" == "--comment-character" -a $# -ge 2 ]; then
      commentCharacter="$2"
      shift 2
   fi

   #-#-#-#-#-#-#-#-#
   headerLine=1
   if [ "$1" == "--header-line" -a $# -ge 2 ]; then
      headerLine="$2"
      shift 2
   fi

   #-#-#-#-#-#-#-#-#
   delimiter='\t'
   delimiter=','
   if [ "$1" == "--delimiter" -a $# -ge 2 ]; then
      delimiter="$2"
      shift 2
   fi

   echo "INFO url       : $url"
   echo "INFO version   : $version $version_reason"
   echo "INFO comment   : $commentCharacter"
   echo "INFO header    : $headerLine"
   echo "INFO delimiter : $delimiter"
   echo

   #
   # This script is invoked from a cr:directory-of-versions, 
   # e.g. source/contactingthecongress/directory-for-the-112th-congress/version
   #
   if [[ ! -d "$version" || "$version" == "latest" ]]; then

      mkdir $version &> /dev/null

      # Go into the conversion cockpit of the new version.
      pushd $version &> /dev/null

         rm -rf source automatic
         mkdir automatic publish

         me=$(cd ${0%/*} && echo ${PWD})/`basename $0`
         me=${me%.*}

         rq=`basename $0`
         rq=${rq%.*}.rq
         echo INFO `cr-pwd.sh`/source
         echo "prefix dcterms:    <http://purl.org/dc/terms/>"                      > automatic/$rq
         echo "prefix conversion: <http://purl.org/twc/vocab/conversion/>"         >> automatic/$rq
         echo ""                                                                   >> automatic/$rq
         echo "select distinct ?versioned (max(?mod) as ?modified)"                >> automatic/$rq
         echo "where {"                                                            >> automatic/$rq
         echo "   ?versioned a conversion:VersionedDataset; dcterms:modified ?mod" >> automatic/$rq
         echo "}"                                                                  >> automatic/$rq
         echo "order by ?modified"                                                 >> automatic/$rq
          
         # Execute the fixed query against the endpoint, and store in source/
         cache-queries.sh $CSV2RDF4LOD_PUBLISH_SPARQL_ENDPOINT -o xml -q automatic/$rq -od source

         echo INFO `cr-pwd.sh`/automatic
         # Convert the XML SPARQL bindings to the sitemap XML format.
         saxon.sh ../../src/cr-sitemap.xsl xml xml -od automatic source/$rq.xml
         mv automatic/$rq.xml.xml publish/sitemap.xml

         sitemap=`cr-ln-to-www-root.sh -n --url-of-filepath publish/sitemap.xml`
         echo automatic/data.ttl
         echo "@prefix : <`cr-dataset-uri.sh --uri`> ."                 > automatic/data.ttl
         cr-default-prefixes.sh --turtle                               >> automatic/data.ttl
         echo                                                          >> automatic/data.ttl
         echo "<`cr-dataset-uri.sh --uri`>"                            >> automatic/data.ttl
         echo "   a dcat:Dataset;"                                     >> automatic/data.ttl
         echo "   dcterms:created `dateInXSDDateTime.sh --turtle`;"    >> automatic/data.ttl
         echo SITEMAP $sitemap
         echo "."                                                      >> automatic/data.ttl
         if [[ $sitemap == http* && "$CSV2RDF4LOD_BASE_URI" == http* ]]; then
            dist=$CSV2RDF4LOD_BASE_URI/id/dcat-distribution/accessURL/`md5.sh -qs $sitemap`
            echo "<`cr-dataset-uri.sh --uri`>"                         >> automatic/data.ttl
            echo "   dcat:distribution <$dist>; "                      >> automatic/data.ttl
            echo "."                                                   >> automatic/data.ttl
            echo "<$dist> a dcat:Distribution;"                        >> automatic/data.ttl
            echo "   dcat:accessURL <$sitemap> ."                      >> automatic/data.ttl
         else
            echo "WARNING: not asserting dcat:distribution for sitemap b/c sitemap $sitemap is not http or base URI $CSV2RDF4LOD_BASE_URI is empty"
         fi

         aggregate-source-rdf.sh --link-as-latest automatic/data.ttl
    
         # #justify.sh $xls $csv xls2csv_`md5.sh \`which justify.sh\`` # TODO: excessive? justify.sh needs to know the broad class rule/engine
         #                                                # TODO: shouldn't you be hashing the xls2csv.sh, not justify.sh?
         #  justify.sh $xls $csv csv2rdf4lod_xls2csv_sh

      popd &> /dev/null

      pushd latest &> /dev/null
         sitemap=`cr-ln-to-www-root.sh publish/sitemap.xml`
         url=`cr-ln-to-www-root.sh --url-of-filepath $sitemap`
         if [[ -n "$url" && "$url" =~ http* ]]; then
            if [ "$CSV2RDF4LOD_PUBLISH_ANNOUNCE_TO_SINDICE" == "true" ]; then
               echo "http://api.sindice.com/v2/ping <-- $url"
               ping-sindice.sh -w $url 
            else
               echo "http://api.sindice.com/v2/ping - skipping; set CSV2RDF4LOD_PUBLISH_ANNOUNCE_TO_SINDICE=true to announce to Sindice."
            fi
         fi
      popd &> /dev/null

   else
      echo "Version exists; skipping."
   fi
elif [[  `is-pwd-a.sh                        cr:dataset                                                  ` == "yes" ]]; then
   if [[ ! -d version ]]; then
      mkdir version
   fi
   pushd version &> /dev/null
      $0 $* # Recursive call to base case 'cr:directory-of-versions'
   popd &> /dev/null
elif [[  `is-pwd-a.sh              cr:source                                                             ` == "yes" ]]; then
   # In a directory such as source/healthdata-tw-rpi-edu
   datasetID=`basename $0`
   datasetID=${datasetID%.*}
   if [[ ! -e $datasetID ]]; then
      mkdir $datasetID
   fi
   pushd $datasetID &> /dev/null
      $0 $* # Recursive call to base case 'cr:directory-of-versions'
   popd &> /dev/null
elif [[  `is-pwd-a.sh cr:data-root                                                                       ` == "yes" ]]; then
   CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID=${CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID:?"not set; source csv2rdf4lod/source-me.sh or see $see"}
   sourceID=$CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID
   if [[ ! -e $sourceID ]]; then
      mkdir $sourceID
   fi
   pushd $sourceID &> /dev/null
      $0 $* # Recursive call to base case 'cr:directory-of-versions'
   popd &> /dev/null
fi
