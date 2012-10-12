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

if [ ! `which serdi` ]; then
   echo
   echo -n "Try to install serdi at $base? (y/N) "
   read -u 1 install_it
   if [ "$install_it" == "y" ]; then
      bz2='http://download.drobilla.net/serd-0.18.0.tar.bz2'
      pushd $base &> /dev/null
         echo curl -O $bz2
         sudo curl -O $bz2
         bz2=`basename $bz2`
         if [ ! -e ${bz2%.tar.bz2} ]; then
            echo tar -xjf $bz2
            sudo tar -xjf $bz2
            sudo rm $bz2
            pushd ${bz2%.tar.bz2} &> /dev/null
               sudo ./waf configure
               sudo ./waf
               sudo ./waf install
            popd &> /dev/null
         fi
      popd &> /dev/null
   fi
fi

if [ ! `which tdbloader` ]; then
   echo
   echo -n "Try to install jena at $base? (y/N) "
   read -u 1 install_it
   if [ "$install_it" == "y" ]; then
      tarball='http://www.apache.org/dist/jena/binaries/apache-jena-2.7.3.tar.gz'
      pushd $base &> /dev/null
         curl -O $tarball
         tarball=`basename $tarball`
         tar xzf $tarball
         rm $tarball
         jenaroot=$base/${tarball%.tar.gz}
      popd &> /dev/null
      if [ -e my-csv2rdf4lod-source-me.sh ]; then
         echo -n "Append JENAROOT to my-csv2rdf4lod-source-me.sh? (y/N) "
         read -u 1 install_it
         if [ "$install_it" == "y" ]; then
            echo JENAROOT=$jenaroot >> my-csv2rdf4lod-source-me.sh
            echo "done:"
            tail -1 my-csv2rdf4lod-source-me.sh
         fi
      fi
   fi
fi
