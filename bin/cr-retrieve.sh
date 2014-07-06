#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-retrieve.sh> ;
#3>    prov:wasRevisionOf    <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-publish-cockpit.sh> .

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
   echo "usage: `basename $0` [-w] [--skip-if-exists]"
   echo
   echo "  Create publish/bin/publish.sh and invoke for every conversion cockpit within the current directory tree."
   echo
   echo "                -w : Avoid dryrun; do it. If not provided, will only dry run."
   echo "  --skip-if-exists : If a version exists for the dataset, do not retrieve it."
   exit 1
fi

#see='https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set'
#CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $see"}
HOME=$(cd ${0%/*} && echo ${PWD%/*})
export CLASSPATH=$CLASSPATH`$HOME/bin/util/cr-situate-classpaths.sh`
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?$HOME}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:data-root cr:source cr:dataset cr:directory-of-versions cr:conversion-cockpit"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

function retrieve_from_metadata {
   dcat="$1"
   versionID="$2"
   if [[ -e "$dcat" ]]; then
      url=`grep "dcat:downloadURL" $dcat | head -1 | awk '{print $2}' | sed 's/<//; s/>.*$//'` # TODO: query it as RDF...
      # ^^ phasing out; moving to multiple URLs ^^
      # Newer: download them all, e.g. grep dcat:downloadURL access.ttl | awk '{print $2}' | sed 's/^.*<//;s/>.*$//'
      urls=''
      for download in `grep dcat:downloadURL $dcat | awk '{print $2}' | sed 's/^.*<//;s/>.*$//'`; do
         # alternative: rdf2nt.sh access.ttl | grep '<http://www.w3.org/ns/dcat#downloadURL>' | awk '{print $3}' | grep http | sed 's/<//;s/>//' | grep -v " "
         urls="$urls '$download'"
      done
      urls=${urls# \'}
      urls=${urls%\'}
      # e.g. lodcloud/data/source/harth-org/btc-2012/version/latest
      google_key=''
      if [[ "$url" =~ https://docs.google.com/spreadsheet* ]]; then
         #google_key=`echo $url | sed 's/^.*key=//;s/#.*$//'`
         # e.g. https://docs.google.com/spreadsheet/ccc?key=tejNArOGrsY_mV1VeZhYCYg#gid=0
         #      -> 'tejNArOGrsY_mV1VeZhYCYg'
         google_key=`echo "$url" | sed 's/^.*key=//;s/&.*$//;s/#.*$//'`
         # e.g. https://docs.google.com/spreadsheet/ccc?key=0An84UEjofnaydFRrUF9YWk03Y3NHNjJqUEg0NUhUZXc&usp=sharing#gid=0
         #      -> '0An84UEjofnaydFRrUF9YWk03Y3NHNjJqUEg0NUhUZXc'
         if [ "$dryrun" != "yes" ]; then
            cat $0.template_gs > retrieve.sh # NOTE: chmod +w /opt/csv2rdf4lod-automation/bin/cr-retrieve.sh.template
            perl -pi -e "s|SPREADSHEET_KEY|$google_key|" retrieve.sh
            if [[ ${#versionID} -gt 0 ]]; then
               perl -pi -e "s|auto|$versionID|" retrieve.sh
            fi
            chmod +x retrieve.sh
            ./retrieve.sh
         else
            echo "`cr-dataset-uri.sh --uri`:"
            echo "   Will retrieve google spreadsheet $google_key b/c not yet retrieved $url"
         fi
      elif [[ "$url" =~ .*.git ]]; then
         if [ "$dryrun" != "yes" ]; then
	    echo "#!/bin/bash"                      > retrieve.sh
	    echo "mkdir -p source && pushd source" >> retrieve.sh
	    echo "git clone $url"                  >> retrieve.sh
	    echo "popd"                            >> retrieve.sh
            chmod +x retrieve.sh
            ./retrieve.sh
         else
            echo "`cr-dataset-uri.sh --uri`:"
            echo "   Will retrieve google spreadsheet $google_key b/c not yet retrieved $url"
         fi
      else
         if [ "$dryrun" != "yes" ]; then
            #echo template from $0 pwd: `pwd`
            cat $0.template > retrieve.sh # NOTE: chmod +w /opt/csv2rdf4lod-automation/bin/cr-retrieve.sh.template
            perl -pi -e "s|DOWNLOAD_URL|$urls|" retrieve.sh
            if [[ ${#versionID} -gt 0 ]]; then
               perl -pi -e "s|cr:auto|$versionID|" retrieve.sh
            fi
            chmod +x retrieve.sh
            ./retrieve.sh
         else
            echo "`cr-dataset-uri.sh --uri`:"
            echo "   Will retrieve b/c not yet retrieved $urls"
         fi
      fi
   else
      echo "$dcat" does not exist
   fi
}

sdv=`cr-sdv.sh --slashes --fast`
wasInformed='a prov:Activity; prov:wasInformedBy <#cr-retrieve>;'

function log_start {
   echo "#3> <retrieval/$sdv> $wasInformed prov:startedAtTime `dateInXSDDateTime.sh --turtle` ."
}
function log_end {
   echo "#3> <retrieval/$sdv> prov:endedAtTime `dateInXSDDateTime.sh --turtle` ."
}

if   [[ `is-pwd-a.sh cr:conversion-cockpit` == "yes" ]]; then

   if [[ -e access.ttl && ! -e source ]]; then
      access=access.ttl #`basename $PWD`/access.ttl
      versionID=`basename $PWD`
      echo "INFO: `basename $0`: retrieving un-retrieved version-specific access metadata for `cr-pwd-type.sh` `cr-source-id.sh` `cr-dataset-id.sh` `cr-version-id.sh`: $access.2"
      log_start
      retrieve_from_metadata $access $versionID
      log_end
   elif [[ -e retrieve.sh && ! -e source ]]; then
      if [[ ! -x retrieve.sh ]]; then
         chmod +x retrieve.sh
      fi
      echo "INFO: `basename $0`: pulling un-retrieved retrieval trigger for `cr-pwd-type.sh` `cr-source-id.sh` `cr-dataset-id.sh` `cr-version-id.sh`: $access. 93"
      log_start
      ./retrieve.sh
      log_end
   fi

elif [[ `is-pwd-a.sh                                                            cr:directory-of-versions` == "yes" ]]; then

   # TODO: generalize this; https://github.com/timrdf/csv2rdf4lod-automation/issues/323
   if [ -e `cr-conversion-root.sh`/csv2rdf4lod-source-me.sh ]; then
      source `cr-conversion-root.sh`/csv2rdf4lod-source-me.sh
   else
      see='https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-environment-variables-(considerations-for-a-distributed-workflow)'
      echo "#3> <> rdfs:seeAlso <$see> ." > `cr-conversion-root.sh`/csv2rdf4lod-source-me.sh
   fi
   # Include project-specific https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-environment-variables
   for sourceme in `find \`cr-conversion-root.sh\` -maxdepth 1 -name "csv2rdf4lod-source-me-for-*"`; do
      source $sourceme
   done

   if [ -e `cr-conversion-root.sh`/csv2rdf4lod-source-me-as-`whoami`.sh ]; then
      source `cr-conversion-root.sh`/csv2rdf4lod-source-me-as-`whoami`.sh
   fi

   w=''
   dryrun="yes"
   if [[ "$1" == "-w" || "$1" == "--write" ]]; then
      w='-w'
      dryrun="no"
      shift
   fi

   skip_if_exists=""
   if [[ "$1" == "--skip-if-exists" ]]; then
      skip_if_exists="$1"
      shift
   fi


   # It seems as though the pattern should be to find most-specific cases and work backwards,
   # allowing all cases to trigger.


   # Version-specific access metadata, with no custom retrieval trigger.
   #
   # e.g. working directory: data/source/us/cr-sparql-sd/version
   #      find returns:                                        ./latest/access.ttl   # depth = 2
   for access in `find . -mindepth 2 -maxdepth 2 -name access.ttl`; do
      if [[ ! -e `dirname $access`/source && ! -e `dirname $access`/retrieve.sh ]]; then
         echo "INFO: `basename $0`: found un-retrieved version-specific access metadata for `cr-pwd-type.sh` `cr-source-id.sh` `cr-dataset-id.sh`: $access. 94"
         pushd `dirname $access` &> /dev/null
            $0 $w $skip_if_exists
         popd &> /dev/null
      fi
   done 

   latest_version=`cr-list-versions.sh`
   if [[ -e retrieve.sh && `cr-idempotent.sh retrieve.sh` == 'yes' ]]; then
      if [[ ! -x retrieve.sh ]]; then
         chmod +x retrieve.sh
      fi
      echo "INFO: `basename $0`: pulling custom retrieval trigger in `cr-pwd-type.sh` `cr-source-id.sh` `cr-dataset-id.sh`. 95"
      log_start
      ./retrieve.sh
      log_end
   elif [[ `find . -mindepth 2 -maxdepth 2 -name retrieve.sh | wc -l | awk '{print $1}'` -gt 0 ]]; then
      # A version-specific custom retrieval trigger.
      #
      # e.g. working directory: data/source/us/cr-sparql-sd/version
      #      find returns:                                        ./latest/retrieve.sh   # depth = 2
      for trigger in `find . -mindepth 2 -maxdepth 2 -name retrieve.sh`; do
         echo "INFO: `basename $0`: found custom retrieval trigger in `cr-pwd-type.sh` `cr-source-id.sh` `cr-dataset-id.sh` $trigger. 96"
         if [[ `cr-idempotent.sh $trigger` == 'yes' || ! -e `dirname $trigger`/source ]]; then
            pushd `dirname $trigger` &> /dev/null
               $0 $w $skip_if_exists
            popd &> /dev/null
         else
            echo "INFO: `basename $0`: (but it wasn't idempotent, or it has already been retrieved) `cr-pwd-type.sh` `cr-source-id.sh` `cr-dataset-id.sh` $trigger."
         fi
      done 
   elif [[ -n "$skip_if_exists" && ${#latest_version} -gt 0 ]]; then
      not='not retrieving b/c --skip-if-exists was specified'
      echo "INFO: `basename $0`: version for `cr-source-id.sh`/`cr-dataset-id.sh` already exists ($latest_version); $not."
   elif [[ -e access.ttl || -e dcat.ttl || -e ../access.ttl || -e ../dcat.ttl ]]; then
      # dcat.ttl was a bad choice of name. It should be named after its purpose, not the specific vocab.
      # that currently achieves it. Still triggering on dcat.ttl for backward compatibility.
      access='' # RDF file containing distribution information - which file to download for this dataset?
      if [ -e access.ttl ]; then
         access='access.ttl'
      elif [ -e dcat.ttl ]; then
         access='dcat.ttl'
      elif [ -e ../access.ttl ]; then
         access='../access.ttl'
      elif [ -e ../dcat.ttl ]; then
         access='../dcat.ttl'
      fi
      if [ -e "$access" ]; then
         echo "INFO: `basename $0`: retrieving un-retrieved version-specific access metadata for `cr-pwd-type.sh` `cr-source-id.sh` `cr-dataset-id.sh` `cr-version-id.sh`: $access. 97"
         log_start
         retrieve_from_metadata $access "" # versionID
         log_end
      fi
   elif [[ ${#latest_version} -eq 0 && ! -e dcat.ttl && ! -e ../dcat.ttl && -e "ls retrieve.*" ]]; then
      # There is no version yet, there is no dcat.ttl, but there is a retrieve.sh
      chmod +x retrieve.*
      echo "INFO: `basename $0`: pulling custom retrieval trigger in `cr-pwd-type.sh` `cr-source-id.sh` `cr-dataset-id.sh`. 98"
      log_start
      ./retrieve.*
      log_end
   elif [[ -e retrieve.sh ]]; then
      if [[ ! -x retrieve.sh ]]; then
         chmod +x retrieve.sh
      fi
      echo "INFO: `basename $0`: pulling custom retrieval trigger in `cr-pwd-type.sh` `cr-source-id.sh` `cr-dataset-id.sh`. 99"
      log_start
      ./retrieve.sh
      log_end
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
