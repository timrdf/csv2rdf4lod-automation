#!/bin/bash

CSV2RDF4LOD_HOME=`pwd`
echo "export CSV2RDF4LOD_HOME=\"$CSV2RDF4LOD_HOME\"" > my-csv2rdf4lod-source-me.sh
echo "`basename $0`:"
echo "   has created my-csv2rdf4lod-source-me.sh."
echo "   has set \$CSV2RDF4LOD_HOME to $CSV2RDF4LOD_HOME in my-csv2rdf4lod-source-me.sh"

cat bin/setup.sh | grep -v "# NOTE:" >> my-csv2rdf4lod-source-me.sh

if [ "$1" == "--csh" ]; then
   perl -pe 's/export [^ =]*$//; s/^(\w+)="([^"]*)"/setenv \1 "\2"/; s/export (\S+)="([^"]*)"/setenv \1 "\2"/' \
         my-csv2rdf4lod-source-me.sh > my-csv2rdf4lod-source-me.csh
elif [ "$1" == "--cygwin" ]; then
   echo "--cygwin not implemented"
fi

echo ""

echo "~~~ What to do next: ~~~"
echo "   'source my-csv2rdf4lod-source-me.sh' to set environment variables."
echo "    sourcing my-csv2rdf4lod-source-me.sh must be done each time you log in, so consider adding this to your .bashrc:"
echo ""
echo "      source $CSV2RDF4LOD_HOME/my-csv2rdf4lod-source-me.sh # http://purl.org/twc/id/software/csv2rdf4lod"
echo ""
echo "    use cr-vars.sh to see the environment variables that CSV2RDF4LOD uses to control execution flow."
mv install.sh bin/
