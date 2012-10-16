#!/bin/bash

sudo=""
echo -n "Install as sudo? (if 'N', then will install as `whoami`) (y/N) "
read -u 1 install_it
if [ "$install_it" == "y" ]; then
   sudo="sudo "
fi

function offer_install_with_apt {
   command="$1"
   package="$2"
   if [ `which apt-get` ]; then
      if [[ ${#command} -gt 0 && ${#package} -gt 0 ]]; then
         if [ ! `which $command` ]; then
            echo
            echo $sudo apt-get install $package
            echo -n "Could not find $command on path. Try to install with command shown above? (y/n): "
            read -u 1 install_it
            if [ "$install_it" == "y" ]; then
               echo $sudo apt-get install $package
               $sudo apt-get install $package
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
      #if [ `which gcc` ]; then
      pushd $base &> /dev/null
         # http://drobilla.net/software/serd/
         bz2='http://download.drobilla.net/serd-0.18.0.tar.bz2'
         echo curl -O $bz2
         $sudo curl -O $bz2
         bz2=`basename $bz2`
         if [ ! -e ${bz2%.tar.bz2} ]; then
            echo tar -xjf $bz2
            $sudo tar -xjf $bz2
            $sudo rm $bz2
            pushd ${bz2%.tar.bz2} &> /dev/null
               $sudo ./waf configure
               $sudo ./waf
               $sudo ./waf install
            popd &> /dev/null
         fi
         $sudo rm `basename $bz2`
      popd &> /dev/null
      #else
      #   echo "ERROR: gcc not on PATH, cannot compile serdi"
      #fi
   fi
else
   echo "[INFO] serdi available at `which serdi`"
fi

if [ ! `which tdbloader` ]; then
   echo
   echo -n "Try to install jena at $base? (y/N) "
   read -u 1 install_it
   if [ "$install_it" == "y" ]; then
      # https://repository.apache.org/content/repositories/releases/org/apache/jena/jena-core/
      tarball='http://www.apache.org/dist/jena/binaries/apache-jena-2.7.3.tar.gz'
      pushd $base &> /dev/null
         echo curl -O --progress-bar $tarball
         $sudo curl -O --progress-bar $tarball
         tarball=`basename $tarball`
         echo tar xzf $tarball
         $sudo tar xzf $tarball
         $sudo rm $tarball
         jenaroot=$base/${tarball%.tar.gz}
      popd &> /dev/null
      if [ -e my-csv2rdf4lod-source-me.sh ]; then
         echo -n "Append JENAROOT to my-csv2rdf4lod-source-me.sh? (y/N) "
         read -u 1 install_it
         if [ "$install_it" == "y" ]; then
            echo "export JENAROOT=$jenaroot"              >> my-csv2rdf4lod-source-me.sh
            echo "export PATH=\"\${PATH}:$jenaroot/bin\"" >> my-csv2rdf4lod-source-me.sh
            echo "done:"
            tail -2 my-csv2rdf4lod-source-me.sh
         fi
      else
         echo "WARNING: set JENAROOT=$jenaroot in your my-csv2rdf4lod-source-me.sh or .bashrc"
         echo "WARNING: set PATH=\"\${PATH}:$jenaroot/bin\" in your my-csv2rdf4lod-source-me.sh or .bashrc"
      fi
   fi
else
   echo "[INFO] tdbloader available at `which tdbloader`"
fi


echo
echo -n "Try to install virtuoso at /opt? (note: sudo required) (y/N) " # $base to be relative
read -u 1 install_it
if [ "$install_it" == "y" ]; then
   # http://sourceforge.net/projects/virtuoso/
   url='http://sourceforge.net/projects/virtuoso/files/latest/download'
   pushd /opt &> /dev/null # $base
      # Not really working:
         #redirect=`curl -sLI $url | grep "^Location:" | tail -1 | sed 's/[^z]*$/\n/g' | awk '{printf("%s\n",$2)}'`
         # ^ e.g. http://superb-dca3.dl.sourceforge.net/project/virtuoso/virtuoso/6.1.6/virtuoso-opensource-6.1.6.tar.gz
         #tarball=`basename $redirect`
         # ^ e.g. virtuoso-opensource-6.1.6.tar.gz
         #echo "${redirect}.----------"
         #echo to
         #echo "${tarball}.----------"
      redirect=$url
      tarball='virtuoso.tar.gz'
      if [ ! -e $tarball ]; then
         sudo touch pid.$$
         echo curl -L -o $tarball --progress-bar $url
         sudo curl -L -o $tarball --progress-bar $url
         echo tar xzf $tarball
         sudo tar xzf $tarball
         #$sudo rm $tarball
         #virtuoso_root=$base/${tarball%.tar.gz} # $base
         virtuoso_root=`find . -maxdepth 1 -cnewer pid.$$ -name "virtuoso*" -type d`
         # ^ e.g. 'virtuoso-opensource-6.1.6/'
         if [ -d $virtuoso_root ]; then
            pushd $virtuoso_root &> /dev/null
               echo aptitude build-dep virtuoso-opensource
               sudo aptitude build-dep virtuoso-opensource
               echo dpkg-buildpackage -rfakeroot
               sudo dpkg-buildpackage -rfakeroot
            popd &> /dev/null
            pkg=`echo $virtuoso_root | sed 's/e-/e_/'`
            echo dpkg -i ${pkg}_amd64.deb # e.g. virtuoso-opensource_6.1.6_amd64.deb
            sudo dpkg -i ${pkg}_amd64.deb
         fi
         echo
      fi
   popd &> /dev/null
fi


echo
echo -n "Try to perl modules (e.g. YAML)? (y/N) "
read -u 1 install_it
if [ "$install_it" == "y" ]; then
   echo perl -MCPAN install YAML
   #$sudo perl -MCPAN -e shell
   echo YAML
   $sudo perl -MCPAN -e install YAML
   echo URI::Escape
   $sudo perl -MCPAN -e install URI::Escape
   echo Data:Dumper
   $sudo perl -MCPAN -e install Data::Dumper
   echo HTTP:Config
   $sudo perl -MCPAN -e install HTTP:Config
   echo LWP:UserAgent
   $sudo perl -MCPAN -e install LWP::UserAgent
   # ^^ OR sudo apt-cache search perl LWP::UserAgent
   #      $sudo apt-get install liblwp-useragent-determined-perl
   # ^^ OR cpan -f -i LWP::UserAgent
   echo IO::Socket::SSL
   $sudo perl -MCPAN -e install IO::Socket::SSL
   echo Text::CSV
   $sudo perl -MCPAN -e install Text::CSV
   echo Text::CSV_XS
   $sudo perl -MCPAN -e install Text::CSV_XS 
fi

# https://github.com/alangrafu/lodspeakr/wiki/How-to-install-requisites-in-Ubuntu
echo "Dependency for LODSPeaKr:"
offer_install_with_apt 'a2enmod' 'apache2'

echo
echo "sudo a2enmod rewrite"
echo -n "LODSPeaKr requires HTTP rewrite. Enable it with the command above? (y/N) "
read -u 1 install_it
if [ "$install_it" == "y" ]; then
   sudo a2enmod rewrite
fi

echo
echo 'https://github.com/alangrafu/lodspeakr/wiki/How-to-install-requisites-in-Ubuntu:'
echo "  /etc/apache2/sites-enabled/000-default must 'AllowOverride All' for <Directory /var/www/>"
echo
echo "sudo service apache2 restart"
echo "Please make the edit, THEN type 'y' to restart apache, or just type 'N' to skip this. (y/N) "
read -u 1 install_it
if [ "$install_it" == "y" ]; then
   echo "~~~~ ~~~~"
   echo "Dependency for LODSPeaKr:"
   sudo service apache2 restart
fi

# curl already done

for pkg in php5 php5-sqlite php5-curl sqlite3; do
   not_installed=`dpkg -s $pkg 2>&1 | grep "is not installed"`
   if [ ${#not_installed} ]; then
      echo "~~~~ ~~~~"
      echo "$pkg (Dependency for LODSPeaKr) is not shown in dpkg; install it? (y/N) "
      read -u 1 install_it
      if [ "$install_it" == "y" ]; then
         echo sudo apt-get install $package
         sudo apt-get install $package
      fi
   fi
done
