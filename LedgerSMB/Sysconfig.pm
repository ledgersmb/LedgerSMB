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
read_config('ledger-smb.conf' => %config) or die;

$logging = $config{''}{logging} if $config{''}{logging};
$check_max_invoices = $config{''}{check_max_invoices} if
	$config{''}{check_max_invoices};
$language = $config{''}{language} if $config{''}{language};
$session = $config{''}{session} if $config{''}{session};
$latex = $config{''}{latex} if $config{''}{latex};

$ENV{PATH} .= $pathsep.(join $pathsep, @{$config{environment}{PATH}}) if
	$config{environment}{PATH};
$ENV{PERL5LIB} .= ":".(join ':', @{$config{environment}{PERL5LIB}}) if
	$config{environment}{PERL5LIB};

%printer = %{$config{printers}} if $config{printers};

$memberfile = $config{paths}{memberfile} if $config{paths}{memberfile};
$userspath = $config{paths}{userspath} if $config{paths}{userspath};
$localepath = $config{paths}{localepath} if $config{paths}{localepath};
$spool = $config{paths}{spool} if $config{paths}{spool};
$templates = $config{paths}{templates} if $config{paths}{templates};
$images = $config{paths}{images} if $config{paths}{images};

$gzip = $config{programs}{gzip} if $config{programs}{gzip};

$sendmail = $config{mail}{sendmail} if $config{mail}{sendmail};
$smtphost = $config{mail}{smtphost} if $config{mail}{smtphost};
$smtptimeout = $config{mail}{smtptimeout} if $config{mail}{smtptimeout};

# We used to have a global dbconnect but have moved to single entries
$globalDBhost = $config{globaldb}{DBhost} if $config{globaldb}{DBhost};
$globalDBport = $config{globaldb}{DBport} if $config{globaldb}{DBport};
$globalDBname = $config{globaldb}{DBname} if $config{globaldb}{DBname};
$globalDBUserName = $config{globaldb}{DBUserName} if $config{globaldb}{DBUserName};
$globalDBPassword = $config{globaldb}{DBPassword} if $config{globaldb}{DBPassword};

#putting this in an if clause for now so not to break other devel users
if ($config{globaldb}{DBname}){
	$GLOBALDBH = DBI->connect("dbi:Pg:dbname=$globalDBname host=$globalDBhost
	                                 port=$globalDBport user=$globalDBUserName
	                                 password=$globalDBPassword");
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
