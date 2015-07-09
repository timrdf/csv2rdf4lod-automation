#
# Install 'package' ($2) if 'command' ($1) is not on the PATH.
# Uses either apt-get or yum.
# This should only be used if package:command is 1:1 and the package name is the same for apt-get and yum.
#
function offer_install_with_yum_or_apt_ifnowhich {
   # See also https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/install-csv2rdf4lod-dependencies.sh
   # See also https://github.com/timrdf/DataFAQs/blob/master/bin/install-datafaqs-dependencies.sh
   # See also Prizms bin/install.sh
   if [[ -n "$sudo" ]]; then
      # TODO: after this was moved to a separate file for use by others, it demands that the caller set it up for us...
      command="$1"
      package="$2"
      reason="$3" # TODO: implement this.
      if [[ -n "$command" && -n "$package" ]]; then

         already_there='no'
         if [[ "$command" == '.' ]]; then
            #echo "apt-get `which apt-get &> /dev/null` dpkg -s `dpkg -s $package &> /dev/null`" >&2
            #dpkg -s $package
            #echo $?
            #which apt-get
            #echo $?
            #echo "^^^^^ dpkg -s ^^^^"
            if [[ `$sudo which apt-get &> /dev/null` && `$sudo dpkg -s $package &> /dev/null` ]]; then # 0 is true, 1 is false
               #echo "dpkg -s says $package is already installed"
               already_there='yes'
            elif [[ "`$sudo dpkg -s $package 2> /dev/null | grep 'Installed-Size:'`" =~ .*Installed.* ]]; then
               #echo "grepping dpkg -s says $package is already installed"
               already_there='yes'
            elif [[ `$sudo which yum 2> /dev/null` ]]; then
               already_there='TODO'
            fi
         else
            if [[ `$sudo which $command 2> /dev/null` ]]; then
               echo "$sudo which says $package is already installed"
               already_there='yes'
            fi
         fi

         #if [[ ! `$sudo which $command 2> /dev/null` ]]; then
         #echo "already there: $already_there"
         if [[ "$already_there" != 'yes' ]]; then
            if [ "$dryrun" != "true" ]; then
               echo
            fi
            if [[ `which apt-get 2> /dev/null` ]]; then
               echo $TODO $sudo apt-get install $package
            elif [[ `which yum 2> /dev/null` ]]; then
               echo $TODO $sudo yum install $package
            else
               echo "WARNING: how to install $package without apg-get or yum?"
            fi
            if [[ "$dryrun" != "true" && ( `which apt-get 2> /dev/null` || `which yum 2> /dev/null` ) ]]; then
               read -p "Q: Could not find $command on path. Try to install with command shown above? (y/n): " -u 1 install_it
               if [[ "$install_it" == [yY] ]]; then
                  if [[ `which apt-get 2> /dev/null` ]]; then
                     echo $sudo apt-get install $package
                          $sudo apt-get install $package
                  elif [[ `which yum 2> /dev/null` ]]; then
                     echo $sudo yum install $package
                          $sudo yum install $package
                  fi
               fi
            fi
         else
            if [[ "$command" == '.' ]]; then
               if [[ -e "`$sudo which dpkg 2> /dev/null`" ]]; then
                  echo "[okay] $package already available:"
                  dpkg -s $package | awk '{print "[okay]    "$0}'
               else
                  echo "[okay] no dpkg (sudo=$sudo): `$sudo which dpkg`"
               fi
            else
               echo "[okay] $command already available at `which $command 2> /dev/null`"
            fi
         fi
      fi
      which $command >& /dev/null
      return $?
   else
      echo "[WARNING] Skipping $1 $2 b/c no sudo." >&2
   fi
}
