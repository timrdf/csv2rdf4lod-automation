#!/bin/bash

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
