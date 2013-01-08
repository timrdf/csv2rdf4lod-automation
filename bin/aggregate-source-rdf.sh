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
# Environment variables used:
#
#    CSV2RDF4LOD_PUBLISH_TTL                                  
#    CSV2RDF4LOD_PUBLISH_NT                                   
#    CSV2RDF4LOD_PUBLISH_RDFXML                               
#
#    CSV2RDF4LOD_PUBLISH_COMPRESS                             

if [[ $# -lt 1 || "$1" == "--help" ]]; then
   echo "usage: `basename $0` [--compress] [--turtle] [--ntriples] [--rdfxml] [--link-as-latest] source/some.{rdf,ttl,nt}"
   echo "  will create publish/*.ttl and publish/bin"
   echo "  --compress : gzip    publish/*"
   echo "  --turtle   : include publish/*.ttl"
   echo "  --ntriples : include publish/*.nt"
   echo "  --rdfxml   : include publish/*.rdf"
   echo "  --link-as-latest: create (or reconfigure) version identifier 'latest' to reference this current version."
   exit 1
fi

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:conversion-cockpit"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh --script `basename $0` $ACCEPTABLE_PWDs
   exit 1
fi

compress="no"
gz=''
if [ "$1" == "--compress" ]; then
   compress="yes"
   gz=".gz"
   shift
fi

turtle="no"
if [ "$1" == "--turtle" ]; then
   turtle="yes"
   shift
fi

ntriples="no"
if [ "$1" == "--ntriples" ]; then
   ntriples="yes"
   shift
fi

rdfxml="no"
if [ "$1" == "--rdfxml" ]; then
   rdfxml="yes"
   shift
fi

link_latest="no"
if [ "$1" == "--link-as-latest" ]; then
   link_latest="yes"
   shift
fi

TEMP="_"`basename $0``date +%s`_$$.tmp

if [[ `is-pwd-a.sh cr:conversion-cockpit` == "yes" ]]; then

   if [ ! -d publish/bin ]; then
      mkdir -p publish/bin
   fi
   
   sourceID=`cr-source-id.sh`
   datasetID=`cr-dataset-id.sh`
   versionID=`cr-version-id.sh`
   sd=$sourceID-$datasetID
   sdv=$sourceID-$datasetID-$versionID


   # $* is the list of RDF files that should be aggregated into publish/

   #    CSV2RDF4LOD_PUBLISH_TTL                                  
   #    CSV2RDF4LOD_PUBLISH_NT                                   
   #    CSV2RDF4LOD_PUBLISH_RDFXML                               
   #
   #    CSV2RDF4LOD_PUBLISH_COMPRESS                             

   if [[ "$CSV2RDF4LOD_PUBLISH_NT" == "true" || "$ntriples" == "true" ]]; then
      if [[ "$CSV2RDF4LOD_PUBLISH_COMPRESS" == "true" || "$compress" == "true" ]]; then
         echo "publish/$sdv.nt.gz"
         rdf2nt.sh $* | gzip                             > publish/$sdv.nt.gz
      else
         echo "publish/$sdv.nt"
         rdf2nt.sh $*                                    > publish/$sdv.nt
      fi
   else
      echo "publish/$sdv.nt[.gz] - skipping; set CSV2RDF4LOD_PUBLISH_NT=true to publish as N-TRIPLES." 
   fi

   if [[ "$CSV2RDF4LOD_PUBLISH_TTL" == "true" || "$turtle" == "true" ]]; then
      echo "publish/$sdv.ttl$gz"
      rm -f publish/$sdv.ttl
      for file in $*; do
         serialization=`guess-syntax.sh --inspect $file mime`

         echo "  (including $file, format is $serialization)" 
         if [[ "$serialization" == "text/turtle" ]]; then
            cat $file                                  >> publish/$sdv.ttl
         elif [[ -z "$serialization" ]]; then
            echo "WARNING: omitting $file b/c could not recognize serialization type"
         else
            # The other formats aren't really human readable, so no worries if it's ugly ttl.
            # N-Triples is Turtle...
            rdf2nt.sh $file                            >> publish/$sdv.ttl
         fi
      done
      if [[ "$CSV2RDF4LOD_PUBLISH_COMPRESS" == "true" || "$compress" == "true" ]]; then
         cat publish/$sdv.ttl | gzip > publish/$sdv.ttl.gz
         rm publish/$sdv.ttl
      fi
   else
      echo "publish/$sdv.ttl[.gz] - skipping; set CSV2RDF4LOD_PUBLISH_TTL=true to publish as Turtle." 
   fi

   # TODO: RDF/XML + compressed RDF/XML

   echo "publish/$sdv.sd_name"
   cr-dataset-uri.sh --uri                            > publish/$sdv.sd_name

   echo "publish/$sdv.void.ttl"
   rr-create-void.sh publish/$sdv.*                   > publish/$sdv.void.ttl

   if [ "$link_latest" == "yes" ]; then
      # from:
      # source/tw-rpi-edu/cr-publish-void-to-endpoint/version/2012-Sep-26
      #
      # tw-rpi-edu/cr-publish-void-to-endpoint/version/2012-Sep-26/publish/tw-rpi-edu-cr-publish-void-to-endpoint-2012-Sep-26.nt
      # tw-rpi-edu/cr-publish-void-to-endpoint/version/2012-Sep-26/publish/tw-rpi-edu-cr-publish-void-to-endpoint-2012-Sep-26.sd_name
      # tw-rpi-edu/cr-publish-void-to-endpoint/version/2012-Sep-26/publish/tw-rpi-edu-cr-publish-void-to-endpoint-2012-Sep-26.ttl
      # tw-rpi-edu/cr-publish-void-to-endpoint/version/2012-Sep-26/publish/tw-rpi-edu-cr-publish-void-to-endpoint-2012-Sep-26.void.ttl
      if [ -e `cr-conversion-root.sh`/$sourceID/$datasetID/version/latest ]; then
         rm -rf `cr-conversion-root.sh`/$sourceID/$datasetID/version/latest
      fi
      ln -s `cr-conversion-root.sh`/$sourceID/$datasetID/version/$versionID `cr-conversion-root.sh`/$sourceID/$datasetID/version/latest
      # hard link to rename the dump file.
      if [[ "$CSV2RDF4LOD_PUBLISH_NT" == "true" || "$ntriples" == "true" ]]; then
         ln `cr-conversion-root.sh`/$sourceID/$datasetID/version/latest/publish/$sdv.nt$gz  `cr-conversion-root.sh`/$sourceID/$datasetID/version/latest/publish/$sd-latest.nt$gz
      fi
      if [[ "$CSV2RDF4LOD_PUBLISH_TTL" == "true" || "$turtle" == "true" ]]; then
         ln `cr-conversion-root.sh`/$sourceID/$datasetID/version/latest/publish/$sdv.ttl$gz `cr-conversion-root.sh`/$sourceID/$datasetID/version/latest/publish/$sd-latest.ttl$gz
      fi
      if [[ "$CSV2RDF4LOD_PUBLISH_RDFXML" == "true" || "$rdfxml" == "true" ]]; then
         ln `cr-conversion-root.sh`/$sourceID/$datasetID/version/latest/publish/$sdv.rdf$gz `cr-conversion-root.sh`/$sourceID/$datasetID/version/latest/publish/$sd-latest.rdf$gz
      fi
   fi

   plan='https://raw.github.com/timrdf/csv2rdf4lod-automation/master/bin/aggregate-source-rdf.sh'
   homepage='https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/aggregate-source-rdf.sh'
   lnwww=publish/bin/ln-to-www-root-$sdv.sh # Note: This was originally done by bin/convert-aggregate.sh (deprecate it)
                                            # Note: This has since be done in bin/util/cr-full-dump.sh (keep them aligned)
   echo "#!/bin/bash"                                                                                               > $lnwww
   echo "#"                                                                                                        >> $lnwww
   echo "# run from `pwd | sed 's/^.*source/source/'`/"                                                            >> $lnwww
   echo "#"                                                                                                        >> $lnwww
   echo "# CSV2RDF4LOD_PUBLISH_VARWWW_ROOT"                                                                        >> $lnwww
   echo "# was "                                                                                                   >> $lnwww
   echo "# ${CSV2RDF4LOD_PUBLISH_VARWWW_ROOT}"                                                                     >> $lnwww
   echo "# when this script was created. "                                                                         >> $lnwww
   echo "#"                                                                                                        >> $lnwww
   echo "#3> <> prov:wasGeneratedBy [ prov:qualifiedAssociation [ prov:hadPlan <$plan> ] ] ."                      >> $lnwww
   echo "#3> <$plan> a prov:Plan; foaf:homepage <$homepage> ."                                                     >> $lnwww
   echo ""                                                                                                         >> $lnwww
   echo ""                                                                                                         >> $lnwww
   echo "CSV2RDF4LOD_PUBLISH_VARWWW_ROOT=\${CSV2RDF4LOD_PUBLISH_VARWWW_ROOT:?\"not set; source csv2rdf4lod/source-me.sh $or_see_github\"}" >> $lnwww
   echo ""                                                                                                         >> $lnwww
   echo "symbolic=\"\""                                                                                            >> $lnwww
   echo "pwd=\"\""                                                                                                 >> $lnwww
   echo "if [[ \"\$1\" == \"-s\" || \"\$CSV2RDF4LOD_PUBLISH_VARWWW_LINK_TYPE\" == \"soft\" ]]; then"               >> $lnwww
   echo "  symbolic=\"-sf \""                                                                                      >> $lnwww
   echo "  pwd=\`pwd\`/"                                                                                           >> $lnwww
   echo "  shift"                                                                                                  >> $lnwww
   echo "fi"                                                                                                       >> $lnwww
   echo ""                                                                                                         >> $lnwww
   echo "sudo=\"sudo\""                                                                                            >> $lnwww
   echo "if [[ \`whoami\` == "root" ]]; then"                                                                      >> $lnwww
   echo "   sudo=\"\""                                                                                             >> $lnwww
   echo "elif [[ \"\`stat --format=%U \"\$CSV2RDF4LOD_PUBLISH_VARWWW_ROOT\"\`\" == \`whoami\` ]]; then"            >> $lnwww
   echo "   sudo=\"\""                                                                                             >> $lnwww
   echo "fi"                                                                                                       >> $lnwww
   echo ""                                                                                                         >> $lnwww
   echo "function lnwww {"                                                                                         >> $lnwww
   echo "   publish=\"\""                                                                                          >> $lnwww
   echo "   if [ \"\$2\" == 'publish' ]; then "                                                                    >> $lnwww
   echo "      publish=\"conversion\""                                                                             >> $lnwww
   echo "   fi"                                                                                                    >> $lnwww
   echo "   wwwfile=\"\$CSV2RDF4LOD_PUBLISH_VARWWW_ROOT/source/$sourceID/file/$datasetID/version/$versionID/\$publish\${1#publish}\"" >> $lnwww
   echo "   if [ -e \"\$1\" -o \"\$2\" == 'publish' ]; then "                                                      >> $lnwww
   echo "      if [ -e \"\$wwwfile\" ]; then "                                                                     >> $lnwww
   echo "         \$sudo rm -f \"\$wwwfile\""                                                                      >> $lnwww
   echo "      else"                                                                                               >> $lnwww
   echo "         \$sudo mkdir -p \`dirname \"\$wwwfile\"\`"                                                       >> $lnwww
   echo "      fi"                                                                                                 >> $lnwww
   echo "      echo \"  \$wwwfile\""                                                                               >> $lnwww
   echo "      \$sudo ln \$symbolic \"\${pwd}\$1\" \"\$wwwfile\""                                                  >> $lnwww
   echo "   else"                                                                                                  >> $lnwww
   echo "      echo \"  -- \$1 omitted --\""                                                                       >> $lnwww
   echo "   fi"                                                                                                    >> $lnwww
   echo "}"                                                                                                        >> $lnwww
   echo ""                                                                                                         >> $lnwww
   for file in `find publish -maxdepth 1 -type f -not -name "*sd_name"`; do
      echo "lnwww $file publish"                                                                                   >> $lnwww
   done
   chmod +x $lnwww

   #echo "publish/bin/virtuoso-load.sh"
   #echo "sudo /opt/virtuoso/scripts/vload nt publish/$sdv.nt `cat publish/$sdv.sd_name`" > publish/bin/virtuoso-load-$sdv.sh
   #chmod +x publish/bin/virtuoso-load.sh

   # NOTE: This was taken from bin/convert-aggregate.sh
   vloadSH=publish/bin/virtuoso-load-${sourceID}-${datasetID}-${versionID}.sh
   vloadvoidSH=publish/bin/virtuoso-load-${sourceID}-${datasetID}-${versionID}-void.sh
   vdeleteSH=publish/bin/virtuoso-delete-${sourceID}-${datasetID}-${versionID}.sh
   echo "#!/bin/bash"                                                                                                           > $vloadSH
   echo "#"                                                                                                                    >> $vloadSH
   echo "# run $vloadSH"                                                                                                       >> $vloadSH
   echo "# from `pwd | sed 's/^.*source/source/'`/"                                                                            >> $vloadSH
   echo "#"                                                                                                                    >> $vloadSH
   echo "# graph was $graph during conversion"                                                                                 >> $vloadSH
   echo "# metadataset graph was $CSV2RDF4LOD_PUBLISH_METADATASET_GRAPH_NAME during conversion"                                >> $vloadSH
   echo "#"                                                                                                                    >> $vloadSH
   echo "#        \$CSV2RDF4LOD_PUBLISH_METADATASET_GRAPH_NAME            # <---- Loads into this with param --as-metadatset"  >> $vloadSH
   echo "#"                                                                                                                    >> $vloadSH
   echo "#"                                                                                                                    >> $vloadSH
   echo "#                               AbstractDataset                  # <---- Loads into this with param --abstract"       >> $vloadSH
   echo "#                     (http://.org/source/sss/dataset/ddd)                                                         "  >> $vloadSH
   echo "#                                     |                   \                                                        "  >> $vloadSH
   echo "# Loads into this by default -> VersionedDataset           meta  # <---- Loads into this with param --meta"           >> $vloadSH
   echo "#              (http://.org/source/sss/dataset/ddd/version/vvv)                                                    "  >> $vloadSH
   echo "#                                     |                                                                            "  >> $vloadSH
   echo "#                                LayerDataset                                                                      "  >> $vloadSH
   echo "#                                   /    \                                                                         "  >> $vloadSH
   echo "# Never loads into this ----> [table]   DatasetSample            # <---- Loads into this with param --sample"         >> $vloadSH
   echo "#"                                                                                                                    >> $vloadSH
   echo "# See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Aggregating-subsets-of-converted-datasets"                >> $vloadSH
   echo "# See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Named-graph-organization"                                 >> $vloadSH
   echo ""                                                                                                                     >> $vloadSH
   echo "wiki='https://github.com/timrdf/csv2rdf4lod-automation/wiki'"                                                         >> $vloadSH
   echo 'CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $wiki/CSV2RDF4LOD-not-set"}'    >> $vloadSH
   echo 'CSV2RDF4LOD_BASE_URI=${CSV2RDF4LOD_BASE_URI:?"not set; source csv2rdf4lod/source-me.sh or see $wiki/CSV2RDF4LOD-not-set"}' >> $vloadSH
   # deviates from orig design, but more concise by making (reasonable?) assumptions:
   #echo "for serialization in nt ttl rdf"                                                                                     >> $vloadSH
   #echo "do"                                                                                                                  >> $vloadSH
   #echo "  dump=$allNT.\$serialization"                                                                                       >> $vloadSH
   #echo "done"                                                                                                                >> $vloadSH
   echo ""                                                                                                                     >> $vloadSH
   echo "see=\"$wiki/CSV2RDF4LOD-environment-variables-%28considerations-for-a-distributed-workflow%29\""                      >> $vloadSH
   echo "if [ \`is-pwd-a.sh cr:dev\` == 'yes' ]; then"                                                                         >> $vloadSH
   echo "   echo \"Refusing to publish; see 'cr:dev and refusing to publish' at\""                                             >> $vloadSH
   echo "   echo \"  $see\""                                                                                                   >> $vloadSH
   echo "   exit 1"                                                                                                            >> $vloadSH
   echo "fi"                                                                                                                   >> $vloadSH
   echo "if [ -e '$lnwww' ]; then"                                                                                             >> $vloadSH
   echo "   # Make sure that the file we will load from the web is published"                                                  >> $vloadSH
   echo "   $lnwww"                                                                                                            >> $vloadSH
   echo "fi"                                                                                                                   >> $vloadSH
   echo ""                                                                                                                     >> $vloadSH
   echo "base=\${CSV2RDF4LOD_BASE_URI_OVERRIDE:-\$CSV2RDF4LOD_BASE_URI}"                                                       >> $vloadSH
   echo "graph=\`cat publish/$sdv.sd_name\`"                                                                                   >> $vloadSH
   echo "metaGraph=\"\$graph\""                                                                                                >> $vloadSH
   echo "if [ \"\$1\" == \"--sample\" ]; then"                                                                                 >> $vloadSH
   http_allRawSample="\$base/source/${sourceID}/file/${datasetID}/version/${versionID}/conversion/${sourceID}-${datasetID}-${versionID}.rdf"
   for layerSlug in $layerSlugs # <---- Add root-level subsets here.
   do
      layerID=`echo $layerSlug | sed 's/^.*\//e/'` # enhancement/1 -> e1
      echo "   layerSlug=\"$layerSlug\""                                                                                       >> $vloadSH
      echo "   sampleGraph=\"\$graph/conversion/\$layerSlug/subset/sample\""                                                   >> $vloadSH
      echo "   sampleURL=\"\$base/source/${sourceID}/file/${datasetID}/version/${versionID}/conversion/${sdv}.${layerID}.sample.ttl\"" >> $vloadSH
      echo "   echo pvload.sh \$sampleURL -ng \$sampleGraph"                                                                   >> $vloadSH
      echo "   \${CSV2RDF4LOD_HOME}/bin/util/pvload.sh \$sampleURL -ng \$sampleGraph"                                          >> $vloadSH
      echo ""                                                                                                                  >> $vloadSH
   done
   echo "   exit 1"                                                                                                            >> $vloadSH
   echo "elif [[ \"\$1\" == \"--meta\" && -e '$allVOID' ]]; then"                                                              >> $vloadSH
   echo "   metaURL=\"\$base/source/${sourceID}/file/${datasetID}/version/${versionID}/conversion/${sdv}.void.ttl\""           >> $vloadSH
   echo "   metaGraph=\"\$base\"/vocab/Dataset"                                                                                >> $vloadSH
   #echo "   #echo sudo /opt/virtuoso/scripts/vload ttl $allVOID \$graph"                                                      >> $vloadSH
   #echo "   #sudo /opt/virtuoso/scripts/vload ttl $allVOID \$graph"                                                           >> $vloadSH
   echo "   echo pvload.sh \$metaURL -ng \$metaGraph"                                                                          >> $vloadSH
   echo "   \${CSV2RDF4LOD_HOME}/bin/util/pvload.sh \$metaURL -ng \$metaGraph"                                                 >> $vloadSH
   echo "   exit 1"                                                                                                            >> $vloadSH
   echo "fi"                                                                                                                   >> $vloadSH
   echo ""                                                                                                                     >> $vloadSH
   echo "# Change the target graph before continuing to load everything"                                                       >> $vloadSH
   echo "if [[ \"\$1\" == \"--unversioned\" || \"\$1\" == \"--abstract\" ]]; then"                                             >> $vloadSH
   echo "   # strip off version"                                                                                               >> $vloadSH
   echo "   graph=\"\`echo \$graph\ | perl -pe 's|/version/[^/]*$||'\`\""                                                      >> $vloadSH
   echo "   graph=\"\$base/source/${sourceID}/dataset/${datasetID}\""                                                          >> $vloadSH
   echo "   echo populating abstract named graph \(\$graph\) instead of versioned named graph."                                >> $vloadSH
   echo "elif [[ \"\$1\" == \"--meta\" ]]; then"                                                                               >> $vloadSH
   echo "   metaGraph=\"\$base\"/vocab/Dataset"                                                                                >> $vloadSH
   echo "elif [[ \"\$1\" == \"--as-metadataset\" ]]; then"                                                                     >> $vloadSH
   echo "   graph=\"\${CSV2RDF4LOD_PUBLISH_METADATASET_GRAPH_NAME:-'http://purl.org/twc/vocab/conversion/MetaDataset'}\""      >> $vloadSH
   echo "   metaGraph=\"\$graph\""                                                                                             >> $vloadSH
   echo "elif [ \$# -gt 0 ]; then"                                                                                             >> $vloadSH
   echo "   echo param not recognized: \$1"                                                                                    >> $vloadSH
   echo "   echo usage: \`basename \$0\` with no parameters loads versioned dataset"                                           >> $vloadSH
   echo "   echo usage: \`basename \$0\` --{sample, meta, abstract}"                                                           >> $vloadSH
   echo "   exit 1"                                                                                                            >> $vloadSH
   echo "fi"                                                                                                                   >> $vloadSH
   echo ""                                                                                                                     >> $vloadSH
   echo "# Load the metadata, either in the same named graph as the data or into a more global one."                           >> $vloadSH
   echo "metaURL=\"\$base/source/${sourceID}/file/${datasetID}/version/${versionID}/conversion/${sdv}.void.ttl\""              >> $vloadSH
   echo "echo pvload.sh \$metaURL -ng \$metaGraph"                                                                             >> $vloadSH
   echo "\${CSV2RDF4LOD_HOME}/bin/util/pvload.sh \$metaURL -ng \$metaGraph"                                                    >> $vloadSH
   echo "if [[ \"\$1\" == \"--meta\" ]]; then"                                                                                 >> $vloadSH
   echo "   exit 1"                                                                                                            >> $vloadSH
   echo "fi"                                                                                                                   >> $vloadSH
   echo ""                                                                                                                     >> $vloadSH
   echo "function try {"                                                                                                       >> $vloadSH
   echo "   dump=\"publish/$sdv\${1}\""                                                                                        >> $vloadSH
   echo "   url=\$base/source/${sourceID}/file/${datasetID}/version/${versionID}/conversion/$sourceID-$datasetID-$versionID\${1}" >> $vloadSH
   echo "   if [ -e \$dump ]; then"                                                                                            >> $vloadSH
   echo "      echo pvload.sh \$url -ng \$graph"                                                                               >> $vloadSH
   echo "      \${CSV2RDF4LOD_HOME}/bin/util/pvload.sh \$url -ng \$graph"                                                      >> $vloadSH
   echo "      exit 1"                                                                                                         >> $vloadSH
   echo "   elif [ -e \$dump.gz ]; then"                                                                                       >> $vloadSH
   echo "      echo pvload.sh \$url.gz -ng \$graph"                                                                            >> $vloadSH
   echo "      \${CSV2RDF4LOD_HOME}/bin/util/pvload.sh \$url.gz -ng \$graph"                                                   >> $vloadSH
   echo "      exit 1"                                                                                                         >> $vloadSH
   echo "   fi"                                                                                                                >> $vloadSH
   echo "}"                                                                                                                    >> $vloadSH
   echo ""                                                                                                                     >> $vloadSH
   echo "try .nt"                                                                                                              >> $vloadSH
   echo "try .ttl"                                                                                                             >> $vloadSH
   echo "try .rdf"                                                                                                             >> $vloadSH
   echo ""                                                                                                                     >> $vloadSH
   echo "#3> <> prov:wasAttributedTo <${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}/id/csv2rdf4lod/$myMD5> ."        >> $vloadSH
   echo "#3> <> prov:generatedAtTime \"`dateInXSDDateTime.sh`\"^^xsd:dateTime ."                                               >> $vloadSH
   echo "#3> <${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}/id/csv2rdf4lod/$myMD5> foaf:name \"`basename $0`\" ."    >> $vloadSH
   chmod +x $vloadSH
   cat $vloadSH | sed 's/pvload.sh .*-ng/pvdelete.sh/g' | sed 's/vload [^ ]* [^^ ]* /vdelete /' | grep -v "tar xzf" | grep -v "unzip" | grep -v "rm " > $vdeleteSH
   chmod +x $vdeleteSH
   if [ "$CSV2RDF4LOD_PUBLISH_VIRTUOSO" == "true" ]; then
      $vdeleteSH
      $vloadSH
   elif [ "$CSV2RDF4LOD_PUBLISH_SUBSET_SAMPLES" == "true" ]; then # TODO: cross of publish media and subsets to publish. This violates it.
      $vdeleteSH --sample
      $vloadSH   --sample
   fi

   #echo "publish/bin/virtuoso-delete.sh"
   #echo "sudo /opt/virtuoso/scripts/vdelete `cat publish/$sdv.sd_name`" > publish/bin/virtuoso-delete-$sdv.sh
   #chmod +x publish/bin/virtuoso-delete.sh

   #echo "publish/bin/virtuoso-load-metadata.sh"
   #echo "sudo /opt/virtuoso/scripts/vload ttl publish/$sdv.void.ttl http://logd.tw.rpi.edu/vocab/Dataset" > publish/bin/virtuoso-load-metadata.sh
   #chmod +x publish/bin/virtuoso-load-metadata.sh

elif [[ `is-pwd-a.sh                                                            cr:directory-of-versions` == "yes" ]]; then
   echo "N/A"
elif [[ `is-pwd-a.sh                                                 cr:dataset                         ` == "yes" ]]; then
   if [ ! -e version ]; then
      mkdir version # See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Directory-Conventions
   fi
   pushd version > /dev/null
      $0 $* # Recursive call
   popd > /dev/null
elif [[ `is-pwd-a.sh              cr:source                                                             ` == "yes" ]]; then
   if [ -d dataset ]; then
      # This would conform to the directory structure if 
      # we had included 'dataset' in the convention.
      # This is here in case we ever fully support it.
      pushd dataset > /dev/null
         $0 $* # Recursive call
      popd > /dev/null
   else
      # Handle the original (3-year old) directory structure 
      # that does not include 'dataset' as a directory.
      for dataset in `directories.sh`; do
         pushd $dataset > /dev/null
            $0 $* # Recursive call
         popd > /dev/null
      done
   fi
elif [[ `is-pwd-a.sh cr:data-root cr:source cr:directory-of-datasets                                    ` == "yes" ]]; then
   for next in `directories.sh`; do
      pushd $next > /dev/null
         $0 $* # Recursive call
      popd > /dev/null
   done
fi
