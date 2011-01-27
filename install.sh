#!/bin/bash

echo export CSV2RDF4LOD_HOME=`pwd` > source-me.sh
echo "`basename $0`:"
echo "   has set \$CSV2RDF4LOD_HOME to $CSV2RDF4LOD_HOME in source-me.sh"

cat bin/setup.sh | grep -v "# NOTE:" >> source-me.sh
echo "   created source-me.sh."
echo ""

echo "What to do next:"
echo "   'source source-me.sh' to set environment variables."
echo "    sourcing source-me.sh must be done each time you log in, so consider adding it to your .login/.bashrc."
echo ""
echo "    use cr-vars.sh to see the environment variables that CSV2RDF4LOD uses to control execution flow."
mv install.sh bin/
