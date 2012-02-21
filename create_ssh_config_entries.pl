#!/usr/bin/perl

use strict;

while (<>) {
   
   chomp;
   my $hostname = $_;
   next if($hostname =~ /^\#/);
   my ($host) = split(/\./, $hostname);
   print "Host " . $host . "\n";
   print "   User surma\n";
   print "   HostName ", $hostname, "\n";
   print "   Port 22\n";
   print "   IdentityFile ~/.shh/id_rsa\n";
   print "   ForwardAgent yes\n" if ($host =~ /redmars|plateng8/);
   last if (eof());
   print "\n";
}
