BEGIN {
   indent="     ";
   maxWidth=0;
}

style != "multiline" {
   gsub(/#\\n\\/,"");gsub(/ *$/,"") # clean up any newlines we added before
   maxWidth = length($0) > maxWidth ? length($0) : maxWidth;  # TODO: maxWidth - length($0)
   NL = NF > 1 ? "\\n" : "";
   printf("%s\'%s %s\' +\n",indent,$0,NL);
}

# TODO ?:dataset should become '+dataset+'
style == "multiline" {
   gsub(/#\\n\\/,""); # clean up any newlines we added before
   gsub(/ *$/,"")
   maxWidth = length($0) > maxWidth ? length($0) : maxWidth;  # TODO: maxWidth - length($0)
   if( NR == 1 ) {
      printf("%s'",indent);
   } else {
      for( pad = prevLength; pad < maxWidth; pad++ ) {
         printf(" ");
      }
      printf("   #\\n\\\n%s ",indent);
   }
   printf($0);
   prevLength=length($0);
}

END {
   if( style == "multiline" ) {
      printf("';\n");
   }
}

