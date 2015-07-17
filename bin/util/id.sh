#!/bin/bash
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

usage_message="usage: $0 [-w] [-od path/to/output/to] some.$input_extension [another.$input_extension ...]" 

if [[ -e "$CSV2RDF4LOD_HOME/lib/saxonb9-1-0-8j.jar" ]]; then
   saxon9="$CSV2RDF4LOD_HOME/lib/saxonb9-1-0-8j.jar"
else
   saxon9=${saxon9:?"saxon jar needs to be specified."}
fi

if [[ ! -e "$xutil/id.xsl" ]]; then
   xutil=$(cd ${0%/*} && echo ${PWD})/
fi

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

# Paths required during processing

# Determine the absolute path to this script.
D=`dirname "$0"`
script_home="`cd \"$D\" 2>/dev/null && pwd || echo \"$D\"`"


if [ 'debug' = 'no' ]; then
   echo "multiple_files: " $multiple_files
fi

memory="-Xmx1024m"
memory="-Xmx2048m"
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

	if [ $multiple_files = "true" ]; then
		if [ ! -e $outfile -o $overwrite = "yes" ]; then
		  echo $base $outfile
        # usage: saxon.sh [-cp classpath] the.xsl input_extension output_extension [-w] [-od path/to/output/to] [-v a=1 b=2 ... -in] some.any [another.any ...]
		  #java $memory -jar $saxon9 $artifact $xutil/id.xsl > $outfile
        saxon.sh $xutil/id.xsl a a $artifact > $outfile
		  #mv $outfile $artifact
	  else 
      echo "$base    WARNING: $outfile already exists. Did not overwrite."
		fi
	else
		# Only one file was given
		if [ $overwrite = "yes" ]; then
		  #java $memory -jar $saxon9 $artifact $xutil/id.xsl > $outfile
        saxon.sh $xutil/id.xsl a a $artifact > $outfile
		  #mv $outfile $artifact
		else
		  #java $memory -jar $saxon9 $artifact $xutil/id.xsl 
        saxon.sh $xutil/id.xsl a a $artifact
	  fi
	fi

  shift
done
