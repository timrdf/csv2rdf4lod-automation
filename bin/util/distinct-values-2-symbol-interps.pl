#!/usr/bin/perl
#
#

use File::Basename;
use RDF::Query::Client;
use Data::Dumper;

my $USAGE = sprintf("usage: %s --endpoint sparql-endpoint --graph named-graph --predicate predicate-uri\n",basename($0));

die $USAGE unless $#ARGV == 5;

my $endpoint  = $ARGV[1];
my $graph     = $ARGV[3];
my $predicate = $ARGV[5];

my $queryString = <<"END";
select distinct ?o
where { 
  graph <$graph> {
   ?s <$predicate> ?o
  } 
}
END

my $query = new RDF::Query::Client($queryString);

my $iterator = $query->execute($endpoint);
while (my $row = $iterator->next) {
   #$row->{'o'}->as_string;
   #my sym = $row->{'o'};
   printf("         conversion:interpret [\n",$row->{'o'});
   printf("            conversion:symbol         %s;\n",$row->{'o'}->as_string);
   printf("            conversion:interpretation %s;\n",$row->{'o'}->as_string);
   print  "         ];\n";
   #warn Dumper($row->{'o'}); # This will dump the contents of the reference.
   #warn ref $row->{'o'} # This will get just the class name of the instance.
} 


my $tinyscalar = 'blah';
my %dictionary = ('one', 1, 'two', 2);
my @superarray = [1,2,3];

#print $dictionary{'one'};
#print $dictionary = @superarray[1]; 
