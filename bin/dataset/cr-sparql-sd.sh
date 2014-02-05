#!/bin/bash
#
#3> <> a conversion:RetrievalTrigger;
#3>    prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/dataset/cr-sparql-sd.sh>;
#3>    prov:wasDerivedFrom   <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/dataset/cr-aggregate-dcat.sh>;
#3>    rdfs:seeAlso          <https://github.com/timrdf/csv2rdf4lod-automation/wiki/Aggregating-subsets-of-converted-datasets>;
#3> .

[ -n "`readlink $0`" ] && this=`readlink $0` || this=$0
HOME=$(cd ${this%/*/*} && echo ${PWD%/*})
export PATH=$PATH`$HOME/bin/util/cr-situate-paths.sh`
export CLASSPATH=$CLASSPATH`$HOME/bin/util/cr-situate-classpaths.sh`

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:bone"
if [ `is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

if [[ "$1" == "--help" ]]; then
   see='https://github.com/timrdf/csv2rdf4lod-automation/wiki/Secondary-Derivative-Datasets#cr-sparql-sd'
   echo "usage: `basename $0` [-n] [version-identifier]"
   echo ""
   echo "Create a dataset from the aggregation of all csv2rdf4lod conversion parameter files."
   echo ""
   echo "               -n : perform dry run only; do not load named graph."
   echo "see $see"
   echo
   exit
fi

dryrun="false"
if [ "$1" == "-n" ]; then
   dryrun="true"
   dryrun.sh $dryrun beginning
   shift
fi

# "SDV" naming
if [[ -n "$CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID" ]]; then
   sourceID="$CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID"
elif [[ `is-pwd-a.sh 'cr:data-root'` == "yes" ]]; then
   section='#csv2rdf4lod_publish_our_source_id'
   see="https://github.com/timrdf/csv2rdf4lod-automation/wiki/Secondary-Derivative-Datasets$section"
   sourceID=${CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID:?"not set and ambiguous based on level in data root; see $see"}
else
   sourceID=`cr-source-id.sh`
fi
datasetID=`basename $this | sed -e 's/.sh$//'`
if [[ "$1" != "" ]]; then
   versionID="$1"
elif [[ `is-pwd-a.sh 'cr:conversion-cockpit'` == "yes" ]]; then
   versionID=`cr-version-id.sh`
else
   versionID=`date +%Y-%b-%d`
fi

pushd `cr-conversion-root.sh` &> /dev/null
   cockpit="$sourceID/$datasetID/version/$versionID"
   if [ "$dryrun" != "true" ]; then
      mkdir -p $cockpit/source $cockpit/automatic &> /dev/null
      rm -rf $cockpit/source/*                    &> /dev/null
   fi

   # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
   #echo "Aggregating all DCAT access metadata in `pwd` into $cockpit/source/." >&2
   # from e.g. ./hub/countries/access.ttl to ./hub/countries/version/2013-Sep-06/access.ttl
   #for dcat in `find . -mindepth 3 -maxdepth 5 -name "*dcat.ttl" -or -name "access.ttl"`; do
   #   echo ${dcat#./}
   #   sdv=$(cd `dirname $dcat` && cr-sdv.sh)
   #   if [ "$dryrun" != "true" ]; then
   #      ln $dcat $cockpit/source/$sdv.dcat.ttl
   #   fi
   #done
   # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

   if [[ -n "$CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT" && "$CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT" =~ http* ]]; then

      pushd $cockpit &> /dev/null
         echo
         curl -H "Accept: application/rdf+xml" -L "$CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT" > source/sparql-sd.rdf
         cat source/sparql-sd.rdf | perl -pi -e "s|http://localhost:8890/sparql|$CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT|" > automatic/sparql-sd.rdf
         # We don't use aggregate-source-rdf.sh b/c it would use the SDV URI organization, and we need the result in
         # the named graph http://localhost:8890/sparql
         # See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Publishing-conversion-results-with-a-Virtuoso-triplestore#modifying-the-sparql-service-description

         cat automatic/sparql-sd.rdf
         if [ "$dryrun" != "true" ]; then
            if [[ `valid-rdf.sh automatic/sparql-sd.rdf` == 'yes' ]]; then
               cr-ln-to-www-root.sh    automatic/sparql-sd.rdf # TODO: aggregate-source-rdf.sh should do this, no?
               varwww=`cr-ln-to-www-root.sh -n automatic/sparql-sd.rdf`
               aggregate-source-rdf.sh automatic/sparql-sd.rdf
               url=`cr-ln-to-www-root.sh --url-of-filepath $varwww`
               if [[ `valid-rdf.sh $url` == 'yes' && `which vload` ]]; then
                  pvdelete.sh                       'http://localhost:8890/sparql'    # localhost is intentional here; it's where Virtuoso pulls its SPARQL SD from.
                  vload rdf automatic/sparql-sd.rdf 'http://localhost:8890/sparql' -v # localhost is intentional here; it's where Virtuoso pulls its SPARQL SD from.
                  # TODO: do we bother with pvload, or just do it?
                  #pvload.sh $url -ng http://localhost:8890/sparql # localhost is intentional here; it's where Virtuoso pulls its SPARQL SD from.
               fi
            else
               echo "`basename $this` WARNING: SPARQL Service Description from "$CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT" was not valid."
            fi
         fi
      popd &> /dev/null
   else
      echo "`basename $this` WARNING: did not create SPARQL Service Description b/c CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT was not http*."
   fi

popd &> /dev/null
dryrun.sh $dryrun ending
