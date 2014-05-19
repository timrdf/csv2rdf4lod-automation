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
#

see='https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set'
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $see"}

if [[ $# -lt 1 || "$1" == "--help" ]]; then
   echo
   echo "usage: `basename $0` [--list-extensionless] [-v] [--replace-extension] [--mark-invalid [--good-guess-is-valid-enough]] <file>+"
   echo
   echo "         --list-extensionless : return a list of files without file extensions."
   echo "                           -v : return the new name of the file."
   echo "          --replace-extension : [not implemented]"
   echo "               --mark-invalid : Rename any file that is not valid RDF by appending '.invalid'"
   echo " --good-guess-is-valid-enough : If we can guess the format, we'll consider it valid.'"
   echo "                       <file> : The file to identify RDF syntax and rename with appropriate extension."
   exit 1
fi

if [[ "$1" == "--list-extensionless" ]]; then
   for file in `find .`; do
      if [[ "${file%.*}" == "" && $file != "." ]]; then
         echo ${file#./}
      fi
   done
   exit
fi

verbose="false"
if [[ "$1" == "-v" || "$1" == "--verbose" ]]; then
   verbose="true"
   shift
fi

rename_style="append"
if [[ "$1" == "--replace-extension" ]]; then
   echo "--replace-extension not implemented" >&2 # need to worry about no extension being there.
   exit 1
   shift
fi

mark_invalid="false"
if [[ "$1" == "--mark-invalid" ]]; then
   mark_invalid="true"
   shift

   good_guess_is_valid_enough="no"
   if [[ "$1" == "--good-guess-is-valid-enough" ]]; then
      good_guess_is_valid_enough="yes"
      shift
   fi
fi

while [ $# -gt 0 ]; do # TODO: incorporate gzipping similar to lodcloud/data/source/lodcloud/dataDumps/version/2014-04-07
   file="$1"
   shift
   if [ -e "$file" ]; then
      #echo "Determining appropriate extension for $file ..." >&2
      extension=`$CSV2RDF4LOD_HOME/bin/util/guess-syntax.sh --inspect $file extension`
      #echo " ... ($extension) $good_guess_is_valid_enough" >&2
      if [[ ! ( "$good_guess_is_valid_enough" == 'yes' \
               && ( "$extension" == "ttl" || "$extension" == "rdf" || "$extension" == "nt" ) \
              ) && "`valid-rdf.sh $file`" != "yes" ]]; then
         # Not valid :-(
         if [[ "$mark_invalid" == "true" ]]; then
            if [ "$verbose" == "true" ]; then 
               echo "$file".invalid           # 
            fi                                # File exists, is not valid RDF, and we're to mark invalid.
            mv "$file" "$file".invalid        #
         else
            if [ "$verbose" == "true" ]; then
               echo "$file"                   # File exists, is not valid RDF, but we're not marking invalid.
            fi
         fi
      else
         # Valid! \./
         if [[ "$extension" == "ttl" || "$extension" == "rdf" || "$extension" == "nt" ]]; then
            existing_extension=${file##*.}
            if [[ -n "$existing_extension" ]]; then
               if [[ "$existing_extension" != $extension ]]; then
                  if [ "$verbose" == "true" ]; then
                     echo "$file.$extension"     # 
                  fi                             # File exists, is valid RDF, it had an extension, and it wasn't correct.
                  mv "$file" "$file.$extension"  #
               else
                  if [ "$verbose" == "true" ]; then
                     echo "$file"                # File exists, is valid RDF, it had an extension that was correct.
                  fi
               fi
            else
               echo "$file"                      # File exists, is valid RDF, and it didn't have an extension.
            fi
         else
            if [ "$verbose" == "true" ]; then
               echo "$file"                      # File exists, is valid RDF, but we don't know what extension to give.
            fi
         fi
      fi # Is file valid RDF or not.
   fi # File exists
done
