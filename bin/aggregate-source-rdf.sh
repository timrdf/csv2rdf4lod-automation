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
#
#    CSV2RDF4LOD_PUBLISH_ANNOUNCE_TO_SINDICE
#    CSV2RDF4LOD_PUBLISH_ANNOUNCE_TO_PTSW
#    CSV2RDF4LOD_PUBLISH_ANNOUNCE_ONLY_ENHANCED

if [[ $# -lt 1 || "$1" == "--help" ]]; then
   echo "usage: `basename $0` [--[no-]compress] [--[no-]turtle] [--[no-]ntriples] [--[no-]rdfxml] [--link-as-latest] source/some.{rdf,ttl,nt}"
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

compress="${CSV2RDF4LOD_PUBLISH_COMPRESS:-'false'}"
if [[ "$1" == "--compress" ]]; then
   compress="true"
   shift
elif [[ "$1" == "--no-compress" ]]; then
   compress="false"
   shift
fi

[[ "$compress" == 'true' ]] && gz='.gz' || gz=''

turtle="${CSV2RDF4LOD_PUBLISH_TTL:-'false'}"
if [ "$1" == "--turtle" ]; then
   turtle="true"
   shift
elif [ "$1" == "--no-turtle" ]; then
   turtle="false"
   shift
fi

ntriples="${CSV2RDF4LOD_PUBLISH_NT:-'false'}"
if [ "$1" == "--ntriples" ]; then
   ntriples="true"
   shift
elif [ "$1" == "--no-ntriples" ]; then
   ntriples="false"
   shift
fi

rdfxml="${CSV2RDF4LOD_PUBLISH_RDFXML:-'false'}"
if [ "$1" == "--rdfxml" ]; then
   rdfxml="true"
   shift
elif [ "$1" == "--no-rdfxml" ]; then
   rdfxml="false"
   shift
fi

link_latest="false"
if [ "$1" == "--link-as-latest" ]; then
   link_latest="true"
   shift
fi

TEMP="_"`basename $0``date +%s`_$$.tmp


# Q: why doesnt' this link the original files to /var/www? cr-sparql-sd had to do it by itself...
# A: cr-publish.sh wraps both cr-ln-to-www-root.sh and this script; use that.

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

   if [[ "$ntriples" == "true" ]]; then
      if [[ "$CSV2RDF4LOD_PUBLISH_COMPRESS" == "true" || "$compress" == "true" ]]; then
         echo "publish/$sdv.nt.gz"
         rdf2nt.sh $* | gzip           > publish/$sdv.nt.gz
      else
         echo "publish/$sdv.nt"
         rdf2nt.sh $*                  > publish/$sdv.nt
      fi
   else
      echo "publish/$sdv.nt[.gz] - skipping; set CSV2RDF4LOD_PUBLISH_NT=true to publish as N-TRIPLES." 
   fi

   if [[ "$turtle" == "true" ]]; then
      echo "publish/$sdv.ttl$gz"
      rm -f publish/$sdv.ttl
      for file in $*; do
         if [[ -e "$file" || "$file" =~ http* ]]; then
            serialization=`guess-syntax.sh --inspect $file mime`

            relatively_safe=`cr-relatively-safe.sh $file`
            REL_WARNING=''
            #if [[ "$relatively_safe" == 'false' ]]; then
            #   REL_WARNING=', WARNING: not relatively safe'
            #   fileBase=`cr-ln-to-www-root.sh -n --url-of-filepath $file`
            #   fileBase=`dirname $fileBase`
            #   echo "   $file -> $fileBase"
            #fi
            echo "  (including $file, format: $serialization$REL_WARNING)" 
            # TODO: check for accompanying .prov.ttl for the prov:wasQuotedFrom the file.
            if [[ "$serialization" == "text/turtle" && "$relatively_safe" == 'yes' ]]; then
               # Make some attempts to preserve the less-ugliness of the file.
               # And, expand the relative paths correctly.
               if [[ `too-big-for-rapper.sh $file` == 'yes' && `which serdi` ]]; then
                  serdi  -i turtle -o turtle $file              >> publish/$sdv.ttl
                  echo                                          >> publish/$sdv.ttl
               elif [[ `which rapper` ]]; then
                  rapper -i turtle -o turtle $file 2> /dev/null >> publish/$sdv.ttl
                  echo                                          >> publish/$sdv.ttl
               else
                  cat $file                                     >> publish/$sdv.ttl
                  echo                                          >> publish/$sdv.ttl
               fi
            elif [[ -z "$serialization" ]]; then
               echo "WARNING: omitting $file b/c could not recognize serialization type."
            else
               # The other formats aren't really human readable, so no worries if it's ugly ttl.
               # N-Triples is Turtle...
               rdf2nt.sh $file                                  >> publish/$sdv.ttl
               echo                                             >> publish/$sdv.ttl
            fi
         fi
      done
      if [[ -e publish/$sdv.ttl ]]; then
         if [[ "$CSV2RDF4LOD_PUBLISH_COMPRESS" == "true" || "$compress" == "true" ]]; then
            cat publish/$sdv.ttl | gzip > publish/$sdv.ttl.gz
            rm publish/$sdv.ttl
         fi
      fi
   else
      echo "publish/$sdv.ttl[.gz] - skipping; set CSV2RDF4LOD_PUBLISH_TTL=true to publish as Turtle." 
   fi

   # TODO: RDF/XML + compressed RDF/XML

   echo "publish/$sdv.sd_name"
   cr-dataset-uri.sh --uri                            > publish/$sdv.sd_name

   echo "publish/$sdv.void.ttl"
   rr-create-void.sh publish/$sdv.*                   > publish/$sdv.void.ttl

   if [[ "$link_latest" == "true" && "$versionID" != "latest" ]]; then
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
      if [ -e $CSV2RDF4LOD_PUBLISH_VARWWW_ROOT/source/$sourceID/file/$datasetID/version/latest ]; then
         rm -rf $CSV2RDF4LOD_PUBLISH_VARWWW_ROOT/source/$sourceID/file/$datasetID/version/latest
      fi
      ln -s `cr-conversion-root.sh`/$sourceID/$datasetID/version/$versionID `cr-conversion-root.sh`/$sourceID/$datasetID/version/latest
      ln -s $CSV2RDF4LOD_PUBLISH_VARWWW_ROOT/source/$sourceID/file/$datasetID/version/$versionID $CSV2RDF4LOD_PUBLISH_VARWWW_ROOT/source/$sourceID/file/$datasetID/version/latest
      # hard link to rename the dump file.
      if [[ "$CSV2RDF4LOD_PUBLISH_NT" == "true" || "$ntriples" == "true" ]]; then
         echo `cr-conversion-root.sh`/$sourceID/$datasetID/version/latest/publish/$sd-latest.nt$gz
         rm -f `cr-conversion-root.sh`/$sourceID/$datasetID/version/latest/publish/$sd-latest.nt$gz
         ln `cr-conversion-root.sh`/$sourceID/$datasetID/version/latest/publish/$sdv.nt$gz  `cr-conversion-root.sh`/$sourceID/$datasetID/version/latest/publish/$sd-latest.nt$gz
      else
         echo "$sourceID/$datasetID/version/latest/publish/$sd-latest.nt$gz - skipping."
      fi
      if [[ "$CSV2RDF4LOD_PUBLISH_TTL" == "true" || "$turtle" == "true" ]]; then
         echo `cr-conversion-root.sh`/$sourceID/$datasetID/version/latest/publish/$sd-latest.ttl$gz
         rm -f `cr-conversion-root.sh`/$sourceID/$datasetID/version/latest/publish/$sd-latest.ttl$gz
         ln `cr-conversion-root.sh`/$sourceID/$datasetID/version/latest/publish/$sdv.ttl$gz `cr-conversion-root.sh`/$sourceID/$datasetID/version/latest/publish/$sd-latest.ttl$gz
      else
         echo "$sourceID/$datasetID/version/latest/publish/$sd-latest.ttl$gz - skipping."
      fi
      if [[ "$CSV2RDF4LOD_PUBLISH_RDFXML" == "true" || "$rdfxml" == "true" ]]; then
         echo `cr-conversion-root.sh`/$sourceID/$datasetID/version/latest/publish/$sd-latest.rdf$gz
         rm -f `cr-conversion-root.sh`/$sourceID/$datasetID/version/latest/publish/$sd-latest.rdf$gz
         ln `cr-conversion-root.sh`/$sourceID/$datasetID/version/latest/publish/$sdv.rdf$gz `cr-conversion-root.sh`/$sourceID/$datasetID/version/latest/publish/$sd-latest.rdf$gz
      else
         echo "$sourceID/$datasetID/version/latest/publish/$sd-latest.rdf$gz - skipping."
      fi
   else
      because=''
      if [[ "$versionID" == "latest" ]]; then
         because=" (because version is already 'latest')"
      fi
      echo "Not linking as latest$because."
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
   echo "elif [[ \"\`stat --format=%U \"\$CSV2RDF4LOD_PUBLISH_VARWWW_ROOT/source\"\`\" == \`whoami\` ]]; then"            >> $lnwww
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
   echo "         if [[ -n \"\$sudo\" ]]; then"                                                                    >> $lnwww
   echo "            echo \$sudo rm -f \"\$wwwfile\""                                                              >> $lnwww
   echo "         fi"                                                                                              >> $lnwww
   echo "         \$sudo rm -f \"\$wwwfile\""                                                                      >> $lnwww
   echo "      else"                                                                                               >> $lnwww
   echo "         if [[ -n \"\$sudo\" ]]; then"                                                                    >> $lnwww
   echo "            echo \$sudo mkdir -p \`dirname \"\$wwwfile\"\`"                                               >> $lnwww
   echo "         fi"                                                                                              >> $lnwww
   echo "         \$sudo mkdir -p \`dirname \"\$wwwfile\"\`"                                                       >> $lnwww
   echo "      fi"                                                                                                 >> $lnwww
   echo "      echo \"  \$wwwfile\""                                                                               >> $lnwww
   echo "      if [[ -n \"\$sudo\" ]]; then"                                                                       >> $lnwww
   echo "         echo \$sudo ln \$symbolic \"\${pwd}\$1\" \"\$wwwfile\""                                          >> $lnwww
   echo "      fi"                                                                                                 >> $lnwww
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
      echo "   echo pvload.sh \$sampleURL -ng \$sampleGraph"                                                                           >> $vloadSH
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
   echo "elif [[ \"\$CSV2RDF4LOD_PUBLISH_SPARQL_ENDPOINT_SEPARATE_NG_PROVENANCE\" == 'true' ]]; then"                          >> $vloadSH
   echo "   metaGraph=\`pvload.sh --prov-graph-name \$graph\`"                                                                 >> $vloadSH
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
   echo "[[ \"\$CSV2RDF4LOD_PUBLISH_SPARQL_ENDPOINT_SEPARATE_NG_PROVENANCE\" == 'true' ]] && sep='--separate-provenance' || sep=''" >> $vloadSH
   echo "function try {"                                                                                                       >> $vloadSH
   echo "   dump=\"publish/$sdv\${1}\""                                                                                        >> $vloadSH
   echo "   url=\$base/source/${sourceID}/file/${datasetID}/version/${versionID}/conversion/$sourceID-$datasetID-$versionID\${1}" >> $vloadSH
   echo "   if [ -e \$dump ]; then"                                                                                            >> $vloadSH
   echo "      echo pvload.sh \$url -ng \$graph \$sep"                                                                         >> $vloadSH
   echo "      \${CSV2RDF4LOD_HOME}/bin/util/pvload.sh \$url -ng \$graph \$sep"                                                >> $vloadSH
   echo "      exit 1"                                                                                                         >> $vloadSH
   echo "   elif [ -e \$dump.gz ]; then"                                                                                       >> $vloadSH
   echo "      echo pvload.sh \$url.gz -ng \$graph \$sep"                                                                      >> $vloadSH
   echo "      \${CSV2RDF4LOD_HOME}/bin/util/pvload.sh \$url.gz -ng \$graph \$sep"                                             >> $vloadSH
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

   announce='false' # It doesn't make sense to announce it unless we've published it as Linked Data.
   if [ "$CSV2RDF4LOD_PUBLISH_VIRTUOSO" == "true" ]; then
      $vdeleteSH
      $vloadSH
      announce='true'
   elif [ "$CSV2RDF4LOD_PUBLISH_SUBSET_SAMPLES" == "true" ]; then # TODO: cross of publish media and subsets to publish. This violates it.
      $vdeleteSH --sample                                         # SUBSET_SAMPLES should not be mutually exclusive from VIRTUOSO.
      $vloadSH   --sample
      announce='true'
   fi

   if [ "$announce" == "true" ]; then
      # See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Ping-the-Semantic-Web
      about=`cr-dataset-uri.sh --uri`
      if [ "$CSV2RDF4LOD_PUBLISH_ANNOUNCE_TO_SINDICE" == "true" ]; then
         echo "http://api.sindice.com/v2/ping <-- $about"
         # TODO: use ping-sindice.sh -w
         curl -H "Accept: text/plain" --data-binary "$about" http://api.sindice.com/v2/ping
      else
         echo "http://api.sindice.com/v2/ping - skipping; set CSV2RDF4LOD_PUBLISH_ANNOUNCE_TO_SINDICE=true to announce to Sindice."
      fi
      if [ "$CSV2RDF4LOD_PUBLISH_ANNOUNCE_TO_PTSW" == "true" ]; then
         echo "http://pingthesemanticweb.com  <-- $about"
         curl `ptsw.sh $about`
      else
         echo "http://pingthesemanticweb.com  - skipping; set CSV2RDF4LOD_PUBLISH_ANNOUNCE_TO_PTSW=true to announce to Ping the Semantic Web."
      fi
      #CSV2RDF4LOD_PUBLISH_ANNOUNCE_ONLY_ENHANCED <- Bother with this?
   else
      echo "http://api.sindice.com/v2/ping - skipping; set CSV2RDF4LOD_PUBLISH_VIRTUOSO=true or CSV2RDF4LOD_PUBLISH_SUBSET_SAMPLES=true to announce to Sindice."
      echo "http://pingthesemanticweb.com  - skipping; set CSV2RDF4LOD_PUBLISH_VIRTUOSO=true or CSV2RDF4LOD_PUBLISH_SUBSET_SAMPLES=true to announce to Ping the Semantic Web."
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
