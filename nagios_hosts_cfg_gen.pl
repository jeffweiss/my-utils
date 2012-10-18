#!/usr/bin/perl

use strict;
use Term::ReadKey;
use Net::Amazon::EC2;
use YAML::Tiny;
use Data::Dumper;
#
#
# begin globals vars section
my ($ip_address, $hostname, $alias, $tier);
my $local;
my @allhosts = ();
if (@ARGV == 1) {
      $local = 1;
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

# create upper and lower case versions from readline for HPSSA
# or just lower for all others
# just a hack at this point but it works
my $lstack = lc($stack);
my $ustack;
if ($lstack =~ /hpssa/) {
  $ustack = uc($lstack);
} else {
  $ustack = $stack;
}

print "Enter and environment (i.e. devel|prod): ";
my $environment = ReadLine(0);
chomp $environment;
$environment = lc $environment;

if ($environment =~ /^dev/) {
  $environment = "development";
}
elsif ($environment =~ /^prod/) {
  $environment = "production";
}

print "Please provide the file location for your public and private keys: ";
my $keysfile = ReadLine(0);
chomp $keysfile;
#check that we got something from the readline or die
die "no value passed for key file: $!" if (length($keysfile) == 0);

#check that the file exists and is really there before we try to read it
die "no such file or directory $keysfile" unless (-f $keysfile);

#read in the yaml file with aws keys
my $yaml = YAML::Tiny->read( $keysfile );

# set public and private key variables based on stack / env information
# after reading the yaml file for the data
my $pubkey = $yaml->[0]->{$lstack}->{$environment}->{public_key};
my $private = $yaml->[0]->{$lstack}->{$environment}->{private_key};

# setup some paths for creating nagios config files
my $hostsfile = $nagioscfgpath . "/" . $ustack . "/" . $lstack . $hostsbasename;
my $hostgroupfile = $nagioscfgpath . "/" . $ustack . "/" . $lstack . $hostgroupbasename;
if ($local) {
   $hostsfile = "hostslocal.cfg";
   $hostgroupfile = "hostgrouplocal.cfg";
}

# Connect to EC2 with my credentials and get me the stuff I need.
#
my $ec2 = Net::Amazon::EC2->new(
	AWSAccessKeyId => $pubkey,
	SecretAccessKey => $private,
);

my $running_instances = $ec2->describe_instances;
# Now that we have the EC2 object open the output file handle
open OFH, ">$hostsfile" or die "Can't open $hostsfile: $!";

foreach my $reservation (@$running_instances) {
	foreach my $instance ($reservation->instances_set) {
		#$fqdn = $instance->dns_name;
		$ip_address = $instance->ip_address;
		foreach my $tag (@{$instance->tag_set}) {
			 if ($tag->key =~ /Name/) {
				  $hostname = $tag->value;
			 }
       elsif ($tag->key =~ /Tier/) {
          $tier = $tag->value;
       }
     }
   }
	}
  printhostsConfigData($hostname, $ip_address, $tier, $ustack);
  push @allhosts, $hostname; 
}
close ('OFH');

open HGOFH, ">$hostgroupfile" or die "Can't open $hostgroupfile for writing: $!";
printhostgrpConfigData($ustack, @allhosts);
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
  print OFH "\tuse\t\t" . $stack . "-Generic-Host\n";
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
  print HGOFH "alias\t\t" . "All " . $stack . " servers\n";
  print HGOFH "members\t\t" . join(",", @allhosts) . "\n";
  print HGOFH "}\n";
  return;
}
