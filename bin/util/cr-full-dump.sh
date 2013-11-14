#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/cr-full-dump.sh>;
#3>    prov:wasDerivedFrom   <cr-publish-droid-to-endpoint.sh>;
#3>    rdfs:seeAlso          <https://github.com/timrdf/csv2rdf4lod-automation/wiki/One-click-data-dump> .
#
# Gather all versioned dataset dump files into one enormous dump file.
# This is highly redundant, but can be helpful for those that "just want the data"
# and don't want to crawl the VoID dataDumps to get it.

#see="https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"
#CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $see"}
HOME=$(cd ${0%/*/*} && echo ${PWD%/*})
export CLASSPATH=$CLASSPATH`$HOME/bin/util/cr-situate-classpaths.sh`
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?$HOME}
export PATH=$PATH`$HOME/bin/util/cr-situate-paths.sh`

see="https://github.com/timrdf/csv2rdf4lod-automation/wiki/Aggregating-subsets-of-converted-datasets"
CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID=${CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID:?"not set; see $see"}

see="https://github.com/timrdf/csv2rdf4lod-automation/wiki/Aggregating-subsets-of-converted-datasets"
CSV2RDF4LOD_BASE_URI=${CSV2RDF4LOD_BASE_URI:?"not set; see $see"}

see="https://github.com/timrdf/csv2rdf4lod-automation/wiki/Aggregating-subsets-of-converted-datasets"
CSV2RDF4LOD_PUBLISH_VARWWW_ROOT=${CSV2RDF4LOD_PUBLISH_VARWWW_ROOT:?"not set; see $see"}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:data-root"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

sourceID=$CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID
datasetID=`basename $0 | sed 's/.sh$//'`
versionID='latest' # Doing it every day is a waste of space for this use case. `date +%Y-%b-%d`

cockpit="$sourceID/$datasetID/version/$versionID"
base=`echo $CSV2RDF4LOD_BASE_URI | perl -pi -e 's|http://||;s/\./-/g;s|/|-|g'` # e.g. lofd-tw-rpi-edu
dumpFileLocal=$base.nt.gz

if [[ "$1" == "--help" ]]; then
   echo "usage: `basename $0` [--target] [-n]"
   echo ""
   echo "  Gather all versioned dataset dump files into one enormous dump file."
   echo "    archive them into a versioned dataset 'latest'"
   echo ""
   echo "         --target : return the dump file location, then quit."
   echo "               -n : perform dry run only; do not load named graph."
   echo
   exit 1
fi


if [ "$1" == "--target" ]; then
   # a conversion:VersionedDataset:
   # e.g. http://purl.org/twc/health/source/tw-rpi-edu/dataset/cr-publish-dcat-to-endpoint/version/2012-Sep-07
   echo $cockpit/publish/$dumpFileLocal
   exit 0
fi

dryrun="false"
if [ "$1" == "-n" ]; then
   dryrun="true"
   dryrun.sh $dryrun beginning
   shift
fi

TEMP="_"`basename $0``date +%s`_$$.tmp

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Clean up from last run.
for panel in 'source' 'automatic' 'automatic/tdb' 'publish' 'doc/logs'; do
   if [ ! -d $cockpit/$panel ]; then
      mkdir -p $cockpit/$panel
   fi
   echo "rm -rf $cockpit/$panel/*"
   if [ "$dryrun" != "true" ]; then
      rm -rf $cockpit/$panel/*
   fi
done

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Collect source files into source/
if [ "$dryrun" != "true" ]; then
   for datadump in `cr-list-versioned-dataset-dumps.sh --warn-if-missing`; do
      echo ln $datadump $cockpit/source/
      if [ "$dryrun" != "true" ]; then
         ln $datadump $cockpit/source/
      fi
   done
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Build up full dump file into publish/
echo "$cockpit/publish/$dumpFileLocal"
if [[ -n "`getconf ARG_MAX`" && \
     `find $cockpit/source -type f | wc -l` -lt `getconf ARG_MAX` ]]; then
   # Saves disk space, but shell can't handle infinite arguments.
   echo "Aggregating versioned dataset dumps into monolith (as batch)"
   if [ "$dryrun" != "true" ]; then
      rdf2nt.sh --verbose `find $cockpit/source -type f` 2> $cockpit/doc/logs/rdf2nt-errors.log | gzip > $cockpit/publish/$dumpFileLocal 2> $cockpit/doc/logs/gzip-errors.log
   fi
else
   echo "Aggregating versioned dataset dumps into monolith (incrementally)"
   # Handles infinite source/* files, but uses disk space.
   for datadump in `find $cockpit/source -type f`; do
      if [ "$dryrun" != "true" ]; then
         rdf2nt.sh $datadump >> $cockpit/publish/$dumpFileLocal.tmp
      fi
   done
   if [ "$dryrun" != "true" ]; then
      cat $cockpit/publish/$dumpFileLocal.tmp | gzip > $cockpit/publish/$dumpFileLocal
      rm $cockpit/publish/$dumpFileLocal.tmp
   fi
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Hack: Where is this directory coming from?
rm -rf $cockpit/source/.droid6

## - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Gather list of unique URI nodes.
for datadump in `find $cockpit/source -type f`; do
   if [ "$dryrun" != "true" ]; then
      echo "tdb <--(URI nodes)-- $datadump"
      uri-nodes.sh '--as-nt' $datadump | tdbloader --quiet --loc=$cockpit/automatic/tdb -
      # CONSIDER: capturing the occurrence frequency of the nodes; needs modeling and tallying.
   fi
done
## - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


## - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Create the URI node listing RDF file.
pushd $cockpit &> /dev/null
   versionedDataset=`cr-dataset-uri.sh --uri`
   sdv=`cr-sdv.sh`
popd &> /dev/null
baseURI="${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}"
topVoID="${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}/void"

echo $cockpit/automatic/$base-uri-nodes.ttl
if [ "$dryrun" != "true" ]; then
   dataDump="$baseURI/source/$sourceID/file/$datasetID/version/$versionID/conversion/$dumpFileLocal"
   echo "@prefix rdfs:       <http://www.w3.org/2000/01/rdf-schema#> ."                               > $cockpit/automatic/$base-uri-nodes.ttl
   echo "@prefix dcterms:    <http://purl.org/dc/terms/> ."                                          >> $cockpit/automatic/$base-uri-nodes.ttl
   echo "@prefix foaf:       <http://xmlns.com/foaf/0.1/> ."                                         >> $cockpit/automatic/$base-uri-nodes.ttl
   echo "@prefix void:       <http://rdfs.org/ns/void#> ."                                           >> $cockpit/automatic/$base-uri-nodes.ttl
   echo "@prefix prov:       <http://www.w3.org/ns/prov#> ."                                         >> $cockpit/automatic/$base-uri-nodes.ttl
   echo "@prefix conversion: <http://purl.org/twc/vocab/conversion/> ."                              >> $cockpit/automatic/$base-uri-nodes.ttl
   echo "@base <$baseURI/source/$sourceID/file/$datasetID/version/$versionID/conversion/> ."         >> $cockpit/automatic/$base-uri-nodes.ttl
   echo                                                                                              >> $cockpit/automatic/$base-uri-nodes.ttl
   echo "#3> <> prov:wasAttributedTo [ foaf:name \"`basename $0`\" ]; ."                             >> $cockpit/automatic/$base-uri-nodes.ttl
   echo                                                                                              >> $cockpit/automatic/$base-uri-nodes.ttl
   echo "<$topVoID> void:rootResource <$topVoID> ."                                                  >> $cockpit/automatic/$base-uri-nodes.ttl
   echo "<$topVoID> void:dataDump     <$dumpFileLocal> ."                                            >> $cockpit/automatic/$base-uri-nodes.ttl
   echo "<$versionedDataset> a conversion:AggregateDataset ."                                        >> $cockpit/automatic/$base-uri-nodes.ttl
   echo                                                                                              >> $cockpit/automatic/$base-uri-nodes.ttl
   loc=$cockpit/automatic/tdb
   query="select ?node where { ?node a <http://www.w3.org/2000/01/rdf-schema#Resource> }"
   echo $query | tdbquery --loc=$loc --query=- --results=csv | sed 's/\s//' \
               | awk -v dump=$dumpFileLocal '{if(NR>1){print "<"dump"> dcterms:subject <"$1"> ."}}'  >> $cockpit/automatic/$base-uri-nodes.ttl
   tdb_size=`du -sh $cockpit/automatic/tdb`
   echo "Removing $tdb_size $cockpit/automatic/tdb"
   rm -f $cockpit/automatic/tdb/*
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ "$dryrun" != "true" ]; then

   pushd $cockpit &> /dev/null
      cr-pwd.sh
      aggregate-source-rdf.sh automatic/$base-uri-nodes.ttl
      #ttl_size=`du -sh automatic/$base-uri-nodes.ttl`
      #echo "Removing $ttl_size automatic/$base-uri-nodes.ttl"
      #rm -f automatic/$base-uri-nodes.ttl

      # TODO: consider avoiding the graph load (or, hack it and pvdelete e.g. http://ieeevis.tw.rpi.edu/source/ieeevis-tw-rpi-edu/dataset/cr-full-dump/version/latest)
   popd &> /dev/null

   # Sneak the top-level VoID into the void file.
   # This will not be published by aggregate-source-rdf.sh, but 
   # will get picked up by cr-publish-void-to-endpoint.sh during cron.
   #
   #echo "$cockpit/publish/$base.void.ttl"
   echo "$cockpit/publish/$sdv.void.ttl +"
   #                                                                                                                              >> $cockpit/publish/$base.void.ttl
   mappings="$baseURI/source/$sourceID/file/cr-aggregated-params/version/latest/conversion/$sourceID-cr-aggregated-params-latest.ttl.gz"
   echo "#3> <> prov:wasAttributedTo [ foaf:name \"`basename $0`\" ]; ."                                                          >> $cockpit/publish/$sdv.void.ttl
   cr-default-prefixes.sh --turtle                                                                                                >> $cockpit/publish/$sdv.void.ttl
   echo "@prefix tag:        <http://www.holygoat.co.uk/owl/redwood/0.1/tags/> ."                                                 >> $cockpit/publish/$sdv.void.ttl
   echo                                                                                                                           >> $cockpit/publish/$sdv.void.ttl
   echo "<$topVoID>"                                                                                                              >> $cockpit/publish/$sdv.void.ttl
   echo "   a void:Dataset, dcat:Dataset;"                                                                                        >> $cockpit/publish/$sdv.void.ttl
   echo "   void:rootResource <$topVoID>;"                                                                                        >> $cockpit/publish/$sdv.void.ttl
   echo "   void:dataDump     <$baseURI/source/$sourceID/file/$datasetID/version/$versionID/conversion/$dumpFileLocal>;"          >> $cockpit/publish/$sdv.void.ttl
   echo "   dcat:distribution <$baseURI/source/$sourceID/file/$datasetID/version/$versionID/conversion/$dumpFileLocal>;"          >> $cockpit/publish/$sdv.void.ttl
   if [[ "$CSV2RDF4LOD_PUBLISH_VIRTUOSO" == "true" && "$CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT" =~ http* ]]; then
      echo "   void:sparqlEndpoint <$CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT>;"                                              >> $cockpit/publish/$sdv.void.ttl
      echo "   dcat:distribution   <$CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT>;"                                              >> $cockpit/publish/$sdv.void.ttl
   fi
   echo "   foaf:page <$baseURI/source/$sourceID/file/cr-sitemap/version/latest/conversion/sitemap.xml>;"                         >> $cockpit/publish/$sdv.void.ttl
   echo "   tag:taggedWithTag <http://datahub.io/tag/lod>, <http://datahub.io/tag/prizms>,"                                       >> $cockpit/publish/$sdv.void.ttl
   echo "                     <http://datahub.io/tag/vocab-mappings>, <http://datahub.io/tag/deref-vocab>,"                       >> $cockpit/publish/$sdv.void.ttl
   echo "                     <http://datahub.io/tag/provenance-metadata>;"                                                       >> $cockpit/publish/$sdv.void.ttl
   echo "   void:uriSpace \"$baseURI/\";"                                                                                         >> $cockpit/publish/$sdv.void.ttl
   echo "   prov:wasDerivedFrom <$mappings>;"                                                                                     >> $cockpit/publish/$sdv.void.ttl
   echo "."                                                                                                                       >> $cockpit/publish/$sdv.void.ttl
   echo "<$mappings>"                                                                                                             >> $cockpit/publish/$sdv.void.ttl
   echo "   dcterms:description \"mappings/twc-conversion\";"                                                                     >> $cockpit/publish/$sdv.void.ttl
   echo "   dcterms:format   <http://www.w3.org/ns/formats/Turtle>;"                                                              >> $cockpit/publish/$sdv.void.ttl
   echo "   a conversion:VocabularyMappings ."                                                                                    >> $cockpit/publish/$sdv.void.ttl
   echo "<$baseURI/source/$sourceID/file/$datasetID/version/$versionID/conversion/$dumpFileLocal>"                                >> $cockpit/publish/$sdv.void.ttl
   echo "   dcterms:format   <http://www.w3.org/ns/formats/N-Triples>;"                                                           >> $cockpit/publish/$sdv.void.ttl
   echo "   dcat:downloadURL <$baseURI/source/$sourceID/file/$datasetID/version/$versionID/conversion/$dumpFileLocal>;"           >> $cockpit/publish/$sdv.void.ttl
   echo "."                                                                                                                       >> $cockpit/publish/$sdv.void.ttl
   echo "<$baseURI/source/$sourceID/file/cr-sitemap/version/latest/conversion/sitemap.xml>"                                       >> $cockpit/publish/$sdv.void.ttl
   echo "   a <http://dbpedia.org/resource/Site_map>;"                                                                            >> $cockpit/publish/$sdv.void.ttl
   echo "   dcterms:subject   <$topVoID>;"                                                                                        >> $cockpit/publish/$sdv.void.ttl
   echo "   foaf:primaryTopic <$topVoID>;"                                                                                        >> $cockpit/publish/$sdv.void.ttl
   echo "."                                                                                                                       >> $cockpit/publish/$sdv.void.ttl

   if [[ -n "$CSV2RDF4LOD_PUBLISH_DATAHUB_METADATA_OUR_BUBBLE_ID" ]]; then
      echo "<$topVoID> owl:sameAs <http://datahub.io/dataset/$CSV2RDF4LOD_PUBLISH_DATAHUB_METADATA_OUR_BUBBLE_ID>;"               >> $cockpit/publish/$sdv.void.ttl
      echo "   a datafaqs:CKANDataset;"                                                                                           >> $cockpit/publish/$sdv.void.ttl
      echo "   dcterms:identifier \"$CSV2RDF4LOD_PUBLISH_DATAHUB_METADATA_OUR_BUBBLE_ID\";"                                       >> $cockpit/publish/$sdv.void.ttl
      echo "."                                                                                                                    >> $cockpit/publish/$sdv.void.ttl
   fi

   echo "VC: $CSV2RDF4LOD_PUBLISH_VC_REPOSITORY"
   if [[ "$CSV2RDF4LOD_PUBLISH_VC_REPOSITORY" == *git ]]; then
      # e.g.     git@github.com:tetherless-world/hub.git (location)
      #      https://github.com/tetherless-world/hub.git (anon)
      #      https://github.com/tetherless-world/hub     (browse)
      #
      # e.g.     git@github.com:timrdf/ieeevis.git       (location)
      #      https://github.com/timrdf/ieeevis.git       (anon)
      #      https://github.com/timrdf/ieeevis           (browse)
      git=''
      if [[ "$CSV2RDF4LOD_PUBLISH_VC_REPOSITORY" == http* ]]; then
         git="git@${CSV2RDF4LOD_PUBLISH_VC_REPOSITORY#http*//}"
         git=`echo $git | sed 's/.com\//.com:/'`
         git_anon="$CSV2RDF4LOD_PUBLISH_VC_REPOSITORY"
         browse="${CSV2RDF4LOD_PUBLISH_VC_REPOSITORY%.git}"
      elif [[ "$CSV2RDF4LOD_PUBLISH_VC_REPOSITORY" == git* ]]; then
         git="$CSV2RDF4LOD_PUBLISH_VC_REPOSITORY"
         git_anon="https://${CSV2RDF4LOD_PUBLISH_VC_REPOSITORY#git@}"
         git_anon=`echo $git_anon | sed 's/.com:/.com\//'`
         browse="${git_anon%.git}"
      fi
      echo $git $git_anon $browse
      if [[ -n "$git" ]]; then
         echo "<$topVoID>"                                                                                                        >> $cockpit/publish/$sdv.void.ttl
         echo "    a doap:Project;"                                                                                               >> $cockpit/publish/$sdv.void.ttl
         echo "    doap:repository   <$topVoID/repo/git>;"                                                                        >> $cockpit/publish/$sdv.void.ttl
         echo "    dcat:distribution <$topVoID/repo/git>;"                                                                        >> $cockpit/publish/$sdv.void.ttl
         echo "."                                                                                                                 >> $cockpit/publish/$sdv.void.ttl
         echo "<$topVoID/repo/git>"                                                                                               >> $cockpit/publish/$sdv.void.ttl
         echo "   a doap:GitRepository, doap:Repository, dcat:Distribution;"                                                      >> $cockpit/publish/$sdv.void.ttl
         echo "   dcterms:title    \"Version Control Repository\";"                                                               >> $cockpit/publish/$sdv.void.ttl
         echo "   doap:location    \"$git\";"                                                                                     >> $cockpit/publish/$sdv.void.ttl
         echo "   doap:anon-root   \"$git_anon\";"                                                                                >> $cockpit/publish/$sdv.void.ttl
         echo "   doap:downloadURL \"$git_anon\";"                                                                                >> $cockpit/publish/$sdv.void.ttl
         echo "   doap:browse      <$browse>;"                                                                                    >> $cockpit/publish/$sdv.void.ttl
         echo "   dcat:accessURL   <$browse>;"                                                                                    >> $cockpit/publish/$sdv.void.ttl
         echo "."                                                                                                                 >> $cockpit/publish/$sdv.void.ttl
      fi
   fi
   # NOTE: the $sdv.void.ttl file augmentations don't get loaded until the aggregate-void script runs again. - - - - - - - - - - - - ^

   #
   # Ephemeral metadata
   #
   cr-default-prefixes.sh --turtle                                                                                                 > $cockpit/publish/$sdv.ephemeral.ttl 
   echo $topVoID                                                                                                                   > $cockpit/publish/$sdv.ephemeral.ttl.sd_name

   # <$topVoID> void:exampleResource ?x from:
   echo "prefix dcterms: <http://purl.org/dc/terms/>"                                                                              > $cockpit/automatic/exampleResource.rq
   echo "prefix void:    <http://rdfs.org/ns/void#>"                                                                              >> $cockpit/automatic/exampleResource.rq
   echo "select distinct ?ex ?date"                                                                                               >> $cockpit/automatic/exampleResource.rq
   echo "where { "                                                                                                                >> $cockpit/automatic/exampleResource.rq
   echo "  ?s void:exampleResource ?ex; dcterms:modified ?date ."                                                                 >> $cockpit/automatic/exampleResource.rq
   echo "  filter(!regex(str(?ex),'thing_'))"                                                                                     >> $cockpit/automatic/exampleResource.rq
   echo "}"                                                                                                                       >> $cockpit/automatic/exampleResource.rq
   echo "order by desc(?date)"                                                                                                    >> $cockpit/automatic/exampleResource.rq
   echo "limit 1"                                                                                                                 >> $cockpit/automatic/exampleResource.rq
   cache-queries.sh $CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT -o csv -q $cockpit/automatic/exampleResource.rq -od $cockpit/source/exampleResource
   exampleResource=`cat $cockpit/source/exampleResource/exampleResource.rq.csv | sed 's/"//g' | grep "^http" | awk -F, '{print $1}' | tail -1`
   if [[ -n "$exampleResource" && "$exampleResource" =~ http* ]]; then
      echo "$cockpit/publish/$sdv.ephemeral.ttl (void:exampleResource $exampleResource)"
      echo "<$topVoID>"                                                                                                           >> $cockpit/publish/$sdv.ephemeral.ttl
      echo "   void:exampleResource <$exampleResource>;"                                                                          >> $cockpit/publish/$sdv.ephemeral.ttl 
      echo "."                                                                                                                    >> $cockpit/publish/$sdv.ephemeral.ttl 
   else
      echo "WARNING: `basename $0` could not determine example resource."
   fi

   # void:triples
   echo "$cockpit/publish/$sdv.ephemeral.ttl (void:triples)"
   triples=`rdf2nt.sh $cockpit/publish/$dumpFileLocal | rapper -i ntriples -c -I http://blah - 2>&1 | awk '$0~/Parsing returned/{print $4}'`
   if [[ ${#triples} -gt 0 && $triples == [0-9]* ]]; then # - - - - - - - - - - Avoid publish/*.void.ttl pattern so that cr-publish-void-to-endpoint.sh doesn't find it.
      echo "<$topVoID> void:triples $triples ."                                                                                   >> $cockpit/publish/$sdv.ephemeral.ttl
      echo "<$topVoID> dcterms:date `dateInXSDDateTime.sh --turtle` ."                                                            >> $cockpit/publish/$sdv.ephemeral.ttl
   fi
   if [[   `valid-rdf.sh $cockpit/publish/$sdv.ephemeral.ttl` != 'yes' ]]; then
      echo "WARNING: `basename $0` did not load ephemeral attributes of $topVoID b/c valid = `valid-rdf.sh $cockpit/publish/$sdv.ephemeral.ttl`"
#   elif [[ `void-triples.sh $cockpit/publish/$sdv.ephemeral.ttl` =~ ^[1-9]+[0-9]*$ ]]; then # was: != [1-9][0-9]* ]]; then
#      # http://stackoverflow.com/questions/2210349/bash-test-whether-string-is-valid-as-an-integer
#      echo "WARNING: `basename $0` did not load ephemeral attributes of $topVoID b/c triples = `void-triples.sh $cockpit/publish/$sdv.ephemeral.ttl`"
   else
      pvdelete.sh $topVoID
      vload ttl $cockpit/publish/$sdv.ephemeral.ttl $topVoID -v
   fi

   #      __________________________""""""""_____________________""""""____________"""""""""______""""""""""""_________________________
   # e.g. http://purl.org/twc/health/source/healthdata-tw-rpi-edu/file/cr-full-dump/version/latest/conversion/purl-org-twc-health.nt.gz
   #
   #      hosted at:
   #                        ________""""""""_____________________""""""____________"""""""""______""""""""""""_________________________
   #                        /var/www/source/healthdata-tw-rpi-edu/file/cr-full-dump/version/latest/conversion/purl-org-twc-health.nt.gz


         # NOTE: this is repeated from bin/aggregate-source-rdf.sh - be sure to align with it.
         # (update: This might have been superceded by bin/aggregate-source-rdf.sh, check!)
         # (update 24 Apr 2013 - this is superceded by cr-ln-to-www-root.sh publish/lofd-tw-rpi-edu.nt.gz, but that's not working (below))
         sudo="sudo"
         if [[ `whoami` == root ]]; then
            sudo=""
         elif [[ "`stat --format=%U "$CSV2RDF4LOD_PUBLISH_VARWWW_ROOT/source"`" == `whoami` ]]; then
            sudo=""
         fi
         
         symbolic=""
         wd=""
         if [[ "$CSV2RDF4LOD_PUBLISH_VARWWW_LINK_TYPE" == "soft" ]]; then
           symbolic="-sf "
           wd=`pwd`/
         fi
         
         wwwFile="$CSV2RDF4LOD_PUBLISH_VARWWW_ROOT/source/$sourceID/file/$datasetID/version/$versionID/conversion/$dumpFileLocal"
         echo "$wwwFile"
         $sudo rm -f $wwwFile
         echo $sudo ln $symbolic "${wd}$cockpit/publish/$dumpFileLocal" $wwwFile
              $sudo ln $symbolic "${wd}$cockpit/publish/$dumpFileLocal" $wwwFile

   #pushd $cockpit &> /dev/null
   #   # Replaces duplication above (but, isnt' working...):
   #   cr-ln-to-www-root.sh publish/$dumpFileLocal
   #   one_click_dump=`cr-ln-to-www-root.sh -n --url-of-filepath publish/$dumpFileLocal`
   #
   #   # In case the triples we snuck in didn't get published into /var/www
   #   #cr-ln-to-www-root.sh publish/$base.void.ttl
   #popd &> /dev/null
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

dryrun.sh $dryrun ending
