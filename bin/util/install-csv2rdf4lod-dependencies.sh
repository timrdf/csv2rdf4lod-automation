#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/install-csv2rdf4lod-dependencies.sh> .

this=$(cd ${0%/*} && echo $PWD/${0##*/})
base=${this%/bin/util/install-csv2rdf4lod-dependencies.sh}
base=${base%/*}

if [[ "$base" == *prizms/repos ]]; then
   # In case we are installed as part of Prizms, 
   # install next to where Prizms is installed.
   base=${base%/prizms/repos}
fi

if [[ "$1" == "--help" ]]; then
   echo
   echo "usage: `basename $0` [--avoid-sudo] [-n]"
   echo
   echo "  Install the third-party utilities that csv2rdf4lod-automation uses."
   echo "  Will install everything relative to the path:"
   echo "     $base"
   echo "  See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Installing-csv2rdf4lod-automation---complete"
   echo
   echo "  --avoid-sudo : Avoid using sudo if at all possible. It's best to avoid root."
   echo
   echo "   -n          | Perform only a dry run. This can be used to get a sense of what will be done before we actually do it."
   echo "               : NOTE: not implemented yet."
   echo
   exit
fi

sudo=""
if [ "$1" == "--avoid-sudo" ]; then
   shift
else
   read -p "Install as sudo? (if 'N', then will install as `whoami`) [y/N] " -u 1 use_sudo
   if [[ "$use_sudo" == [yY] ]]; then
      sudo="sudo "
   fi
fi

dryrun="false"
TODO=''
if [ "$1" == "-n" ]; then
   dryrun="true"
   dryrun.sh $dryrun beginning
   TODO="[TODO]"
   shift
fi

function offer_install_with_apt {
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

offer_install_with_apt 'git'          'git-core'
offer_install_with_apt 'java'         'openjdk-6-jdk'
offer_install_with_apt 'awk'          'gawk'
offer_install_with_apt 'curl'         'curl'
offer_install_with_apt 'rapper'       'raptor-utils'
offer_install_with_apt 'unzip'        'unzip'

if [ ! `which serdi` ]; then
   if [ "$dryrun" != "true" ]; then
      echo
      read -p "Try to install serdi at $base? [y/N] " -u 1 install_it
   fi
   if [[ "$install_it" == [yY] || "$dryrun" == "true" ]]; then
      #if [ `which gcc` ]; then
      pushd $base &> /dev/null
         # http://drobilla.net/software/serd/
         bz2='http://download.drobilla.net/serd-0.18.2.tar.bz2'
         echo $TODO curl -O $bz2 from `pwd`
         if [ "$dryrun" != "true" ]; then
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
         fi
      popd &> /dev/null
      #else
      #   echo "ERROR: gcc not on PATH, cannot compile serdi"
      #fi
   fi
else
   echo "[okay] serdi available at `which serdi`"
fi


if [ ! `which tdbloader` ]; then
   if [ "$dryrun" != "true" ]; then
      echo
      read -p "Try to install jena at $base? (y/N) " -u 1 install_it
   fi
   if [[ "$install_it" == [yY] || "$dryrun" == "true" ]]; then
      # https://repository.apache.org/content/repositories/releases/org/apache/jena/jena-core/
      tarball='http://www.apache.org/dist/jena/binaries/apache-jena-2.7.3.tar.gz' # TODO: up to 2.7.4 now.
      pushd $base &> /dev/null
         echo $TODO curl -O --progress-bar $tarball from `pwd`
         if [ "$dryrun" != "true" ]; then
            $sudo curl -O --progress-bar $tarball
            tarball=`basename $tarball`
            echo tar xzf $tarball
            $sudo tar xzf $tarball
            $sudo rm $tarball
            jenaroot=$base/${tarball%.tar.gz}
         fi
      popd &> /dev/null
      if [[ -e my-csv2rdf4lod-source-me.sh ]]; then
         if [ "$dryrun" != "true" ]; then
            read -p "Append JENAROOT to my-csv2rdf4lod-source-me.sh? (y/N) " -u 1 install_it
            if [[ "$install_it" == [yY] ]]; then
               echo "export JENAROOT=$jenaroot"              >> my-csv2rdf4lod-source-me.sh
               echo "export PATH=\"\${PATH}:$jenaroot/bin\"" >> my-csv2rdf4lod-source-me.sh
               echo "done:"
               tail -2 my-csv2rdf4lod-source-me.sh
            fi
         else
            echo "$TODO set JENAROOT=$jenaroot in `pwd`/my-csv2rdf4lod-source-me.sh"
         fi
      else
         if [ "$dryrun" != "true" ]; then
            echo "WARNING: set JENAROOT=$jenaroot in your my-csv2rdf4lod-source-me.sh or .bashrc"
            echo "WARNING: set PATH=\"\${PATH}:$jenaroot/bin\" in your my-csv2rdf4lod-source-me.sh or .bashrc"
         else
            echo "$TODO installer would not be able to set JENAROOT= in `pwd`/my-csv2rdf4lod-source-me.sh"
         fi
      fi
   fi
else
   echo "[okay] tdbloader available at `which tdbloader`"
fi


# config and db in /var/lib/virtuoso
# programs in /usr/bin /usr/lib
# inti.d script in /etc/init.d

# http://blog.bodhizazen.net/linux/apt-get-how-to-fix-very-broken-packages/
# var/lib/dpkg/info:
# virtuoso-opensource.conffiles  virtuoso-opensource.md5sums    virtuoso-opensource.postrm     
# virtuoso-opensource.list       virtuoso-opensource.postinst   virtuoso-opensource.prerm 

# change localhost to map to that IP (shown in /etc/hosts)
# comment 127.0.0.1    localhost and add 'localhost' to the other IP

# /etc/apache2/sites-available/default ~=  /etc/apache2/sites-available/std.common

# a2enmod proxy
# service apache2 restart

# "No protocol handler was valid for the URL /sparql. If you are using a DSO version of mod_proxy" ==>
#   apt-get install libapache2-mod-proxy-html
#   a2enmod proxy-html

if [ "$dryrun" != "true" ]; then
   echo
   read -p "Try to install virtuoso at /opt? (note: sudo *required*) (y/N) " -u 1 install_it # $base to be relative
fi
if [[ "$install_it" == [yY] || "$dryrun" == "true" ]]; then
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
         if [ "$dryrun" != "true" ]; then
            sudo touch pid.$$
         fi
         echo $TODO curl -L -o $tarball --progress-bar $url from `pwd`
         if [ "$dryrun" != "true" ]; then
            sudo curl -L -o $tarball --progress-bar $url
            echo $TODO tar xzf $tarball
            sudo tar xzf $tarball
            #$sudo rm $tarball
            #virtuoso_root=$base/${tarball%.tar.gz} # $base
            virtuoso_root=`find . -maxdepth 1 -cnewer pid.$$ -name "virtuoso*" -type d`
            # ^ e.g. 'virtuoso-opensource-6.1.6/'
            if [ -d $virtuoso_root ]; then
               pushd $virtuoso_root &> /dev/null # apt-get remove virtuoso-opensource
                  echo
                  echo
                  echo $TODO aptitude build-dep virtuoso-opensource
                  sudo aptitude build-dep virtuoso-opensource
                  echo
                  echo
                  echo $TODO dpkg-buildpackage -rfakeroot
                  sudo dpkg-buildpackage -rfakeroot
               popd &> /dev/null
               pkg=`echo $virtuoso_root | sed 's/e-/e_/'`
               echo dpkg -i ${pkg}_amd64.deb # e.g. virtuoso-opensource_6.1.6_amd64.deb
               sudo dpkg -i ${pkg}_amd64.deb
            fi
            echo
         fi
      fi
   popd &> /dev/null
fi


if [ "$dryrun" != "true" ]; then
   echo
   read -p "Try to perl modules (e.g. YAML)? (y/N) " -u 1 install_it
fi
if [[ "$install_it" == [yY] || "$dryrun" == "true" ]]; then
   #echo $TODO perl -MCPAN install YAML
   #$sudo perl -MCPAN -e shell
   echo $TODO perl -MCPAN install YAML
   if [ "$dryrun" != "true" ]; then
      $sudo perl -MCPAN -e install YAML
   fi
   echo $TODO perl -MCPAN install URI::Escape
   if [ "$dryrun" != "true" ]; then
      $sudo perl -MCPAN -e install URI::Escape
   fi
   echo $TODO perl -MCPAN install Data:Dumper
   if [ "$dryrun" != "true" ]; then
      $sudo perl -MCPAN -e install Data::Dumper
   fi
   echo $TODO perl -MCPAN install HTTP:Config
   if [ "$dryrun" != "true" ]; then
      $sudo perl -MCPAN -e install HTTP:Config
   fi
   echo $TODO perl -MCPAN install LWP:UserAgent
   if [ "$dryrun" != "true" ]; then
      $sudo perl -MCPAN -e install LWP::UserAgent
   fi
   # ^^ OR sudo apt-cache search perl LWP::UserAgent
   #      $sudo apt-get install liblwp-useragent-determined-perl
   # ^^ OR cpan -f -i LWP::UserAgent
   echo $TODO perl -MCPAN install IO::Socket::SSL
   if [ "$dryrun" != "true" ]; then
      $sudo perl -MCPAN -e install IO::Socket::SSL
   fi
   echo $TODO perl -MCPAN install Text::CSV
   if [ "$dryrun" != "true" ]; then
      $sudo perl -MCPAN -e install Text::CSV
   fi
   echo $TODO perl -MCPAN install Text::CSV_XS
   if [ "$dryrun" != "true" ]; then
      $sudo perl -MCPAN -e install Text::CSV_XS 
   fi
fi


if [ "$dryrun" != "true" ]; then
   echo
   read -p "Try to python modules (e.g. python-dateutil)? (y/N) " -u 1 install_it
fi
if [[ "$install_it" == [yY] || "$dryrun" == "true" ]]; then
   $TODO $sudo easy_install -U surf surf.sesame2 surf.sparql_protocol surf.rdflib python-dateutil
   if [ "$dryrun" != "true" ]; then
      $sudo easy_install -U surf surf.sesame2 surf.sparql_protocol surf.rdflib python-dateutil
   fi
   # see https://github.com/timrdf/csv2rdf4lod-automation/wiki/Installing-csv2rdf4lod-automation---complete
fi

exit 1


# https://github.com/alangrafu/lodspeakr/wiki/How-to-install-requisites-in-Ubuntu
echo "Dependency for LODSPeaKr:"
offer_install_with_apt 'a2enmod' 'apache2'

# curl already done

for package in php5 php5-cli php5-sqlite php5-curl sqlite3; do
   not_installed=`dpkg -s $package 2>&1 | grep "is not installed"`
   if [ ${#not_installed} ]; then
      echo
      echo "~~~~ ~~~~"
      echo sudo apt-get install $package
      echo -n "$package (Dependency for LODSPeaKr) is not shown in dpkg; install it with command above? (y/N) "
      read -u 1 install_it
      if [ "$install_it" == "y" ]; then
         echo sudo apt-get install $package
         sudo apt-get install $package
      fi
   fi
done

echo
echo "~~~~ ~~~~"
echo "sudo a2enmod rewrite"
echo -n "LODSPeaKr requires HTTP rewrite. Enable it with the command above? (y/N) "
read -u 1 install_it
if [ "$install_it" == "y" ]; then
   sudo a2enmod rewrite
fi

echo
echo "~~~~ ~~~~"
echo 'https://github.com/alangrafu/lodspeakr/wiki/How-to-install-requisites-in-Ubuntu:'
echo "  /etc/apache2/sites-enabled/000-default must 'AllowOverride All' for <Directory /var/www/>"
echo
echo "sudo service apache2 restart"
echo -n "Please edit 000-default to AllowOverride All, THEN type 'y' to restart apache, or just type 'N' to skip this. (y/N) "
read -u 1 install_it
if [ "$install_it" == "y" ]; then
   echo "~~~~ ~~~~"
   echo "Dependency for LODSPeaKr:"
   sudo service apache2 restart
fi

# Just for general use:
echo
echo "~~~~ ~~~~"
offer_install_with_apt 'screen' 'screen'

dryrun.sh $dryrun ending
