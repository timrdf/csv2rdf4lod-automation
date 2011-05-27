#!/bin/bash
#
# Usage:
#
# Notes:
#   (vdelete usage: vload graph_uri)

# todo (now obe?): use CSV2RDF4LOD_PUBLISH_VIRTUOSO_SCRIPT_PATH
#sudo /opt/virtuoso/scripts/vdelete $* 
$CSV2RDF4LOD_HOME/bin/util/virtuoso/vdelete $*
