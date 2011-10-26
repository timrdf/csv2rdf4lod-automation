# cell-ify-eparams.awk
#
# columns 12 to 72 should be cellified: jot -s "," `expr 71 - 12 + 1` 12
# 
#
# Parameters:
#    cellify:     What columns?     comma-separated list of column indexes to cellify. e.g. 65,66,67,68,69
#                                     hint: use `jot -s "," 5 65` or seq
#
#    label_up:    Primary label?
#
#    up_object:   Primary object?   Object of up value. If '.', use ov:csvHeader as a literal. If ':', use ov:csvHeader as a resource.
#
#    up_range:    Primary object?   Object of up value
#
#    out_range:   ? e.g. Type of out value.                                        e.g. xsd:gYear
#
#    labels_up:   What range?       comma-separated list of secondary predicate labels.
#
# Example:
#      conversion:enhance [
#         ov:csvCol         65;
#         ov:csvHeader     "BAR00";
#         conversion:label "BAR00";
#         conversion:range  todo:Literal;
#      ];
#
# (params: )
#
#      conversion:enhance [
#          ov:csvCol         65;
#          ov:csvHeader     "BAR00";
#          conversion:label "Year";                      # WAS: BAR00
#          conversion:object "2000"^^xsd:gYear;          # new: value represented by column header
#          conversion:range  rdfs:decimal;               # WAS: todo:Literal
#       ];
#       conversion:enhance [                             # new:
#          ov:csvCol         65;                         # new:
#          conversion:predicate "Place";                 # new:
#          conversion:object    "Bar";                   # new:
#       ];                                               # new:
#
# Example usage:
#
#    (input)
#
#    conversion:enhance [
#       ov:csvCol         12;
#       ov:csvHeader     "Sum_WORK90";
#       conversion:label "Sum_WORK90";
#       conversion:range  todo:Literal;
#    ];
#
#    cat cities-pc-cnty.csv.e1.params.ttl | awk -f $CSV2RDF4LOD_HOME/bin/util/cell-ify-eparams.awk -v cellify=`jot -s "," 60 12` -v label_up="Year" -v up_range=xsd:gYear -v out_range=xsd:decimal -v labels_up=Venue
#
#    (output)
#
#    conversion:enhance [
#       ov:csvCol         12;
#       ov:csvHeader     "Sum_WORK90";
#       a scovo:Item;                                               # : 
#       conversion:label  "Year";                                   # : was "Sum_WORK90";
#       conversion:object ""^^xsd:gYear;                            # : 
#       conversion:range  xsd:decimal;                              # : was todo:Literal;
#    ];
#    conversion:enhance [                                           # : 
#       ov:csvCol            12;                                    # : 
#       conversion:predicate "Venue";                               # : 
#       conversion:object    "";                                    # : 
#    ];                                                             # :
#
# NOTE: The conversion:objects must still be populated.

BEGIN {
   PADDING = 70;

   num_cells = split(cellify,cell_column,",");
   for(i=1; i<=num_cells; i++) {
      c = cell_column[i];
      a_cell[c] = "true";
   } 
   num_labels_up = split(labels_up,secondaryPs,",");

   in_cell_enhancement = "false";
}

$1 == "ov:csvCol" && in_cell_enhancement ==  "false" {
   column=$2;
   gsub(/;/,"",column);
   gsub(/\"/,"",column);
   if( a_cell[column] == "true" ) {
      in_cell_enhancement = "true";
   }
}

function annotate(pre,pad,annotation)
{
   line=pre;
   spaces="";
   for(i=1; i<(pad-length(line)); i++) {
      spaces=spaces" ";
   }
   return sprintf("%s%s# : %s",line,spaces,annotation);
}


in_cell_enhancement == "true" {
   if( $1 == "ov:csvCol" ) {
      lastCol=$2;
      gsub(/;/,"",lastCol);
      gsub(/\"/,"",lastCol);
   }
   line=$0;

   if( length(label_up) > 0 && $1 == "conversion:label" || $1 == "#conversion:label" ) {
      print annotate("         conversion:label  \""label_up"\";",PADDING,"was "$2);
   }else if( length(out_range) > 0 && $1 == "conversion:range" ) {
      print annotate("         conversion:range  "out_range";",PADDING,"was "$2);
   }else if( $1 == "];" ) {
      print $0
      for(i=1; i<=num_labels_up; i++) {
          what=sprintf("         conversion:predicate \"%s\";",secondaryPs[i]); 
         print annotate(        "      conversion:enhance [",PADDING,"");
         print annotate(        "         ov:csvCol            "lastCol";",PADDING,"");
         print annotate(what ,PADDING,"");
         print annotate(        "         conversion:object    \"\";",PADDING,"");
         print annotate(        "      ];",PADDING,"");
      }
   }else {
      print
   }

   if( $1 == "ov:csvHeader" ) {
      current_header=$2; # Old approach missed header after first space.
      current_header=$0; gsub(/^[^"]*"/,"",current_header);
                         gsub(/".*$/,   "",current_header);
      gsub(/"/,"",current_header);
      gsub(/;/,"",current_header);
      print annotate("         a scovo:Item;",PADDING,"");
      print annotate("         a qb:Observation;",PADDING,"");
   }
   if( length(label_up) > 0 && ( $1 == "conversion:label" || $1 == "#conversion:label" ) ) {
      datatype = length(up_range) > 0 ? "^^"up_range : "";
      if( up_object == ":" ) {
         print annotate("         conversion:object :"current_header";",PADDING,"");
      }else if( up_object == "." ) {
         print annotate("         conversion:object \""current_header"\""datatype";",PADDING,"");
      }else {
         print annotate("         conversion:object \""up_object"\""datatype";",PADDING,"");
      }
   }
}

{
   if( in_cell_enhancement == "true" && $1 == "];" ) {
      in_cell_enhancement = "false";
   }else if( in_cell_enhancement == "false" ) {
      print $0
   }
}

END {
   #if( num_cells == 0 ) {
      print "# params:"
      print "#   -v cellify=`jot -s \",\" 5 10` -v label_up=Year -v up_object={. : Blah} -v up_range=xsd:gYear -v out_range=xsd:decimal -v labels_up=Venue,Another,YAnother"
      print "#   -v cellify=`echo \"\" | awk '{for(i=5;i<=10;i++){printf(\",%s\",i)}}'` -v label_up=Year -v up_object=Blah -v up_range=xsd:gYear -v out_range=xsd:decimal -v labels_up=Venue,Another,YAnother"
   #}
}
