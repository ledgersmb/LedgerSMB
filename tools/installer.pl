# This file is an installer for the LedgerSMB system.  It is designed to run
# explicitly with the perl interpreter (i.e. perl install.pl).  Most behavior
# is system dependent using standard tools and so there is no issue there.  To
# tell the program where to install the web app to, you can either set a
# WEBAPPDIR environment variable or pass this to the first argument on the
# command line.
#
# example on UNIX:
#
# WEBAPPDIR=/opt/ledgersmb/demo perl install.pl
#
# The following works on UNIX and Windows (if you change the path to the right
# location).
#
# perl install.pl /opt/ledgersmb/demo
#
# A Windows example migt be
#
# perl install.pl 'C://Application Data/LedgerSMB/Demo'
#
# While the directory will be created if it does not exist, the parent directory
# must exist or the program will throw an error.
#
use strict;
use warnings;
use File::Copy::Recursive qw(rcopy dircopy fcopy);

sub exit_with_help {
    my ($msg, $exit) = shift;
    print "\n\nWelcome to the LedgerSMB installer utility.\n\n";
    print "To invoke try one of these syntaxes:\n";
    print "  perl install.pl /path/to/install/ \n";
    print "  WEBAPPDIR=/path/to/install perl install.pl\n\n";
    print "If you are on Windows, remember to use forward slashes for paths, " .
           "for example:\n";
    print "  perl install.pl 'C://path/to/install'\n\n";
    die "$msg\n\n";
}

# HEADER:  SETTING UP THE BUILD ENVIRONMENT
my $dest_dir = $ENV{WEBAPPDIR};
$dest_dir ||= $ARGV[0];

system('make');
system('make test');

exit_with_help('Web app directory not set', 1) if !defined $dest_dir;

# Basic set up

fcopy('conf/ledgersmb.conf.default', 'ledgersmb.conf') unless -f 'ledgersmb.conf';

mkdir 'build';
mkdir 'build/webapp';

File::Copy::Recursive::rcopy_glob('*.pl', 'build/webapp') or die $!;
rcopy('bin', 'build/webapp/bin') or die $!;

# if necessary add other files here that we don't want installed
unlink "build/weball/installer.pl";
unlink "build/weball/install_interactive.pl";

mkdir 'build/PM';
rcopy('LedgerSMB.pm', 'build/PM') or die $!;
rcopy('LedgerSMB', 'build/PM/LedgerSMB') or die $!;
rcopy('Makefile.PL', 'build/PM') or die $!;
dircopy('t', 'build/PM/t') or die $!;

# the following tests won't work under any circumstances from PM
unlink('build/PM/t/62-api.t');
unlink('build/PM/t/63-lwp.t');

# HEADER:  BUILDING AND INSTALLING THE APPLICATION

chdir 'build/PM';
system('perl Makefile.PL');
system('make');
system('make install');

chdir '../..';
dircopy('build/webapp', $dest_dir);
fcopy('conf/ledgersmb.conf.default', "$dest_dir/ledgersmb.conf")
                                          unless -f "$dest_dir/ledgersmb.conf";


exit(0);
