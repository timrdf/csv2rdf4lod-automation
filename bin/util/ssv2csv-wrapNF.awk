# ssv2csv-wrapNF.awk
#
# Space-separated value to comma-separate values.
#
# Params:
#
# cols - the number of columns in the space-separated file.
#
# Input:
#
# state_code  area_code   area_name
# 
# xx 0000  Statewide
# 04 6200  Phoenix
# 06 0360  Anaheim-Santa Ana PMSA
#
# Output:
#
# state_code,area_code,"area_name"
# 
# xx,0000,"Statewide"
# 04,6200,"Phoenix"
# 06,0360,"Anaheim-Santa Ana PMSA"
# 06,4480,"Los Angeles-Long Beach PMSA"

# cat gp.area | awk -f wrap-last-in-quotes.awk -v cols=3 > gp.area.csv
# cols=2 is default

BEGIN {
   cols = (length(cols)>0) ? cols : 2
}

NF > 1 {
   printf("%s",$1);
   for(i=2;i<cols;i++) {
      printf(",%s",$i);
   }
   printf(",\"");
   printf("%s",$cols);
   for(i=cols+1;i<=NF;i++) {
      printf(" %s",$i);
   }
   printf("\"\n");
}

NF == 0 {
   print
}
