#!/bin/bash
#
#   Copyright 2012 Timothy Lebo
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
# 
# exit 0 if it likes it's guess
# exit 1 if it does not.
#
#
# Example usage:
#
#   syntax=`$CSV2RDF4LOD_HOME/bin/util/guess-syntax.sh $url rapper`
#   liked_guess=$? # 0 : liked its guess, 1: did NOT like its guess
#   if [[ $liked_guess == 1 ]]; then
#      syntax=`$CSV2RDF4LOD_HOME/bin/util/guess-syntax.sh --inspect ${TEMP}${unzipped} rapper`
#   fi

if [[ $# -lt 1 || "$1" == "--help" ]]; then
   echo   >&2
   echo "usage: `basename $0` [--tell <tool> <mimetype>] [--inspect] url-of.rdf [{mime,rapper,jena,extension}]" >&2
   echo "  --tell <tool> <mimetype> : return the token that the given <tool> uses for the given <mimetype>." >&2
   echo "  --inspect                : look at the local file and guess (if not specified, guesses based on the file name)." >&2
   echo   >&2
   exit 1 >&2
fi

if [ "$1" == "--tell" ]; then
   tool="$2"
   mime="$3" 
   if [ "$tool" == "serdi" ]; then
      if [ "$mime" == "text/turtle" ]; then
         echo turtle
      elif [ "$mime" == "text/plain" ]; then
         echo ntriples
      fi
   elif [[ "$tool" == 'http://www.w3.org/ns/formats' ]]; then
      if [[ "$mime" == "text/turtle" || "$mime" == 'ttl' ]]; then
         echo http://www.w3.org/ns/formats/Turtle
      elif [[ "$mime" == "text/plain" || "$mime" == 'nt' ]]; then
         echo http://www.w3.org/ns/formats/N3
      elif [[ "$mime" == "application/rdf+xml" || "$mime" == 'rdf' ]]; then
         echo http://www.w3.org/ns/formats/RDF_XML
      fi
   elif [[ "$tool" == 'find' ]]; then
      if [[ "$mime" == "text/turtle" || "$mime" == 'ttl' ]]; then
         echo ttl
      elif [[ "$mime" == "text/plain" || "$mime" == 'nt' ]]; then
         echo n3
      elif [[ "$mime" == "application/rdf+xml" || "$mime" == 'rdf' ]]; then
         echo rdf
      fi
   fi
   # TODO: rapper, jena, extension
   exit
fi

inspect="false"
if [ "$1" == "--inspect" ]; then
   inspect="true"
   shift
fi

url=$1
tool=$2

guess=""

#
# Take a stab:
#

if   [[ $url =~ \\.nt$  || $url =~ \\.nt\\.  || $url =~ \\.nt#  || $url == *nt  || $url == *.nt.gz  ]]; then # Replaced \. with \\. b/c other OSes were recognizing them as regex.
   guess="-i ntriples"
elif [[ $url =~ \\.ttl$ || $url =~ \\.ttl\\. || $url =~ \\.ttl# || $url == *ttl || $url == *.ttl.gz ]]; then # TODO special case should be handled in general.
   guess="-i turtle"
elif [[ $url =~ \\.rdf$ || $url =~ \\.rdf\\. || $url =~ \\.rdf# || $url == *rdf || $url == *.rdf.gz ]]; then
   guess="-i rdfxml"
elif [[ $url =~ \\.xml$ || $url =~ \\.xml\\. || $url =~ \\.xml# || $url == *xml || $url == *.xml.gz ]]; then
   guess="-i rdfxml"
else
   # We failed to guess based on the file name.
   guess="-g"
fi
filename_guess="$guess"
if [ $inspect == "true" ]; then
   KB_300=307200
   SAMPLE=1000
   #echo "`basename $0` inspecting $url for syntax" >&2
   if [[ ! -f $url ]]; then
      guess="$guess"
   elif [[ `gzipped.sh $url` == "yes" ]]; then
      TEMP="_"`basename $0``date +%s`_$$.tmp
      gunzip -c $url | head -$SAMPLE > $TEMP
      guess=`$0 --inspect $TEMP` # Recursive call on uncompressed sample from the gzip.
      rm $TEMP
   elif [[ `head -c $KB_300 $url | wc -l | awk '{print $1}'` -eq 0 ]]; then
      # Handle the case where there are no newlines in the file (even if it's GB of RDF/XML...).
      #echo "`basename $0` file had no lines :^(" >&2
      #
      # If the file is huge (e.g. 1.1 GB) but has no newlines, awk reports:
      #
      #   awk(37171,0x7fff7834f310) malloc: *** mach_vm_map(size=18446744072872574976) failed (error code=3)
      #   *** error: can't allocate region
      #   *** set a breakpoint in malloc_error_break to debug
      #   awk: out of memory in awkprintf
      #   input record number 1, file 
      #   source line number 1
      #
      # (Thanks, http://eurostat.linked-statistics.org ...)
      if [[ `head -c $KB_300 $url | grep -m 1 '<rdf:RDF '` ]]; then
         #echo "`basename $0` file had rdf:RDF" >&2
         guess="-i rdfxml"
      else
         #echo "`basename $0` file did not have rdf:RDF" >&2
         guess="$filename_guess"
      fi
   elif [[ `head -10 $url | awk '$0 ~ /.*<html>.*/ {c++} END {printf("%s",c)}'` -gt 0 ]]; then
      guess="-g"
   elif [[ `head -$SAMPLE $url | awk '$0 ~ /^@prefix.*/ {c++} END {printf("%s",c)}'` -gt 0 ]]; then
      # @prefix
      guess="-i turtle"                   #      <     >     <     >     <     >      .
   elif [[   `head -$SAMPLE $url | awk '$0 ~ /^[^<]*<[^>]+>[^>]*<[^>]+>[^>]*<[^>]+>[^>]*<[^>]+>[^<]*\.[^<]*$/ && $0 !~ "rdf:about=" && $0 !~ "rdf:nodeID=" {c++} END {printf("%s",c)}'` -gt 1 ]]; then
      # <> <> <>
      guess="-i nquads"
   elif [[   `head -$SAMPLE $url | awk '$0 ~ /^[^<]*<[^>]+>[^>]*<[^>]+>[^>]*<[^>]+>[^<]*\.[^<]*$/ && $0 !~ "rdf:about=" && $0 !~ "rdf:nodeID=" {c++} END {printf("%s",c)}'` -gt 1 ]]; then
      # <> <> <>
      guess="-i ntriples"
   elif [[ `head -$SAMPLE $url | awk '$0 ~ "rdf:about=" || $0 ~ "rdf:resource" {c++} END {printf("%s",c)}'` -gt 2 ]]; then
      # rdf:about=
      guess="-i rdfxml"
   elif [[ `head -$SAMPLE $url | awk '$0 ~ "rdf:RDF" || $0 ~ "xmlns:rdf=" {c++} END {printf("%s",c)}'` -gt 0 ]]; then
      # rdf:RDF
      guess="-i rdfxml"
   elif [[ `head -$SAMPLE $url | awk '$0 ~ /> +a +</ {c++} $0 ~ /^ *a +</ {c++} END {printf("%s",c)}'` -gt 0 ]]; then
      # <http://> a <http://>,
      #           a <http://>,
      guess="-i turtle"
   else
      #echo "still no idea after --inspect" >&2
      #echo "ntriples: `head -$SAMPLE $url | awk '$0 ~ /[^<]*<[^>]+>[^>]*[^<]*<[^>]+>[^>]*[^<]*<[^>]+>[^>]*/{c++}END{printf("%s",c)}'`" >&2
      #echo "turtle:   `head -$SAMPLE $url | awk '$0 ~ /^@prefix.*/ {c++} END {printf("%s",c)}'`" >&2
      #echo "rdfxml:   `head -$SAMPLE $url | awk '$0 ~ "rdf:about=" {c++} END {printf("%s",c)}'`" >&2
      guess="$filename_guess"
   fi
   #echo "`basename $0` done with $url ($guess)" >&2
fi

#
# Translate to whims of each tool: (TODO: reason to mimetype, then translate to tool)
#

if [ "$tool" == "rapper" ]; then
   if [[ $guess == "-i ntriples" || "$guess" == "text/plain" ]]; then
      guess="-i ntriples"
   elif [[ $guess == "-i turtle" || "$guess" == "text/turtle" ]]; then
      guess="-i turtle"
   elif [[ $guess == "-i rdfxml" || "$guess" == "application/rdf+xml" ]]; then
      guess="-i rdfxml"
   elif [[ $guess == "-g" || "$guess" == "undetermined" ]]; then
      echo ""
      exit 1
   else
      echo ""
      exit 1
   fi
   guess=$guess # TODO: transition to mime-based logic.

elif [ "$tool" == "jena" ]; then
   if [[ $guess == "-i ntriples" || "$guess" == "text/plain" ]]; then
      guess="$guess"
   elif [[ $guess == "-i ntriples" || "$guess" == "text/plain" ]]; then
      guess="$guess"
   else
      exit 1
   fi

elif [ "$tool" == "vload" -o "$tool" == "extension" ]; then
   # rdf, ttl, nt, nq
   if [[ $guess == "-i ntriples" || "$guess" == "text/plain" ]]; then
      guess="nt"
   elif [[ $guess == "-i turtle" || "$guess" == "text/turtle" ]]; then
      guess="ttl"
   elif [[ $guess == "-i rdfxml" || "$guess" == "application/rdf+xml" ]]; then
      guess="rdf"
   elif [[ $guess == "-g" || "$guess" == "undetermined" ]]; then
      exit 1
   else
      exit 1
   fi

elif [ "$tool" == "mime" ]; then
   if [[ $guess == "-i ntriples" || "$guess" == "text/plain" ]]; then
      guess="text/plain"
   elif [[ $guess == "-i turtle" || "$guess" == "text/turtle" ]]; then
      guess="text/turtle"
   elif [[ $guess == "-i rdfxml" || "$guess" == "application/rdf+xml" ]]; then
      guess="application/rdf+xml"
   elif [[ $guess == "-g" || "$guess" == "undetermined" ]]; then
      echo ""
      exit 1
   else
      echo ""
      exit 1
   fi
   #guess=$guess # TODO: transition to mime-based logic.

elif [ "$tool" == "formats:" ]; then
   if [[ $guess == "-i ntriples" || "$guess" == "text/plain" ]]; then
      guess="http://www.w3.org/ns/formats/N-Triples"
   elif [[ $guess == "-i nquads" || "$guess" == "text/plain" ]]; then
      guess="http://www.w3.org/ns/formats/N-Quads"
   elif [[ $guess == "-i turtle" || "$guess" == "text/turtle" ]]; then
      guess="http://www.w3.org/ns/formats/Turtle"
   elif [[ $guess == "-i rdfxml" || "$guess" == "application/rdf+xml" ]]; then
      guess="http://www.w3.org/ns/formats/RDF_XML"
   elif [[ $guess == "-g" || "$guess" == "undetermined" ]]; then
      echo ""
      exit 1
   else
      echo ""
      exit 1
   fi
   #guess=$guess # TODO: transition to mime-based logic.

fi

#    N3: http://www.w3.org/ns/formats/N3
#    N-Triples: http://www.w3.org/ns/formats/N-Triples
#    OWL XML Serialization: http://www.w3.org/ns/formats/OWL_XML
#    OWL Functional Syntax: http://www.w3.org/ns/formats/OWL_Functional
#    OWL Manchester Syntax: http://www.w3.org/ns/formats/OWL_Manchester
#    POWDER: http://www.w3.org/ns/formats/POWDER
#    POWDER-S: http://www.w3.org/ns/formats/POWDER-S
#    RDFa: http://www.w3.org/ns/formats/RDFa
#    RDF/XML: http://www.w3.org/ns/formats/RDF_XML
#    RIF XML Syntax: http://www.w3.org/ns/formats/RIF_XML
#    SPARQL Results in XML: http://www.w3.org/ns/formats/SPARQL_Results_XML
#    SPARQL Results in JSON: http://www.w3.org/ns/formats/SPARQL_Results_JSON
#    SPARQL Results in CSV: http://www.w3.org/ns/formats/SPARQL_Results_CSV
##    SPARQL Results in TSV: http://www.w3.org/ns/formats/SPARQL_Results_TSV
#    Turtle: http://www.w3.org/ns/formats/Turtle


echo $guess
if [[ $guess == "-g" || $guess == "" ]]; then
   exit 1
fi
