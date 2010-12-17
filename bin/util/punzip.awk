# punzip.awk
#
# Params:
#   zip
#
# used by punzip.sh
#
{
   gsub(/^ *[^ ]* *[^ ]* *[^ ]* */,"");
   file=$0; 
   ofile=file; 
   gsub(/ /,"_",ofile); 
   cmd=sprintf("unzip -p %s \"%s\" > %s",zip,file,ofile); 
   print ofile; 
   system(cmd)
}
