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

# This looks for all files in the subdirectories that might contain spaces
# and changes the spaces in the filenames to underscores.
# author: Sarah Magidson

# Chancge field separator
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

# Replace spaces in filenames with underscore
for a in `find . -name "* *" | grep csv`; do
   mv $a $(echo "$a" | sed 's/ /_/g' -)
done

# Change back bash field separator
IFS=$SAVEIFS
