# symbol-interpretation.awk
#
# see also: ssv2csv-wrapNF.awk to format to this input.
#
# input:
#
#   416,"Wage Stabilization Board"
#   501,"Unidentifiable"
# 
# output:
#         conversion:interpret [
#            conversion:symbol         "416";
#            conversion:interpretation "Wage Stabilization Board";
#         ];
#         conversion:interpret [
#            conversion:symbol         "501";
#            conversion:interpretation "Unidentifiable";
#         ];

{
   comma=index($0,",");
   symbol=substr($0,1,comma-1);
   interpretation=substr($0,comma+1,length($0));
   if( swap == "yes" ) {
      symbol=substr($0,comma+1,length($0));
      interpretation=substr($0,1,comma-1);
   }
   printf("         conversion:interpret [\n");
   printf("            conversion:symbol         \"%s\";\n",symbol);
   printf("            conversion:interpretation \"%s\";\n",interpretation);
   printf("         ];\n");
}
