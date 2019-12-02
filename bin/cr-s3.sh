#!/bin/bash
#
#3> <> prov:wasGeneratedBy [ prov:qualifiedAssociation [ prov:hadPlan <https://raw.github.com/timrdf/csv2rdf4lod-automation/master/bin/cr-ln-to-www-root.sh> ] ] .
#3> <https://raw.github.com/timrdf/csv2rdf4lod-automation/master/bin/aggregate-source-rdf.sh> a prov:Plan; foaf:homepage <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-ln-to-www-root.sh> .
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
CSV2RDF4LOD_PUBLISH_AWS_S3_BUCKET=${CSV2RDF4LOD_PUBLISH_AWS_S3_BUCKET:?"not set; source csv2rdf4lod/source-me.sh "}

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

profile="admin" # TODO: take as an argument.

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

timepath="`dateInXSDDateTime.sh --uri-path | sed 's/....-....$//'`" # e.g. 2019/10/13/T/19/44
#                                                                                          ^^
# NOTE: assumes single-threaded; will put multiple records in same file for uploads that occur within the same clock minute.

# /\ options
# \/ chosen:
logpath="$timepath"
local_salt=''
local_salt="_`uuidgen`"

upload_provenance="publish/log/s3/$logpath/s3-log${local_salt}.ttl"
mkdir -p `dirname "$upload_provenance"`
if [ ! -e "$upload_provenance" ]; then
   cr-default-prefixes.sh --turtle >> "$upload_provenance"
fi

errorTally=0
while [ $# -gt 0 ]; do
   file="$1"
   shift

   # cr-ln-to-www-root.sh -n --url-of-filepath source/1996/1013.jpg
   url=`${CSV2RDF4LOD_HOME}/bin/cr-ln-to-www-root.sh -n --url-of-filepath "$file" 2>/dev/null`
   # ^^ handles logic to map local file path to public URL within our domain name.
   echo "$file -> $url"
   # ^^ e.g.            https://us.com/source/abc.123.com/file/labels/version/2015-04-13/source/1996/1013.jpg

   #                                                                 s3://my-bucket
   s3=${url/${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}/$CSV2RDF4LOD_PUBLISH_AWS_S3_BUCKET}
   # ^^ transforms the public-facing URL from within our domain to within our S3 bucket.
   echo "`echo "$file" | sed 's/./ /g'` -> $s3"
   # ^^ e.g. s3://my-bucket/source/abc.124.org/file/labels/version/2015-04-13/source/1996/1013.jpg

   aws s3 ls "$s3"
   if [[ $? -ne 0 ]]; then # https://unix.stackexchange.com/a/370925
      # File is not in S3.
      echo "$manifestation -> $s3" 

      startTime=`dateInXSDDateTime.sh --turtle`
      echo aws --profile $profile s3 cp "$file" "$s3"
           aws --profile $profile s3 cp "$file" "$s3"
      endTime=`dateInXSDDateTime.sh --turtle`

      #
      # Log provenance
      #
      host_md5=`md5.sh -qs $CSV2RDF4LOD_PUBLISH_AWS_S3_BUCKET`
      host="${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}/id/host/${host_md5}"

      md5=`${CSV2RDF4LOD_HOME}/bin/util/md5.sh "$file"`
      manifestation="${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}/id/md5/$md5"

      s3_path=${url/${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}}
      s3_path_md5=`md5.sh -qs "${s3_path}"`
      fileItem="$manifestation/host/${host_md5}/path/${s3_path_md5}"

      pathOnHost="${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}/id/host/${host_md5}/path/${s3_path_md5}"

      dirPath=`dirname ${s3_path}`
      dirPathOnHost="${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}/id/host/${host_md5}/path/`md5.sh -qs $dirPath`"

      activity="${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}/id/copy/$timepath/from/$md5/`md5.sh -qs $s3`"

      echo "<$fileItem>"                                               >> "$upload_provenance"
      echo "   a frbr:Item, nfo:FileDataObject; # ${s3_path}"          >> "$upload_provenance"
      echo "   frbr:exemplarOf <$manifestation>;"                      >> "$upload_provenance"
      echo "   prov:atLocation <$pathOnHost> ."                        >> "$upload_provenance"
      echo                                                             >> "$upload_provenance"
      echo "<$pathOnHost>"                                             >> "$upload_provenance"
      echo "   a nfo:FileDataObject;"                                  >> "$upload_provenance"
      echo "   nfo:fileUrl <$s3>;"                                     >> "$upload_provenance"
      echo "   prov:atLocation <$dirPathOnHost> ."                     >> "$upload_provenance"
      echo                                                             >> "$upload_provenance"
      echo "<$manifestation>"                                          >> "$upload_provenance"
      echo "   a frbr:Manifestation, nfo:FileHash;"                    >> "$upload_provenance"
      echo "   nfo:hashAlgorithm <http://dbpedia.org/resource/MD5>;"   >> "$upload_provenance"
      echo "   nfo:hashValue     \"$md5\" ."                           >> "$upload_provenance"
      echo                                                             >> "$upload_provenance"
      echo "<$dirPathOnHost>"                                          >> "$upload_provenance"
      echo "   a nfo:Folder;"                                          >> "$upload_provenance"
      echo "   dcterms:identifier \"$dirPath\";"                       >> "$upload_provenance"
      echo "   prov:atLocation <$host> ."                              >> "$upload_provenance"
      echo                                                             >> "$upload_provenance"
      echo "<$CSV2RDF4LOD_PUBLISH_AWS_S3_BUCKET>"                      >> "$upload_provenance"
      echo "   gn:parentFeature <$host> ."                             >> "$upload_provenance"
      echo                                                             >> "$upload_provenance"
      echo "<$activity>"                                               >> "$upload_provenance"
      echo "   prov:startedAtTime $startTime;"                         >> "$upload_provenance"
      echo "   prov:used          <$fileItem>;"                        >> "$upload_provenance"
      echo "   prov:endedAtTime   $endTime;"                           >> "$upload_provenance"
      echo "   prov:generated     <$pathOnHost>;"                      >> "$upload_provenance"
      echo "."                                                         >> "$upload_provenance"
   else
      echo "File does exists"
      aws s3 ls "$s3"
      # aws s3 ls s3://our-first-bucket-first-otc/source/abc.virginia.gov/product-label-approval/version/2019-05-10/source/1996/1013.jpg
      # 2019-10-12 15:11:29     151727 1013.jpg
   fi

#   # /var/www/source/datahub.io/file/vis-seven-scenarios-codings/version/2013-Mar-08/manual/ScenarioPaperopencodingcleancopy.txt.xml.ttl.graffle
#   if [ "$uri_of_path" == "yes" ]; then
#      echo ${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}${file#$CSV2RDF4LOD_PUBLISH_VARWWW_ROOT}
#      continue
#   fi
#
#   # publish/sitemap.xml
#   if [ -e "$file" ]; then
#      # automatic/www.cv-foundation.org/openaccess/content_cvpr_2014/papers/Redi_6_Seconds_of_2014_CVPR_paper.txt.prov.ttl
#
#      directory=`dirname $file`
#      directory=${file%%/*}
#      if [[ "$directory" == 'source'    || "$directory" == "manual" || \
#            "$directory" == 'automatic' || "$directory" == "publish" ]]; then
#         lnwww $file $directory
#      else  
#         echo "`basename $0` ignoring b/c not in {source,manual,automatic,publish} convention: $file" >&2
#         let "errorTally=errorTally+1"
#      fi
#   else
#      "WARNING: $file does not exist"
#      let "errorTally=errorTally+1"
#   fi
done
