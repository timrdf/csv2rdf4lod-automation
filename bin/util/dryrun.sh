#!/bin/bash
#
# Utility script for other scripts.
#
# Usage:
#    dryrun.sh {true,false} {beginning,ending}

if [ "$1" == "--help" ]; then
   echo
   echo "usage: `basename $0` {true,false} {beginning,ending}"
   echo "  prints NOTE to stdout describing the status of the dryrun (IF it is a dryrun)."
   echo
fi

if [[ "$1" == "true" || "$1" == "yes" ]]; then
   if [ "$2" == "beginning" ]; then
      echo "" 
      echo "" 
      echo "       (NOTE: only performing dryrun)"
      echo "" 
      echo ""
   elif [ "$2" == "ending" ]; then
      echo "" 
      echo "" 
      echo "       (NOTE: only performed dryrun)"
      echo ""
      echo ""
   fi
fi
