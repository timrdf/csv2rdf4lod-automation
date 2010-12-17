#!/bin/sh
#
# AFRL provides this Software to you on an "AS IS" basis, without warranty
# of any kind. AFRL HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES OR CONDITIONS,
# EITHER EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OR CONDITIONS OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE. You are solely responsible for determining the appropriateness of
# using this Software and assume all risks associated with the use of this
# Software, including but not limited to the risks of program errors, damage to
# or loss of data, programs or equipment, and unavailability or interruption of
# operations.
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

input_extension="any"
output_extension="any"
replace_extension="false"

usage_message="usage: `basename $0` [-cp classpath] the.xsl input_extension output_extension [-w] [-od path/to/output/to] some.$input_extension [another.$input_extension ...]" 

if [ $# -lt 3 ]; then
  echo $usage_message 
	exit 1
fi
add_cp="NOCLASSPATH"
if [ $1 = "-cp" ]; then
  add_cp="$2"
  shift 2
fi

if [ $# -lt 3 ]; then
  echo $usage_message 
	exit 1
fi
xsl="$1"
input_extension="$2"
output_extension="$3"
shift 3

if [ $# -lt 1 ]; then
  echo $usage_message 
	exit 1
fi
overwrite="no"
if [ $1 = "-w" ]; then
  overwrite="yes"
  shift
fi

if [ $# -lt 1 ]; then
  echo $usage_message 
	exit 1
fi
output_dir_set="false"
if [ $1 = "-od" ]; then
	output_dir_set="true"
  output_dir="$2"
	if [ ! -d $output_dir ]; then
	  mkdir $output_dir
	fi
	shift 2
fi

if [ $# -lt 1 ]; then
  echo $usage_message 
	exit 1
fi
multiple_files="false"
if [ $# -gt 1 ]; then
  multiple_files="true"
fi

if [ "debug" = "false" ]; then
  echo "add_cp:            $add_cp"
  echo "xsl:               $xsl"
  echo "input_extension:   $input_extension"
  echo "output_extension:  $output_extension"
  echo "overwrite:         $overwrite"
  echo "output_dir_set:    $output_dir_set"
  echo "multiple_files:    $multiple_files"
  echo "replace_extension: $multiple_files"
fi

# Paths required during processing
#TODO: removed 18 may 2010 source ~/afrl/classpath-scripts/saxon9.sh # This SHOULD NOT modify classpath, only create saxon9
saxon9=${saxon9:?"needs to be set to run Saxon."}

# Determine the absolute path to this script.
D=`dirname "$0"`
script_home="`cd \"$D\" 2>/dev/null && pwd || echo \"$D\"`"

if [ $add_cp = "NOCLASSPATH" ]; then
	#cp=$saxon8
	cp=$CLASSPATH:$saxon9
else
	#cp="$add_cp":$saxon8
	cp="$add_cp":$saxon9
fi

memory_option="-Xmx1024m"
class="net.sf.saxon.Transform"
while [ $# -gt 0 ]; do
	artifact="$1"

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
			java $memory_option -cp $cp $class -dtd:off $artifact $xsl > $outfile
	  else 
      echo "$base    WARNING: $outfile already exists. Did not overwrite."
		fi
	else
		# Only one file was given
		if [ $overwrite = "yes" ]; then
			java $memory_option -cp $cp $class -dtd:off $artifact $xsl > $outfile
		else
			java $memory_option -cp $cp $class -dtd:off $artifact $xsl
	  fi
	fi

  shift
done
