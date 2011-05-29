#!/bin/bash
#
# Give any params to get URI-friendly coin:slug
# see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CoIN:-Composition-of-Identifier-Names

if [ $# -eq 0 ]; then
   date +%Y-%m-%dT%H:%M:%S%z | sed 's/^\(.*\)\(..\)$/\1:\2/'
elif [ $1 == "coin:slug" ]; then
   date +%Y-%m-%dT%H_%M_%S%z | sed 's/^\(.*\)\(..\)$/\1:\2/' | sed 's/:/-/g; s/\+/-/g'
else
   date +%Y-%m-%dT%H:%M:%S%z | sed 's/^\(.*\)\(..\)$/\1:\2/'
fi
