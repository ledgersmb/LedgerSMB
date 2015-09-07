#!/usr/bin/perl
#
use strict;

print "Welcome to the interactive db setup and test utility.\n";

print "POSTGRESQL DATABASE SETUP\n\n\n";
print "Name of company file/database to install? ";

chomp($ENV{LSMB_NEW_DB} = <STDIN>);


print "\n\nPostgreSQL superuser's username: ";
chomp($ENV{PGUSER} = <STDIN>);

print "Enter a password? (y/N) ";
my $usepass = <STDIN>;
chomp $usepass;
if ('y' eq $usepass){
    print "Password for $ENV{PGUSER}: ";
    chomp($ENV{PGPASSWORD} = <STDIN>);
}

print "\n\n\nLedgerSMB Administrative User Setup\n\n\n";
print "Administrator's first name? ";
chomp ($ENV{LSMB_ADMIN_FNAME}= <STDIN>);
print "Administrator's last name? ";
chomp ($ENV{LSMB_ADMIN_LNAME}= <STDIN>);
print "Administrator's Username? ";
chomp ($ENV{LSMB_ADMIN_USERNAME}= <STDIN>);
print "Administrator's Password? ";
chomp ($ENV{LSMB_ADMIN_PASSWORD}= <STDIN>);

print "\n\n\nChart of Accounts Setup\n\n\n";
print "Country Code (2 letter code): ";
chomp ($ENV{LSMB_COUNTRY_CODE}= <STDIN>);

print "Chart of Accounts: ";
chomp ($ENV{LSMB_LOAD_COA}= <STDIN>);

print "Gifi (optional): ";
chomp ($ENV{LSMB_LOAD_GIFI}= <STDIN>);

system('make installdb');

1;
