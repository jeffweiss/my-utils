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
my $hostsbasename = "-hosts.cfg";
my $hostgroupbasename = "-hostgroups.cfg";
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

my $hostsfile = $nagioscfgpath . "/" . $stack . "/" . $lstack . $hostsbasename;
my $hostgroupfile = $nagioscfgpath . "/" . $stack . "/" . $lstack . $hostgroupbasename;
if ($debug) {
   $hostsfile = "hoststest.cfg";
   $hostgroupfile = "hostgrouptest.cfg";
}

my @allhosts = ();

# Connect to EC2 with my credentials and get me the stuff I need.
#
my $ec2 = Net::Amazon::EC2->new(
	AWSAccessKeyId => 'enter your pub key here',
	SecretAccessKey => 'enter your private key here',
);

my $running_instances = $ec2->describe_instances;
# Now that we have the EC2 object open the output file handle
open OFH, ">>$hostsfile" or die "Can't open $hostsfile: $!";

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
  printhostsConfigData($hostname, $ip_address, $tier, $stack);
  push @allhosts, $hostname; 
}
close ('OFH');

open HGOFH, ">$hostgroupfile" or die "Can't open $hostgroupfile for writing: $!";
printhostgrpConfigData($stack, @allhosts);
close ('HGOFH');

sub printhostsConfigData {

  my $hostname = shift;
  my $ip = shift;
  my $tier = shift;
  my $stack = shift;
  my $alias;

  ($alias = $hostname) =~ s/-/\ /g; 

  print OFH "# Defining host entry for $hostname of $stack in $tier\n";
  print OFH "define host{" . "\n";
  print OFH "\thost_name\t$hostname\n";
  print OFH "\tuse\t\t" . "Generic-Host\n";
  print OFH "\talias\t\t" . $alias . "\n";
  print OFH "\taddress\t\t" . $ip . "\n"; 
  print OFH "}\n";
  return;
}

sub printhostgrpConfigData {
  my $stack = shift;
  my @allhosts = @_;
  my $lstack = lc($stack);

  print HGOFH "define hostgroup{" . "\n";
  print HGOFH "hostgroup_name\t" . $lstack . "-all\n";
  print HGOFH "alias\t\t" . "All " . $stack . "servers\n";
  print HGOFH "members\t\t" . join(",", @allhosts) . "\n";
  print HGOFH "}\n";
  return;
}
