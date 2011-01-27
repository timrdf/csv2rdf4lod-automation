# update-e-params-subject-discrim.awk
# params: 
#    dataset_identifier
#    datasetVersion
#    subjectDiscriminator

{
   if( $0~"conversion:subject_discriminator" ) {
      printf("      conversion:subject_discriminator \"%s\";\n",subjectDiscriminator)

   }else if( $0~"conversion:dataset_version" ) {                          # TODO: DEPRECATED (but converter not recognizing it)
      printf("   conversion:dataset_version \"%s\";\n",datasetVersion)
   }else if( $0~"conversion:version_identifier" ) {
      printf("   conversion:version_identifier \"%s\";\n",datasetVersion)

   }else if( $0~"conversion:dataset_identifier" && length(dataset_identifier) > 0) {
      printf("   conversion:dataset_identifier \"%s\";\n",dataset_identifier)
   }else {
      print
   }
}
