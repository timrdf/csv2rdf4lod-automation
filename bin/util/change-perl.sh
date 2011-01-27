#!/bin/bash

OLD_PERL="^perl "
NEW_PERL="/usr/bin/perl "

if [ ${1:-""} == "-w" ]; then
   grep -l $OLD_PERL -R . | xargs -n 1 perl -pi -e "s|$OLD_PERL|$NEW_PERL|g"
else
   echo ""
   grep -l $OLD_PERL -R .
   echo ""
   echo "run '`basename $0` -w' to modify files in place."
fi
