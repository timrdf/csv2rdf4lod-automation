#!/bin/bash
# 
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/modification-date.sh

if [[ "`uname -a`" =~ Darwin ]]; then
   stat -f "%m" $1
elif [[ "`uname -a`" =~ Ubuntu ]]; then
   stat -c "%Y" $1
fi
