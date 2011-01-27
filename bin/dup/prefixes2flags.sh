#!/bin/bash
#
# usage:

usage="usage: `basename $0` some.ttl ..."
#\n\
#combine automatic/*.raw.ttl into publish/SSS-DDD-VVV.raw.nt for the requested datasets.\n\
#\n\
#-con: conversion identifier to publish (raw, e1, e2, ...) (default: raw)\n\
#\n\
#This is run from data.gov/ (where directories 9, 10, 32, ... reside)."

if [ $# -lt 1 ]; then
   echo $usage
   exit 1
fi

#CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"must be set. source csv2rdf4lod/source-me.sh."}
#formats=${formats:?"must be set. source csv2rdf4lod/source-me.sh"}

while [ $# -gt 0 ]; do
   turtleArtifact=$1
   cat $turtleArtifact | grep "@prefix" | sort -u | sed -e 's/://' | awk '{gsub("<","");gsub(">","");printf(" -D %s=%s ",$2,$3)}'
   shift
done
