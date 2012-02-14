#!/bin/bash
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
#   $path_to/in2out.sh -s -w *.poly
#
# file renaming:
#   file1.arb.in  ($input_extension = 'in') ($output_extension = 'out') ($replace_extension = 'true')  -> file1.arb.out
#   file1.arb.in  ($input_extension = 'in') ($output_extension = 'out') ($replace_extension != 'true') -> file1.arb.in.out
#   file1.arb.txt ($input_extension = 'in') ($output_extension = 'out')                                -> file1.arb.txt.out
#
# Author: Timothy Lebo

input_extension="poly"
output_extension="dpg"
replace_extension="false"
debug="false"

usage_message="usage: $0" 

# Determine the absolute path to this script.
D=`dirname "$0"`
script_home="`cd \"$D\" 2>/dev/null && pwd || echo \"$D\"`"

month_num=`date +%m`
if [ $month_num -eq "01" ]; then month_abbrev="Jan"; fi
if [ $month_num -eq "02" ]; then month_abbrev="Feb"; fi
if [ $month_num -eq "03" ]; then month_abbrev="Mar"; fi
if [ $month_num -eq "04" ]; then month_abbrev="Apr"; fi
if [ $month_num -eq "05" ]; then month_abbrev="May"; fi
if [ $month_num -eq "06" ]; then month_abbrev="Jun"; fi
if [ $month_num -eq "07" ]; then month_abbrev="Jul"; fi
if [ $month_num -eq "08" ]; then month_abbrev="Aug"; fi
if [ $month_num -eq "09" ]; then month_abbrev="Sep"; fi
if [ $month_num -eq "10" ]; then month_abbrev="Oct"; fi
if [ $month_num -eq "11" ]; then month_abbrev="Nov"; fi
if [ $month_num -eq "12" ]; then month_abbrev="Dec"; fi

date_s=`date +%s`
date_stringOLD=`date +%d`_${month_abbrev}_`date +%Y`_${date_s}_s
date_string=`date +%Y-${month_abbrev}-%d_%H-%M-%S` #__${date_s}_s`

echo $date_string
