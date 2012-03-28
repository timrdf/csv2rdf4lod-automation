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
#
# Usage:
#
# Notes:
#   (vdelete usage: vload graph_uri)

# todo (now obe?): use CSV2RDF4LOD_PUBLISH_VIRTUOSO_SCRIPT_PATH
#@deprecated: sudo /opt/virtuoso/scripts/vdelete $* 
$CSV2RDF4LOD_HOME/bin/util/virtuoso/vdelete $*
