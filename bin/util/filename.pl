#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use LWP::UserAgent;

my $url	= shift;
my $ua	= LWP::UserAgent->new( max_redirect => 0 );

while (1) {
	my $resp = $ua->head($url);
	unless ($resp) {
		warn "Failed to HEAD $url\n";
		exit;
	}
	if ($resp->is_redirect) {
		my $redir	= $resp->header( 'Location' );
		$url		= $redir;
		next;
	}
	last;
}

print "$url\n";
