#!/bin/bash

if [[ "`uname -a`" =~ Darwin ]]; then
   echo Darwin
elif [[ "`uname -a`" =~ Ubuntu ]]; then
   echo Ubuntu
fi
