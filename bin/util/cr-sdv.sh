#!/bin/bash

sourceID=`cr-source-id.sh`
datasetID=`cr-dataset-id.sh`
versionID=`cr-version-id.sh`

if [ ${#versionID} -gt 0 ]; then
   echo `cr-source-id.sh`-`cr-dataset-id.sh`-`cr-version-id.sh`
elif [ ${#datasetID} -gt 0 ]; then
   echo `cr-source-id.sh`-`cr-dataset-id.sh`
elif [ ${#sourceID} -gt 0 ]; then
   echo `cr-source-id.sh`
fi
