#!/bin/sh
#
# usage:

back_one=`cd .. 2>/dev/null && pwd`
ANCHOR_SHOULD_BE_SOURCE=`basename $back_one`
if [ $ANCHOR_SHOULD_BE_SOURCE != "source" ]; then
   echo "  Working directory does not appear to be a SOURCE directory."
   echo "  Run `basename $0` from a SOURCE directory (e.g. csv2rdf4lod/data/source/SOURCE/)"
   exit 1
fi

source=`basename \`pwd\` | sed 's/\./-/g'` # data.gov data-gov hack

#echo "anchor: $ANCHOR_SHOULD_BE_SOURCE" >&2
#echo "source: $source" >&2

# older version of same query: find . -maxdepth 1 -type d | sed 's/^\.\///' | grep -v "^\.$" | grep -v "^$"

if [ $# -gt 0 -a "$1" == "-s" ]; then
   # sort by directory size
   find . -maxdepth 1 -type d | sed -e 's/\.\///' -e 's/^\.$//' | grep -v "^$" | grep -v "\..*" | xargs du -s | sort -n | awk '{print $2}'
else
   find . -maxdepth 1 -type d | sed -e 's/\.\///' -e 's/^\.$//' | grep -v "^$" | grep -v "\..*"
fi
