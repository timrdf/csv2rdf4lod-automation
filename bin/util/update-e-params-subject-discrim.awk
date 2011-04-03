# update-e-params-subject-discrim.awk
# params: 
#    baseURI
#    sourceID
#    dataset_identifier
#    datasetVersion
#    layerID
#    subjectDiscriminator

{
   if( $1 == "@prefix" && $2 == ":" ) {
      # Fix up default namespace.
      printf("@prefix :           <%s/source/%s/dataset/%s/version/%s/params/enhancement/%s/> .",baseURI,sourceID,dataset_identifier,);

   }else if( $0 == ":dataset a void:Dataset;" ) {
      # Change subject to name of layer dataset itself.
      printf("%s/source/%s/dataset/%s/version/%s/conversion/enhancement/%s",baseURI,sourceID,dataset_identifier,datasetVersion,$layerID);

   }else if( $0~"conversion:subject_discriminator" ) {
      printf("      conversion:subject_discriminator \"%s\";\n",subjectDiscriminator)

   }else if( $0~"conversion:dataset_version" ) {                          # TODO: DEPRECATED (but converter not recognizing it)
      printf("   conversion:dataset_version    \"%s\";\n",datasetVersion)

   }else if( $0~"conversion:version_identifier" ) {
      printf("   conversion:version_identifier \"%s\";\n",datasetVersion)

   }else if( $0~"conversion:dataset_identifier" && length(dataset_identifier) > 0) {
      printf("   conversion:dataset_identifier \"%s\";\n",dataset_identifier)

   }else {
      print
   }
}
