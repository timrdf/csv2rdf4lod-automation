#!/usr/bin/perl

=head1 NAME

lod-transcode.pl - Materialize the files necessary to host slash-based linked data.

=head1 SYNOPSIS

 lod-transcode.pl [OPTIONS] data.rdf http://base /path/to/www

=head1 DESCRIPTION

This script will materialize the necessary files for serving static linked data.
Given an input file data.rdf, this script will find all triples that use a URI
as subject or object that contains the supplied base URI, and serialize the
matching triples to the appropriate files for serving as linked data.

For example, using the input RDF:

 @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
 @prefix db: <http://dbpedia.org/resource/> .
 @prefix prop: <http://dbpedia.org/property/> .
 @prefix dbo: <http://dbpedia.org/ontology/> .
 
 db:Berlin a dbo:City ;
     rdfs:label "Berlin"@en ;
     prop:population 3431700 .
 db:Deutsche_Bahn dbo:locationCity db:Berlin .

Invoking this command:

 lod-transcode.pl -i=turtle data.ttl http://dbpedia.org /var/www

Will produce the files:

 /var/www/data/Berlin.rdf
 /var/www/data/Berlin.ttl
 /var/www/data/Deutsche_Bahn.rdf
 /var/www/data/Deutsche_Bahn.ttl

The process of mapping URIs to files on disk can be configured using the command
line OPTIONS 'uripattern' and 'filepattern':

 lod-materialize.pl --uripattern="/resource/(.*)" --filepattern="/page/\\1" data.rdf http://dbpedia.org /var/www

This will create the files:

 /var/www/page/Berlin.rdf
 /var/www/page/Berlin.ttl
 /var/www/page/Deutsche_Bahn.rdf
 /var/www/page/Deutsche_Bahn.ttl

=head1 OPTIONS

Valid command line options are:

=over 4

=item * -in=FORMAT

=item * -i=FORMAT

Specify the name of the RDF format used by the input file. Defaults to "ntriples".

=item * -out=FORMAT,FORMAT

=item * -o=FORMAT,FORMAT

Specify a comma-seperated list of RDF formats used for serializing the output
files. Defaults to "rdfxml,turtle,ntriples".

=item * --define ns=URI

=item * -D ns=URI

Specify a namespace mapping used by the serializers.

=item * --verbose

Print information about file modifications to STDERR.

=item * -n

Perform a dry-run without modifying any files on disk.

=item * --progress[=N]

Prints out periodic progress of the materialization process. If specified, the
frequency argument N is used to only print the progress information on every Nth
triple.

=item * --concurrency=N

Performs the transcoding of materialized files into secondary RDF formats using
the specified number of threads.

=item * --uripattern=PATTERN

