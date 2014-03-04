#!/bin/bash
#
# Copyright (c) 2012, The National Archives <pronom@nationalarchives.gsi.gov.uk>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following
# conditions are met:
#
#  * Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
#  * Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
#  * Neither the name of the The National Archives nor the
#    names of its contributors may be used to endorse or promote products
#    derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

#3> <> prov:wasDerivedFrom [ rdfs:label "droid-binary-6.1-bin/droid.sh" ] .
#
# droid's shell script seems to demand that it be invoked from within the directory
# that the script exists (and the libraries are relative to lib/).
# This constraint isn't suitable when we are working within a data directory 
# and simply want to invoke it for a particular file 
# (also it only accepts directories -- another limitation).
#
# Usage:
#    twc-healthdata/data/source/hub-healthdata-gov/medlineplus-health-topic-files/version/2012-Dec-15/source$ cr-droid.sh . > b
#
#    /srv/twc-healthdata/data/source$ cr-pwd.sh 
#       source/
#    /srv/twc-healthdata/data/source$ find . -mindepth 6 -maxdepth 6 -name cr-droid.ttl

if [ "$1" == "--help" ]; then
   echo "usage: `basename $0` [--help] (--conversion-cockpit-sources | (<dir> | <file)+)"
   echo
   echo "   --conversion-cockpit-sources: identify all files in every conversion cockpit's source/ directory."
   echo "                                 <dir> and <file> arguments have no affect with this option."
   echo "   <dir>:  a directory whose files should be format identified."
   echo "   <file>: a file that should be format identified."
   exit
fi

see='https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set'
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $see"}

rm -f /tmp/droid-archive*

