#  This is the new configuration file for LedgerSMB.  Eventually all system 
# configuration directives will go here,  This will probably not fully replace
# the ledger-smb.conf until 1.3, however.

package LedgerSMB::Sysconfig;

use LedgerSMB::Form;
use Config::Std;
use DBI qw(:sql_types); 

binmode STDOUT, ':utf8';

# For Win32, change $pathsep to ';';
$pathsep=':';

$session='DB';
$logging=0; # No logging on by default

@io_lineitem_columns = qw(unit onhand sellprice discount linetotal);

# Whitelist for redirect destination
@scripts = ('aa.pl', 'admin.pl', 'am.pl', 'ap.pl', 'ar.pl', 'arap.pl', 
	'arapprn.pl', 'bp.pl', 'ca.pl', 'cp.pl', 'ct.pl', 'gl.pl', 'hr.pl',
	'ic.pl', 'io.pl', 'ir.pl', 'is.pl', 'jc.pl', 'login.pl', 'menu.pl',
	'oe.pl', 'pe.pl', 'pos.pl', 'ps.pl', 'pw.pl', 'rc.pl', 'rp.pl');

# if you have latex installed set to 1
$latex = 1;

# spool directory for batch printing
$spool = "spool";

# path to user configuration files
$userspath = "users";

# images base directory
$images = "images";

# templates base directory
$templates = "templates";

# member file
$memberfile = "users/members";

# location of sendmail
$sendmail = "/usr/sbin/sendmail -t";

# SMTP settings
$smtphost = '';
$smtptimout = 60;

# set language for login and admin
$language = "";

# Maximum number of invoices that can be printed on a check
$check_max_invoices = 5;

# program to use for file compression
$gzip = "gzip -S .gz";

# Path to the translation files
$localepath = 'locale/po';

# available printers
%printer = ( Laser	=> 'lpr -Plaser',
             Epson	=> 'lpr -PEpson',
	     );

my %config;
read_config('ledgersmb.conf' => %config) or die;

# Root variables
for $var (qw(pathsep logging check_max_invoices language session latex
	db_autoupdate)){
    ${$var} = $config{''}{$var} if $config{''}{$var};
}

%printer = %{$config{printers}} if $config{printers};

# ENV Paths
for $var (qw(PATH PERL5LIB)){
$ENV{$var} .= $pathsep.(join $pathsep, @{$config{environment}{$var}}) if
	$config{environment}{$var};
}

# Application-specific paths
for $var (qw(localepath spool templates images)){
	${$var} = $config{paths}{$var} if $config{paths}{$var};
}

# Programs
for $var (qw(gzip)){
	${$var} = $config{programs}{$var} if $config{programs}{$var};
}

# mail configuration
for $var (qw(sendmail smpthost smtptimeout)){
	${$var} = $config{mail}{$var} if $config{mail}{$var};
}


# We used to have a global dbconnect but have moved to single entries
for $var (qw(DBhost DBport DBname DBUserName DBPassword)){
	${"global".$var} = $config{globaldb}{$var} if $config{globaldb}{$var};
}

#putting this in an if clause for now so not to break other devel users
if ($config{globaldb}{DBname}){
	my $dbconnect = "dbi:Pg:dbname=$globalDBname host=$globalDBhost
		port=$globalDBport user=$globalDBUserName
		password=$globalDBPassword"; # for easier debugging
	$GLOBALDBH = DBI->connect($dbconnect);
	if (!$GLOBALDBH){
		$form = new Form;
		$form->error("No GlobalDBH Configured or Could not Connect");
	}
}
# These lines prevent other apps in mod_perl from seeing the global db 
# connection info

my $globalDBConnect = undef;
my $globalUserName = undef;
my $globalPassword = undef;

1;
