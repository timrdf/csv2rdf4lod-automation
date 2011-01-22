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

== Script descriptions ==
dg-create-dataset-dir.sh
* Sets up the directory structure, 
* queries data.gov for formats, 
* retrieves all but rdf, 
* unzips files, and 
* sets up the convert script.
* Uncommenting one line in bin/dg-create-dataset-dir.sh  will also run the raw conversion. (search for "NOTE" and follow the instructions)

cr-create-convert-sh.sh 
* You will only need to use this manually if data.gov does not return *.csv files

dg-get-mod-date.sh 
* You will rarely need this to convert csv data. Run with a data.gov datasetID to get the web server modificationd date.

== Known bugs and limitations ==
The shell scripts assume sh/bash. (naive mistake, I know...)
Filenames with spaces in the source/ directory cause problems when creating the convert-VVV.sh. The automation breaks down, but can be fixed manually by using cr-create-convert-sh.sh:
** cr-create-convert-sh.sh -w source/*.csv  

"the last 5 minutes the program has been working (pcurl) without reporting anything."
** pcurl.sh requests modification dates from the web servers, which tend to take a while to respond.

The converter outputs ttl and rapper cannot parse turtle files >2GB.
* this will not break batch processing with other datasets; it will just fail to contribute the big dataset's RDF.
* From data.gov/, "find */version/*/automatic -size +1900M" to find output files that rapper will fail to parse.
* split_ttl.pl will take a list of files (do all in automatic/ at same time to avoid overwriting) and split them into "chunk-FILENAME-NNN.ttl"
* "du -sch *.raw.ttl | tail -1" will show file size of all raw ttl
* "du -sch chunk* | tail -1" will show file size of all chunked versions
* when everything is split, re-running dg-publish-raw.sh will pick up the chunks and fail silently on the unchunked.

"Can't locate RDF/Trine.pm" when running lod-materialize
* run the script with perl instead of running the script directly ("purl lod-materialize.pl" instead of "./lod-materialize.pl")
