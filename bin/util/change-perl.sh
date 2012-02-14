#!/bin/bash
#
#   Copyright 2012 Timothy Lebo
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

OLD_PERL="^perl "
NEW_PERL="/usr/bin/perl "

if [ ${1:-""} == "-w" ]; then
   grep -l $OLD_PERL -R . | xargs -n 1 perl -pi -e "s|$OLD_PERL|$NEW_PERL|g"
else
   echo ""
   grep -l $OLD_PERL -R .
   echo ""
   echo "run '`basename $0` -w' to modify files in place."
fi
