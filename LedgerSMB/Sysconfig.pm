#  This is the new configuration file for LedgerSMB.  Eventually all system 
# configuration directives will go here,  This will probably not fully replace
# the ledger-smb.conf until 1.3, however.

package LedgerSMB::Sysconfig;

$session='DB';
$logging=0; # No logging on by default

@io_lineitem_columns = qw(unit onhand sellprice discount linetotal);

# if you have latex installed set to 1
$latex = 1;

# spool directory for batch printing
$spool = "spool";

# path to user configuration files
$userspath = "users";

# templates base directory
$templates = "templates";

# member file
$memberfile = "users/members";

# location of sendmail
$sendmail = "| /usr/sbin/sendmail -t";

# set language for login and admin
$language = "";

# Maximum number of invoices that can be printed on a check
$check_max_invoices = 5;

# program to use for file compression
$gzip = "gzip -S .gz";

#################################
# Global database parameters
#################################
# These parameters *must* be set correctly
# for LedgerSMB >= 1.2 to work
my $globalDBConnect = 'dbi:Pg:dbname=ledgersmb;host=localhost;port=5432';
my $globalUserName = "ledgersmb";
my $globalPassword = "set me to correct password";

#$GLOBALDBH = DBI->connect($globalDBConnect, $globalDBUserName, $globalDBPassword); 


1;
