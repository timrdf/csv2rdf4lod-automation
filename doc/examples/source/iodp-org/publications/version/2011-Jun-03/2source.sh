#!/bin/bash

root="http://data.oceandrilling.org/publications"

mkdir source &> /dev/null
pushd source &> /dev/null

   $CSV2RDF4LOD_HOME/bin/util/pcurl.sh $root/301_DOI_submission_sheet.csv
   $CSV2RDF4LOD_HOME/bin/util/pcurl.sh $root/302_DOI_submission_sheet.csv
   $CSV2RDF4LOD_HOME/bin/util/pcurl.sh $root/303306_DOI_submission_sheet.csv
   $CSV2RDF4LOD_HOME/bin/util/pcurl.sh $root/304305_DOI_submission_sheet.csv
   $CSV2RDF4LOD_HOME/bin/util/pcurl.sh $root/307_DOI_submission_sheet.csv
   $CSV2RDF4LOD_HOME/bin/util/pcurl.sh $root/308_DOI_submission_sheet.csv
   $CSV2RDF4LOD_HOME/bin/util/pcurl.sh $root/309312_DOI_submission_sheet.csv
   $CSV2RDF4LOD_HOME/bin/util/pcurl.sh $root/310_DOI_submission_sheet.csv
   $CSV2RDF4LOD_HOME/bin/util/pcurl.sh $root/311_DOI_submission_sheet.csv
   $CSV2RDF4LOD_HOME/bin/util/pcurl.sh $root/323_ER_DOI_submission_sheet.csv
   $CSV2RDF4LOD_HOME/bin/util/pcurl.sh $root/ODP_DOI_200IR_Submission_sheet.csv
   $CSV2RDF4LOD_HOME/bin/util/pcurl.sh $root/ODP_DOI_201IR_Submission_sheet.csv
   $CSV2RDF4LOD_HOME/bin/util/pcurl.sh $root/ODP_DOI_202IR_redeposit.csv
   $CSV2RDF4LOD_HOME/bin/util/pcurl.sh $root/ODP_DOI_203IR_Submission_sheet.csv
   $CSV2RDF4LOD_HOME/bin/util/pcurl.sh $root/ODP_DOI_204IR_Submission_sheet.csv
   $CSV2RDF4LOD_HOME/bin/util/pcurl.sh $root/ODP_DOI_205IR_Submission_sheet.csv
   $CSV2RDF4LOD_HOME/bin/util/pcurl.sh $root/ODP_DOI_206IR_Submission_sheet.csv
   $CSV2RDF4LOD_HOME/bin/util/pcurl.sh $root/ODP_DOI_207IR_Submission_sheet.csv
   $CSV2RDF4LOD_HOME/bin/util/pcurl.sh $root/ODP_DOI_208IR_Submission_sheet.csv
   $CSV2RDF4LOD_HOME/bin/util/pcurl.sh $root/ODP_DOI_209IR_Submission_sheet.csv
   $CSV2RDF4LOD_HOME/bin/util/pcurl.sh $root/ODP_DOI_210IR_Submission_sheet.csv 

popd &> /dev/null
