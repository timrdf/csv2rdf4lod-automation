# header2params2.sh
#
# new version of headers2params.sh, processing by line instead of parsing the first line.
#
# Used by $CSV2RDF4LOD_HOME/bin/convert.sh
#
# Parameters:
#
#   -v surrogate
#   -v sourceID
#   -v datasetID
#   -v datasetVersion
#   -v subjectDiscriminator
#   -v conversionID
#
#   -v cellDelimiter
#   -v header
#   -v dataStart
#   -v dataEnd
#
#   -v onlyIfCol
#   -v repeatAboveIfEmptyCol
#   -v interpretAsNull
#
#   -v whoami
#   -v machine_uri
#   -v person_uri

BEGIN { 
   ALWAYS_SHOW_CONVERSION_PROCESS = 1; # Added back in to gather empirical results quantifying "effort" to create e1 params. 
   showConversionProcess = ALWAYS_SHOW_CONVERSION_PROCESS + length(conversionID) + length(subjectDiscriminator) + length(header) + length(dataStart) + length(interpretAsNull) + length(dataEnd);
   #FS=","
   STEP = length(conversionID) ? sprintf("enhancement/%s",conversionID) : "raw";
   TYPE = length(conversionID) ? "Enhancement" : "Raw";
   # TODO: '|' has no length? --\/
          DELIMTER  = length(cellDelimiter) ? cellDelimiter : "	" # <--- that's a tab character.
   commentDELIMITER = length(cellDelimiter) ? ""            : "#";
   #print "#AWK: "length(cellDelimiter)" length cellDelimiter:",cellDelimiter," DELIMITER: ",DELIMITER," comment: ",commentDELIMITER

   if(length(showConversionProcess)) {
      print "@prefix rdf:           <http://www.w3.org/1999/02/22-rdf-syntax-ns#> ."
      print "@prefix rdfs:          <http://www.w3.org/2000/01/rdf-schema#> ."
   }
   RDFS="rdfs"
   if(length(conversionID)) {
      print "@prefix todo:          <http://www.w3.org/2000/01/rdf-schema#> ."
      RDFS="todo"
   }
   print "@prefix xsd:           <http://www.w3.org/2001/XMLSchema#> ."
   if(length(conversionID)) {
      print "@prefix owl:           <http://www.w3.org/2002/07/owl#> ."
      print "@prefix vann:          <http://purl.org/vocab/vann/> ."
      print "@prefix skos:          <http://www.w3.org/2004/02/skos/core#> ."
      print "@prefix time:          <http://www.w3.org/2006/time#> ."
      print "@prefix wgs:           <http://www.w3.org/2003/01/geo/wgs84_pos#> ."
      print "@prefix geonames:      <http://www.geonames.org/ontology#> ."
      print "@prefix geonamesid:    <http://sws.geonames.org/> ."
      print "@prefix govtrackusgov: <http://www.rdfabout.com/rdf/usgov/geo/us/> ."
      print "@prefix dbpedia:       <http://dbpedia.org/resource/> ."
      print "@prefix dbpediaprop:   <http://dbpedia.org/property/> ."
      print "@prefix dbpediaowl:    <http://dbpedia.org/ontology/> ."
      print "@prefix con:           <http://www.w3.org/2000/10/swap/pim/contact#> ."
      print "@prefix muo:           <http://purl.oclc.org/NET/muo/muo#> ."
      print "@prefix vs:            <http://www.w3.org/2003/06/sw-vocab-status/ns#> ."
      print "@prefix frbr:          <http://purl.org/vocab/frbr/core#> ."
      print "@prefix bibo:          <http://purl.org/ontology/bibo/> ."
      print "@prefix prov:          <http://www.w3.org/ns/prov#> ."
      print "@prefix doap:          <http://usefulinc.com/ns/doap#> ."
      print "@prefix nfo:           <http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#> ."
      print "@prefix sio:           <http://semanticscience.org/resource/> ."
      print "@prefix org:           <http://www.w3.org/ns/org#> ."
      print "@prefix vsr:           <http://purl.org/twc/vocab/vsr#> ."
      print "@prefix dcat:          <http://www.w3.org/ns/dcat#> ."
      print "@prefix qb:            <http://purl.org/linked-data/cube#> ."
      print "@prefix pml:           <http://provenanceweb.org/ns/pml#> ."
      print "@prefix dgtwc:         <http://data-gov.tw.rpi.edu/2009/data-gov-twc.rdf#> ."
   }
   print "@prefix dcterms:       <http://purl.org/dc/terms/> ."
   print "@prefix void:          <http://rdfs.org/ns/void#> ."
   print "@prefix scovo:         <http://purl.org/NET/scovo#> ."
   print "@prefix sioc:          <http://rdfs.org/sioc/ns#> ."
   print "@prefix foaf:          <http://xmlns.com/foaf/0.1/> ."
   print "@prefix ov:            <http://open.vocab.org/terms/> ."
   print "@prefix conversion:    <http://purl.org/twc/vocab/conversion/> ."

   # Converter produces URIs for the LayerDatasets:
   #
   # <http://logd.tw.rpi.edu/source/nitrd-gov/dataset/fedRDnetIT/version/2011-Jan-27/conversion/raw>
   # <http://logd.tw.rpi.edu/source/nitrd-gov/dataset/fedRDnetIT/version/2011-Jan-27/conversion/enhancement/1>
   #
   # To make the params more connected to the datasets, we're replacing this:
   #### NOTE: brought this back for a place for implicit bundles to be named, HOWEVER, the dataset is NOT being named within this:
   printf("@prefix :              <%s/source/%s/dataset/%s/version/%s/params/%s/> .\n",surrogate,sourceID,datasetID,datasetVersion,STEP);
   # with this:
   # Still not right; moved down to subject:
   #printf("@prefix :           <%s/source/%s/dataset/%s/version/%s/conversion/%s> .\n",surrogate,sourceID,datasetID,datasetVersion,STEP);


   #
   # Describe the creator.
   #
   # NOTE: user account and person implemented in bin/util/user-account.sh, too.
                                     print
   if( length(machine_uri) && length(whoami) ) {
      if(length(person_uri)) {
                                    printf("<%s> foaf:holdsAccount <%s#%s> .\n",person_uri,   machine_uri,whoami);
      }
                                    printf("<%s#%s>\n   a foaf:OnlineAccount;\n   foaf:accountName \"%s\";\n",machine_uri,whoami,   whoami);
                                    printf("   dcterms:isPartOf <%s>;\n",machine_uri);
      if(length(person_uri)) {
                                    printf("   sioc:account_of  <%s>;\n",person_uri);
      }
                                    printf(".\n");
   }else if(length(person_uri)&&length(whoami)) {
                                    printf("<%s> dcterms:identifier \"%s\" .\n",person_uri,whoami);
   }

   if( length(conversionID)) {       
                                    printf("\n");
                                    printf("#:a_bundle\n");
                                    printf("#   a conversion:ImplicitBundle;\n");
                                    printf("#   conversion:property_name \"a_property\"; # Can also be a URI, e.g. dcterms:title.\n");
                                    printf("#   conversion:name_template \"[/sd]company/[#2]/[r]\";\n");
                                    printf("#   #conversion:type_name     \"My Class\";   # Can also be a URI, e.g. foaf:Person.\n");
                                    printf("#.\n");
   }
   #
   # Describe the dataset.
   #
                                     print
                                    printf("<%s/source/%s/dataset/%s/version/%s/conversion/%s>\n",surrogate,sourceID,datasetID,datasetVersion,STEP);
                                     print "   a conversion:LayerDataset, void:Dataset;\n"
                                    printf("   conversion:base_uri           \"%s\"^^xsd:anyURI;\n",surrogate);
                                    printf("   conversion:source_identifier  \"%s\";\n",sourceID);
                                    printf("   conversion:dataset_identifier \"%s\";\n",datasetID);
                                    printf("   conversion:version_identifier \"%s\";\n",datasetVersion);
   if(!length(conversionID))        printf("   conversion:conversion_identifier \"raw\";\n");
   if( length(conversionID))        printf("   conversion:enhancement_identifier \"%s\";\n",conversionID);
                                     print ""
                                     print "   conversion:conversion_process ["
                                    printf("      a conversion:%sConversionProcess;\n",TYPE);
   if(!length(conversionID))        printf("      conversion:conversion_identifier \"raw\";\n");
   if( length(conversionID))        printf("      conversion:enhancement_identifier \"%s\";\n",conversionID);
   if(length(subjectDiscriminator)) printf("      conversion:subject_discriminator  \"%s\";\n",subjectDiscriminator);

   #
   # Authorship description.
   #
                                     print
   if(length(machine_uri) && length(whoami)) {
                                    printf("      dcterms:creator <%s#%s>;\n",machine_uri,whoami); # NOTE: implemented in bin/util/user-account.sh, too.
   }else if(length(person_uri) && length(whoami)) {
                                    printf("      dcterms:creator [ a foaf:OnlineAccount; foaf:accountName \"%s\";\n",whoami);
                                    printf("                        sioc:account_of <%s> ];\n",person_uri);
   }else if(length(whoami)) {
                                    printf("      dcterms:creator [ a foaf:OnlineAccount; foaf:accountName \"%s\" ];\n",whoami);
   }
   if(length(nowXSD)) {
                                    printf("      dcterms:created \"%s\"^^xsd:dateTime;\n\n",nowXSD);
   }
                                    printf("\n");
                                    printf("      #conversion:enhance [\n");
                                    printf("      #   ov:csvRow 2;\n");
                                    printf("      #   a conversion:DataStartRow;\n");
                                    printf("      #];\n");
                                    printf("\n");
   #
   # Structural enhancement parameters.
   #
   if( cellDelimiter != "\t" ) {
                                    printf("      conversion:delimits_cell \"%s\";\n",cellDelimiter);
                                    printf("      #conversion:delimits_cell \"	\"; # tab\n"); # TODO: Jena likes "\u0009" better.
   }else {
                                    printf("      conversion:delimits_cell \"	\"; # tab\n"); # TODO: Jena likes "\u0009" better.
   }
                                    printf("      #conversion:delimits_cell \"|\";   # pipe\n");
                                    printf("      #conversion:delimits_cell \",\";   # comma\n");
                                    print
   if(length(header)) {               
                                    # Include header info even if just raw.
                                    printf("      conversion:enhance [      \n");
                                    printf("         ov:csvRow %s;\n",header);
                                    printf("         a conversion:HeaderRow;\n");
                                    printf("      ];                        \n\n");
   }
   if(length(dataStart)) {
                                    printf("      conversion:enhance [          \n");
                                    printf("         ov:csvRow %s;\n",dataStart);
                                    printf("         a conversion:DataStartRow; \n");
                                    printf("      ];                            \n");
   }
   comment_out = length(interpretAsNull) && length(conversionID) ? "" : "#"; # We want to put in the template so it is easy to uncomment.
                                    printf("      %sconversion:interpret [\n",                        comment_out);
                                    printf("      %s   conversion:symbol        \"%s\";\n",           comment_out,interpretAsNull);
                                    printf("      %s   conversion:interpretation conversion:null; \n",comment_out);
                                    printf("      %s];\n",                                            comment_out);
   if(length(dataEnd)) {
                                    printf("      conversion:enhance [        \n");
                                    printf("         ov:csvRow %s;\n",dataEnd);
                                    printf("         a conversion:DataEndRow; \n");
                                    printf("      ];                          \n");
   }
                                    printf("      #conversion:enhance [\n");
                                    printf("      #   conversion:domain_template \"thing_[r]\";\n");
                                    printf("      #   conversion:domain_name     \"Thing\";\n");
                                    printf("      #];\n");
                                    printf("      #conversion:enhance [\n");
                                    printf("      #   conversion:class_name \"Thing\";\n");
                                    printf("      #   conversion:subclass_of <http://purl.org/...>;\n");
                                    printf("      #];\n");
}

