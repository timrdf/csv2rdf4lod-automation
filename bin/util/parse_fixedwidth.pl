#!/usr/bin/perl

use strict;
use warnings;
use Text::CSV;
use Data::Dumper;

unless (scalar(@ARGV) == 2) {
	warn <<"END";
Usage: $0 fields.csv data.txt

fields.csv should be in CSV format, and include a single header line giving the
order of columns and must include the fields: NAME, LEN, START, and DESCRIPTION.
Every line after the header describes a fixed-width field in data.txt. The
value of START is the starting character position on the line where the field
value begins (a value of 1 means the first character on the line), and the value
of LEN is the character length of the field.

Every line in data.txt is parsed according to the fields parsed from fields.csv.
A single header line is output in CSV format listing each field NAME as it
appeared in fields.csv. Whitespace at the beginning and end of each field value
is removed, and a record corresponding to each line is output in CSV format in
the same order that fields appear in fields.csv.

END
	exit;
}

my ($fields, $data)	= @ARGV;

open( my $ffh, '<', $fields ) or die $!;
open (my $dfh, '<', $data ) or die $!;

my @field_data	= read_fields( $ffh );
parse_data( $dfh, \@field_data );

sub parse_data {
	my $dfh			= shift;
	my $field_data	= shift;
	my $line;
	
	my @columns	= map { $_->{NAME} } @$field_data;
	my $csv		= Text::CSV->new({binary => 1 });
	my $status	= $csv->combine(@columns);    # combine columns into a string
	my $csvline	= $csv->string();             # get the combined string
	print $csvline . "\n";
	
	while (defined(my $line = <$dfh>)) {
		chomp($line);
		next if ($line =~ m/^#/);
		my %record;
		foreach my $f (@$field_data) {
			my $name	= $f->{ 'NAME' };
			my $start	= 0+$f->{ 'START' } - 1;	# data file uses ordinal-1 (but substr uses 0)
			my $len		= 0+$f->{ 'LEN' };
			my $value	= substr($line, $start, $len);
			$value		=~ s/\s+$//;
			$value		=~ s/^\s+//;
			chomp($value);
			$record{ $name }	= $value;
		}
		
		
		my $status	= $csv->combine(@record{ @columns });    # combine columns into a string
		my $csvline	= $csv->string();                        # get the combined string
		print $csvline . "\n";
	}
}

sub read_fields {
	my $ffh		= shift;
	my $line;
	my $csv		= Text::CSV->new({binary => 1 });
	do { $line = <$ffh> } while ($line =~ m/^#/);	# skip past comment lines
	my $status 	= $csv->parse($line);        		# parse a CSV string into fields
	my @fields	= $csv->fields();            		# get the parsed fields
	my %fields	= map { $_ => 1 } @fields;
	
	foreach my $field (qw(NAME LEN START DESCRIPTION)) {
		unless ($fields{$field}) {
			die "Fields file doesn't seem to have a $field column";
		}
	}
	
	my @field_data;
	while (defined($line = <$ffh>)) {
		my $status 	= $csv->parse($line);        # parse a CSV string into fields
		my @columns	= $csv->fields();            # get the parsed fields
		my %data;
		@data{ @fields }	= @columns;
		push(@field_data, \%data);
	}
	
	return @field_data;
}
