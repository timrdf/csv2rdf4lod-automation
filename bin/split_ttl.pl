#!/usr/bin/perl

use strict;
use warnings;
use File::Spec;

my $counter = 0;

while (my $file = shift) {
(undef, my $dir, my $f) = File::Spec->splitpath($file);
$dir  = '.' if ($dir eq '');
open( my $fh, '<', $file ) or die "$!: $file";

my $out;
my $outfile = File::Spec->catfile($dir, "cHuNk-${f}-$counter.ttl");
unless (-r $outfile) {
   open( $out, '>', $outfile ) or die "$!: $outfile";
}
while (defined($_ = <$fh>)) {
   next unless ($out);
   if (/prefix rdf: /) {
      close($out);
      $out  = undef;
      $counter++;
      $outfile = File::Spec->catfile($dir, "cHuNk-${f}-$counter.ttl");
      if (-r $outfile) {
         next;
      } else {
         open($out, '>', $outfile) or die "$!: $outfile";
      }
   }
   print {$out} $_;
}
$counter++;
}

