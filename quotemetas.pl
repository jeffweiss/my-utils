#!/usr/bin/perl

use strict;

while (<>) {
	chomp;
	my $line = $_;
	$line =~ s/\s+/\\s/g;
	print $line, "\n";

}

