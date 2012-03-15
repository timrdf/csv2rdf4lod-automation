# bin/util/e-params-increment.awk
#
# used by convert.sh when -e flag is used to create a new layer, e.g., '-e 2'
#
# params: 
#
#   -v eID

{
   if(/^@prefix : /){
      # change
      # @prefix :           <http://logd.tw.rpi.edu/source/nitrd-gov/dataset/fed_RD_IT/version/2011-Jan-27/conversion/enhancement/1> .
      # to
      # @prefix :           <http://logd.tw.rpi.edu/source/nitrd-gov/dataset/fed_RD_IT/version/2011-Jan-27/conversion/enhancement/2> .
      sub(/enhancement\/[^\/]*\//,"enhancement/"eID);
      print $0
   }else if(/^</ && /source\// && /dataset\// && /version\// && /conversion\// && /enhancement\/[^\/]*>/){
      sub(/enhancement\/[^\/]*>/,"enhancement/"eID">");
      print $0
   }else if( $0~"conversion:enhancement_identifier" ) {
      printf("      conversion:enhancement_identifier \"%s\";\n",eID)}
   else {
      print
   }
}
