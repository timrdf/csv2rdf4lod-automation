# header2params2.sh
#
# new version of headers2params.sh, processing by line instead of parsing the first line.
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
#
# -v whoami
# -v machine_uri
# -v person_uri

BEGIN { 
   showConversionProcess = length(conversionID) + length(subjectDiscriminator) + length(header) + length(dataStart) + length(interpretAsNull) + length(dataEnd);
   FS=","
   STEP = length(conversionID) ? sprintf("enhancement/%s",conversionID) : "raw";
   TYPE = length(conversionID) ? "Enhancement" : "Raw";
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
      print "@prefix owl:        <http://www.w3.org/2002/07/owl#> ."
      print "@prefix vann:       <http://purl.org/vocab/vann/> ."
      print "@prefix skos:       <http://www.w3.org/2004/02/skos/core#> ."
      print "@prefix time:       <http://www.w3.org/2006/time#> ."
      print "@prefix wgs:        <http://www.w3.org/2003/01/geo/wgs84_pos#> ."
      print "@prefix geonames:   <http://www.geonames.org/ontology#> ."
      print "@prefix dbpedia:    <http://dbpedia.org/resource/> ."
      print "@prefix con:        <http://www.w3.org/2000/10/swap/pim/contact#> ."
      print "@prefix muo:        <http://purl.oclc.org/NET/muo/muo#> ."
   }
   print "@prefix dcterms:    <http://purl.org/dc/terms/> ."
   print "@prefix void:       <http://rdfs.org/ns/void#> ."
   print "@prefix scovo:      <http://purl.org/NET/scovo#> ."
   print "@prefix sioc:       <http://rdfs.org/sioc/ns#> ."
   print "@prefix foaf:       <http://xmlns.com/foaf/0.1/> ."
   #if(showConversionProcess>0) {
      print "@prefix ov:         <http://open.vocab.org/terms/> ."
   #}
   print "@prefix conversion: <http://purl.org/twc/vocab/conversion/> ."

   # Converter produces URIs for the LayerDatasets:
   #
   # <http://logd.tw.rpi.edu/source/nitrd-gov/dataset/fedRDnetIT/version/2011-Jan-27/conversion/raw>
   # <http://logd.tw.rpi.edu/source/nitrd-gov/dataset/fedRDnetIT/version/2011-Jan-27/conversion/enhancement/1>
   #
   # To make the params more connected to the datasets, we're replacing this:
   #### NOTE: brought this back for a place for implicit bundles to be named, HOWEVER, the dataset is NOT being named within this:
   printf("@prefix :           <%s/source/%s/dataset/%s/version/%s/params/%s/> .\n",surrogate,sourceID,datasetID,datasetVersion,STEP);
   # with this:
   # Still not right; moved down to subject:
   #printf("@prefix :           <%s/source/%s/dataset/%s/version/%s/conversion/%s> .\n",surrogate,sourceID,datasetID,datasetVersion,STEP);

                                     print
   # NOTE: user account and person implemented in bin/util/user-account.sh, too.
   if( length(machine_uri) && length(whoami) ) {
      if(length(person_uri)) {
                                    printf("<%s> foaf:holdsAccount <%s%s> .\n",person_uri,   machine_uri,whoami);
      }
                                    printf("<%s%s>\n   a foaf:OnlineAccount;\n   foaf:accountName \"%s\";\n",machine_uri,whoami,   whoami);
                                    printf("   dcterms:isPartOf <%s>;\n",machine_uri);
      if(length(person_uri)) {
                                    printf("   sioc:account_of  <%s>;\n",person_uri);
      }
                                    printf(".\n");
   }else if(length(person_uri)&&length(whoami)) {
                                    printf("<%s> dcterms:identifier \"%s\" .\n",person_uri,whoami);
   }
                                     print
                                    printf("<%s/source/%s/dataset/%s/version/%s/conversion/%s>\n",surrogate,sourceID,datasetID,datasetVersion,STEP);
                                     print "   a conversion:LayerDataset, void:Dataset;"
                                    printf("   conversion:base_uri           \"%s\"^^xsd:anyURI;\n",surrogate);
                                    printf("   conversion:source_identifier  \"%s\";\n",sourceID);
                                    printf("   conversion:dataset_identifier \"%s\";\n",datasetID);
                                    printf("   conversion:version_identifier \"%s\";\n",datasetVersion);
                                    #printf("   conversion:dataset_version    \"%s\"; # DEPRECATED in favor of version_identifier\n",datasetVersion);
   if(showConversionProcess > 0) {
                                     print "   conversion:conversion_process ["
                                    printf("      a conversion:%sConversionProcess;\n",TYPE);
   if(length(conversionID))         printf("      conversion:enhancement_identifier \"%s\";\n",conversionID);
   if(length(subjectDiscriminator)) printf("      conversion:subject_discriminator  \"%s\";\n",subjectDiscriminator);
                                     print
   if(length(person_uri)&&length(machine_uri)&&length(whoami)) { # NOTE: implemented in bin/util/user-account-cite.sh, too.
                                    printf("      dcterms:creator <%s%s>;\n",machine_uri,whoami);
   }else if(length(machine_uri) && length(whoami)) {
                                    printf("      dcterms:creator <%s%s>;\n",machine_uri,whoami); # TODO: same as above.
   }else if(length(person_uri)  && length(whoami)) {
                                    printf("      dcterms:creator [ a foaf:OnlineAccount; foaf:accountName \"%s\";\n",whoami);
                                    printf("                        sioc:account_of <%s> ];\n",person_uri);
   }else if(length(whoami)) {
                                    printf("      dcterms:creator [ a foaf:OnlineAccount; foaf:accountName \"%s\" ];\n",whoami);
   }
   if(length(nowXSD)) {
                                    printf("      dcterms:created \"%s\"^^xsd:dateTime;\n",nowXSD);
   }
   if(length(header)) {               
   # TODO: include header info even if just raw.
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
   } # END if(showConversionProcess > 0)
}

length(conversionID) { #NR == 1 && length(conversionID) {
      label=$0;
      (length(label)>0) ? sprintf("\n         ov:csvHeader      \"%s\";",label) : "";
      print "      conversion:enhance ["
      printf("         ov:csvCol         %s;\n",NR)
      printf("         ov:csvHeader     \"%s\";\n",label) # TODO: if HeaderRow == 0, s/csvHeader/eg/
      if(length(conversionID)) {
         printf("         conversion:label \"%s\";\n",label);
         printf("         conversion:comment \"\";\n");
      }
      printf("         conversion:range  %s:Literal;\n",RDFS); # this is either 'rdfs' or 'todo' (raw and e1, respectively)
      if( length(onlyIfCol) && onlyIfCol == i ) {
         print "         a conversion:Only_if_column;"
      }
      if( length(repeatAboveIfEmptyCol) && repeatAboveIfEmptyCol == NR ) {
         print "         a conversion:Repeat_previous_if_empty_column;"
      }
      print "      ];"
   #}
}

END {
   if (showConversionProcess > 0) print "   ];"
   printf(".");
}
