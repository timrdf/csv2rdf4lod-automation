#!/bin/bash
#
#   Copyright 2012 Timothy Lebo
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
# usage:
#   data.gov-create-dataset-dir.sh 92
#   data.gov-create-dataset-dir.sh 92 93 94 95 105 789
#   data.gov-create-dataset-dir.sh `echo '' | awk '{for(i=12;i<=32;i++) printf("%s ",i)}'`
#
# find datasets with (supposed) csv datafiles: grep -R "http://www.data.gov/download/.*/csv$" *

#usage="usage: `basename $0` [-v version] [-n] datasetIdentifier ..."
usage="usage: `basename $0` datasetIdentifier ..."

if [ $# -lt 1 ]; then
   echo $usage
   exit 1
fi

back_one=`cd .. 2>/dev/null && pwd`
ANCHOR_SHOULD_BE_SOURCE=`basename $back_one`
if [ $ANCHOR_SHOULD_BE_SOURCE != "source" ]; then
   echo "  Working directory does not appear to be a SOURCE directory."
   echo "  Run `basename $0` from a SOURCE directory (e.g. csv2rdf4lod/data/source/SOURCE/)"
   exit 1
fi

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"must be set; source csv2rdf4lod/source-me.sh (created by install.sh)."}
formats=${formats:?"must be set; source csv2rdf4lod/source-me.sh (created by install.sh)."}

