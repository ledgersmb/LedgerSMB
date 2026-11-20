use strict;
use warnings;

use ExtUtils::MakeMaker;
# Merges the prerequisites (per phase) from ./cpanfile into WriteMakefile()
use ExtUtils::MakeMaker::CPANfile;
use File::Find;
use File::ShareDir::Install;

# Runtime assets are installed as share files; UI/ and utils/ are deliberately
# not installed. Each directory gets its own share dir (a 'dist' share would
# flatten them together), retrievable with
# File::ShareDir::module_dir('LedgerSMB::<dir>').
install_share(module => "LedgerSMB::$_", $_) for qw( sql templates locale workflows );

# Map every file in lib/ and old/lib/ (including non-.pm files such as the
# X12 *.cf configuration) into the same module tree.
my %pm;
for my $root (qw( lib old/lib )) {
    find({
        no_chdir => 1,
        wanted   => sub {
            return unless -f $_;
            return if m{/\.empty$};
            (my $rel = $_) =~ s{^\Q$root\E/}{};
            $pm{$_} = "\$(INST_LIB)/$rel";
        },
    }, $root);
}

# The in-tree version may carry a pre-release suffix (e.g. '1.14.0-dev'),
# which isn't a valid CPAN version; use the numeric part.
my $version = MM->parse_version('lib/LedgerSMB.pm');
if (not defined $version or $version eq 'undef') {
    open my $fh, '<', 'lib/LedgerSMB.pm' or die "Unable to read lib/LedgerSMB.pm: $!";
    while (<$fh>) {
        if (/^\s*our\s+\$VERSION\s*=\s*'(\d+(?:\.\d+)*)(?:-[^']*)?'/) {
            $version = $1;
            last;
        }
    }
    die 'Unable to determine version from lib/LedgerSMB.pm' unless $version;
}

WriteMakefile(
    NAME             => 'LedgerSMB',
    VERSION          => $version,
    ABSTRACT         => 'Double-entry accounting and ERP system',
    LICENSE          => 'gpl_2',
    MIN_PERL_VERSION => '5.38.0',
    MAKEFILE         => 'Makefile.perl',
    PM               => \%pm,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'          => '6.64',
        'ExtUtils::MakeMaker::CPANfile' => 0,
        'File::ShareDir::Install'      => '0.13',
    },
    test             => { TESTS => 't/*.t' },
);

package MY;
use File::ShareDir::Install qw( postamble );
