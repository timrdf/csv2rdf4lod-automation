#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-retrieve.sh> ;
#3>    prov:wasRevisionOf    <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-publish-cockpit.sh> .

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
   echo
   echo "usage: `basename $0` [-w] [--skip-if-exists]"
   echo
   echo "  Create publish/bin/publish.sh and invoke for every conversion cockpit within the current directory tree."
   echo
   echo "                -w : Avoid dryrun; do it. If not provided, will only dry run."
   echo "  --skip-if-exists : If a version exists for the dataset, do not retrieve it."
   exit 1
fi

see='https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set'
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $see"}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:data-root cr:source cr:dataset cr:directory-of-versions"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

if   [[ `is-pwd-a.sh cr:conversion-cockpit` == "yes" ]]; then

   echo "Possible, but not designed and not implemented."

elif [[ `is-pwd-a.sh                                                            cr:directory-of-versions` == "yes" ]]; then

   dryrun="yes"
   if [[ "$1" == "-w" || "$1" == "--write" ]]; then
      dryrun="no"
      shift
   fi

   skip_if_exists="no"
   if [[ "$1" == "--skip-if-exists" ]]; then
      skip_if_exists="yes"
      shift
   fi

   latest_version=`cr-list-versions.sh`
   if [[ "$skip_if_exists" == "yes" && ${#latest_version} -gt 0 ]]; then
      not='not retrieving b/c --skip-if-exists was specified'
      echo "INFO: `basename $0`: version for `cr-source-id.sh`/`cr-dataset-id.sh` already exists ($latest_version); $not."
   elif [[ -e access.ttl || -e dcat.ttl || -e ../access.ttl || -e ../dcat.ttl ]]; then
      # dcat.ttl was a bad choice of name. It should be named after it's purpose, not the specific vocab.
      # that currently achieves it. Still triggering on dcat.ttl for backward compatibility.
      dcat='' # RDF file containing distribution information - which file to download for this dataset?
      if [ -e access.ttl ]; then
         dcat='access.ttl'
      elif [ -e dcat.ttl ]; then
         dcat='dcat.ttl'
      elif [ -e ../access.ttl ]; then
         dcat='../access.ttl'
      elif [ -e ../dcat.ttl ]; then
         dcat='../dcat.ttl'
      fi
      if [ -e "$dcat" ]; then
         url=`grep "dcat:downloadURL" $dcat | head -1 | awk '{print $2}' | sed 's/<//; s/>.*$//'` # TODO: query it as RDF...
         if [ "$dryrun" != "yes" ]; then
            #echo template from $0 pwd: `pwd`
            cat $0.template > retrieve.sh # NOTE: chmod +w /opt/csv2rdf4lod-automation/bin/cr-retrieve.sh.template
            perl -pi -e "s|DOWNLOAD_URL|$url|" retrieve.sh
            chmod +x retrieve.sh
            ./retrieve.sh
         else
            echo "`cr-dataset-uri.sh --uri`:"
            echo "   Will retrieve b/c not yet retrieved $url"
         fi
      fi
   elif [[ ${#latest_version} -eq 0 && ! -e dcat.ttl && ! -e ../dcat.ttl && -e "ls retrieve.*" ]]; then
      # There is no version yet, there is no dcat.ttl, but there is a retrieve.sh
      chmod +x retrieve.*
      ./retrieve.*
   else
      echo "[WARNING]: did not know how to handle `cr-pwd.sh`; no access metadata available."
   fi

elif [[ `is-pwd-a.sh                                                 cr:dataset                         ` == "yes" ]]; then
   if [ ! -e version ]; then
      mkdir version # See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Directory-Conventions
   fi
   pushd version > /dev/null
      $0 $* # Recursive call
   popd > /dev/null
elif [[ `is-pwd-a.sh                        cr:directory-of-datasets                                    ` == "yes" ]]; then
   for next in `directories.sh`; do
      pushd $next > /dev/null
         $0 $* # Recursive call
      popd > /dev/null
   done
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
      for dataset in `cr-list-datasets.sh`; do
         pushd $dataset > /dev/null
            $0 $* # Recursive call
         popd > /dev/null
      done
   fi
elif [[ `is-pwd-a.sh cr:data-root                                                                       ` == "yes" ]]; then
   for sourceID in `cr-list-sources.sh`; do
      pushd $sourceID > /dev/null
         $0 $* # Recursive call
      popd > /dev/null
   done
fi
