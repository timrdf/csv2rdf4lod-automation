#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/cr-full-dump.sh>;
#3>    prov:wasDerivedFrom   <cr-publish-droid-to-endpoint.sh>;
#3>    rdfs:seeAlso          <https://github.com/timrdf/csv2rdf4lod-automation/wiki/One-click-data-dump> .
#
# Gather all versioned dataset dump files into one enormous dump file.
# This is highly redundant, but can be helpful for those that "just want the data"
# and don't want to crawl the VoID dataDumps to get it.

see="https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $see"}

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

TEMP="_"`basename $0``date +%s`_$$.tmp

sourceID=$CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID
datasetID=`basename $0 | sed 's/.sh$//'`
versionID='latest' # Doing it every day is a waste of space for this use case. `date +%Y-%b-%d`

cockpit="$sourceID/$datasetID/version/$versionID"
base=`echo $CSV2RDF4LOD_BASE_URI | perl -pi -e 's|http://||;s/\./-/g;s|/|-|g'`
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

for panel in 'source' 'automatic' 'publish' 'doc/logs'; do
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
     `find $cockpit/source -name "*.*" | wc -l` -lt `getconf ARG_MAX` ]]; then
   # Saves disk space, but shell can't handle infinite arguments.
   if [ "$dryrun" != "true" ]; then
      rdf2nt.sh --version 2 `find $cockpit/source` 2> $cockpit/doc/logs/rdf2nt-errors.log | gzip > $cockpit/publish/$dumpFileLocal 2> $cockpit/doc/logs/gzip-errors.log
   fi
else
   # Handles infinite source/* files, but uses disk space.
   for datadump in `find $cockpit/source`; do
      if [ "$dryrun" != "true" ]; then
         rdf2nt.sh --version 2 $datadump >> $cockpit/publish/$dumpFileLocal.tmp
      fi
   done
   if [ "$dryrun" != "true" ]; then
      cat $cockpit/publish/$dumpFileLocal.tmp | gzip > $cockpit/publish/$dumpFileLocal
      rm $cockpit/publish/$dumpFileLocal.tmp
   fi
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Pull out the RDF URI nodes from the full dump.
echo $cockpit/automatic/$base-uri-node-occurrences.txt
if [ "$dryrun" != "true" ]; then
   uri-nodes.sh $cockpit/publish/$dumpFileLocal                                       > $cockpit/automatic/$base-uri-node-occurrences.txt
fi

# no space left on device...
# echo $cockpit/automatic/$base-uri-node-occurrences-sorted.txt
# cat          $cockpit/automatic/$base-uri-node-occurrences.txt | sort    > $cockpit/automatic/$base-uri-node-occurrences-sorted.txt

echo $cockpit/automatic/$base-uri-nodes.txt
if [ "$dryrun" != "true" ]; then
   cat          $cockpit/automatic/$base-uri-node-occurrences.txt | sort -u           > $cockpit/automatic/$base-uri-nodes.txt
fi

echo $cockpit/automatic/$base-uri-nodes.ttl
#if [ "$dryrun" != "true" ]; then
   echo "@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> ."                                                                  > $cockpit/automatic/$base-uri-nodes.ttl
   echo "@prefix foaf: <http://xmlns.com/foaf/0.1/> ."                                                                            >> $cockpit/automatic/$base-uri-nodes.ttl
   echo "@prefix void: <http://rdfs.org/ns/void#> ."                                                                              >> $cockpit/automatic/$base-uri-nodes.ttl
   echo "@prefix prov: <http://www.w3.org/ns/prov#> ."                                                                            >> $cockpit/automatic/$base-uri-nodes.ttl
   echo                                                                                                                           >> $cockpit/automatic/$base-uri-nodes.ttl
   pushd $cockpit &> /dev/null
      versionedDataset=`cr-dataset-uri.sh --uri`
   popd &> /dev/null
   baseURI="${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}"
   topVoID="${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}/void"
   cat $cockpit/automatic/$base-uri-nodes.txt | awk -v dataset=$versionedDataset '{print $1,"void:inDataset <"dataset"> ."}'      >> $cockpit/automatic/$base-uri-nodes.ttl
   echo "#3> <> prov:wasAttributedTo [ foaf:name \"`basename $0`\" ]; ."                                                          >> $cockpit/automatic/$base-uri-nodes.ttl
   echo "<$topVoID> void:rootResource <$topVoID> ."                                                                               >> $cockpit/automatic/$base-uri-nodes.ttl
   echo "<$topVoID> void:dataDump     <$baseURI/source/$sourceID/file/$datasetID/version/$versionID/conversion/$dumpFileLocal> ." >> $cockpit/automatic/$base-uri-nodes.ttl
#fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#if [ "$dryrun" != "true" ]; then
   pushd $cockpit &> /dev/null
      cr-pwd.sh
      sourceID=`cr-source-id.sh`   # Saved for later
      datasetID=`cr-dataset-id.sh` # Saved for later
      versionID=`cr-version-id.sh` # Saved for later
      aggregate-source-rdf.sh automatic/$base-uri-nodes.ttl
   popd &> /dev/null

   # Sneak the top-level VoID into the void file.
   # This will not be published by aggregate-source-rdf.sh, but 
   # will get picked up by cr-publish-void-to-endpoint.sh during cron.
   #
   echo "$cockpit/publish/$base.void.ttl"
   echo "#3> <> prov:wasAttributedTo [ foaf:name \"`basename $0`\" ]; ."                                                          >> $cockpit/publish/$base.void.ttl
   echo "<$topVoID> void:rootResource <$topVoID> ."                                                                               >> $cockpit/publish/$base.void.ttl
   echo "<$topVoID> void:dataDump     <$baseURI/source/$sourceID/file/$datasetID/version/$versionID/conversion/$dumpFileLocal> ." >> $cockpit/publish/$base.void.ttl

   #      __________________________""""""""_____________________""""""____________"""""""""______""""""""""""_________________________
   # e.g. http://purl.org/twc/health/source/healthdata-tw-rpi-edu/file/cr-full-dump/version/latest/conversion/purl-org-twc-health.nt.gz
   #
   #      hosted at:
   #                        _________"""""""_____________________""""""____________"""""""""______""""""""""""_________________________
   #                        /var/www/source/healthdata-tw-rpi-edu/file/cr-full-dump/version/latest/conversion/purl-org-twc-health.nt.gz

   # NOTE: this is repeated from bin/aggregate-source-rdf.sh - be sure to align with it.
   # (update: This might have been superceded by bin/aggregate-source-rdf.sh, check!)
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
#fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

dryrun.sh $dryrun ending