while [ $# -gt 0 ]; do

   datasetIdentifier=$1

   if [ ! -e $datasetIdentifier ]; then
      mkdir $datasetIdentifier
   fi

   if [ ! -e $datasetIdentifier/doc ]; then
      mkdir $datasetIdentifier/doc
   fi

   if [ ! -e $datasetIdentifier/version ]; then
      mkdir $datasetIdentifier/version
   fi

   rm $datasetIdentifier/doc/error.html &> /dev/null

   if [ ! -e $datasetIdentifier/urls.txt ]; then

      # Grab the web page describing the dataset
      docDir=$datasetIdentifier/doc/version/`date.sh | sed 's/_.*$//'` 2> /dev/null
      echo $docDir
      mkdir -p $docDir
      pushd $docDir
         rm error.html error.html.pml.ttl error.html.tidy error.html.tidy.txt &> /dev/null
         #detailsURL="http://www.data.gov/raw/$datasetIdentifier"
         detailsURL="http://www.data.gov/details/$datasetIdentifier"
         pcurl.sh $detailsURL -e html
         tidy.sh *.html &> /dev/null
         saxon.sh $CSV2RDF4LOD_HOME/bin/dup/xhtmltable2.xsl     tidy txt -w *.tidy
         saxon.sh $CSV2RDF4LOD_HOME/bin/dg-get-format-links.xsl tidy txt    *.tidy | grep -v "WARNING" > urls.txt
         numURLs=`wc -l urls.txt | perl -nle '/^\s*(\d+)/ and print $1'`
         echo "urls.txt length: "`wc -l urls.txt`" ==> $numURLs"
         if [ ${numURLs:-"0"} -lt 1 ]; then
            echo "WARNING: Could not obtain data download URLs from data.gov details page. Brute forcing all possible data types."
            for type in csv esri kml rss xls xml ; do
               echo "http://www.data.gov/download/${datasetIdentifier}/${type}" >> urls.txt
            done
         fi 
         docHTML=`ls *.html`
         cat urls.txt | awk -f $CSV2RDF4LOD_HOME/bin/util/dataurls2pml.awk -v source=$docHTML > $docHTML.tidy.ttl
         cat urls.txt | awk -v source="`filename-v3.pl $detailsURL`" 'BEGIN{print "@prefix irw: <http://www.ontologydesignpatterns.org/ont/web/irw.owl#> .\n"}{printf("<%s> irw:refersTo <%s> .\n\n",source,$1)}' > urls.ttl
         cp urls.txt ../../../urls.txt
      popd &> /dev/null

      datasetVersion=`dg-get-mod-date.sh $datasetIdentifier`
      if [ "$datasetVersion" == "" ]; then
         datasetVersion="undated"
         if [ `which md5` ]; then
            #md5 data | perl -pe 's/^.* = //' # TODO: get md5 and use instead of 'undated'
            datasetVersion="undated"
         elif [ `which md5sum` ]; then
            #md5sum data | perl -pe 's/\s.*//'
            datasetVersion="undated"
         else
            datasetVersion="undated"
         fi
      fi

      sourceDir=version/$datasetVersion/source
      base="../../.."

      if [ ! -e $datasetIdentifier/version/$datasetVersion ]; then
         mkdir $datasetIdentifier/version/$datasetVersion
      fi
      if [ ! -e $datasetIdentifier/version/$datasetVersion/source ]; then
         mkdir $datasetIdentifier/version/$datasetVersion/source
      fi
      if [ ! -e $datasetIdentifier/version/$datasetVersion/manual ]; then
         mkdir $datasetIdentifier/version/$datasetVersion/manual
      fi

      echo ""
      pushd $datasetIdentifier/$sourceDir &> /dev/null
      if [ `wc -l $base/urls.txt | awk '{print $1}'` -gt 0 ]; then
         echo ""
         echo "------------------------- Data file URLs for dataset $datasetIdentifier ------------------------"
         cat $base/urls.txt
         if [ ${DG_RETRIEVAL_REQUEST_DATA:-"true"} == "true" ]; then
            #pcurl.sh `cat $base/urls.txt | grep -v "rdf"`
            for url in `cat $base/urls.txt | grep -v "rdf"`; do
               pcurl.sh $url -n $datasetIdentifier -e `echo $url | sed 's/^.*\///'`
            done
            if [ `ls *.[Zz][Ii][Pp] 2> /dev/null | wc -l` -gt 0 ]; then
               #unzip *.[Zz][Ii][Pp]
               for zip in *.[Zz][Ii][Pp]
               do
                  punzip.sh $zip
               done
            fi
         else
            echo "NOTE: not requesting data b/c \$DG_RETRIEVAL_REQUEST_DATA != true" 
            pcurl.sh -I `cat $base/urls.txt`
            #for url in `cat $base/urls.txt`; do
            #   redirectedURL=`filename2.pl $url`
            #   echo "$url -> $redirectedURL"
            #done
         fi
      else
         echo "------------------------ No data file URLs for dataset $datasetIdentifier ----------------------"
         rm $base/urls.txt
         rm $base/doc/error.html.tidy* $base/doc/error.html.tidy.ttl &> /dev/null
      fi
      popd &> /dev/null

      if [ ! -e $datasetIdentifier/version/$datasetVersion/convert-$datasetIdentifier.sh ]; then
      if [ `find $datasetIdentifier/$sourceDir -type f -and -name '*[Cc][Ss][Vv]' | wc -l` -gt 0 ]; then
         pushd $datasetIdentifier/version/$datasetVersion &> /dev/null
         # TODO: spaces in filenames are not being handled correctly. e.g., dataset 1500-1505.
         cr-create-convert-sh.sh -d $datasetIdentifier `find source -type f -and -name '*.[Cc][Ss][Vv]'` > convert-$datasetIdentifier.sh 
         chmod +x convert-$datasetIdentifier.sh
         # perl is grabbing the .csv.pml.ttl and should not be.
         #cr-create-convert-sh.sh -d $datasetIdentifier `perl -l -MFile::Find -e 'find(sub { my $name = $File::Find::name; next unless (-r $_ and -f _ and /[.]csv/i); $name =~ s/ /\\ /g; print $name; }, @ARGV);' source` > convert-$datasetIdentifier.sh 



         #
         # If you would like to run the raw conversion automatically when the directory
         # structure is being set up, set the environment variable DG_RETRIEVAL_CONVERT_RAW=true.
         # see dg-vars.sh
         #
         if [ ${DG_RETRIEVAL_CONVERT_RAW:-"."} == "yes" ]; then 
            ./convert-$datasetIdentifier.sh
         else
            echo "NOTE: not running conversion: convert-$datasetIdentifier.sh b/c \$DG_RETRIEVAL_CONVERT_RAW != true"
            echo "NOTE: to automatically run conversion, see dg-vars.sh and set \$DG_RETRIEVAL_CONVERT_RAW=\"true\""
         fi



         popd &> /dev/null
      fi
      fi
   else
      echo "$datasetIdentifier/urls.txt already has data files listed - already set up"
   fi

   shift
done
