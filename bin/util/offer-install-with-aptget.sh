#!/bin/bash

function offer_install_with_apt {
   # See also https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/install-csv2rdf4lod-dependencies.sh
   # See also https://github.com/timrdf/DataFAQs/blob/master/bin/install-datafaqs-dependencies.sh

   command="$1"
   package="$2"
   if [ `which apt-get` ]; then
      if [[ -n "$command" && -n "$package" ]]; then
         if [ ! `which $command` ]; then
            if [ "$dryrun" != "true" ]; then
               echo
            fi
            echo $TODO $sudo apt-get install $package
            if [ "$dryrun" != "true" ]; then
               read -p "Could not find $command on path. Try to install with command shown above? (y/n): " -u 1 install_it
               if [[ "$install_it" == [yY] ]]; then
                  echo $sudo apt-get install $package
                       $sudo apt-get install $package
               fi
            fi
         else
            echo "[okay] $command already available at `which $command`"
         fi
      fi
   else
      echo "[WARNING] Sorry, we need apt-get to install $command / $package for you."
   fi
   which $command >& /dev/null
   return $?
}
