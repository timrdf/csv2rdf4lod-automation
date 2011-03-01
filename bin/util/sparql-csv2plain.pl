#!/usr/bin/perl

my $filename   = shift;
if (-r $filename and $filename =~ m{[.]csv}) {
   my $outfilename   = $filename;
   $outfilename   =~ s/csv$/plain/;
   use Text::CSV;
   my $csv = Text::CSV->new( { binary => 1 } ) or die "Cannot use CSV: ".Text::CSV->error_diag ();
   open( my $fh, "<:utf8", $filename ) or die "$filename: $!";
   $csv->getline($fh);
   my $row = $csv->getline($fh);
   my $value   = $row->[0];
   $value      =~ s/^["<](.*)[">]$/$1/g;
   open(my $out, '>:utf8', $outfilename) or die "Cannot open $outfilename: $!";
   print $out $value;
}
