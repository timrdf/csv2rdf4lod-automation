#!/bin/bash

CSV2RDF4LOD_HOME=`pwd`
echo export CSV2RDF4LOD_HOME=$CSV2RDF4LOD_HOME > source-me.sh
echo "`basename $0`:"
echo "   has created source-me.sh."
echo "   has set \$CSV2RDF4LOD_HOME to $CSV2RDF4LOD_HOME in source-me.sh"

cat bin/setup.sh | grep -v "# NOTE:" >> source-me.sh
echo ""

echo "~~~ What to do next: ~~~"
echo "   'source source-me.sh' to set environment variables."
echo "    sourcing source-me.sh must be done each time you log in, so consider adding this to your .bashrc:"
echo "      source $CSV2RDF4LOD_HOME/source-me.sh # http://purl.org/twc/id/software/csv2rdf4lod"
echo ""
echo "    use cr-vars.sh to see the environment variables that CSV2RDF4LOD uses to control execution flow."
mv install.sh bin/
