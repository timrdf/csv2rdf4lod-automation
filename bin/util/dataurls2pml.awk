# dataurls2pml.awk
#
# params:
#   source
#
# input:
#
# example:
#    $echo http://www.data.gov/download/10/csv | awk -f dataurls2pml.awk -v source=my.html
#       @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
#
#       <my.html> rdfs:seeAlso <http://www.data.gov/download/10/csv> .

BEGIN {
   print "@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> ."
   print ""
}

{
   printf("<%s> rdfs:seeAlso <%s> .\n",source,$0);
}
