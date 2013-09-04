#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/install-csv2rdf4lod-dependencies.sh> .

this=$(cd ${0%/*} && echo $PWD/${0##*/})
sibling=`dirname $this`
base=${this%/bin/util/install-csv2rdf4lod-dependencies.sh}
base=${base%/*}

if [[ "$base" == *prizms/repos ]]; then
   # In case we are installed as part of Prizms,
   # install next to where Prizms is installed.
   base=${base%/prizms/repos}
fi

div="-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"

if [[ "$1" == "--help" ]]; then
   echo
   echo "usage: `basename $0` [-n] [--avoid-sudo]"
   echo
   echo "  Install the third-party utilities that csv2rdf4lod-automation uses."
   echo "  Will install everything relative to the path:"
   echo "     $base"
   echo "  See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Installing-csv2rdf4lod-automation---complete"
   echo
   echo "   -n          | Perform only a dry run. This can be used to get a sense of what will be done before we actually do it."
   echo
   echo "  --avoid-sudo : Avoid using sudo if at all possible. It's best to avoid root."
   echo
   exit
fi

#echo $0 $* >&2

dryrun="false"
TODO=''
if [ "$1" == "-n" ]; then
   dryrun="true"
   $sibling/dryrun.sh $dryrun beginning
   TODO="[TODO]"
   shift
fi

sudo=""
if [ "$1" == "--avoid-sudo" ]; then
   avoiding_sudo="yes"
   shift
elif [ "$1" == "--use-sudo" ]; then
   i_can_sudo=`sudo -v &> /dev/null`
   sudo_status=$?
   if [[ $sudo_status -ne 0 ]]; then
      echo "WARNING: `basename $0` was asked to --use-sudo, but `whoami` does not have that privilege." >&2
   else
      sudo="sudo "
   fi
   shift
elif [ "$dryrun" != "true" ]; then
   read -p "Install as sudo? (if 'N', will install as `whoami`) [y/N] " -u 1 use_sudo
   if [[ "$use_sudo" == [yY] ]]; then
      sudo="sudo "
   fi
   echo
fi

# Do a pass to avoid sudo, then continue using sudo if we must.
#if [[ "$dryrun" == "true" ]]; then
#   $0 -n --avoid-sudo
#else
#   $0 --avoid-sudo
#fi
# Press on with installing as sudo after we've tried to install without it.

function offer_install_with_apt {
   # See also https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/install-csv2rdf4lod-dependencies.sh
   # See also https://github.com/timrdf/DataFAQs/blob/master/bin/install-datafaqs-dependencies.sh
   # See also Prizms bin/install.sh
   if [[ -n "$sudo" ]]; then
      command="$1"
      package="$2"
      if [ `which apt-get` ]; then
         if [[ -n "$command" && -n "$package" ]]; then
            if [ ! `which $command` ]; then
               if [ "$dryrun" != "true" ]; then
                  echo
               fi
               echo $TODO $sudo apt-get install $package
               if [[ "$dryrun" != "true" ]]; then
                  read -p "Q: Could not find $command on path. Try to install with command shown above? (y/n): " -u 1 install_it
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
   else
      echo "[WARNING] Skipping apt-get $1 $2 b/c no sudo."
   fi
}

if [[ "$dryrun" != "true" && -n "$sudo" ]]; then
   echo $sudo apt-get update
        $sudo apt-get update &> /dev/null
fi

offer_install_with_apt 'git'    'git-core'      # These are dryrun safe and are only done if $sudo.
#offer_install_with_apt 'java'   'openjdk-6-jre' # openjdk-6-jdk ?
offer_install_with_apt 'javac'  'openjdk-6-jdk' # openjdk-6-jdk ?
offer_install_with_apt 'awk'    'gawk'          #
offer_install_with_apt 'curl'   'curl'          #
offer_install_with_apt 'rapper' 'raptor-utils'  #
offer_install_with_apt 'unzip'  'unzip'         #
offer_install_with_apt 'screen' 'screen'        #
offer_install_with_apt 'tidy'   'tidy'          #

if [[ ! `which serdi` ]]; then
   if [ "$dryrun" != "true" ]; then
      echo
      read -p "Q: Try to install serdi at $base? [y/N] " -u 1 install_it
   fi
   if [[ "$install_it" == [yY] || "$dryrun" == "true" ]]; then
      #if [ `which gcc` ]; then
      pushd $base &> /dev/null
         # http://drobilla.net/software/serd/
         bz2='http://download.drobilla.net/serd-0.18.2.tar.bz2'
         echo $TODO curl -O $bz2 from `pwd`
         if [[ "$dryrun" != "true" ]]; then
            if [[ -n "$sudo" ]]; then
               $sudo curl -O $bz2
               bz2=`basename $bz2`
               if [[ ! -e ${bz2%.tar.bz2} ]]; then
                  echo $sudo tar -xjf $bz2
                  $sudo tar -xjf $bz2
                  $sudo rm $bz2
                  pushd ${bz2%.tar.bz2} &> /dev/null
                     $sudo ./waf configure     # These need sudo (
                     $sudo ./waf               # These need sudo
                     $sudo ./waf install       # These need sudo
                  popd &> /dev/null
               fi
               $sudo rm -f `basename $bz2`
            else
               echo "[WARNING] could not install serdi because `whoami` does not have sudo permissions."
            fi
         fi
      popd &> /dev/null
      #else
      #   echo "ERROR: gcc not on PATH, cannot compile serdi"
      #fi
   fi
else
   echo "[okay] serdi available at `which serdi`"
fi




if [[ ! `which tdbloader` ]]; then # || ! "`which tdbloader`" =~ /home/`whoami`/opt/*
   if [ "$dryrun" != "true" ]; then
      echo
      echo $div
      read -p "Q: Could not find tdbloader on path. Try to install jena at $base? (y/n): " -u 1 install_it
   fi
   if [[ "$install_it" == [yY] || "$dryrun" == "true" ]]; then
      jenaroot=`find $base -type d -name "apache-jena*"`
      if [[ -z "$jenaroot" || ! -e $jenaroot ]]; then
         # https://repository.apache.org/content/repositories/releases/org/apache/jena/jena-core/
         tarball='http://www.apache.org/dist/jena/binaries/apache-jena-2.7.3.tar.gz' # 404s
         zip='http://www.apache.org/dist/jena/binaries/apache-jena-2.7.4.zip' # 404s
         zip='http://archive.apache.org/dist/jena/binaries/apache-jena-2.10.0.zip'
         pushd $base &> /dev/null
            echo $TODO curl -O --progress-bar $zip from `pwd`
            if [ "$dryrun" != "true" ]; then
               # For 2.7.3's tarball, which does not work anymore.
               #$sudo curl -O --progress-bar $tarball
               #tarball=`basename $tarball`
               #echo tar xzf $tarball
               #$sudo tar xzf $tarball
               #$sudo rm $tarball
               #jenaroot=$base/${tarball%.tar.gz}

               # For 2.7.4's zip...
               curl -O --progress-bar $zip
               zip=`basename $zip`
               echo unzip $zip
                    unzip $zip
               jenaroot=$base/${zip%.zip}
            fi
         popd &> /dev/null
      else
         echo "  ($jenaroot is already present, so we didn't try to download it again.)"
      fi
      echo
      if [[ -e my-csv2rdf4lod-source-me.sh ]]; then
         # This file exists when installing csv2rdf4lod-automation with its install.sh
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
         # JENAROOT and PATH should be set in csv2rdf4lod-source-me-as-<username>.sh
         # It _could_ be done in ~/.bashrc, but then we're spreading our configuration in multiple places.
         if [ "$dryrun" != "true" ]; then
            echo "JENAROOT=$jenaroot # <-- needs to be set in your my-csv2rdf4lod-source-me.sh or ~/.bashrc"
            echo "PATH=\"\${PATH}:$jenaroot/bin\" # <-- needs to be set in your my-csv2rdf4lod-source-me.sh or ~/.bashrc"
         else
            echo "[NOTE] Need to set JENAROOT=$jenaroot and PATH=\"\${PATH}:$jenaroot/bin\" in my-csv2rdf4lod-source-me.sh"
         fi
      fi
   fi
else
   echo "[okay] tdbloader available at `which tdbloader`"
fi




cannot_locate=`echo 'yo' | perl -e 'use URI::Escape; @userinput = <STDIN>; foreach (@userinput) { print uri_escape($_); }' 2>&1 | grep "Can't locate"`
perl_packages="YAML URI::Escape Data::Dumper HTTP:Config LWP:UserAgent IO::Socket::SSL Text:CSV Text::CSV_XS"
if [[ "$cannot_locate" =~ *Can*t*locate* && -n "$sudo" ]]; then
   echo ${#cannot_locate} $cannot_locate
   if [[ "$dryrun" != "true" ]]; then
      echo
      echo $div
      read -p "Q: Try to install perl modules (e.g. YAML)? (Y/n) " -u 1 install_perl
   fi
   if [[ "$install_perl" == [yY] || "$dryrun" == "true" && -n "$cannot_locate" ]]; then
      #echo $TODO perl -MCPAN install YAML
      #$sudo perl -MCPAN -e shell
      echo $TODO perl -MCPAN install YAML
      if [ "$dryrun" != "true" ]; then
         $sudo perl -MCPAN -e install YAML
      fi
      echo $TODO perl -MCPAN install URI::Escape
      if [ "$dryrun" != "true" ]; then
         $sudo perl -MCPAN -e install URI::Escape
         # used in:
         #    bin/util/pvload.sh
         #    bin/util/cache-queries.sh
         #    bin/util/ptsw.sh
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
         # used in:
         #   bin/util/filename-v3.pl
         #   bin/util/filename2.pl
         #   bin/util/filename.pl
      fi
      # ^^ OR sudo apt-cache search perl LWP::UserAgent
      #      $sudo apt-get install liblwp-useragent-determined-perl
      # ^^ OR cpan -f -i LWP::UserAgent
      echo $TODO perl -MCPAN install IO::Socket::SSL
      if [ "$dryrun" != "true" ]; then
         $sudo perl -MCPAN -e install IO::Socket::SSL
         # used in:
         #   bin/util/pcurl.sh
      fi
      echo $TODO perl -MCPAN install Text::CSV
      if [ "$dryrun" != "true" ]; then
         $sudo perl -MCPAN -e install Text::CSV
         # used in:
         #   bin/util/parse_fixedwidth.pl
         #   bin/util/sparql-csv2plain.pl
      fi
      echo $TODO perl -MCPAN install Text::CSV_XS
      if [ "$dryrun" != "true" ]; then
         $sudo perl -MCPAN -e install Text::CSV_XS
      fi
   fi
else
   if [[ "$dryrun" != "true" ]]; then
      echo
      echo $div
   fi
   for package in $perl_packages; do
      echo "[okay] perl -MCPAN install $package"
   done
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

virtuoso_installed="no"
if [[ -e '/var/lib/virtuoso/db/virtuoso.ini' && \
      -e '/usr/bin/isql-v'                   && \
      -e '/etc/init.d/virtuoso-opensource'   && \
      -e '/var/lib/virtuoso/db/virtuoso.log' ]]; then
   # done via dpkg
   virtuoso_installed="yes"
   echo "[okay] virtuoso installed"
fi
if [[ -e '/etc/virtuoso-opensource-6.1/virtuoso.ini'        && \
      -e '/var/lib/virtuoso-opensource-6.1/db/virtuoso.log' && \
      -e '/etc/init.d/virtuoso-opensource-6.1'              && \
      -e '/usr/bin/isql-vt' ]]; then 
   # done via aptitude
   virtuoso_installed="yes"
   echo "[okay] virtuoso installed"
fi

if [[ "$dryrun" != "true" && "$virtuoso_installed" == "no" ]]; then
   echo
   echo $div
   read -p "Q: Try to install virtuoso at /opt? (note: sudo *required*) (y/N) " -u 1 install_it # $base to be relative
fi
if [[ "$virtuoso_installed" == "no" ]]; then
   if [[ "$install_it" == [yY] || "$dryrun" == "true" && -n "$sudo" ]]; then

      distributor=`lsb_release --short --id` # e.g. Ubuntu, or Debian
      codename=`lsb_release --short --codename` # e.g. lucid, precise, or squeeze

      echo "Virtuoso not installed; OS type $distributor $codename"
      if [[ "$distributor" == "Ubuntu" || "$distributor" == "Debian" ]]; then # lucid
         url='http://sourceforge.net/projects/virtuoso/files/latest/download' # http://sourceforge.net/projects/virtuoso/
         pushd /opt &> /dev/null # $base
            # Not really working:
               #redirect=`curl -sLI $url | grep "^Location:" | tail -1 | sed 's/[^z]*$/\n/g' | awk '{printf("%s\n",$2)}'`
               # ^ e.g. http://superb-dca3.dl.sourceforge.net/project/virtuoso/virtuoso/6.1.6/virtuoso-opensource-6.1.6.tar.gz
               #tarball=`basename $redirect`
               # ^ e.g. virtuoso-opensource-6.1.6.tar.gz
               #echo "${redirect}.----------" #echo to #echo "${tarball}.----------"
            redirect=$url
            tarball='virtuoso.tar.gz'
            virtuoso_root='' # Set from tarball extraction or recovered from pid.$$
            if [ ! -e $tarball ]; then
               if [[ "$dryrun" != "true" ]]; then
                  rm -f pid.*
                  sudo touch pid.$$ # So we know the directory that was created from the tarball
               fi                                              # |
               echo $TODO curl -L -o $tarball --progress-bar $url from `pwd`
               if [ "$dryrun" != "true" ]; then                # |
                  sudo curl -L -o $tarball --progress-bar $url # |
                  echo $TODO sudo tar xzf $tarball             # |
                             sudo tar xzf $tarball             # |
                  #$sudo rm $tarball                           #\|/
                  #virtuoso_root=$base/${tarball%.tar.gz} # $base
                  virtuoso_root=`find . -maxdepth 1 -cnewer pid.$$ -name "virtuoso*" -type d`
                  # ^ e.g. 'virtuoso-opensource-6.1.6/'
                  echo $virtuoso_root > sudo tee pid.$$
               fi
            else # Tarball exists.
               virtuoso_root=`cat pid.*`
               echo "$tarball exists; virtuso root should be: $virtuoso_root"
            fi
            if [ "$dryrun" != "true" ]; then
               if [ -d "$virtuoso_root" ]; then
                  pushd $virtuoso_root &> /dev/null # apt-get remove virtuoso-opensource
                     echo
                     echo
                     echo "$TODO sudo apt-get update"
                                 sudo apt-get update
                     echo
                     echo
                     echo "$TODO sudo apt-get install aptitude"
                                 sudo apt-get install aptitude
                     echo
                     echo
                     echo "$TODO sudo aptitude install dpkg-dev build-essential libreadline-gplv2-dev" 
                                 sudo aptitude install dpkg-dev build-essential
                     # Ubuntu 12 can't install libreadline5-dev, replaced by libreadline-gplv2-dev

                     echo
                     echo
                     echo "$TODO sudo aptitude build-dep virtuoso-opensource" # NOTE: if this is run on a TWC VM with
                                 sudo aptitude build-dep virtuoso-opensource # /etc/hosts localhost 127.0.0.1, it will fail.

#  sudo aptitude build-dep virtuoso-opensource
# The following NEW packages will be installed:
#   libreadline-dev{b} libreadline6-dev{ab} 
# 0 packages upgraded, 2 newly installed, 0 to remove and 17 not upgraded.
# Need to get 0 B/265 kB of archives. After unpacking 823 kB will be used.
# The following packages have unmet dependencies:
#  libreadline-gplv2-dev : Conflicts: libreadline-dev but 6.2-8 is to be installed.
#  libreadline6-dev : Conflicts: libreadline-gplv2-dev but 5.2-11 is installed.
#  libreadline-dev : Conflicts: libreadline-gplv2-dev but 5.2-11 is installed.
# The following actions will resolve these dependencies:
# 
#      Remove the following packages:
# 1)     libreadline-gplv2-dev 
# ...
# The following NEW packages will be installed:
#   libreadline-dev libreadline6-dev{a} 
# The following packages will be REMOVED:
#   libreadline-gplv2-dev{a} libreadline5{u} 

# FIDO: sudo aptitude install  virtuoso-opensource

                     echo
                     echo
                     echo "$TODO sudo dpkg-buildpackage -rfakeroot"
                                 sudo dpkg-buildpackage -rfakeroot
                  popd &> /dev/null
                  pkg=`echo $virtuoso_root | sed 's/e-/e_/'`
                  echo dpkg -i ${pkg}_amd64.deb # e.g. virtuoso-opensource_6.1.6_amd64.deb
                  sudo dpkg -i ${pkg}_amd64.deb
               fi
               echo
            fi
            # Administering Virtuoso is discussed at:
            #   https://github.com/timrdf/csv2rdf4lod-automation/wiki/Publishing-conversion-results-with-a-Virtuoso-triplestore
            #   https://github.com/jimmccusker/twc-healthdata/wiki/VM-Installation-Notes
            #
            # Debian package build results in:
            #
            #   /usr/bin/isql-v
            #   /var/lib/virtuoso/db/virtuoso.ini
            #   /usr/bin and /var and /usr/lib
            #   endpoint: http://aquarius.tw.rpi.edu/projects/healthdata/sparql
            #
            # Restart virtuoso with sudo /etc/init.d/virtuoso-opensource restart
            # Monitor virtuoso with sudo tail -f /var/lib/virtuoso/db/virtuoso.log
            #                                    ^^ this shows "... Server online at 1111 (pid ...)"
         popd &> /dev/null
      elif [[ "$distributor" == "Debian" ]]; then # squeeze
         # http://virtuoso.openlinksw.com/dataspace/doc/dav/wiki/Main/VOSDebianNotes
         echo $TODO sudo apt-get update
         if [[ "$dryrun" != "true" ]]; then
              sudo apt-get update
         fi
         echo $TODO sudo aptitude install virtuoso-opensource
         if [[ "$dryrun" != "true" ]]; then
              sudo aptitude install virtuoso-opensource
         fi
      fi
   fi # Told to install or dry running as sudo
else
   echo "[okay] virtuoso is already installed at /etc/init.d/virtuoso-opensource + /var/lib/virtuoso/db/virtuoso.ini + /usr/bin/isql-v + /var/lib/virtuoso/db/virtuoso.log"
fi




# python --version
#   Python 2.6.5
#
# Installs at /usr/local/lib/python2.6/dist-packages
#   /usr/local/lib/python2.6/dist-packages/SuRF-1.1.4_r352-py2.6.egg
#   /usr/local/lib/python2.6/dist-packages/surf.sesame2-0.2.1_r335-py2.6.egg
#   /usr/local/lib/python2.6/dist-packages/surf.sparql_protocol-1.0.0_r336-py2.6.egg
#   /usr/local/lib/python2.6/dist-packages/surf.rdflib-1.0.0_r338-py2.6.egg
#   /usr/local/lib/python2.6/dist-packages/python_dateutil-2.1-py2.6.egg
#   /usr/local/lib/python2.6/dist-packages/ckanclient-0.10-py2.6.egg # from "sudo easy_install -U ckanclient"

pdiv=$div
if [[ -z "$sudo" ]]; then
   # Set a user-based install that does NOT require sudo.
   # (As mentioned at https://github.com/timrdf/DataFAQs/wiki/Installing-DataFAQs
   #  and http://www.astropython.org/tutorial/2010/1/User-rootsudo-free-installation-of-Python-modules)
   if [[ ! -e ~/.pydistutils.cfg ]]; then
      echo $TODO ~/.pydistutils.cfg
      if [[ "$dryrun" != "true" ]]; then
         echo "[install]"                                     > ~/.pydistutils.cfg
         echo "install_scripts = $base/python/bin"           >> ~/.pydistutils.cfg
         echo "install_data = $base/python/share"            >> ~/.pydistutils.cfg
         echo "install_lib = $base/python/lib/site-packages" >> ~/.pydistutils.cfg
      fi
   else
      echo "[okay] ~/.pydistutils.cfg"
   fi
   # PYTHONPATH needs to be set to look into install_lib from ^^
   export PYTHONPATH=$base/python/lib/site-packages:$PYTHONPATH
   if [ "$dryrun" != "true" ]; then
      echo "WARNING: set PYTHONPATH=$base/python/lib/site-packages:\$PYTHONPATH in your my-csv2rdf4lod-source-me.sh or .bashrc"
   else
      echo "[NOTE] installer would not be able to set PYTHONPATH= in `pwd`/my-csv2rdf4lod-source-me.sh"
   fi
fi
offer_install_with_apt 'easy_install' 'python-setuptools' # dryrun aware
V=`python --version 2>&1 | sed 's/Python \(.\..\).*$/\1/'`
eggs="rdflib surf surf.sesame2 surf.sparql_protocol surf.rdflib python-dateutil ckanclient"
for egg in $eggs; do
   # See also https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/install-csv2rdf4lod-dependencies.sh
   # See also https://github.com/timrdf/DataFAQs/blob/master/bin/install-datafaqs-dependencies.sh
   eggReg=`echo $egg | sed 's/-/./g;s/_/./g'`
   find /usr/local/lib/python$V/dist-packages -mindepth 1 -maxdepth 1 | grep -i $eggReg &> /dev/null
   status=$?
   #there=`find /usr/local/lib/python$V/dist-packages -mindepth 1 -maxdepth 1 -type d | grep -i $eggReg`
   echo find /usr/local/lib/python$V/dist-packages -mindepth 1 -maxdepth 1 -type d -name "$eggReg*" >&2
   there=`find /usr/local/lib/python$V/dist-packages -mindepth 1 -maxdepth 1 -type d -name "$eggReg*"`
   status=$?
   if [[ -z "$there" || ! -e "$there" || ! "$there" =~ *.egg ]]; then # TODO: this path is $base/python/lib/site-packages if -z $sudo
      # TODO: not recognizing that 'ckanclient' is missing.
      if [[ "$dryrun" != "true" ]]; then
         echo $pdiv
      fi
      if [[ "$egg" == "rdflib" ]]; then
         eggV='==3.4.0'
      else
         eggV=''
      fi
      echo $TODO $sudo easy_install -U $egg$eggV
      if [[ "$dryrun" != "true" ]]; then
         echo
         read -p "Q: Try to install python module $egg using the command above? (y/n) " -u 1 install_it
         if [[ "$install_it" == [yY] ]]; then
            echo
                 $sudo easy_install -U $egg$eggV
                # SUDO IS NOT REQUIRED HERE.
            # see https://github.com/timrdf/csv2rdf4lod-automation/wiki/Installing-csv2rdf4lod-automation---complete
            pdiv=""
         fi
      fi
   else
      echo "[okay] python egg \"$egg\" is already available at $there ($eggReg $status)"
   fi
done

$sibling/dryrun.sh $dryrun ending
