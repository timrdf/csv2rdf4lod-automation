#!/usr/bin/perl
# Duplicate unix' tee command for stderr instead of stdin

use File::Basename;

my $USAGE = sprintf("usage: %s [-a] <file>\n",basename($0));

die $USAGE unless $#ARGV == 0 || $#ARGV == 1;

my $appendOrNot = $ARGV[0] == "-a" ? ">>" : ">";

my $outFile = $ARGV[$#ARGV];

die $! unless open(OUTFILE,$appendOrNot,$outFile);

while (defined($line = <STDIN>)) {
   print($line);
   print OUTFILE $line   
}

close(OUTFILE);
