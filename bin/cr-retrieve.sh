#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-retrieve.sh> ;
#3>    prov:wasRevisionOf    <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-publish-cockpit.sh> .

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
   echo "usage: `basename $0` [-w]"
   echo "  Create publish/bin/publish.sh and invoke for every conversion cockpit within the current directory tree."
   echo "  -w : Avoid dryrun; do it. If not provided, will only dry run."
fi

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:source cr:dataset cr:directory-of-versions"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

write="no"
if [[ "$1" == "-w" || "$1" == "--write" ]]; then
   write="yes"
fi

TEMP="_"`basename $0``date +%s`_$$.tmp

if   [[ `is-pwd-a.sh cr:conversion-cockpit` == "yes" ]]; then

   echo "Possible, but not designed and not implemented."

elif [[ `is-pwd-a.sh                                                            cr:directory-of-versions` == "yes" ]]; then

   dcat='' # RDF file containing distribution information - which file to download for this dataset?
   if [ -e dcat.ttl ]; then
      dcat='dcat.ttl'
   elif [ -e ../dcat.ttl ]; then
      dcat='../dcat.ttl'
   fi
   if [ -e "$dcat" ]; then
      url=`grep "dcat:downloadURL" $dcat | head -1 | awk '{print $2}' | sed 's/<//; s/>.*$//'` # TODO: query it as RDF...
      cat $0.template > retrieve.sh
      perl -pi -e "s|DOWNLOAD_URL|$url|" retrieve.sh
      chmod +x retrieve.sh
      ./retrieve.sh
   fi

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

if [ -e $TEMP ]; then
   rm -f $TEMP
fi
