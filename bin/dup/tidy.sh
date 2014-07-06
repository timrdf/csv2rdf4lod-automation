#!/bin/bash
# <!DOCTYPE html SYSTEM "/Users/lebot/afrl/information_management/m4rker/model_integration/xutil/xhtml-dtd/xhtml1-transitional.dtd">

input_extension="html"
output_extension="tidy"
replace_extension="false"

usage_message="usage: `basename $0` [-w] [-od path/to/output/to] some.html [another.html ...]"

if [ $# -lt 1 ]; then
   echo $usage_message 
   exit 1
fi

overwrite="no"
if [[ $1 = "-w" ]]; then
   overwrite="yes"
   shift
fi

output_dir_set="false"
if [[ $1 = "-od" ]]; then
   output_dir_set="true"
   output_dir="$2"
   if [[ ! -d $output_dir ]]; then
      mkdir $output_dir
   fi
   shift 2
fi

multiple_files="false"
if [[ $# -gt 1 ]]; then
   multiple_files="true"
fi

grepdoctype="grep -v 'DOCTYPE html PUBLIC' | grep -v 'xhtml1-transitional.dtd'"
doctype="<!DOCTYPE html SYSTEM \"$CSV2RDF4LOD_HOME/bin/dup/xhtml1-transitional.dtd\">"

tidy="tidy"
if [ ! `which tidy &> /dev/null` ]; then
   echo "WARNING: tidy not on path." >&2
   tidy=/usr/bin/tidy
fi

function tidy_it {
   echo $doctype
   cat $1 | grep -v 'DOCTYPE html PUBLIC' | grep -v 'xhtml1-transitional.dtd' | grep -v "xhtml1-strict.dtd" | $tidy -asxml $1 | grep -v 'DOCTYPE html PUBLIC' | grep -v 'xhtml1-transitional.dtd' | grep -v "xhtml1-strict.dtd"
   #cat $artifact | grep -v 'DOCTYPE html PUBLIC' | grep -v 'xhtml1-transitional.dtd' | grep -v "xhtml1-strict.dtd" | tidy -asxml | grep -v 'DOCTYPE html PUBLIC' | grep -v 'xhtml1-transitional.dtd' | grep -v "xhtml1-strict.dtd" >> $artifact.tidy
}

while [ $# -gt 0 ]; do
   artifact="$1"

   if [[ $replace_extension == "yes" && \
         "`echo $artifact | sed 's/^.*\.\(.*\)$/\1/' | grep $input_extension | wc -l`" -gt 0 ]]; then
      # If the extension is the expected $input_extension and extension should be replaced.
      base=`basename $artifact | sed 's/^\(.*\)\..*$/\1/'` # Strip all after last period.
      extension=$output_extension
   elif [[ $output_dir_set == "true" && "$output_dir" != "`dirname $artifact`" && \
         "`echo $artifact | sed 's/^.*\.\(.*\)$/\1/' | grep $input_extension | wc -l`" -gt 0 ]]; then
      base=`basename $artifact | sed 's/^\(.*\)\..*$/\1/'` # Strip all after last period.
      extension="$input_extension"
   else
      # The extension was not $input_extension OR extention should be appended (i.e. not replaced)
      base=`basename $artifact`
      extension=$output_extension
   fi
   if [[ $output_dir_set == "false" ]]; then
      # If output directory not provided, write to file at same location as artifact
      output_dir=`dirname $artifact`
   fi
   outfile=$output_dir/$base.$extension

   see='https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set'
   if [ ! `which tidy &> /dev/null` ]; then
      CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"tidy not on path and CSV2RDF4LOD_HOME not set. Will fail at xml-ifying html. See $see"}
      tidy="java -jar $CSV2RDF4LOD_HOME/bin/lib/jtidy-r938/jtidy-r938.jar"
   fi

   if [ $multiple_files = "true" -o $output_dir_set = "true" ]; then
      if [ ! -e "$outfile" -o $overwrite == "yes" ]; then
         echo $base $outfile
        #echo java $memory_option $cp $class -dtd:off $cxsl $artifact $xsl $vars _to_ $outfile
         #     java $memory_option $cp $class -dtd:off $cxsl $artifact $xsl $vars    > $outfile
         tidy_it "$artifact" > "$outfile"
      else
         echo "$base    WARNING: $outfile already exists. Did not overwrite."
      fi
   else
      # Only one file was given
      if [ $overwrite == "yes" ]; then
         #java $memory_option $cp $class -dtd:off $cxsl $artifact $xsl $vars > $outfile
         tidy_it $artifact > $outfile
      else
         #java $memory_option $cp $class -dtd:off $cxsl $artifact $xsl $vars
         tidy_it $artifact
     fi
   fi

  shift
done
