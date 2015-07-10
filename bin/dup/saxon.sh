#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/dup/saxon.sh>;
#3> .
#
# usage:
#
#   $path_to/in2out.sh file1.in > file1.out
#       output is sent to stdout
#
#   $path_to/in2out.sh -w file1.in; ls = file1.out 
#       same effect as $path_to/in2out.sh file1.in > file1.out: OVERWRITES
#
#   $path_to/in2out.sh -od newdir file1.in > file1.out 
#       -od has no effect with single file (use in2out.sh file1.in > newdir/file1.out instead)
#
#   $path_to/in2out.sh -w -od newdir file1.in > file1.out 
#       -w and -od have no effect with single file
#
#   $path_to/in2out.sh file1.in file999.in; ls = file1.out file999.out  
#       an out file is created 'next to' each given file (in the same directory as input file)
#
#   $path_to/in2out.sh -od newdir file1.in file999.in
#       if 'newdir' exists and output file does NOT exist, write output file into 'newdir'
#       if 'newdir' exists and output file DOES exist, print warning and do not write file
#       if 'newdir' does not exist, creates 'newdir' and write output file into 'newdir'
#
#   $path_to/in2out.sh -w -od newdir file1.in file999.in
#       if 'newdir' exists, write output file into 'newdir' (OVERWRITES even if it exists)
#       if 'newdir' does not exist, creates 'newdir' and write output file into 'newdir'
#
# file renaming:
#   file1.arb.in  ($input_extension = 'in') ($output_extension = 'out') ($replace_extension = 'true')  -> file1.arb.out
#   file1.arb.in  ($input_extension = 'in') ($output_extension = 'out') ($replace_extension != 'true') -> file1.arb.in.out
#   file1.arb.txt ($input_extension = 'in') ($output_extension = 'out')                                -> file1.arb.txt.out
#
# Author: Timothy Lebo

