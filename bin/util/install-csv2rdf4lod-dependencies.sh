#!/bin/bash

function offer_install_with_apt {
   command="$1"
   package="$2"
   if [ `which apt-get` ]; then
      if [[ ${#command} -gt 0 && ${#package} -gt 0 ]]; then
         if [ ! `which $command` ]; then
            echo
            echo sudo apt-get install $package
            echo -n "Could not find $command on path. Try to install with command shown above? (y/n): "
            read -u 1 install_it
            if [ "$install_it" == "y" ]; then
               echo sudo apt-get install $package
               sudo apt-get install $package
            fi
         else
            echo "$command available at `which $command`"
         fi
      fi
   else
      echo "Sorry, we need apt-get to install $command / $package for you."
   fi
   which $command >& /dev/null
   return $?
}

offer_install_with_apt 'curl'         'curl'
offer_install_with_apt 'rapper'       'raptor-utils'
offer_install_with_apt 'unzip'        'unzip'

#echo
#echo -n "Try to install dependencies? (y/N) "
#read -u 1 install_it
#if [ "$install_it" == "y" ]; then
#fi
