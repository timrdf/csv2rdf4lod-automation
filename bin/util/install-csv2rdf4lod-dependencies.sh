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
            echo "[INFO] $command available at `which $command`"
         fi
      fi
   else
      echo "[WARNING] Sorry, we need apt-get to install $command / $package for you."
   fi
   which $command >& /dev/null
   return $?
}

offer_install_with_apt 'curl'         'curl'
offer_install_with_apt 'rapper'       'raptor-utils'
offer_install_with_apt 'unzip'        'unzip'

this=$(cd ${0%/*} && echo $PWD/${0##*/})
base=${this%/bin/util/install-csv2rdf4lod-dependencies.sh}
base=${base%/*}
echo $base

if [ ! `which serdi` ]; then
   echo
   echo -n "Try to install serdi? (y/N) "
   read -u 1 install_it
   if [ "$install_it" == "y" ]; then
      bz2='http://download.drobilla.net/serd-0.18.0.tar.bz2'
      pushd $base &> /dev/null
         curl -O $bz2
         bz2=`basename $bz2`
         tar -xjf $bz2
         rm $bz2
         pushd ${bz2%.tar.bz2} &> /dev/null
            ./waf configure
            ./waf
            sudo ./waf install
         popd &> /dev/null
      popd &> /dev/null
   fi
fi
