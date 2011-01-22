NOTE: This writeup has been replaced by the wiki page: https://github.com/timrdf/csv2rdf4lod-automation/wiki





== Installation ==
* run ./install.sh
** this will create source-me.sh and move install.sh into bin
* source source-me.sh (and add this to your shell init like .bashrc)

=== Dependencies ===
* tidy must be installed on your system.
** http://tidy.sourceforge.net/ - for any platform
** versions known to work:
*** HTML Tidy for Mac OS X released on 31 October 2006 - Apple Inc. build 13
*** HTML Tidy for Mac OS X released on 31 October 2006 - Apple Inc. build 15.3

Other dependencies are included in bin/.

=== Test it out ===
* cd data/source/data.gov/
* hit dg (and tab to complete)
** you will see: dg-create-dataset-dir.sh  dg-get-mod-date.sh

run:
$ dg-create-dataset-dir.sh 1492

this queries data.gov for the formats 1492 offers, downloads them, unzips it if it was zipped, and converts any csvs available.

$ cd 1492/version/2010-Jan-21/
$ less automatic/data.gov.FEMAPublicAssistanceSubGrantee.csv.raw.ttl

There is your raw RDF.

$ source convert-1492.sh
$ less automatic/data.gov.FEMAPublicAssistanceSubGrantee.csv.e1.ttl

There is your enhanced RDF. It will look just like your raw RDF, but with a different prediate namespace.

edit manual/data.gov.FEMAPublicAssistanceSubGrantee.csv.e1.params.ttl to be:

      conversion:enhance [
         ov:csvCol         2;
         ov:csvHeader     "Declaration Date";
         conversion:label "Declaration Date";
         conversion:range  xsd:date;             
         conversion:date_pattern "MM/dd/yyyy";
         conversion:bundled_by [ ov:csvCol 1 ];
      ];

$ source convert-1492.sh
$ less automatic/data.gov.FEMAPublicAssistanceSubGrantee.csv.e1.ttl

see 

ds1492:thing_1 
   e1:disaster_number  "1239" ;
   e1:declaration_date "1998-08-26"^^xsd:date ;

and pat yourself on the back.

continue to edit manual/data.gov.FEMAPublicAssistanceSubGrantee.csv.e1.params.ttl and source convert-1492.sh until you are satisfied with automatic/data.gov.FEMAPublicAssistanceSubGrantee.csv.e1.ttl.

Check out http://data-gov.tw.rpi.edu/wiki/URI_design_for_RDF_conversion_of_CSV-based_data for enrichment parameter documentation and examples.
Check out http://data-gov.tw.rpi.edu/wiki/Csv2rdf4lod for documentation on Java version of converter.

== If you're brave ==
If you want to grab all of the data.gov data (~80GB) and run raw conversions on all csvs that appear,

* cd data/source/data.gov/

* head -10 ../../../doc/lists/data.gov-dataset-identifiers.txt | xargs -n 1 -P 2 dg-create-dataset-dir.sh
(that was just for practice)

* cat      ../../../doc/lists/data.gov-dataset-identifiers.txt | xargs -n 1 -P 2 dg-create-dataset-dir.sh
(that'll do all 1700 of them)

change "-P 2" to however many cpu cores you have (or however many parallel executions you want).

If you want only csv data and trust datasets-returning-csv.csv,
* cat      ../../../doc/lists/datasets-returning-csv.csv | xargs -n 1 -P 2 dg-create-dataset-dir.sh 
