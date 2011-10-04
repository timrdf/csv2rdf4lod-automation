#/bin/bash
#
#3> @prefix rdfs:    <http://www.w3.org/2000/01/rdf-schema#> .
#3> @prefix dcterms: <http://purl.org/dc/terms/> .
#3> @prefix doap:    <http://usefulinc.com/ns/doap#> .
#3>
#3> <> a doap:Project;
#3>   dcterms:description "Script to extract Turtle from comments.";
#3>   rdfs:seeAlso <https://github.com/timrdf/csv2rdf4lod-automation/wiki/tic-turtle-in-comments>;
#3> .

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
   echo "usage: `basename $0` [file]*"
   echo "  file: a path of a file that has \"#3>\" designations for Turtle in Comments."
   echo "  If no files given, search for files to process in current directory."
   echo "  https://github.com/timrdf/csv2rdf4lod-automation/wiki/tic-turtle-in-comments"
   exit 1
fi

# If no parameters, process all files.
if [ $# -lt 1 ]; then
   for ttl in `grep "^#3>" * | sed 's/:.*$//' | sort -u`; do
      $0 $ttl
   done
fi

while [ $# -gt 0 ]; do
   file="$1"
   grep "^#3>" $file | sed 's/^#3>//;s/^ //' | rapper -q -i turtle -o turtle -I $file -
   shift
done
