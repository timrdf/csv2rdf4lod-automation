# update-e-params-subject-discrim.awk
# params: 
#    datasetVersion
#    subjectDiscriminator

{
   if( $0~"conversion:subject_discriminator" ) {
      printf("      conversion:subject_discriminator \"%s\";\n",subjectDiscriminator)
   }else if( $0~"conversion:dataset_version" ) {
      printf("   conversion:dataset_version \"%s\";\n",datasetVersion)
   }else {
      print
   }
}
