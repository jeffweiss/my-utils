#!/usr/bin/perl

use strict;

$| = 0;
my $nagioscfgpath = "/etc/nagios/configs";
my $nagiosbasename = "-hosts.cfg";

print "Enter a stack name: ";
my $stack = <>;
chomp $stack;
my $lstack = lc($stack);
print $lstack, "\n";

print "Enter the name of the server list text file: ";
my $inputfile = <>;
chomp $inputfile;
open ('FH', "<$inputfile") or die "Can't open $inputfile for reading:$!";
my $tier;

my $outputfile = $nagioscfgpath . "/" . $stack . "/" . $lstack . $nagiosbasename;

$outputfile = "test.cfg";

open OFH, ">>$outputfile" or die "Can't open $outputfile: $!";

while (<FH>) {
     chomp;
     my $line = $_;
     if ($line =~ /^\[(.*?)\]/) {
          $tier = $1;
          print OFH "#$stack $tier\n";
          next;
     }
     my ($friendlyname, $fqdn) = split /\t+/, $line;
     my $ip;
     ($ip = $fqdn) =~ s/^ec2-(\d+)-(\d+)-(\d+)-(\d+).*?$/$1.$2.$3.$4/;
     print "$ip == $fqdn\n";
     printConfigData($friendlyname, $fqdn, $ip);
}
close ('OFH');
close ('FH');

sub printConfigData {

      my $hostname = shift;
      my $fqdn = shift;
      my $ip = shift;

      my $alias;
      ($alias = $hostname) =~ s/-/\ /g; 
      print $alias, "\n";

      print OFH "define host{" . "\n";
      print OFH "\thost_name\t$hostname\n";
      print OFH "\tuse\t\t" . $stack . "-Generic-Host\n";
      print OFH "\talias\t\t" . $alias . "\n";
      print OFH "\taddress\t\t" . $ip . "\n"; 
      print OFH "}\n";
      return;
}

