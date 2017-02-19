#!/bin/bash
# 
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/tree/master/bin/util/virtuoso/mac/install-virtuoso-on-mac.sh>
#3>    doap:implements <https://github.com/openlink/virtuoso-opensource/blob/develop/7/README>;
#3>
#3> .

# Config parameters:

#desired_branch='v7.1.0' # A tag...
desired_branch='stable/7' # Now at 7.2

# Go!

dir='virtuoso-from-github'
if [[ ! -e $dir ]]; then
   git clone https://github.com/openlink/virtuoso-opensource.git $dir
fi

if [[ ! -e dependencies/prefix/bin ]]; then
   read -p "Q: Attempt to install Virtuoso's dependencies ()? [y/n] " -u 1 install_them
   if [[ "$install_them" == [yY] ]]; then
      ./install-virtuoso-on-mac-dependencies.sh
   else
      echo "Okay, but good luck! https://github.com/timrdf/csv2rdf4lod-automation/wiki/Publishing-conversion-results-with-a-Virtuoso-triplestore#installing-virtuoso-on-mac"
   fi
fi

echo "Adding to PATH: `pwd`/dependencies/prefix/bin" # These are installed by install-virtuoso-on-mac-dependencies.sh
PATH="$PATH:`pwd`/dependencies/prefix/bin"

configPrefix="`pwd`/virtuoso-${desired_branch//\//-}"

pushd $dir &> /dev/null

   current_branch=`git branch | grep "^\*" | awk '{print $2}'`
   if [[ "$current_branch" != $desired_branch ]]; then
      echo "current branch: \"$current_branch\"  --  desired branch: \"$desired_branch\""
      git status
      echo && read -p "Q: git checkout $desired_branch? [y/n] " -u 1 do_it
      if [[ "$do_it" == [yY] ]]; then
         git checkout "$desired_branch"
      fi
   fi

   #
   # If ! git diff Makefile.am 
   #      or 
   #    ! git diff binsrc/virtuoso/viunix.c
   #
   echo && read -p "POI: Virtuoso's src needs to be changed in two places. Follow https://gist.github.com/timrdf/7737dd03833e9be2b372 [done?] " -u 1 i_did_it

   # ./autogen.sh 
   #  > Makefile.am:28: `dist_doc_DATA' is used but `docdir' is undefined
   #
   #     > http://lists.gnu.org/archive/html/automake/2007-11/msg00128.html
   #
   #       > bash-3.2$ git diff Makefile.am 
   #       |   diff --git a/Makefile.am b/Makefile.am
   #       |   index 0db1fa3..000a1fe 100644
   #       |   --- a/Makefile.am
   #       |   +++ b/Makefile.am
   #       |   @@ -25,6 +25,8 @@ ACLOCAL_AMFLAGS       = -I binsrc/config
   #       |    
   #       |    SUBDIRS = . docsrc libsrc binsrc appsrc
   #       |    
   #       |   +docdir = ${datadir}/doc/${PACKAGE}
   #       |   +
   #       |    dist_doc_DATA = \
   #       |           $(srcdir)/AUTHORS \
   #       |           $(srcdir)/COPYING \
   ./autogen.sh

   echo && read -p "Q: ./configure --prefix=$configPrefix? [y/n] " -u 1 do_it
   if [[ "$do_it" == [yY] ]]; then
      # As told to do by https://github.com/openlink/virtuoso-opensource/blob/stable/7/README#L331:
      #
      #  > CFLAGS="-O -arch i386 -arch x86_64 -mmacosx-version-min=10.10"
      #
      #     > auxfiles.c:77:7: error: redefinition of 'cp_unremap_quota' with a different type: 'long' vs 'int'
      #     | int32 cp_unremap_quota;
      #     |       ^
      #     | ./wifn.h:1296:12: note: previous definition is here
      #     | extern int cp_unremap_quota;
      #     |            ^
      #     | auxfiles.c:78:7: error: redefinition of 'cp_unremap_quota_is_set' with a different type: 'long' vs 'int'
      #     | int32 cp_unremap_quota_is_set;
      #     |       ^
      #     | ./wifn.h:1297:17: note: previous definition is here
      #     |                                         extern int cp_unremap_quota_is_set;
      #
      #       > http://ehc.ac/p/virtuoso/mailman/virtuoso-users/thread/B72B2E9F-0B17-4442-B1D8-89CFA5F208DA@acm.org/
      #          (change CFLAGS as below)
      CFLAGS="-O2 -m64"
      export CFLAGS
      ./configure --prefix=$configPrefix --program-transform-name="s/isql/isql-v/" --with-readline --disable-dependency-tracking
   fi

   echo && read -p "Q: make? [y/n] " -u 1 do_it
   if [[ "$do_it" == [yY] ]]; then
      make
   fi

   echo && read -p "Q: make install? [y/n] " -u 1 do_it
   if [[ "$do_it" == [yY] ]]; then
      make install
   fi