if [ "$1" == "--conversion-cockpit-sources" ]; then

   # cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
   ACCEPTABLE_PWDs="cr:data-root cr:source cr:dataset cr:directory-of-versions cr:conversion-cockpit"
   if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
      ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
      exit 1
   fi

   if [ `cr-pwd-type.sh` == "cr:conversion-cockpit" ]; then
      if [ ! -d source ]; then
         echo "[INFO] `cr-pwd.sh` has no source/; skipping."
      elif [ -e source/cr-droid.ttl ]; then
         echo "[INFO] `cr-pwd.sh` already has source/cr-droid.ttl; skipping."
      else
         datasetV=`cr-dataset-uri.sh --uri`
         pushd source &> /dev/null
            echo "@prefix prov: <http://www.w3.org/ns/prov#> . "                 > cr-droid.ttl
            echo                                                                >> cr-droid.ttl
            cr-droid.sh .                                                       >> cr-droid.ttl
            for retrieved in `find . -name "*.pml.ttl"`; do
               retrieved=${retrieved%.pml.ttl}
               retrieved=${retrieved#\./}
               echo                                                             >> cr-droid.ttl
               echo "<$datasetV> prov:wasDerivedFrom <${retrieved%.pml.ttl}> ." >> cr-droid.ttl
            done
         popd         &> /dev/null
      fi

      # TODO (if source/cr-droid.ttl exists):
      #
      # <http://http://healthdata.tw.rpi.edu/source/hub-healthdata-gov/dataset/medlineplus-health-topic-files/version/2012-Dec-15>
      #    a conversion:VersionedDataset; 
      #    void:subset <http://healthdata.tw.rpi.edu/source/hub-healthdata-gov/dataset/medlineplus-health-topic-files/version/2012-Dec-15/subset/meta/droid>;
      # .
      # <http://healthdata.tw.rpi.edu/source/hub-healthdata-gov/dataset/medlineplus-health-topic-files/version/2012-Dec-15/subset/meta/droid>
      #    a conversion:Metadataset;
      #    void:dataDump <http://healthdata.tw.rpi.edu/source/hub-healthdata-gov/file/hospital-compare/version/2012-Jul-17/source/cr-droid.ttl>;
      # .

   elif [ `cr-pwd-type.sh` == "cr:directory-of-versions" ]; then
      #declare -A depths
      #depths['cr:directory-of-versions']=2
      #depths['cr:dataset']=3
      #depths['cr:source']=4

      #for version in `cr-list-versions.sh`; do
      for version in `find . -mindepth 2 -maxdepth 2 -name source -type d`; do
         pushd `dirname $version` &> /dev/null
            $0 $*
         popd &> /dev/null
      done 
   elif [ `cr-pwd-type.sh` == "cr:dataset" ]; then
      for sourceDir in `find . -mindepth 3 -maxdepth 3 -name source -type d`; do
         pushd `dirname $sourceDir` &> /dev/null
            $0 $*
         popd &> /dev/null
      done 
   elif [ `cr-pwd-type.sh` == "cr:source" ]; then
      for sourceDir in `find . -mindepth 4 -maxdepth 4 -name source -type d`; do
         pushd `dirname $sourceDir` &> /dev/null
            $0 $*
         popd &> /dev/null
      done 
   elif [ `cr-pwd-type.sh` == "cr:data-root" ]; then
      for sourceDir in `find . -mindepth 5 -maxdepth 5 -name source -type d`; do
         pushd `dirname $sourceDir` &> /dev/null
            $0 $*
         popd &> /dev/null
      done 
   fi

   exit
fi

# The current directory from which this script was invoked.
INVOCATION_WD=`pwd`

# We must be within this directory to invoke droid (an unfortunate limitation).
DROID_HOME=$CSV2RDF4LOD_HOME/lib/droid-binary-6.1-bin

while [ $# -gt 0 ]; do
   target="$1"
   if [ -e "$target" ]; then
      #echo $INVOCATION_WD $target >&2
      if [ -f $target ]; then
         # Unfortunately, droid requires the values to be wrapped in double quotes.
         target_abs="\"$INVOCATION_WD/`dirname $target`\""
      else
         target_abs="\"$INVOCATION_WD/$target\""
      fi
      echo             >&2
      echo $target_abs >&2

      pushd $DROID_HOME &> /dev/null
                   sigs="--signature-file \"$CSV2RDF4LOD_HOME/config/droid/signatures.xml\""
         container_sigs="--container-file \"$CSV2RDF4LOD_HOME/config/droid/container-signatures.xml\""
         export droidUserDir=$INVOCATION_WD/.droid6 # https://groups.google.com/forum/?fromgroups=#!topic/droid-list/DRmKU1qyGIk
         export droidTempDir=$INVOCATION_WD/.droid6tmp
         #export droidWorkDir=$INVOCATION_WD/.droid6work
         export droidLogDir=''
         export log4j=''
         export logLevel=''
         echo `basename $0` droidUserDir $droidUserDir >&2
         echo `basename $0` droidTempDir $droidTempDir >&2
         #echo `basename $0` droidWorkDir $droidWorkDir >&2
         echo `basename $0` droidLogDir  $droidLogDir  >&2
         echo `basename $0` log4j        $log4j        >&2
         echo `basename $0` logLevel     $logLevel     >&2
         # DROID seems to spam /tmp: 
         rm -rf /tmp/droid-archive*.tmp
         echo ./droid.sh --no-profile-resource $target_abs --open-archives $sigs $container_sigs --quiet >&2
              ./droid.sh --no-profile-resource $target_abs --open-archives $sigs $container_sigs --quiet | perl -pi -e "s|$INVOCATION_WD/||" | awk -f $CSV2RDF4LOD_HOME/bin/util/cr-droid.awk
         export droidUserDir=''
         export droidTempDir=''
         #export droidWorkDir=''
         if [ -e $INVOCATION_WD/.droid6 ]; then
            echo "`basename $0` temporary .droid6     is `du -sh $INVOCATION_WD/.droid6`"     >&2
            echo "`basename $0` temporary .droid6tmp  is `du -sh $INVOCATION_WD/.droid6tmp`"  >&2
            #echo "`basename $0` temporary .droid6work is `du -sh $INVOCATION_WD/.droid6work`" >&2
            echo "`basename $0` removing $INVOCATION_WD/.droid6"                              >&2
            rm -rf $INVOCATION_WD/.droid6 $INVOCATION_WD/.droid6tmp $INVOCATION_WD/.droid6work
         fi
      popd              &> /dev/null
   else
      echo "WARNING: $target does not exist; not processing" >&2
   fi
   shift
done

exit 1
# Everything below here is in droid.sh; we want to suit the vars shown below.






# DROID launch script for UNIX/Linux/Mac systems
# ==============================================

# Settings:
# =========

# Default work dir: droidUserDir
# ------------------------------
# This is where droid will place user settings
# If not set, it will default to a directory called ".droid6" 
# under the user's home directory.
# It can be configured using this property, or by an environment
# variable of the same name.
droidUserDir=""

# Default work dir: droidTempDir
# ------------------------------
# This is where droid will create temporary files.
# If not set, it will default to a directory called "tmp" 
# under the droid user directory.
# It can be configured using this property, or by an environment
# variable of the same name.
droidTempDir=""

# Default log dir: droidLogDir
# ----------------------------
# This is where droid will write its log files.
# If not set, it will default to a folder called "logs"
# under the droidWorkDir.
# It can be configured using this property, or by an environment
# variable of the same name.
droidLogDir=""


# Log configuration: log4j
# ------------------------
# This is the location of the lo4j configuration file to use.
# By default, it will use a file called "log4j.properties"
# which is found under the droidWorkDir.
# It can be configured using this setting, or by an environment
# variable called log4j.configuration
log4j=""


# Default console logging level
# -----------------------------
# This allows you to set the default logging level used by DROID
# when logging to the command line console.  If not set,
# it defaults to INFO level logging, unless running in quiet
# mode from the command-line, in which case the log level is
# overridden to be ERROR.
logLevel=""

# Max memory: droidMemory
# -----------------------
# The maximum memory for DROID to use in megabytes.
droidMemory="512m"



# Run DROID:
# ==========

# Collect settings into runtime options for droid:
OPTIONS=""

# Detect if we are running on a mac or not:
os=`uname`
if [ "Darwin" = "$os" ]; then
    OPTIONS=$OPTIONS" -Xdock:name=DROID"
    OPTIONS=$OPTIONS" -Dcom.apple.mrj.application.growbox.intrudes=false"
    OPTIONS=$OPTIONS" -Dcom.apple.mrj.application.live-resize=true"
fi

# Build command line options from the settings above:
if [ -n "$droidMemory" ]; then
    OPTIONS=$OPTIONS" -Xmx$droidMemory"
fi
if [ -n "$droidUserDir" ]; then
    OPTIONS=$OPTIONS" -DdroidUserDir=$droidUserDir"
fi
if [ -n "$droidTempDir" ]; then
    OPTIONS=$OPTIONS" -DdroidTempDir=$droidTempDir"
fi
if [ -n "$droidLogDir" ]; then
    OPTIONS=$OPTIONS" -DdroidLogDir=$droidLogDir"
fi
if [ -n "$log4j" ]; then
    OPTIONS=$OPTIONS" -Dlog4j.configuration=$log4j"
fi
if [ -n "$logLevel" ]; then
    OPTIONS=$OPTIONS" -DconsoleLogThreshold=$logLevel"
fi

# echo "Running DROID with these options: $OPTIONS $@"

export CLASSPATH=$CLASSPATH`$CSV2RDF4LOD_HOME/bin/util/cr-situate-classpaths.sh`

for path in `echo $CLASSPATH | sed 's/:/ /g'`; do
   echo $path
done

# Run the command line or user interface version with the options:
if [ $# -gt 0 ]; then
    #java $OPTIONS -jar $CSV2RDF4LOD_HOME/lib/droid-command-line-6.1.jar "$@"
    java $OPTIONS uk.gov.nationalarchives.droid.command.DroidCommandLine "$@"
else
    #java $OPTIONS -jar $CSV2RDF4LOD_HOME/lib/droid-ui-6.1.jar
    java $OPTIONS -jar $CSV2RDF4LOD_HOME/lib/droid-ui-6.1.jar
fi
