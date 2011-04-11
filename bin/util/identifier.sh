#!/bin/bash
#
# Clean up a title to create an identifier.
#
# usage:
#  bash-3.2$ identifier.sh '---School Nutrition Environment State Policy Classification System (SNESPCS)----'
#  school-nutrition-environment-state-policy-classification-system-snespcs

echo $1 | sed 's/)//g; s/(//g' | awk '{
   gsub(/ /,"-");
   gsub(/-$/,""); 
   while ( $0 ~ /--/ ) 
      gsub(/--/,"-"); 
   sub(/-$/,""); 
   sub(/^-/,""); 
   print tolower($0)
}'
