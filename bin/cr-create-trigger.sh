#!/bin/bash 
me=$(cd ${0%/*} && echo ${PWD})/`basename $0`

options=''
for available in `find \`dirname $me\` -name "*\`basename $0\`.*"`; do
   option="${available##*sh.}"
   if [[ "$option" != 'swp' ]]; then
      options="$options$sp${available##*sh.}"
      sp=", "
   fi
done

usage="usage: `basename $0` {$options}"

if [[ `is-pwd-a.sh 'cr:directory-of-versions' 'cr:conversion-cockpit'` == 'yes' ]]; then
   if [[ -e "$me.$1" ]]; then
      if [[ ! -e "$1.sh" ]]; then
         cat "$me.$1" > "$1.sh"
         chmod +x "$1.sh"
         ls -lt "$1.sh"
      else
         echo "$1.sh already exists; skipping."
      fi
   else
      if [[ $# -gt 0 ]]; then
         echo "trigger type $1 not available; skipping."
      fi
      echo "$usage"
   fi
else
   echo "not in a conversion cockpit; skipping."
   echo "$usage"
fi
