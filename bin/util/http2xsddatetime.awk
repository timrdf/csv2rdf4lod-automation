# input (from HTTP response header):
#   Last-Modified: Mon, 18 May 2009 14:26:29 GMT
# 
# output:
#   2009-May-18 
{
   num["Jan"]="01";
   num["Feb"]="02";
   num["Mar"]="03";
   num["Apr"]="04";
   num["May"]="05";
   num["Jun"]="06";
   num["Jul"]="07";
   num["Aug"]="08";
   num["Sep"]="09";
   num["Oct"]="10";
   num["Nov"]="11";
   num["Dec"]="12";
   timezone = $8 == "GMT" ? "Z" : "";
   printf("%s-%s-%sT%s%s\n",$5,      # year
                            num[$4], # month
                            $3,      # day
                            $6,      # time
                            timezone);
}
