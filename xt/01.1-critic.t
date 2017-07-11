#!/usr/bin/perl

use strict;
use warnings;
use Test::More; # plan automatically generated below
use File::Find;
use Perl::Critic;

my @on_disk;


# LedgerSMB aims to comply with the Perl::Critic policies recommended
# by by CERT. See:
# https://gist.github.com/briandfoy/4525877
# https://www.securecoding.cert.org/confluence/display/perl/SEI+CERT+Perl+Coding+Standard
#
# Currently our code violates some of the recommended policies, so tests
# are being added to this list as violations are fixed.

# lsmb_new


# The CERT recommended policies yet to be applied are listed below. Some
# of these are explicitly excluded below, as they would otherwise be
# applied by the -severity option in use.

# lsmb_wip ( lsmb_new_wip, lsmb_old_wip)

# The following CERT recommended policies will not be enforced:
#
#    ErrorHandling::RequireCarping
#      As per ledgerSMB coding guidelines, calling "die" is the preferred
#      way to signal an error. We can't stop die()ing, because that's how
#      our error handling is implemented.  See:
#      https://ledgersmb.org/community-guide/community-guide/development/coding-guidelines/perl-coding-guidelines
#      https://matrix.to/#/!qyoLumPqusaXqFJNyK:matrix.org/$1492804519389522uYnup:matrix.org
#
#    Subroutines::ProhibitUnusedPrivateSubroutines
#      This policy doesn't recognise when private subroutines are legitimately
#      used as builder functions for Moose properties, which is a common
#      pattern employed in LedgerSMB code. Neither does it recognise when
#      private methods are used to compose roles in other files.

# lsmb_reject

# LedgerSMB enforces some other Perl::Critic policies
#
#  lsmb_new


# LedgerSMB explicitly excludes some policies which we currently violate
# and which would be applied automatically by the -severity option in use.
# As violations are fixed, we can gradually remove these exclusions.

# more lsmb_new_wip, less for lsmb_new
# my @exclude_policies = qw(

# more lsmb_old_wip, less for lsmb_old
# my @exclude_policies_oldcode = qw(


sub test_files {
    my ($critic, $files) = @_;

    for my $file (@$files) {
        my @findings = $critic->critique($file);

        ok(scalar(@findings) == 0, "Critique for $file");
        for my $finding (@findings) {
            diag($finding->description);
        }
    }

    return;
}

sub collect {
    return if $File::Find::name !~ m/\.(pm|pl)$/;

    my $module = $File::Find::name;
    push @on_disk, $module
}
find(\&collect, 'lib/', 'old/');

my @on_disk_oldcode =
    grep { m#^old/#  }
    @on_disk;

@on_disk =
    grep { ! m#^old/# }
    @on_disk;

plan tests => scalar(@on_disk) + scalar(@on_disk_oldcode);

test_files(
    Perl::Critic->new(
        -profile => 'xt/perlcriticrc',
        -severity => 1,
        -theme => 'lsmb_new',
    ),
    \@on_disk
);

test_files(
    Perl::Critic->new(
        -only => 1,
        -profile => 'xt/perlcriticrc',
        -severity => 1,
        -theme => 'lsmb_old',
    ),
    \@on_disk_oldcode
);



