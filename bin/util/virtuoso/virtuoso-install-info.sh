#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/tree/master/bin/util/virtuoso>;
#3>    rdfs:seeAlso          <https://github.com/timrdf/csv2rdf4lod-automation/wiki/Publishing-conversion-results-with-a-Virtuoso-triplestore>;
#3>    rdfs:seeAlso          <https://github.com/timrdf/prizms/issues/79> .

virtuoso_install_method=''

# When Virtuoso is installed with:
#   dpkg -i ${pkg}_amd64.deb

# /var/lib/virtuoso/db/virtuoso.ini
# /var/lib/virtuoso/db/virtuoso.log
# /etc/init.d/virtuoso-opensource
# /usr/bin/isql-v

ini='/var/lib/virtuoso/db/virtuoso.ini'
init_d='/etc/init.d/virtuoso-opensource'
isql='/usr/bin/isql-v'

if [[ -e "$ini" && -e "$init_d" && -e "$isql" ]]; then
   virtuoso_install_method='dpkg'
fi

if [[ -z "$virtuoso_install_method" ]]; then
   # When Virtuoso is installed with:
   #   sudo aptitude install virtuoso-opensource

   # /etc/virtuoso-opensource-6.1/virtuoso.ini
   # /var/lib/virtuoso-opensource-6.1/db/virtuoso.log
   # /etc/init.d/virtuoso-opensource-6.1
   # /usr/bin/isql-vt

   ini=''
   log=''
   init_d=''
   isql=''

   for virtuoso in `find /etc -maxdepth 1 -type d -name "virtuoso-*"`; do
      if [[ -e $virtuoso/virtuoso.ini && -z "$ini" ]]; then
         ini="$virtuoso/virtuoso.ini"
      fi
   done
   for virtuoso in `find /etc/init.d -maxdepth 1 -name "virtuoso-opensource-*"`; do
      if [[ -z "$init_d" ]]; then
         init_d="$virtuoso"
         if [[ -e /var/lib/`basename $virtuoso`/db/virtuoso.log ]]; then
            log=/var/lib/`basename $virtuoso`/db/virtuoso.log
         fi
      fi
   done
   isql='/usr/bin/isql-vt'

   if [[ -e "$ini" && -e "$init_d" && -e "$isql" ]]; then
      virtuoso_install_method='aptitude'
   fi
fi

if [[ "$1" == '--help' ]]; then
   echo "usage: `basename $0` {--help, method, ini, init_d, log}"
   echo "method: `$0 method`"
   echo "ini:    `$0 ini`"
   echo "init_d: `$0 init_d`"
   echo "log:    `$0 log `"
elif [[ "$1" == 'method' ]]; then
   echo $virtuoso_install_method
elif [[ "$1" == 'ini' ]]; then
   echo $ini
elif [[ "$1" == 'init_d' ]]; then
   echo $init_d
elif [[ "$1" == 'log' ]]; then
   echo $log
else
   if [[ -n "$virtuoso_install_method" ]]; then
      echo "yes"
   else
      echo "no"
   fi
fi
