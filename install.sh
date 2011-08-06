#!/bin/bash

ext="sh"
if [ "$1" == "--csh" ]; then
   ext="csh"
fi

CSV2RDF4LOD_HOME=`pwd`
echo "export CSV2RDF4LOD_HOME=\"$CSV2RDF4LOD_HOME\"" > my-csv2rdf4lod-source-me.${ext}
echo "`basename $0`:"
echo "   has created my-csv2rdf4lod-source-me.${ext}."
echo "   has set \$CSV2RDF4LOD_HOME to $CSV2RDF4LOD_HOME in my-csv2rdf4lod-source-me.${ext}"

cat bin/setup.sh | grep -v "# NOTE:" >> my-csv2rdf4lod-source-me.sh

if [ "$1" == "--csh" ]; then
 # perl -pi -e
   perl -pe 's/export [^ =]*$//; s/^(\w+)="([^"]*)"/setenv \1 "\2"/; s/export (\S+)="([^"]*)"/setenv \1 "\2"/' \
         my-csv2rdf4lod-source-me.sh > my-csv2rdf4lod-source-me.csh
elif [ "$1" == "--cygwin" ]; then
   echo "--cygwin not implemented"
fi

echo ""

echo "~~~ What to do next: ~~~"
echo "   'source my-csv2rdf4lod-source-me.${ext}' to set environment variables."
echo "    sourcing my-csv2rdf4lod-source-me.${ext} must be done EACH TIME you log in, so consider adding this to your .bashrc:"
echo ""
echo "      source $CSV2RDF4LOD_HOME/my-csv2rdf4lod-source-me.${ext} # http://purl.org/twc/id/software/csv2rdf4lod"
echo ""
echo "    use cr-vars.${ext} to see the environment variables that CSV2RDF4LOD uses to control execution flow."
mv install.sh bin/
