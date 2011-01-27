#!/bin/bash

back_one=`cd .. 2>/dev/null && pwd`
ANCHOR_SHOULD_BE_A_VERSION=`basename $back_one` # Use the names from the canonical directory structure
if [ ! -d automatic -o $ANCHOR_SHOULD_BE_A_VERSION != "version" ]; then
   exit 1
fi

# WARNING: only handles e1 through e9

find automatic -name "*.e[!.].ttl" | sed -e 's/^.*\.e\([^.]*\).ttl/\1/' | sort -u

# This would be great, except it might get a parameter that hasn't been modified yet:
#find manual -name "*.params.ttl" | sed -e 's/^.*\.\(.*\)\.params.ttl$/\1/' | sort -ru
