#!/usr/bin/perl

use strict;
use Getopt::Long;
# We will be using expect to manage the login process for copying the SSH keys
use Expect;

# Fancy password prompt
use Term::ReadKey;


$| = 0;
print "Enter your Unix Username: ";
my $user = ReadLine(0);

chomp $user;

print "Enter your password: ";
ReadMode('noecho');
my $password = ReadLine(0);

chomp $password;
ReadMode('normal');

print "Enter the name of the server list text file: ";
my $inputfile = ReadLine(0);
chomp $inputfile;

open('FH', "<$inputfile") or die "can't open $inputfile: $!";

my $outputfile = "/home/$user/.ssh/testconfig";
open OFH, ">>$outputfile" or die "can't open $outputfile: $!";

# Loop through the file of hostnames one at a time
while (defined (my $hostname = <FH>)) {
  chomp $hostname;

  # Check to see if key authentication is already working so we don't copy the key twice.
  if(system("ssh -o BatchMode=yes -o ConnectTimeout=5 $hostname uptime 2>&1 | grep -q average") != "0")
  {
    # Set up the command to copy the ssh key
    my $cmd = "ssh-copy-id -i $hostname";

    # Print comfort text
    print "Now copying key to $hostname";

    # Set up expect and spawn a command
    my $timeout = '10';
    my $ex = Expect->spawn($cmd) or die "Cannot spawn $cmd\n";

    # Look for the password prompt and send the password
    $ex->expect($timeout, ["[pP]assword:"]);
    $ex->send("$password\n");
    $ex->soft_close();
      printConfigData($hostname, $user);
 } else { print "Key already deployed on $hostname\n" }
}
close('FH');
close('OFH');

sub printConfigData {

      my $hostname = shift;
      my $user = shift;

      my ($host) = split(/\./, $hostname);
      print OFH "Host " . $host . "\n";
      print OFH "   User $user\n";
      print OFH "   HostName ", $hostname, "\n";
      print OFH "   Port 22\n";
      print OFH "   IdentityFile ~/.shh/id_rsa\n"; 
      print OFH "\n";
      return;
}

