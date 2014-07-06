#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/secondary/cr-linksets.sh>;
#3>    rdfs:seeAlso          <https://github.com/timrdf/csv2rdf4lod-automation/wiki/Finding-Linksets-among-Linked-Data-Bubbles>;
#3>    rdfs:seeAlso          <https://github.com/timrdf/csv2rdf4lod-automation/wiki/Automated-creation-of-a-new-Versioned-Dataset>;
#3>    rdfs:seeAlso          <https://github.com/timrdf/csv2rdf4lod-automation/wiki/Secondary-Derivative-Datasets#cr-linksets>;
#3>    rdfs:seeAlso          <https://github.com/timrdf/csv2rdf4lod-automation/wiki/cr-pingback>;
#3> .
#

HOME=$(cd ${0%/*/*} && echo ${PWD%/*})
export PATH=$PATH`$HOME/bin/util/cr-situate-paths.sh`
export CLASSPATH=$CLASSPATH`$HOME/bin/util/cr-situate-classpaths.sh`
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?$HOME}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:data-root cr:source cr:dataset cr:directory-of-versions"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

TEMP="_"`basename $0``date +%s`_$$.tmp

sourceID=$CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID
datasetID=`basename $0 | sed 's/.sh$//'`
versionID=`date +%Y-%b-%d`

cockpit="$sourceID/$datasetID/version/$versionID"

if [[ "$1" == "--help" ]]; then
   echo "usage: `basename $0` [--target] [-n ]"
   echo
   echo "            --target : return the dump file location, then quit."
   echo "                  -n : perform dry run only; do not load named graph."
   exit 1
fi

if [ "$1" == "--target" ]; then
   # a conversion:VersionedDataset:
   # e.g. http://purl.org/twc/health/source/tw-rpi-edu/dataset/cr-publish-dcat-to-endpoint/version/2012-Sep-07
   echo $cockpit/publish/$dumpFileLocal
   exit 0
fi

if [[ `is-pwd-a.sh                                                            cr:directory-of-versions` == "yes" ]]; then

   dryrun="false"
   if [ "$1" == "-n" ]; then
      dryrun="true"
      dryrun.sh $dryrun beginning
      shift
   fi

   CSV2RDF4LOD_BASE_URI=${CSV2RDF4LOD_BASE_URI:?"not set; source csv2rdf4lod/source-me.sh or see $see"}
   baseURI=${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}
   base=`echo $baseURI | perl -pi -e 's|http://||;s/\./-/g;s|/|-|g'` # e.g. lofd-tw-rpi-edu
   CSV2RDF4LOD_PUBLISH_DATAHUB_METADATA_OUR_BUBBLE_ID=${CSV2RDF4LOD_PUBLISH_DATAHUB_METADATA_OUR_BUBBLE_ID:?"not set; source csv2rdf4lod/source-me.sh or see $see"}

   #-#-#-#-#-#-#-#-#
   sourceID=`cr-source-id.sh` # Should be same as $CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID
   version="$versionID"
   version_reason=""

   # While $sourceID-cr-full-dump-latest.ttl.gz contains "one triple per resource",
   #                                $base.nt.gz contains *all* triples.
   #
   # We use the first to find connections to other bubbles and the second to determine vocabulary use.

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

   echo "INFO url       : $url"
   echo "INFO version   : $version $version_reason"
   echo

   #
   # This script is invoked from a cr:directory-of-versions, 
   # e.g. source/contactingthecongress/directory-for-the-112th-congress/version
   #
   if [[ ! -d $version || 'debugging' == 'debugging' ]]; then

      # Create the directory for the new version.
      mkdir -p $version/source

      # Go into the directory that stores the original data obtained from the source organization.
      echo INFO `cr-pwd.sh`/$version/source
      pushd $version/source &> /dev/null
         rm -f *
         touch .__CSV2RDF4LOD_retrieval # Make a timestamp so we know what files were created during retrieval.
         # - - - - - - - - - - - - - - - - - - - - Replace below for custom retrieval  - - - \
         echo pcurl.sh $url                                                                # |
         pcurl.sh $url                                                                     # |
         # - - - - - - - - - - - - - - - - - - - - Replace above for custom retrieval - - - -/
         echo done pcurl.sh $url
      popd &> /dev/null

      # Go into the conversion cockpit of the new version.
      pushd $version &> /dev/null

         baseURI=${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}

         if [ ! -e automatic ]; then
            mkdir automatic
         fi

         tarball=$sourceID-cr-full-dump-latest.ttl.gz
         # <http://ieeevis.tw.rpi.edu/void> <http://rdfs.org/ns/void#rootResource> <http://ieeevis.tw.rpi.edu/void> .
         # <http://ieeevis.tw.rpi.edu/void> <http://rdfs.org/ns/void#dataDump> <http://ieeevis.tw.rpi.edu/source/ieeevis-tw-rpi-edu/file/cr-full-dump/version/latest/conversion/ieeevis-tw-rpi-edu.nt.gz> .
         # <http://ieeevis.tw.rpi.edu/source/ieeevis-tw-rpi-edu/file/cr-full-dump/version/latest/conversion/ieeevis-tw-rpi-edu.nt.gz> <http://purl.org/dc/terms/subject> <a> .
         # <http://ieeevis.tw.rpi.edu/source/ieeevis-tw-rpi-edu/file/cr-full-dump/version/latest/conversion/ieeevis-tw-rpi-edu.nt.gz> <http://purl.org/dc/terms/subject> <b> .
         # <http://ieeevis.tw.rpi.edu/source/ieeevis-tw-rpi-edu/file/cr-full-dump/version/latest/conversion/ieeevis-tw-rpi-edu.nt.gz> <http://purl.org/dc/terms/subject> ... .
         ours=${CSV2RDF4LOD_PUBLISH_DATAHUB_METADATA_OUR_BUBBLE_ID}
         echo "Extracting list of RDF URI nodes from our bubble: $ours"
         #gunzip -c source/$tarball | awk '{print $1}' | grep "^<" | sed 's/^<//;s/>$//' | sort -u > automatic/$ours.csv
         rdf2nt.sh source/$tarball | grep "<http://purl.org/dc/terms/subject>" | awk '{print $3}' | sed 's/^<//;s/>$//' | grep -v "^$baseURI" | sort -u > automatic/$ours.csv

         echo "`wc -l automatic/$ours.csv | awk '{print $1}'` external RDF URI nodes in our bubble"

         tally=0
         total=`ckan-datasets-in-group.py | wc -l | awk '{print $1}'`
         for bubble in `ckan-datasets-in-group.py`; do
            let "tally=$tally+1"
            if [[ "$dryrun" != "true" ]]; then
               if [ ! -e automatic/$bubble ]; then
                  mkdir automatic/$bubble
               fi
               uri_space=`ckan-urispace-of-dataset.py $bubble`
               if [ -n "$uri_space" ]; then
                  echo "$tally/$total Searching $ours for URIs in $uri_space (for $bubble)"
                  echo "$uri_space" > automatic/$bubble/urispace.txt
                  if [[ "$dryrun" != "true" ]]; then
                     grep "^$uri_space" automatic/$ours.csv > automatic/$bubble/linkset.txt
                     for linkset in `find automatic/$bubble -name "linkset.txt" -size +1c`; do
                        echo "$tally/$total $bubble `cat automatic/$bubble/linkset.txt | wc -l`"
                     done
                  fi
               else
                  echo "WARNING: no URI space found for $bubble"
               fi
            else
               echo "$tally/$total [dryrun] Searching $ours for URIs in bubble $bubble"
            fi
         done

         DATAHUB='http://datahub.io'
         linkset_time=`dateInXSDDateTime.sh --turtle`
         for linkset in `find automatic -name "linkset.txt" -size +1c`; do
            # e.g.: automatic/data-gov/linkset.txt
            bubble=`echo $linkset | awk -F/ '{print $2}'`
            wc -l $linkset
            size=`cat automatic/$bubble/linkset.txt | wc -l | awk '{print $1}'`

            datasetDATASET=`    md5.sh -qs $DATAHUB/dataset/$ours$DATAHUB/dataset/$bubble`
            datasetTIMEdataset=`md5.sh -qs $DATAHUB/dataset/$ours\`date +%s\`$DATAHUB/dataset/$bubble`

            echo automatic/$bubble.ttl
            echo "@prefix : <`cr-dataset-uri.sh --abstract`/> ."              > automatic/$bubble.ttl
            cr-default-prefixes.sh --turtle                                  >> automatic/$bubble.ttl
            echo                                                             >> automatic/$bubble.ttl
            echo "<$baseURI/void>"                                           >> automatic/$bubble.ttl
            echo "   owl:sameAs <$DATAHUB/dataset/$ours>;"                   >> automatic/$bubble.ttl
            echo "   a datafaqs:CKANDataset;"                                >> automatic/$bubble.ttl
            echo "   void:subset :$datasetTIMEdataset ."                     >> automatic/$bubble.ttl
            echo ""                                                          >> automatic/$bubble.ttl
            #echo ":$datasetDATASET"                                          >> automatic/$bubble.ttl
            #echo "   a void:Dataset;"                                        >> automatic/$bubble.ttl
            #echo "   void:subset           :$datasetTIMEdataset;"            >> automatic/$bubble.ttl
            #echo "   prov:generalizationOf :$datasetTIMEdataset;"            >> automatic/$bubble.ttl
            #echo "   void:target"                                            >> automatic/$bubble.ttl
            #echo "      <$DATAHUB/dataset/$ours>, "                          >> automatic/$bubble.ttl
            #echo "      <$DATAHUB/dataset/$bubble>;"                         >> automatic/$bubble.ttl
            #echo "."                                                         >> automatic/$bubble.ttl
            #echo ""                                                          >> automatic/$bubble.ttl
            echo ":$datasetTIMEdataset"                                      >> automatic/$bubble.ttl
            echo "   a void:Linkset, void:Dataset;"                          >> automatic/$bubble.ttl
            echo "   dcterms:created $linkset_time;"                         >> automatic/$bubble.ttl
            echo "   void:inDataset <`cr-dataset-uri.sh --uri`>;"            >> automatic/$bubble.ttl
            echo "   void:target "                                           >> automatic/$bubble.ttl
            echo "     <$DATAHUB/dataset/$ours>,"                            >> automatic/$bubble.ttl
            echo "     <$DATAHUB/dataset/$bubble>;"                          >> automatic/$bubble.ttl
            echo "   void:triples     $size;"                                >> automatic/$bubble.ttl
            echo "   sio:member-count $size;"                                >> automatic/$bubble.ttl
            echo "."                                                         >> automatic/$bubble.ttl
            echo "<`cr-dataset-uri.sh --uri`> a conversion:LinksetDataset ." >> automatic/$bubble.ttl
            echo                                                             >> automatic/$bubble.ttl
            for uri in `cat automatic/$bubble/linkset.txt`; do
               echo "<$uri> void:inDataset :linkset_$datasetTIMEdataset ." >> automatic/$bubble.ttl
               echo ":linkset_$datasetTIMEdataset sio:has-member <$uri> ." >> automatic/$bubble.ttl
            done
         done
         # If you want to peek yourself: find automatic -name linkset.txt -size +0k | xargs wc -l
 
         url="${baseURI}/source/$sourceID/file/cr-full-dump/version/latest/conversion/$base.nt.gz"
         echo "source/$base.nt.gz <- $url"
         curl --progress-bar -L $url > source/$base.nt.gz
         if [[ -n "$baseURI" && "$dryrun" != "true" ]]; then
            echo automatic/vocabulary.ttl
            if [[ "$dryrun" != "true" ]]; then
               echo "@prefix void: <http://rdfs.org/ns/void#> ."                > automatic/vocabulary.ttl
               for term in `p-and-c.sh source/$base.nt.gz | sort -u`; do
                  if [[ "$term" =~ http* ]]; then
                     if [[ ${term%#*} != $term ]]; then
                        echo " void:vocabulary <${term%#*}#>"
                        echo "<$baseURI/void> void:vocabulary <${term%#*}> ."  >> automatic/vocabulary.ttl # No trailing '#'
                     elif [[ ${term%/*} != $term ]]; then     # http://www.w3.org/TR/2011/NOTE-void-20110303/#vocabularies
                        echo " void:vocabulary <${term%/*}/>"
                        echo "<$baseURI/void> void:vocabulary <${term%/*}/> ." >> automatic/vocabulary.ttl
                     else
                        echo "WARNING: `basename $0`: could not determine namespace for $term"
                     fi
                  else
                     echo "WARNING: `basename $0`: skipping non-HTTP term $term"
                  fi
               done
            fi
         else
            echo "automatic/vocabulary.ttl - skipping b/c base URI not set."
         fi

         echo aggregate-source-rdf.sh automatic/*.ttl
         if [[ "$dryrun" != "true" ]]; then
            aggregate-source-rdf.sh automatic/*.ttl
         fi

         # #justify.sh $xls $csv xls2csv_`md5.sh \`which justify.sh\`` # TODO: excessive? justify.sh needs to know the broad class rule/engine
         #                                                # TODO: shouldn't you be hashing the xls2csv.sh, not justify.sh?
         #  justify.sh $xls $csv csv2rdf4lod_xls2csv_sh

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

dryrun.sh $dryrun ending
