#!/bin/bash
#
# Utility script for other scripts.
#
# Usage:
#    dryrun.sh {true,false} {beginning,ending}

if [ "$1" == "true" ]; then
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
