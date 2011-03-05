# header2params.sh
#
# Used by $CSV2RDF4LOD_HOME/bin/convert.sh
#
# Parameters:
# -v surrogate
# -v sourceID
# -v datasetID
# -v datasetVersion
# -v subjectDiscriminator
# -v conversionID
#
# -v header
# -v dataStart
# -v dataEnd
#
# -v onlyIfCol
# -v repeatAboveIfEmptyCol
# -v interpretAsNull

BEGIN { 
   showConversionProcess = length(conversionID) + length(subjectDiscriminator) + length(header) + length(dataStart) + length(interpretAsNull) + length(dataEnd);
   FS=","
   STEP = length(conversionID) ? sprintf("enhancement/%s",conversionID) : "raw"
   if(length(conversionID)) {
      print "@prefix rdf:        <http://www.w3.org/1999/02/22-rdf-syntax-ns#> ."
      print "@prefix rdfs:       <http://www.w3.org/2000/01/rdf-schema#> ."
   }
   RDFS="rdfs"
   if(length(conversionID)) {
      print "@prefix todo:       <http://www.w3.org/2000/01/rdf-schema#> ."
      RDFS="todo"
   }
   print "@prefix xsd:        <http://www.w3.org/2001/XMLSchema#> ."
   if(length(conversionID)) {
      print "@prefix dcterms:    <http://purl.org/dc/terms/> ."
      print "@prefix vann:       <http://purl.org/vocab/vann/> ."
      print "@prefix geonames:   <http://www.geonames.org/ontology#> ."
      print "@prefix scovo:      <http://purl.org/NET/scovo#> ."
   }
   print "@prefix void:       <http://rdfs.org/ns/void#> ."
   #if(showConversionProcess>0) {
      print "@prefix ov:         <http://open.vocab.org/terms/> ."
   #}
   print "@prefix conversion: <http://purl.org/twc/vocab/conversion/> ."
   printf("@prefix :           <%s/source/%s/dataset/%s/version/%s/params/%s/> .\n",surrogate,sourceID,datasetID,datasetVersion,STEP);

                                     print
                                     print ":dataset a void:Dataset;"
                                    printf("   conversion:base_uri           \"%s\"^^xsd:anyURI;\n",surrogate);
                                    printf("   conversion:source_identifier  \"%s\";\n",sourceID);
                                    printf("   conversion:dataset_identifier \"%s\";\n",datasetID);
                                    printf("   conversion:dataset_version    \"%s\";\n",datasetVersion);
   if(showConversionProcess > 0) {
                                     print "   conversion:conversion_process ["
                                     print "      a conversion:RawConversionProcess;"
   if(length(conversionID))         printf("      conversion:enhancement_identifier \"%s\";\n",conversionID);
   if(length(subjectDiscriminator)) printf("      conversion:subject_discriminator  \"%s\";\n",subjectDiscriminator);
   if(length(header)) {               
                                    printf("      conversion:enhance [      \n");
                                    printf("         ov:csvRow %s;\n",header);
                                    printf("         a conversion:HeaderRow;\n");
                                    printf("      ];                        \n");
   }
   if(length(dataStart)) {
                                    printf("      conversion:enhance [          \n");
                                    printf("         ov:csvRow %s;\n",dataStart);
                                    printf("         a conversion:DataStartRow; \n");
                                    printf("      ];                            \n");
   }
   if(length(interpretAsNull)) {
                                    printf("      conversion:interpret [          \n");
                                    printf("         conversion:symbol \"%s\";\n",interpretAsNull);
                                    printf("         conversion:intepretation conversion:null; \n");
                                    printf("      ];                            \n");
   }
   if(length(dataEnd)) {
                                    printf("      conversion:enhance [        \n");
                                    printf("         ov:csvRow %s;\n",dataEnd);
                                    printf("         a conversion:DataEndRow; \n");
                                    printf("      ];                          \n");
   }
   }
}
NR == 1 && length(conversionID) {
   for(i=1;i<=NF;i++) {
      label=$i;
      gsub(/"/,"",label);
      (length($i)>0) ? sprintf("\n         ov:csvHeader      \"%s\";",$i) : "";
      print "      conversion:enhance ["
      printf("         ov:csvCol         %s;\n",i)
      printf("         ov:csvHeader     \"%s\";\n",label)
      if(length(conversionID)) {
         printf("         conversion:label \"%s\";\n",label)
      }
      printf("         conversion:range  %s:Literal;\n",RDFS); # this is either 'rdfs' or 'todo' (raw and e1, respectively)
      if( length(onlyIfCol) && onlyIfCol == i ) {
         print "         a conversion:Only_if_column;"
      }
      if( length(repeatAboveIfEmptyCol) && repeatAboveIfEmptyCol == i ) {
         print "         a conversion:Repeat_previous_if_empty_column;"
      }
      print "      ];"
   }
}
END {
   if (showConversionProcess > 0) print "   ];"
   printf(".");
}
