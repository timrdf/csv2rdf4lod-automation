#!/bin/sh
# <!DOCTYPE html SYSTEM "/Users/lebot/afrl/information_management/m4rker/model_integration/xutil/xhtml-dtd/xhtml1-transitional.dtd">

usage_message="usage: $0 some.html [another.html ...]"
#[-w] [-od path/to/output/to] some.$input_extension [another.$input_extension ...]"

if [ $# -lt 1 ]; then
  echo $usage_message 
   exit 1
fi

grepdoctype="grep -v 'DOCTYPE html PUBLIC' | grep -v 'xhtml1-transitional.dtd'"
doctype="<!DOCTYPE html SYSTEM \"$CSV2RDF4LOD_HOME/bin/dup/xhtml1-transitional.dtd\">"

tidy="tidy"
if [ ! `which tidy &> /dev/null` ]; then
   echo "WARNING: tidy not on path."
   tidy=/usr/bin/tidy
fi

while [ $# -gt 0 ]; do
   artifact="$1"

   if [ ! `which tidy &> /dev/null` ]; then
      CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"tidy not on path and CSV2RDF4LOD_HOME not set. Will fail at xml-ifying html."}
      tidy="java -jar $CSV2RDF4LOD_HOME/bin/lib/jtidy-r938/jtidy-r938.jar"
   fi

   echo $doctype                                                        > $artifact.tidy
   cat $artifact | grep -v 'DOCTYPE html PUBLIC' | grep -v 'xhtml1-transitional.dtd' | grep -v "xhtml1-strict.dtd" | $tidy -asxml $artifact | grep -v 'DOCTYPE html PUBLIC' | grep -v 'xhtml1-transitional.dtd' | grep -v "xhtml1-strict.dtd" >> $artifact.tidy
   #cat $artifact | grep -v 'DOCTYPE html PUBLIC' | grep -v 'xhtml1-transitional.dtd' | grep -v "xhtml1-strict.dtd" | tidy -asxml | grep -v 'DOCTYPE html PUBLIC' | grep -v 'xhtml1-transitional.dtd' | grep -v "xhtml1-strict.dtd" >> $artifact.tidy
   #$xutil/id.sh $artifact.tidy                                                              
  shift
done
