#!/bin/bash
#
# install.sh - determine CSV2RDF4LOD_HOME and create configuration file.
#
#   Copyright 2012 Timothy Lebo
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
# Usage:
#
#   install.sh [--csh] [--non-interactive] [--vars-only]
#
#     --csh : seat up for csh instead of bash.
#     --non-interactive : do not print user-based stdout; just print the configuration to stdout.
#     --vars-only       : do not include the PATH and alias configurations; only include the CSV2RDF4LOD_ variables.

CSV2RDF4LOD_HOME=$(cd ${0%/*} && echo ${PWD})

ext="sh"
if [ "$1" == "--csh" ]; then
   ext="csh"
   shift
elif [ "$1" == "--cygwin" ]; then
   ext="cyg"
   shift
fi

interactive="yes"
if [ "$1" == "--non-interactive" ]; then
   interactive="no"
fi

vars_only="no"
if [ "$1" == "--vars-only" ]; then
   vars_only="yes"
fi

pushd $CSV2RDF4LOD_HOME &> /dev/null

   see='https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-environment-variables-%28considerations-for-a-distributed-workflow%29'
   echo "#3> <#> a <http://purl.org/twc/vocab/conversion/CSV2RDF4LOD_environment_variables> ;"    > my-csv2rdf4lod-source-me.${ext}
   echo "#3>     rdfs:seeAlso"                                                                   >> my-csv2rdf4lod-source-me.${ext}
   echo "#3>     <$see>,"                                                                        >> my-csv2rdf4lod-source-me.${ext}
   echo "#3>     <https://github.com/timrdf/csv2rdf4lod-automation/wiki/Script:-source-me.sh>" . >> my-csv2rdf4lod-source-me.${ext}
   echo ""                                                                                       >> my-csv2rdf4lod-source-me.${ext}
   echo "export CSV2RDF4LOD_HOME=\"$CSV2RDF4LOD_HOME\""                                          >> my-csv2rdf4lod-source-me.${ext}

   if [ "$interactive" == "yes" ]; then
      echo "`basename $0`:"
      echo "   has created my-csv2rdf4lod-source-me.${ext}."
      echo "   has set \$CSV2RDF4LOD_HOME to $CSV2RDF4LOD_HOME in my-csv2rdf4lod-source-me.${ext}"
   fi

   cat bin/setup.sh | grep -v "# _NOTE_" | grep -v "# _WARNING_"                                 >> my-csv2rdf4lod-source-me.sh

   if [ "$ext" == "csh" ]; then
    # perl -pi -e
      perl -pe 's/export [^ =]*$//; s/^(\w+)="([^"]*)"/setenv \1 "\2"/; s/export (\S+)="([^"]*)"/setenv \1 "\2"/' \
            my-csv2rdf4lod-source-me.sh > my-csv2rdf4lod-source-me.csh
   elif [ "$ext" == "cyg" ]; then
      echo "--cygwin not implemented"
   fi

   echo ""

   mv install.sh bin/

   if [ "$interactive" == "no" ]; then
      $CSV2RDF4LOD_HOME/bin/util/grep-head.sh -p '# End of CSV2RDF4LOD_ variables' my-csv2rdf4lod-source-me.sh
   else
      source my-csv2rdf4lod-source-me.${ext} &> /dev/null

      echo
      echo "~~~ What to do next: ~~~"
      echo
      echo "   'source my-csv2rdf4lod-source-me.${ext}' to set the environment variables that cvs2rdf4lod-automation needs to run."
      echo "    sourcing my-csv2rdf4lod-source-me.${ext} must be done each time you log in, so consider adding this to your .bashrc:"
      echo ""
      echo "      source $CSV2RDF4LOD_HOME/my-csv2rdf4lod-source-me.${ext} # http://purl.org/twc/id/software/csv2rdf4lod"
      echo ""

      echo
      echo "Put the following 'source' command into your ~/.bashrc?"
      echo "      source $CSV2RDF4LOD_HOME/my-csv2rdf4lod-source-me.${ext} # http://purl.org/twc/id/software/csv2rdf4lod"
      echo -n "(y/N) "
      read -u 1 install_it
      echo
      if [ "$install_it" == "y" ]; then
         echo                                                                                                          >> ~/.bashrc
         echo "source $CSV2RDF4LOD_HOME/my-csv2rdf4lod-source-me.${ext} # http://purl.org/twc/id/software/csv2rdf4lod" >> ~/.bashrc
      fi

      echo
      echo "~~~ What to do next: ~~~"
      echo
      echo "    running 'cr-vars.${ext} --check' to checks for dependencies that csv2rdf4lod-automation needs to run."
      echo "    running 'install-csv2rdf4lod-dependencies.sh' installs dependencies."


      echo
      echo -n "Try to install dependencies? (y/N) "
      read -u 1 install_it
      echo
      if [ "$install_it" == "y" ]; then
         install-csv2rdf4lod-dependencies.sh
      fi

      echo
      echo "~~~ What to do next: ~~~"
      echo
      echo "    running `cr-vars.${ext}` shows the environment variables that csv2rdf4lod-automation uses to control execution flow."
      echo "      (see https://github.com/timrdf/csv2rdf4lod-automation/wiki/Installing-csv2rdf4lod-automation)"

      echo
      echo -n "run cr-vars.sh now? (Y/n) "
      read -u 1 install_it
      echo
      if [ "$install_it" != "n" ]; then
         cr-vars.sh
      fi

      echo
      echo "Installation is complete. Check out the following for next steps:"
      echo "* https://github.com/timrdf/csv2rdf4lod-automation/wiki/Installing-csv2rdf4lod-automation"
      echo "* https://github.com/timrdf/csv2rdf4lod-automation/wiki/A-quick-and-easy-conversion"
      echo "* https://github.com/timrdf/csv2rdf4lod-automation/wiki/Conversion-process-phases"
      echo
   fi

popd &> /dev/null
