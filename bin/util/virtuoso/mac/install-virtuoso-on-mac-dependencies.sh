#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/tree/master/bin/util/virtuoso/mac/install-virtuoso-on-mac-dependencies.sh>
#3>    doap:implements <https://github.com/openlink/virtuoso-opensource/blob/develop/7/README>;
#3>
#3> .

missing=""

# Ordered according to https://github.com/openlink/virtuoso-opensource/blob/develop/7/README:
#for tool in autoconf automake libtoolize flex bison gperf gawk m4 make; do
# Reordered based on dependencies:
for tool in gawk libtoolize autoconf automake flex bison gperf m4 make; do
   if [[ `which $tool 2> /dev/null` ]]; then
      echo
      echo "- - - - - - - - - - - - $tool - - - - - - - - - - - - "
      $tool --version
   else
      missing="$missing $tool"
   fi 
done

echo "- - - - - - - - - - - - openssl - - - - - - - - - - - - "
openssl version

if [[ "$missing" == "" ]]; then
   echo
   echo "All dependencies are available"
   exit 0
fi

echo
echo
echo "Missing: $missing"

echo "Do you have sudo? (sudo -v)"
i_can_sudo=`sudo -v &> /dev/null`
i_can_sudo=$?
 
mkdir -p dependencies && pushd dependencies &> /dev/null
   buildPrefix=`pwd`/prefix
   for tool in $missing; do
      echo "missing $tool"

      url=''
      if [[ $tool == "autoconf" ]]; then
         # Reported by Virtuoso:
         # url='http://ftp.gnu.org/gnu/autoconf/autoconf-2.57.tar.gz'
         # ... but automake-1.9 requires 2.58 or better (according to its build cycle): 
         # url='http://ftp.gnu.org/gnu/autoconf/autoconf-2.58.tar.gz'
         # ... and Virtuoso's ./autogen.sh requires 2.5.9 or higher...
         url='http://ftp.gnu.org/gnu/autoconf/autoconf-2.59.tar.gz'

         # needs automake
         # needs libtoolize
         # needs gawk

      elif [[ $tool == "automake" ]]; then
         url='http://ftp.gnu.org/gnu/automake/automake-1.9.tar.gz'

         # configure: error: Autoconf 2.58 or better is required.
         # Please make sure it is installed and in your PATH.

      elif [[ $tool == "gawk" ]]; then
         url='http://ftp.gnu.org/gnu/gawk/gawk-3.1.1.tar.gz'

         # needs libtoolize

      elif [[ $tool == "libtoolize" ]]; then
         url='http://mirror.sbb.rs/gnu/libtool/libtool-1.5.14.tar.gz'

         # needs automake
      fi

      if [[ $url != '' ]]; then
         mkdir -p $tool && pushd $tool &> /dev/null
            local=`basename $url`
            if [[ ! -e $local ]]; then
               curl -L $url > $local
            fi

            if [[ -e $local ]]; then
               dir=${local%%.tar.gz}
               tar xzf $local
               pushd $dir &> /dev/null
                  export PATH=$PATH:$buildPrefix/bin
                  if [[ ! $i_can_sudo -eq 0 ]]; then
                     echo && read -p "Q: ./configure --prefix=$buildPrefix $dir? [y/n] " -u 1 do_it
                     sudo=""
                  else
                     echo && read -p "Q: ./configure $dir? [y/n] " -u 1 do_it
                     sudo="sudo"
                  fi
                  if [[ "$do_it" == [yY] ]]; then
                     if [[ ! $i_can_sudo -eq 0 ]]; then
                        ./configure --prefix=$buildPrefix
                     else
                        ./configure
                     fi
                     echo && read -p "Q: make $dir? [y/n] " -u 1 do_it
                     if [[ "$do_it" == [yY] ]]; then
                        $sudo make
                        #make check
                        echo && read -p "Q: make install $dir? [y/n] " -u 1 do_it
                        if [[ "$do_it" == [yY] ]]; then
                           $sudo make install
                        fi
                     fi
                  fi
               popd &> /dev/null
            fi
         popd &> /dev/null
      fi
   done
popd &> /dev/null

echo $missing
