#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/tree/master/bin/util/grddl.sh> .

HOME=$(cd ${0%/*} && echo ${PWD%/*/*})        # e.g. ...csv2rdf4lod-automation
me=$(cd ${0%/*} && echo ${PWD})/`basename $0` # e.g. ...csv2rdf4lod-automation/bin/util/grddl.sh

if [[ $# -lt 1 ]]; then
   echo "usage: `basename $0` [--flush-cached-transforms] <file.xml>"
   echo
   echo "   Prints to stdout the GRDDL'd RDF from GRDDL-annotated XML files."
fi

if [[ "$1" == "--flush-cached-transforms" ]]; then
   find . -name ".`basename $0`*" | xargs rm
   shift
fi

content="$1"

if [[ -e "$content" ]]; then
   # <x          xmlns:grddl="http://www.w3.org/2003/g/data-view#"
   #    grddl:transformation="https://raw.github.com/timrdf/vsr/master/src/xsl/grddl/graffle.xsl">

   transforms=${me%.*}.xsl
   for transform in `$HOME/bin/dup/saxon.sh $transforms a a $content`; do
      echo "`basename $0`: found link to transform $transform in $content" >&2 
      XSL="$transform"
      if [[ $transform =~ http.* ]]; then
         transform_url_hash=`$HOME/bin/util/md5.sh -qs $transform`
         XSL=".`basename $0`-$transform_url_hash.xsl"
         if [[ ! -e $XSL ]]; then
            echo "`basename $0`: caching transform $transform to $XSL" >&2 
            echo "<!--"         > $XSL
            echo "#3> <> prov:wasGeneratedBy [ prov:qualifiedAssociation [ prov:hadPlan <file://$me> ] ] ."  >> $XSL
            echo "-->"         >> $XSL
            echo "trying to get $transform to `pwd`/$XSL" >&2
            curl -L -s $transform >> $XSL
         else
            echo "`basename $0`: transform $transform already cached at $XSL" >&2 
         fi
      fi
      $HOME/bin/dup/saxon.sh $XSL a a $content
   done
fi
