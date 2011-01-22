# Input:
#
# state_code  area_code   area_name
# 
# xx 0000  Statewide
# 04 6200  Phoenix
# 06 0360  Anaheim-Santa Ana PMSA

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

# To switch from space-delimited to tab-delimited:
# awk -F\t -f ssv2csv.awk

NF > 1 {
   printf("%s",$1);
   for(i=2;i<=NF;i++) {
      printf(",%s",$i);
   }
   print ""
}

NF == 0 {
   print
}
