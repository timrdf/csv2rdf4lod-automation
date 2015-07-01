#!/bin/bash
#
#3> <> prov:wasGeneratedBy [ prov:qualifiedAssociation [ prov:hadPlan <https://raw.github.com/timrdf/csv2rdf4lod-automation/master/bin/aggregate-source-rdf.sh> ] ] .
#3> <https://raw.github.com/timrdf/csv2rdf4lod-automation/master/bin/aggregate-source-rdf.sh> a prov:Plan; foaf:homepage <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/aggregate-source-rdf.sh> .
#
#
# Usage:
#
#  cr-ln-to-www-root.sh manual/ScenarioPaperopencodingcleancopy.txt.xml.ttl.graffle
#    Returns the local absolute file path within the htdocs directory, e.g.
#       /var/www/source/datahub.io/file/vis-seven-scenarios-codings/version/2013-Mar-08/manual/ScenarioPaperopencodingcleancopy.txt.xml.ttl.graffle
#
#  cr-ln-to-www-root.sh --url-of-filepath `cr-ln-to-www-root.sh manual/ScenarioPaperopencodingcleancopy.txt.xml.ttl.graffle`
#    Returns the web-accessible URL of the given absolute htdocs file path (which was returned when publishing as in the last example).
#
#     cr-ln-to-www-root.sh -n --url-of-filepath source/lodspeakr-basic-menu.svg
#     == cr-ln-to-www-root.sh --url-of-filepath `cr-ln-to-www-root.sh -n source/lodspeakr-basic-menu.svg`

see="https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $see"}

export PATH=$PATH`$CSV2RDF4LOD_HOME/bin/util/cr-situate-paths.sh`
export CLASSPATH=$CLASSPATH`$CSV2RDF4LOD_HOME/bin/util/cr-situate-classpaths.sh`

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:conversion-cockpit"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

if [[ "$1" == "--help" || $# -lt 1 ]]; then
   echo
   echo "usage: `basename $0` [-n] [--url-of-filepath] <file>+"
   echo
   echo "                  -n : dry run; do not link/copy file to htdocs directory; report the htdocs directory."
   echo "   --url-of-filepath : print the http URL of where <file> will be published."
   exit
fi

CSV2RDF4LOD_PUBLISH_VARWWW_ROOT=${CSV2RDF4LOD_PUBLISH_VARWWW_ROOT:?"not set; source csv2rdf4lod/source-me.sh "}

dryrun='no'
if [ "$1" == "-n" ]; then
   dryrun='yes'
   shift
fi

uri_of_path='no'
if [ "$1" == "--url-of-filepath" ]; then
   uri_of_path='yes'
   shift
fi

if [[ "$dryrun" == "yes" && "$uri_of_path" == "yes" ]]; then
   for local_path in `$0 -n $*`; do
      $0 --url-of-filepath $local_path
   done
   exit
fi

symbolic=""
pwd=""
if [[ "$1" == "-s" || "$CSV2RDF4LOD_PUBLISH_VARWWW_LINK_TYPE" == "soft" ]]; then
  symbolic="-sf "
  pwd=`pwd`/
  shift
fi

sudo="sudo"
if [[ `whoami` == root ]]; then
   sudo=""
elif [[ "`stat --format=%U "$CSV2RDF4LOD_PUBLISH_VARWWW_ROOT/source"`" == `whoami` ]]; then
   sudo=""
fi

function lnwww {
   publish=""
   if [ "$2" == 'publish' ]; then
      publish="conversion"
   fi
   sourceID=`cr-source-id.sh`
   datasetID=`cr-dataset-id.sh`
   versionID=`cr-version-id.sh`

   wwwfile="$CSV2RDF4LOD_PUBLISH_VARWWW_ROOT/source/$sourceID/file/$datasetID/version/$versionID/$publish${1#publish}"
   if [ -e "$1" -o "$2" == 'publish' ]; then

      echo " $wwwfile"
      if [[ "$dryrun" != "yes" ]]; then
         if [ -e "$wwwfile" ]; then
            echo "   $sudo rm -f  $wwwfile" >&2
                     $sudo rm -f "$wwwfile"
         else
            echo "   $sudo mkdir -p `dirname "$wwwfile"`" >&2
                     $sudo mkdir -p `dirname "$wwwfile"`
         fi
         echo "   "$sudo ln $symbolic "${pwd}$1" "$wwwfile" >&2
                   $sudo ln $symbolic "${pwd}$1" "$wwwfile"
      fi
   else
      echo "  -- $1 omitted --" >&2
      let "errorTally=errorTally+1"
   fi
}

errorTally=0
while [ $# -gt 0 ]; do
   file="$1"
   shift

   # /var/www/source/datahub.io/file/vis-seven-scenarios-codings/version/2013-Mar-08/manual/ScenarioPaperopencodingcleancopy.txt.xml.ttl.graffle
   if [ "$uri_of_path" == "yes" ]; then
      echo ${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}${file#$CSV2RDF4LOD_PUBLISH_VARWWW_ROOT}
      continue
   fi

   # publish/sitemap.xml
   if [ -e "$file" ]; then
      # automatic/www.cv-foundation.org/openaccess/content_cvpr_2014/papers/Redi_6_Seconds_of_2014_CVPR_paper.txt.prov.ttl

      directory=`dirname $file`
      directory=${file%%/*}
      if [[ "$directory" == 'source'    || "$directory" == "manual" || \
            "$directory" == 'automatic' || "$directory" == "publish" ]]; then
         lnwww $file $directory
      else  
         echo "`basename $0` ignoring b/c not in {source,manual,automatic,publish} convention: $file" >&2
         let "errorTally=errorTally+1"
      fi
   else
      "WARNING: $file does not exist"
      let "errorTally=errorTally+1"
   fi
done
