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

# usage:
#   data.gov-create-dataset-dir.sh <file or URL>

#usage="usage: `basename $0` [-v version] [-n] datasetIdentifier ..."
usage="usage: `basename $0` <file-or-URL> ..."

if [ $# -lt 1 ]; then
   echo $usage
   echo "  file-or-URL - RDF file (any syntax) containing conversion:{source,dataset,version}_identifer and dct:source pointing to data files."
   echo "  (if creating a dataset directory without a parameters file, just mkdir -p source/MY-SOURCE-ID/MY-DATASET-ID/version/MY-VERSION-ID/source)"
   exit 1
fi

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:data-root"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

SETUP_PARAMS="_"`basename $0``date +%s`_$$.tmp

while [ $# -gt 0 ]; do

   fileOrURL="$1"
   
   if [ -e "$fileOrURL" ]; then
      cp $fileOrURL $SETUP_PARAMS
   fi
   rapper -g -o ntriples "$fileOrURL" > $SETUP_PARAMS.nt
   justify.sh $SETUP_PARAMS $SETUP_PARAMS.nt serialization_change 

   if [ `wc -l $SETUP_PARAMS.nt | awk '{print $1}'` -le 0 ]; then
      continue
   fi

   #
   # conversion:VersionedDataset
   #
   for dataset in `cat $SETUP_PARAMS.nt | awk '$2=="<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>"       && 
                                              ($3=="<http://purl.org/twc/vocab/conversion/VersionedDataset>" ||
                                               $3=="<http://purl.org/twc/vocab/conversion/LayerDataset>")    && 
                                               did[$1] != $1 {did[$1]=$1; print $1}'`; do # did := already setup the dataset's version.
      echo $dataset 
      #
      # conversion:source_identifier
      #
      for sourceID in `cat $SETUP_PARAMS.nt | awk '$1==dataset && $2=="<http://purl.org/twc/vocab/conversion/source_identifier>"{gsub(/\"/,"");print $3}' dataset=$dataset`; do
         echo "   $sourceID"
         #
         # conversion:dataset_identifier
         #
         datasetID=`cat $SETUP_PARAMS.nt | awk '$1==dataset && $2=="<http://purl.org/twc/vocab/conversion/dataset_identifier>"{gsub(/\"/,"");print $3}' dataset=$dataset`
         if [ ${#datasetID} -le 0 ]; then
            # If conversion:dataset_identifier not given, use dc:identifier.
            datasetID=`cat $SETUP_PARAMS.nt | awk '$1==dataset && $2=="<http://purl.org/dc/terms/identifier>"{gsub(/\"/,"");print $3}' dataset=$dataset | sed -e 's/ /_/g'`
         fi
         echo "      $datasetID"
         #
         # conversion:version_identifier
         #
         for versionID in `cat $SETUP_PARAMS.nt | awk '$1==dataset && $2=="<http://purl.org/twc/vocab/conversion/version_identifier>"{gsub(/\"/,"");print $3}' dataset=$dataset`; do
            echo "         $versionID"
            if [ ${#dataset} -gt 0 -a ${#sourceID} -gt 0 -a ${#datasetID} -gt 0 -a ${#versionID} -gt 0 ]; then
               versionDir=$sourceID/$datasetID/version/$versionID
               if [ -e $versionDir ]; then
                  echo "Directory exists; skipping: $versionDir"
               else 
                  mkdir -p $versionDir/source
                  if [ ! -e $fileOrURL ]; then
                     pushd $versionDir/source &> /dev/null
                        pcurl.sh $fileOrURL
                     popd &> /dev/null
                  fi
                  pushd $versionDir/source &> /dev/null
                     cp ../../../../../$SETUP_PARAMS* .
                     #
                     # dct:source URLs
                     #
                     for url in `cat $SETUP_PARAMS.nt | awk '$1==dataset && $2=="<http://purl.org/dc/terms/source>"{gsub("<","");gsub(">","");print $3}' dataset=$dataset`; do
                        if [ ${#url} -gt 0 ]; then
                              echo "            $url"
                              pcurl.sh $url

                              # TODO: encapsulate zip/csv-recognition into a script and call from here.
                        fi
                     done
                  popd &> /dev/null
               fi
            fi
         done
      done
   done
   rm $SETUP_PARAMS*

   exit 1



   # TODO: incorporate functionality below and remove from here:

 
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
         docHTML=`ls *.html`
         cat urls.txt | awk -f $CSV2RDF4LOD_HOME/bin/util/dataurls2pml.awk -v source=$docHTML > $docHTML.tidy.ttl
         cat urls.txt  | awk -v source="`filename-v3.pl $detailsURL`" 'BEGIN{print "@prefix irw: <http://www.ontologydesignpatterns.org/ont/web/irw.owl#> .\n"}{printf("<%s> irw:refersTo <%s> .\n\n",source,$1)}' > urls.ttl
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
            pcurl.sh `cat $base/urls.txt | grep -v "rdf"`
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
