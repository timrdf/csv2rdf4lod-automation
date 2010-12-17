# update-e-params.awk
# params: eID

{
   if( $0~"conversion:enhancement_identifier" ) {
      printf("      conversion:enhancement_identifier \"%s\";\n",eID)}
   else {
      print
   }
}
