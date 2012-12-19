BEGIN {
   print "@prefix dcterms: <http://purl.org/dc/terms/> ."
   print
}

{
   if( $0 ~ /^.*:.*!.*,.*$/) {

      container=$0
      sub(/!\/.*$/,"", container)
      container_format=container
      sub(/:\/.*$/,"", container_format)
      sub(/^.*:\//,"", container)

      contained=$0
      sub(/^.*!\//,"",  contained)
      sub(/,[^,].*$/,"",contained)

      format=$0
      sub(/^.*,/,"",    format)
      sub(/fmt-/,"fmt/",format)

      print "<"container">"
      print "   dcterms:hasPart <"container"/"contained">;"
      print "."
      print "<"container"/"contained">"
      print "   dcterms:isPartOf <"container">;"
      if( tolower(format) != "unknown" ) {
         print "   dcterms:format   <http://provenanceweb.org/formats/pronom/"format">;"
      }
      print "."
      print ""

   } else {

      file=$0
      sub(/,[^,]*$/,"",file)
 
      format=$0
      sub(/^.*,/,"",    format)
      sub(/fmt-/,"fmt/",format)

      if( tolower(format) != "unknown" ) {
         print "<"file"> dcterms:format <http://provenanceweb.org/formats/pronom/"format"> ."
         print ""
      } else {
         # SIO-Qualify the unknown and say that DROID doesn't know.
      }
   }
}
