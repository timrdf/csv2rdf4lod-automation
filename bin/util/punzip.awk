# punzip.awk
#
# Input: ugly listing that shouldn't be used to know what files are in a zip (but we are anyway).
#
#     19440711  06-03-11 16:54   data.csv
#
# Params:
#   zip - the zip to pull the file from.
#   [file_name] - if given, replace the file name from the zip.
#   [file_extension] - if given, append to the output file name.
#
# If only file_extension, then append to the file used in the zip.
# If only the file_name, use just that.
# If both, then append file_extension to file_name
#
# used by punzip.sh
#
{
   gsub(/^ *[^ ]* *[^ ]* *[^ ]* */,"");
   file=$0; # Don't just grab $4 (spaces in filenames)
   ofile=file; 
   if( length(file_name) && length(file_extension) ) {
      ofile = sprintf("%s.%s",file_name,file_extension);  
      #print "overriding "file" with "ofile
   }else if( length(file_name) ) {
      ofile = file_name;  
      #print "overriding "file" with "ofile
   }else if( length(file_extension) ) {
      ofile = sprintf("%s.%s",ofile,file_extension);  
      #print "overriding "file" with "ofile
   }
   gsub(/ /,"_",ofile); 
   cmd=sprintf("unzip -p %s \"%s\" > %s",zip,file,ofile); 
   print ofile; # Print the resulting file name so the caller can assert provenance.
   system(cmd)
}