{ # length(conversionID) {
   cellValue=$0;
   gsub(/"/,"\\\"",cellValue)

   # If we know there is no header, we can give an example value.
   headerOrExample = (length(header) && header <= 0) ? "conversion:eg " : "ov:csvHeader  "; 

   print "      conversion:enhance ["
   printf("         ov:csvCol          %s;\n",NR);
   printf("         %s     \"%s\";\n",headerOrExample,cellValue);
   if(length(conversionID)) { 
      # NOTE: This MUST NOT be added to the raw interpretation parameters,
      #       otherwise columns will collapse together prematurely (with human approval).
      printf("         #conversion:bundled_by [ ov:csvCol 1 ];\n");
      printf("         #conversion:label   \"%s\";\n",cellValue);
      printf("         #conversion:equivalent_property dcterms:identifier;\n");
      printf("         #conversion:subproperty_of      dcterms:identifier;\n");
   }
   printf("         conversion:comment \"\";\n");
   if(length(conversionID)) { 
      printf("         #conversion:range_template  \"[/sd]thing[.]\";\n");
   }
   printf("         conversion:range   %s:Literal;\n",RDFS); # Either 'rdfs' or 'todo' (for raw and e*, respectively)
   if(length(conversionID)) { 
      printf("         #conversion:range_name  \"Thing\";\n");
   }
   if(length(conversionID)) { 
      if( length(onlyIfCol) && onlyIfCol == i ) {
         print "         a conversion:Only_if_column;"
      }
      if( length(repeatAboveIfEmptyCol) && repeatAboveIfEmptyCol == NR ) {
         print "         a conversion:Repeat_previous_if_empty_column;"
      }
   }
   print "      ];"
}

END {
   print "      #conversion:enhance ["
   print "      #   ov:csvRow 3,4,5;"
   print "      #   conversion:fromRow 3;"
   print "      #   conversion:toRow   5;"
   print "      #   a conversion:ExampleResource;"
   print "      #];"

   print "   ];"
   printf(".");
}
