#  This is the new configuration file for LedgerSMB.  Eventually all system 
# configuration directives will go here,  This will probably not fully replace
# the ledger-smb.conf until 1.3, however.

package LedgerSMB::Sysconfig;

use Config::Std;
use DBI qw(:sql_types); 


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

$ENV{PATH} .= ":".(join ':', @{$config{environment}{PATH}}) if
	$config{environment}{PATH};
$ENV{PERL5LIB} .= ":".(join ':', @{$config{environment}{PERL5LIB}}) if
	$config{environment}{PERL5LIB};

%printer = %{$config{printers}} if $config{printers};

$memberfile = $config{paths}{memberfile} if $config{paths}{memberfile};
$userspath = $config{paths}{userspath} if $config{paths}{userspath};
$localepath = $config{paths}{localepath} if $config{paths}{localepath};
$spool = $config{paths}{spool} if $config{paths}{spool};
$templates = $config{paths}{tempates} if $config{paths}{tempates};

$sendmail = $config{programs}{sendmail} if $config{programs}{sendmail};
$gzip = $config{programs}{gzip} if $config{programs}{gzip};

$globalDBConnect = $config{globaldb}{DBConnect} if $config{globaldb}{DBConnect};
$globalDBUserName = $config{globaldb}{DBUserName} if $config{globaldb}{DBUserName};
$globalDBPassword = $config{globaldb}{DBPassword} if $config{globaldb}{DBPassword};

#putting this in an if clause for now so not to break other devel users
if ($config{globaldb}{DBConnect}){
	$GLOBALDBH = DBI->connect($globalDBConnect, $globalDBUserName, $globalDBPassword) or die;
}
# These lines prevent other apps in mod_perl from seeing the global db 
# connection info

my $globalDBConnect = undef;
my $globalUserName = undef;
my $globalPassword = undef;

1;
