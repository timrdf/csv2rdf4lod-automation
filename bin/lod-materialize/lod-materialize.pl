#!/usr/bin/perl

=head1 NAME

lod-materialize.pl - Materialize the files necessary to host slash-based linked data.

=head1 SYNOPSIS

 lod-materialize.pl [OPTIONS] data.rdf http://base /path/to/www

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

 lod-materialize.pl -i=turtle data.ttl http://dbpedia.org /var/www

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

use File::Copy;
use Fcntl qw(LOCK_EX LOCK_UN);
use RDF::Trine;
use File::Spec;
use File::Path 2.06 qw(make_path);
use Getopt::Long;
use Data::Dumper;
use List::MoreUtils qw(part);

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

unless (@ARGV) {
	print <<"END";
Usage: $0 [OPTIONS] data.rdf http://base /path/to/www/
END
	exit;
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

if ($apache) {
	print "\n# Apache Configuration:\n";
	print "#######################\n";
	my $match	= substr($matchre,1);
	my $redir	= $outre;
	$redir		=~ s/\\(\d+)/\$$1/g;
	if ($dir_index) {
		print "DirectoryIndex $dir_index\n\n";
	}
	print <<"END";
Options +MultiViews
AddType text/turtle .ttl
AddType text/plain .nt
AddType application/rdf+xml .rdf

RewriteEngine On
RewriteBase /
RewriteRule ^${match}\$ $redir [R=303,L]
#######################

END
	exit;
}

$|						= 1;
my $parser				= RDF::Trine::Parser->new( $in );
my $serializer			= RDF::Trine::Serializer->new( 'ntriples', namespaces => \%namespaces );
my $files_created		= 0;
my $triples_processed	= 0;
my $flushes				= 0;
my %files_per_dir;
my %output_cache;
my $cached_triples;
open( my $fh, '<:utf8', $file ) or die "Can't open RDF file $file: $!";
my %bnode_heads;
my $bnode_model			= RDF::Trine::Model->temporary_model;
$parser->parse_file( 'http://base/', $fh, \&handle_triple );
flush_data();
print_progress();

warn "Blank Node model has size " . $bnode_model->size . "\n" if ($debug);
if ($bnode_model->size > 0) {
	my %seen;
	my $iter	= $bnode_model->as_stream;
	while (my($uri, $bnodes) = each(%bnode_heads)) {
		foreach my $blank (@$bnodes) {
			next if ($seen{ $blank->as_string }++);
			my $bditer	= $bnode_model->bounded_description( $blank );
			while (my $t = $bditer->next) {
				next if ($t->subject->isa('RDF::Trine::Node::Resource') and $t->subject->uri_value eq $uri);
				next if ($t->object->isa('RDF::Trine::Node::Resource') and $t->object->uri_value eq $uri);
				cond_add_triple_for_node( $t, RDF::Trine::Node::Resource->new($uri) );
			}
		}
	}
	flush_data();
	print_progress();
}
print "\n" if ($count);



my %serializers;
foreach my $s (@out) {
	$serializers{ $s }	= RDF::Trine::Serializer->new( $s, namespaces => \%namespaces );
}

my @new_formats	= grep { $_ ne 'ntriples' } keys %serializers;
my %ext			= ( rdfxml => 'rdf', turtle => 'ttl', ntriples => 'nt' );
if (@new_formats) {
	my @files : shared;
	@files	= sort keys %files;
	my $i	= 0;
	if ($threads == 1) {
		transcode_files( 1, \@files );
	} else {
		my @partitions	= part { $i++ % $threads } @files;
		my @threads;
		foreach my $pnum (0 .. $#partitions) {
			my $t	= threads->create( \&transcode_files, $pnum, $partitions[ $pnum ] );
			push(@threads, $t);
	#		transcode_files( $pnum, $partitions[ $pnum ] );
		}
		
		$_->join() for (@threads);
	}
	print "\n" if ($count);
}
if (defined($dir_index)) {
	foreach my $f (keys %files) {
		my $abs	= File::Spec->rel2abs($f);
		$abs	=~ s/[.]nt//;
		my $dir	= $abs;
		if (-d $dir) {
			foreach my $f2 (glob("${abs}.*")) {
				my ($ext)	= $f2 =~ /.*[.](.*)$/ or do { warn $f2; next };
				my $new	= File::Spec->catfile( File::Spec->rel2abs( $dir ), $dir_index . ".$ext" );
				if ($debug > 1) {
					my $f2rel	= File::Spec->abs2rel( $f2 );
					my $newrel	= File::Spec->abs2rel( $new );
					warn "Renaming $f2rel -> $newrel\n";
				}
				unless ($dryrun) {
					copy($f2, $new) or warn "Failed to copy $f2 to $new: $!";
				}
			}
		}
	}
}

sub transcode_files {
	my $process	= shift;
	my $files	= shift;
	my $total	= scalar(@$files);
	foreach my $i (0 .. $#{ $files }) {
		my $filename	= $files->[ $i ];
		if ($count) {
			my $num		= $i+1;
			my $perc	= ($num/$total) * 100;
			printf("\rProcess $process transcoding file $num / $total (%3.1f%%)\t\t", $perc);
		}
		my $parser	= RDF::Trine::Parser->new('ntriples');
		my $store	= RDF::Trine::Store::DBI->temporary_store;
		my $model	= RDF::Trine::Model->new( $store );
		warn "Parsing file $filename ...\n" if ($debug > 1);
		unless ($dryrun) {
			open( my $fh, '<:utf8', $filename ) or do { warn $!; next };
			$parser->parse_file_into_model( $url, $fh, $model );
		}
		while (my($name, $s) = each(%serializers)) {
			my $ext	= $ext{ $name };
			my $outfile	= $filename;
			$outfile	=~ s/[.]nt/.$ext/;
			warn "Creating file $outfile ...\n" if ($debug > 1);
			unless ($dryrun) {
				open( my $out, '>:utf8', $outfile ) or do { warn $!; next };
				flock( $out, LOCK_EX );
				$s->serialize_model_to_file( $out, $model );
				flock( $out, LOCK_UN );
			}
		}
		
		unless (exists $serializers{'ntriples'}) {
			warn "Removing file $filename ...\n" if ($debug > 1);
			unless ($dryrun) {
				unlink($filename);
			}
		}
	}
}

sub handle_triple {
	my $st	= shift;
	$triples_processed++;
# 	warn "parsing triple: " . $st->as_string . "\n";
	my $bnode	= 0;
	my @added;
	my @bnodes;
	foreach my $pos (qw(subject object)) {
		my $obj	= $st->$pos();
		if ($obj->isa('RDF::Trine::Node::Blank')) {
			$bnode	= 1;
			push(@bnodes, $obj);
		}
		my $add	= cond_add_triple_for_node( $st, $obj );
		if ($add) {
			push(@added, $obj);
		}
	}
	
	if ($bnode) {
		$bnode_model->add_statement( $st );
		foreach my $u (@added) {
			push( @{ $bnode_heads{ $u->uri_value } }, @bnodes );
		}
	}
	
	if ($count) {
		if ($triples_processed % $count == 0) {
			print_progress();
		}
	}
}

sub cond_add_triple_for_node {
	my $st	= shift;
	my $obj	= shift;
	return unless ($obj->isa('RDF::Trine::Node::Resource'));
	my $uri	= $obj->uri_value;
	return unless (my @matched = $uri =~ qr/^${url}$matchre/);
# 		my ($source, $dataset, $version, $thing)	= ($1, $2, $3, $4);
# 		my $path		= File::Spec->catdir( $base, source => $source, 'file', dataset => $dataset, version => $version );
	
	my $file	= $outre;
	foreach my $i (1 .. scalar(@matched)) {
		while ($file =~ m/(\$|\\)$i/) {
			$file	=~ s/(\$|\\)$i/$matched[$i-1]/;
		}
	}
	(undef, my $path, my $thing)	= File::Spec->splitpath( File::Spec->catfile( $base, $file ) );
	unless ($paths{ $path }) {
		warn "Creating directory $path ...\n" if ($debug > 1);
		$paths{ $path }++;
		$files_per_dir{ $path }	= 0;
		unless ($dryrun) {
			make_path( $path );
		}
	}
	
	my $filename	= File::Spec->catfile( $path, "${thing}.nt" );
	unless ($files{ $filename }) {
		unless (-w $filename) {
			warn "Creating file $filename ...\n" if ($debug > 1);
			$files_per_dir{ $path }++;
			if ($files_per_dir > 0 and $files_per_dir{ $path } > $files_per_dir) {
				warn "*** Hit maximum file limit in directory $path. Materialized data will be incomplete.\n";
				next;
			}
			$files_created++;
		}
		$files{ $filename }++;
	}
	unless ($dryrun) {
		unless (exists $output_cache{ $filename }) {
			$output_cache{ $filename }	= [];
		}
		push(@{$output_cache{ $filename }}, $st);
		$cached_triples++;
		
		if ($cached_triples >= $cache_size) {
			flush_data();
		}
	}
	return 1;
}

sub flush_data {
	my $output	= scalar(@{ [ keys %output_cache ] });
	if ($output) {
		$flushes++;
		while (my($filename,$array) = each(%output_cache)) {
			open( my $fh, '>>:utf8', $filename ) or do { warn "*** Failed to open $filename for append: $!"; next };
			flock( $fh, LOCK_EX );
			$serializer->serialize_iterator_to_file( $fh, RDF::Trine::Iterator::Graph->new($array) );
			flock( $fh, LOCK_UN );
		}
	}
	%output_cache	= ();
	$cached_triples	= 0;
}

sub print_progress {
	my $files_touched	= scalar(@{ [ keys %files ] });
	print "\r${triples_processed}T / ${files_touched}F / ${files_created}N / ${flushes}W";
}
