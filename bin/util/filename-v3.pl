#!/usr/bin/perl

# I've attached a new debugging version that will spit out the redirect info 
# so you can get an idea of what's going on. If the chain ends in an ftp address,
# it'll also spit out some ftp errors (because you can't do a HEAD request over ftp). 
#   -greg

use strict;
use warnings;
use URI;
use Data::Dumper;
use LWP::UserAgent;

unless (@ARGV) {
	warn "Usage: $0 URL\n\n";
	exit 1;
}

my $url	= shift;
my $ua	= LWP::UserAgent->new( max_redirect => 0 );

my %seen;
while (1) {
	if ($seen{ $url }++) {
		warn "Found a redirect loop. Exiting.\n";
		exit -1;
	}
	my $resp = $ua->head($url);
	unless ($resp) {
		warn "Failed to HEAD $url\n";
		exit;
	}
	my $loc		= $resp->header( 'Location' );
	my $redir	= URI->new_abs( $loc, $url )->as_string;
	warn $resp->status_line . (defined($redir) ? " (location: " . $redir . ")" : '') . "\n";
	if ($resp->is_redirect) {
		$url		= $redir;
		next;
	}
	last;
}

print "$url\n";