popd &> /dev/null # Left virtuoso-from-github/

# When this script is run from:
#    .../utilities/virtuoso
# It checks the Virtuoso git repo to:
#    .../utilities/virtuoso/virtuoso-7-git
# and installs at:
#    .../utilities/virtuoso/virtuoso-7-prefix/bin/virtuoso-t
#    .../utilities/virtuoso/virtuoso-7-prefix/var/lib/virtuoso/db/virtuoso.ini
#     ^ specifies > .../utilities/virtuoso/virtuoso-7-prefix/var/lib/virtuoso/db/virtuoso.db
#     ^ specifies > .../utilities/virtuoso/virtuoso-7-prefix/var/lib/virtuoso/db/virtuoso.log
#    .../utilities/virtuoso/virtuoso-7-prefix/bin/isql (or isql-v, if --program-transform-name set on config)

# cd .../utilities/virtuoso/virtuoso-7-prefix/; bin/virtuoso-t -f -c var/lib/virtuoso/db/virtuoso.ini &
#
#  > 12:06:18 Version 07.20.3212-pthreads for Darwin as of Mar 22 2015
#  | ...
#  | 12:06:24 PL LOG: Installing Virtuoso Conductor version 1.00.8740 (DAV)
#  | ...
#  | 12:06:24 62  ???                                 0x0000000000000004 0x0 + 4
#  | 12:06:24 GPF: page.c:2516 page_apply called with not enough stack
#  | GPF: page.c:2516 page_apply called with not enough stack
#  | 12:06:24 Server received signal 11. Continuing with the default action for that signal.
#
#    > https://github.com/openlink/virtuoso-opensource/issues/277#issuecomment-68116337
#
#      > bash-3.2$ git diff binsrc/virtuoso/viunix.c
#      | diff --git a/binsrc/virtuoso/viunix.c b/binsrc/virtuoso/viunix.c
#      | index 4076248..ad7d548 100644
#      | --- a/binsrc/virtuoso/viunix.c
#      | +++ b/binsrc/virtuoso/viunix.c
#      | @@ -572,7 +572,7 @@ main (int argc, char **argv)
#      |
#      |    process_exit_hook = viunix_terminate;
#      | 
#      | -  thread_initial (60000);
#      | +  thread_initial (500000); /* https://github.com/openlink/virtuoso-opensource/issues/277#issuecomment-68116337 */
#      |    if (!background_sem)
#      |      background_sem = semaphore_allocate (0);

configPrefixLocal=`basename $configPrefix`

if [[ -e $configPrefixLocal/bin/virtuoso-t ]]; then

   echo
   echo "Virtuoso can be started by running:"
   echo "   cd `pwd`"
   echo "   $configPrefixLocal/bin/virtuoso-t -f -c $configPrefixLocal/var/lib/virtuoso/db/virtuoso.ini &"

   echo && read -p "Q: Start Virtuoso now? [y/n] " -u 1 do_it
   if [[ "$do_it" == [yY] ]]; then
      $configPrefixLocal/bin/virtuoso-t -f -c $configPrefixLocal/var/lib/virtuoso/db/virtuoso.ini &
   fi

   sleep 10 

   echo
   echo "Virtuoso's Conductor is at http://localhost:8890/conductor/"

   echo
   echo "Virtuoso's SPARQL endpoint is at http://localhost:8890/sparql"

   echo
   echo "You can change Virtuoso's password through the command line using the following:"
   echo "   cd `pwd`"
   echo "   $configPrefixLocal/bin/isql-v 1111 dba dba"
   echo "   set password dba SOMEOTHERPASSWORD;"
   echo "   exit;"

   echo
   echo "We will offer to shut down Virtuoso for you in 25 seconds..."

   sleep 25

   echo
   echo "Virtuoso can be shut down by running:"
   echo "   cd `pwd`"
   echo "   virtuoso-stable-7/bin/isql-v 1111 dba dba -K"
   echo && read -p "Q: Shut down Virtuoso now? [y/n] " -u 1 do_it
   if [[ "$do_it" == [yY] ]]; then
      virtuoso-stable-7/bin/isql-v 1111 dba dba -K
   fi
else 
   echo "$configPrefixLocal/bin/virtuoso-t does not exist; do something and try again."
fi
