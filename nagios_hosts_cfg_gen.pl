#!/usr/bin/perl

use strict;
use Term::ReadKey;
use Net::Amazon::EC2;
use Data::Dumper;

#
#
# begin globals vars section
my ($ip_address, $hostname, $alias, $tier);
my $debug;
if (@ARGV == 1) {
      $debug = 1;
}

my $nagioscfgpath = "/etc/nagios/configs";
my $nagiosbasename = "-hosts.cfg";
# end global vars section
#
# set STDOUT buffer to flush immediately
$| = 0;
# Read in some stuff from the command line
# hopefully it is correct but if not we will fail the run.
print "Enter a stack name: ";
my $stack = ReadLine(0);
chomp $stack;
my $lstack = lc($stack);

my $outputfile = $nagioscfgpath . "/" . $stack . "/" . $lstack . $nagiosbasename;
if ($debug) {
   $outputfile = "test.cfg";
}


# Connect to EC2 with my credentials and get me the stuff I need.
#
my $ec2 = Net::Amazon::EC2->new(
	AWSAccessKeyId => 'YourAWSPublicKey',
	SecretAccessKey => 'YourAWSPrivateKey',
);

my $running_instances = $ec2->describe_instances;
# Now that we have the EC2 object open the output file handle
open OFH, ">>$outputfile" or die "Can't open $outputfile: $!";

foreach my $reservation (@$running_instances) {
	foreach my $instance ($reservation->instances_set) {
		#$fqdn = $instance->dns_name;
		$ip_address = $instance->ip_address;
		for (my $i = 0; $i < scalar(@{$instance->tag_set}); $i++) {
			if ($instance->tag_set->[$i]->key =~ /Name/) {
				$hostname = $instance->tag_set->[$i]->value;
			}
		}
		for (my $i = 0; $i < scalar(@{$instance->tag_set}); $i++) {
			if ($instance->tag_set->[$i]->key =~ /Tier/) {
				$tier = $instance->tag_set->[$i]->value;
			}
		}
	}
  printConfigData($hostname, $ip_address, $tier, $stack);
}
close ('OFH');

sub printConfigData {

      my $hostname = shift;
      my $ip = shift;
      my $tier = shift;
      my $stack = shift;
      my $alias;

      ($alias = $hostname) =~ s/-/\ /g; 

      print OFH "# Defining host entry for $hostname of $stack in $tier\n";
      print OFH "define host{" . "\n";
      print OFH "\thost_name\t$hostname\n";
      print OFH "\tuse\t\t" . $stack . "-Generic-Host\n";
      print OFH "\talias\t\t" . $alias . "\n";
      print OFH "\taddress\t\t" . $ip . "\n"; 
      print OFH "}\n";
      return;
}