Specifies the URI pattern to match against URIs used in the input RDF. URIs in
the input RDF are matched against this pattern appended to the base URI
(http://base above).

=item * --filepattern=PATTERN

Specifies the path template to use in constructing data filenames. This pattern
will be used to construct an absolute filename by interpreting it relative to
the path specified for the document root (/path/to/www above).

=item * --directoryindex=FILE

If specified, will look for any files created that share a base name with a
created directory (e.g. ./foo.rdf and ./foo/), move the file into the directory,
and rename it to the specified directoryindex FILE name with its original file
extension intact (e.g. ./foo/index.rdf). This will allow Apache's MultiViews
mechanism to properly serve the data.

=item * --apache

Print the Apache configuration needed to serve the produced RDF files as linked
data. This includes setting Multiview for content negotiation, the media type
registration for RDF files and mod_rewrite rules for giving 303 redirects from
resource URIs to the content negotiated data URIs.

=item * --buffer-size=TRIPLES

Specifies the number of output triples to buffer before flushing data to disk.
This can dramatically improve performance as writes to commonly used files can
be aggregated into a single large IO ops instead of many small IO ops.

=back

=cut

use strict;
use warnings;
use threads;

use FindBin qw($Bin);
use File::Copy;
use Fcntl qw(LOCK_EX LOCK_UN);
use File::Spec;
use File::Find;
use File::Path 2.06 qw(make_path);
use Getopt::Long;
use Data::Dumper;
use List::MoreUtils qw(part);
$|				= 1;

my %namespaces;
my $in			= 'ntriples';
my $out			= 'rdfxml,turtle,ntriples';
my $matchre		= q</resource/(.*)>;
my $outre		= '/data/$1';
my $dryrun		= 0;
my $debug		= 0;
my $apache		= 0;
my $count		= 0;
my $threads		= 1;
my $cache_size	= 1;
my $files_per_dir	= 0;
my $dir_index;

my $result	= GetOptions (
	"in=s"			=> \$in,
	"out=s"			=> \$out,
	"define=s"		=> \%namespaces,
	"D=s"			=> \%namespaces,
	"uripattern=s"	=> \$matchre,
	"filepattern=s"	=> \$outre,
	"verbose+"		=> \$debug,
	"n"				=> \$dryrun,
	"progress:1"	=> \$count,
	"apache"		=> \$apache,
	"concurrency|j=s"	=> \$threads,
	"filelimit|L=i"	=> \$files_per_dir,
	"directoryindex=s"	=> \$dir_index,
	"buffer-size|S=i"	=> \$cache_size,
);

if ($in ne 'ntriples') {
	warn "Input for materialization must be ntriples but '$in' requested\n";
	exit(2);
}

unless (@ARGV) {
	print <<"END";
Usage: $0 [OPTIONS] data.rdf http://base /path/to/www/
END
	exit(1);
}

my $file	= shift or die "An RDF filename must be given";
my $url		= shift or die "A URL base must be given";
my $base	= shift or die "A path to the base URL must be given";
my @out		= split(',', $out);
my %files;
my %paths;

if ($url =~ m<[/]$>) {
	chop($url);
}

if ($debug) {
	warn "Input file               : $file\n";
	warn "Input format             : $in\n";
	warn "Output formats           : " . join(', ', @out) . "\n";
	warn "URL Pattern              : $matchre\n";
	warn "File Pattern             : $outre\n";
	warn "Output path              : " . File::Spec->rel2abs($base) . "\n";
	warn "File Limit per Directory : $files_per_dir\n" if ($files_per_dir);
}

my %ext			= ( rdfxml => 'rdf', 'rdfxml-abbrev' => 'rdf', turtle => 'ttl', ntriples => 'nt' );
my @new_formats	= grep { $_ ne 'ntriples' } @out;
my $format_string	= '' . join(' ', map {qq[-f 'xmlns:$_="$namespaces{$_}"']} (keys %namespaces));
if (@new_formats) {
	my $i	= 0;
	my @files;
	find( {
		no_chdir	=> 1,
		wanted		=> sub {
			local($/)	= undef;
			return unless ($File::Find::name =~ /[.]nt$/);
			my $input	= File::Spec->rel2abs( $File::Find::name );
			push(@files, $input);
		}
	}, $base );
	
	if ($threads == 1) {
		transcode_file( 1, \@files );
	} else {
		my @partitions	= part { $i++ % $threads } @files;
		my @threads;
		foreach my $pnum (0 .. $#partitions) {
			my $t	= threads->create( \&transcode_files, $pnum, $partitions[ $pnum ] );
			push(@threads, $t);
		}
		$_->join() for (@threads);
	}
}

sub transcode_files {
	my $process	= shift;
	my $files	= shift;
	my $total	= scalar(@$files);
	foreach my $i (0 .. $#{ $files }) {
		my $filename	= $files->[ $i ];
		if ($dir_index) {
			my ($dir)		= ($filename =~ /^(.*)[.]nt$/);
			if (-d $dir) {
				my $newfilename	= File::Spec->catfile($dir, "${dir_index}.nt");
# 				warn "*** SHOULD RENAME $filename to $newfilename\n";
				rename($filename, $newfilename);
				$filename	= $newfilename;
			}
		}
		
		if ($count) {
			my $num		= $i+1;
			my $perc	= ($num/$total) * 100;
			printf("\rProcess $process transcoding file $num / $total (%3.1f%%)\t\t", $perc);
		}
		foreach my $format (@new_formats) {
			my $ext		= $ext{ $format };
			my $outfile	= $filename;
			$outfile	=~ s/[.]nt/.$ext/;
			
			if (-r $outfile) {
				my $in_mtime	= (stat($filename))[9];
				my $out_mtime	= (stat($outfile))[9];
				if ($out_mtime > $in_mtime) {
# 					warn "*** $filename seems to already have been transcoded to $format\n";
					next;
				}
			}
			
			warn "Creating file $outfile ...\n" if ($debug > 1);
			unless ($dryrun) {
				my $cmd	 = "rapper -q -i ntriples -o $format $format_string $filename";
				open(my $fh, "$cmd|") or do { warn $!; next; };
				open(my $tfh, '>', $outfile) or do { warn $!; next };
				print {$tfh} <$fh>;
			}
		}
	}
	printf("\n");
}
