# update-e-params-subject-discrim.awk
#
# params: 
#
#   -v baseURI
#   -v sourceID
#   -v dataset_identifier
#   -v datasetVersion
#   -v layerID
#   -v subjectDiscriminator

{
   if( $1 == "@prefix" && $2 == ":" ) {
      # Fix up default namespace.
      printf("@prefix :           <%s/source/%s/dataset/%s/version/%s/params/enhancement/%s/> .\n",baseURI,sourceID,dataset_identifier,datasetVersion,layerID);

   }else if( $0 == ":dataset a void:Dataset;" ) {
      # Change subject to name of layer dataset itself.
      printf("<%s/source/%s/dataset/%s/version/%s/conversion/enhancement/%s>\n",baseURI,sourceID,dataset_identifier,datasetVersion,layerID);

   }else if( /^</ && /source\// && /dataset\// && /version\// && /conversion\// && /enhancement\/[^\/]*>/ ) {
      # <http://logd.tw.rpi.edu/source/lebot/dataset/golfers/version/2012-Mar-11/conversion/enhancement/1>
      # becomes
      # <http://logd.tw.rpi.edu/source/lebot/dataset/golfers/version/2012-Mar-15/conversion/enhancement/1>
      sub(/version\/[^\/]*/,"version/"datasetVersion);
      print $0
   }else if( $0~"conversion:subject_discriminator *\"" ) {
      printf("      conversion:subject_discriminator \"%s\";\n",subjectDiscriminator)

   }else if( $0~"conversion:dataset_version *\"" ) {                          # TODO: DEPRECATED (but converter not recognizing it)
      printf("   conversion:dataset_version    \"%s\";\n",datasetVersion)

   }else if( $0~"conversion:version_identifier *\"" ) {
      printf("   conversion:version_identifier \"%s\";\n",datasetVersion)

   }else if( $0~"conversion:dataset_identifier *\"" && length(dataset_identifier) > 0) {
      printf("   conversion:dataset_identifier \"%s\";\n",dataset_identifier)

   }else {
      print
   }
}
