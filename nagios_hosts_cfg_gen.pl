#!/usr/bin/perl

use strict;
use Term::ReadKey;

my $debug;
if (@ARGV == 1) {
      $debug = 1;
}
$| = 0;
#
# sort of global vars
my $nagioscfgpath = "/etc/nagios/configs";
my $nagiosbasename = "-hosts.cfg";
my $tier;

print "Enter a stack name: ";
my $stack = ReadLine(0);
chomp $stack;
my $lstack = lc($stack);

print "Enter the name of the server list text file: ";
my $inputfile = ReadLine(0);
chomp $inputfile;

open ('FH', "<$inputfile") or die "Can't open $inputfile for reading:$!";

my $outputfile = $nagioscfgpath . "/" . $stack . "/" . $lstack . $nagiosbasename;
if ($debug) {
   $outputfile = "test.cfg";
}
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
     # pull the ip address out of the hostname for Amazon EC2
     ($ip = $fqdn) =~ s/^ec2-(\d+)-(\d+)-(\d+)-(\d+).*?$/$1.$2.$3.$4/;
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

      print OFH "define host{" . "\n";
      print OFH "\thost_name\t$hostname\n";
      print OFH "\tuse\t\t" . $stack . "-Generic-Host\n";
      print OFH "\talias\t\t" . $alias . "\n";
      print OFH "\taddress\t\t" . $ip . "\n"; 
      print OFH "}\n";
      return;
}

