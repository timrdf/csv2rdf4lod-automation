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

# need to provide the key that can be seen in the URL pane of the web browser.
if [ $# -lt 1 ]; then
   echo "usage: `basename $0` spreadsheet-key"
fi

echo 'http://spreadsheets.google.com/tq?tqx=out:csv&tq=select%20*&key='$1
echo "http://spreadsheets.google.com/pub?key=$1&output=csv"