HOME=$(cd ${0%/*/*} && echo ${PWD%/*})
me=$(cd ${0%/*} && echo ${PWD})/`basename $0`

export CLASSPATH=$CLASSPATH`$HOME/bin/util/cr-situate-classpaths.sh`

input_extension="any"
output_extension="any"
replace_extension="false"

usage_message="usage: `basename $0` [-cp classpath] [--memory {4,8,16,...}] [-D -Da=1 -Db=2 ... -using] the.xsl input_extension output_extension [-w] [-od path/to/output/to] [-v a=1 b=2 ... -in] some.$input_extension [another.$input_extension ...]" 

if [[ $# -lt 3 ]]; then
   echo $usage_message 
   exit 1
fi
add_cp="NOCLASSPATH"
if [[ $1 == "-cp" ]]; then
   add_cp="$2"
   shift 2
fi

memory_option="-Xmx1024m"
  memory2_4='-Xms2048m -Xmx4096m'
  memory4_8='-Xms4096m -Xmx8192m'
 memory8_16='-Xms8192m -Xmx16384m'
if [[ $1 == "--memory" ]]; then
   if [[ "$2" == '4' ]]; then
      memory_option=$memory2_4
      shift
   elif [[ "$2" == '8' ]]; then
      memory_option=$memory4_8
      shift
   elif [[ "$2" == '16' ]]; then
      memory_option=$memory8_16
      shift
   elif [[ "$2" == '32' ]]; then
      memory_option=$memory8_16
      shift
   elif [[ "$2" == '64' ]]; then
      memory_option=$memory8_16
      shift
   elif [[ "$2" == '128' ]]; then
      memory_option=$memory8_16
      shift
   elif [[ "$2" == '256' ]]; then
      memory_option=$memory8_16
      shift
   elif [[ "$2" == '512' ]]; then
      memory_option=$memory8_16
      shift
   else
      memory_option=$memory2_4
   fi
   shift
else
   memory_option=$memory2_4
fi

entex_option='-DentityExpansionLimit=1000000' # http://dblp.dagstuhl.de/faq/How+to+parse+dblp+xml.html

javaargs=""
if [[ "$1" = "-D" ]]; then
   shift
   while [ "$1" != "--using" ]; do
      javaargs="$vars $1"
      shift
   done 
   shift # peel "-in"
fi

if [[ $# -lt 3 ]]; then
   echo $usage_message 
   exit 1
fi
xsl="$1"
input_extension="$2"
output_extension="$3"
shift 3

cxsl=""
if [[ ! `grep "xmlns:" $xsl` ]]; then
   # http://saxon.sourceforge.net/saxon7.9/using-xsl.html#Compiling
   #
   # export CLASSPATH=$CLASSPATH`cr-situate-classpaths.sh`
   #
   # java net.sf.saxon.Compile <stylesheet> <output-compiled-stylesheet>
   #
   # -c:filename           Use compiled stylesheet from file
   #
   # java net.sf.saxon.Transform -c:path/to/some.xsl.c path/to/some.xml
   cxsl="-c:$xsl"
   xsl=""
fi

if [[ $# -lt 1 ]]; then
   echo $usage_message 
   exit 1
fi
overwrite="no"
if [[ $1 = "-w" ]]; then
   overwrite="yes"
   shift
fi

if [[ $# -lt 1 ]]; then
   echo $usage_message 
   exit 1
fi
output_dir_set="false"
if [[ $1 = "-od" ]]; then
   output_dir_set="true"
   output_dir="$2"
   if [[ ! -d $output_dir ]]; then
      mkdir $output_dir
   fi
   shift 2
fi

vars=""
if [[ "$1" = "-v" ]]; then
   shift
   while [ "$1" != "-in" ]; do
      vars="$vars $1"
      shift
   done 
   shift # peel "-in"
fi

if [[ $# -lt 1 ]]; then
   echo $usage_message 
   exit 1
fi
multiple_files="false"
if [[ $# -gt 1 ]]; then
   multiple_files="true"
fi

#if [ "debug" == "nodebug" ]; then
#  echo "add_cp:            $add_cp"
#  echo "xsl:               $xsl"
#  echo "input_extension:   $input_extension"
#  echo "output_extension:  $output_extension"
#  echo "overwrite:         $overwrite"
#  echo "output_dir_set:    $output_dir_set"
#  echo "multiple_files:    $multiple_files"
#  echo "replace_extension: $multiple_files"
#fi

# Paths required during processing
#saxon9=${saxon9:?"needs to be set to run Saxon."}

# Determine the absolute path to this script.
D=`dirname "$0"`
script_home="`cd \"$D\" 2>/dev/null && pwd || echo \"$D\"`"

# csv2rdf4lod/bin/dup/saxonb9-1-0-8j.jar

cp=""
if [ "$add_cp" != "NOCLASSPATH" ]; then
   #cp="$add_cp":$saxon8
   cp="$add_cp":$CLASSPATH
fi

class="net.sf.saxon.Transform"
while [ $# -gt 0 ]; do
   artifact="$1"
   shift

   if [ `echo $artifact | sed 's/^.*\.\(.*\)$/\1/' | grep $input_extension | wc -l` -gt 0 -a $replace_extension = "yes" ]; then
    # If the extension is the expected $input_extension and extention should be replaced
      base=`basename $artifact | sed 's/^\(.*\)\..*$/\1/'` # Strip all after last period.
   else
      # The extension was not $input_extension OR extention should be appended (i.e. not replaced)
      base=`basename $artifact`
   fi
   if [ $output_dir_set = "false" ]; then
      # If output directory not provided, write to file at same location as artifact
      output_dir=`dirname $artifact` 
   fi
   outfile=$output_dir/$base.$output_extension

   #echo saxon9: $saxon9 CP: $cp

   if [ $multiple_files = "true" -o $output_dir_set = "true" ]; then
      if [ ! -e $outfile -o $overwrite = "yes" ]; then
         echo $base $outfile
         #echo java $memory_option $javaargs $cp $class -dtd:off $cxsl $artifact $xsl $vars _to_ $outfile >&2
              java $memory_option $javaargs $cp $class -dtd:off $cxsl $artifact $xsl $vars    > $outfile
      else 
         echo "$base    WARNING: $outfile already exists. Did not overwrite."
      fi
   else
      # Only one file was given
      if [ $overwrite = "yes" ]; then
         #echo java $memory_option $javaargs $cp $class -dtd:off $cxsl $artifact $xsl $vars _to_ $outfile >&2
              java $memory_option $javaargs $cp $class -dtd:off $cxsl $artifact $xsl $vars > $outfile
      else
         #echo java $memory_option $javaargs $cp $class -dtd:off $cxsl $artifact $xsl $vars >&2
              java $memory_option $javaargs $cp $class -dtd:off $cxsl $artifact $xsl $vars
     fi
   fi
done
