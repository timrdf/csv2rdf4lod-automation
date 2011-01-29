# e-params-increment.awk
# params: eID

{
   # TODO: change the URI of the dataset, too.
   if( $0~"conversion:enhancement_identifier" ) {
      printf("      conversion:enhancement_identifier \"%s\";\n",eID)}
   else {
      print
   }
}
