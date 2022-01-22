
package LedgerSMB::Database::Config;

=head1 NAME

LedgerSMB::Database::Config - Database setup data (CoA, GIFI, SIC & templates)

=head1 DESCRIPTION


=cut

use strict;
use warnings;

use Moose;
use namespace::autoclean;

use File::Find::Rule;
use File::Spec;
use Locales;

use LedgerSMB::Sysconfig;

=head1 SYNOPSIS

my $dbconfig = LedgerSMB::Database::Config->new;

=cut


###############################
#
#
# Private functions
#
##############################

sub _list_directory {
    my $dir = shift;

    return [] if ! -d $dir;

    opendir(DIR, $dir);
    my @files =
        sort(grep !/^(\.|[Ss]ample.*)/,
             readdir(DIR));
    closedir(DIR);

    return \@files;
}



=head1 METHODS

=head2 templates

Returns a hash where the keys are the "names" of the template sets and
the values are refs to arrays holding the list of files in the template
set.

=cut

sub templates {
    my $basedir = LedgerSMB::Sysconfig::templates();
    my $templates = _list_directory($basedir);

    return {
        map {
            $_ => [ File::Find::Rule->new->file
                    ->in(File::Spec->catfile($basedir, $_)) ]
        }
        grep { -d File::Spec->catfile($basedir, $_) }
        grep { $_ ne 'lib' } @$templates
    };
}

=head2 charts_of_accounts

Returns a hash where the keys are the alpha-2 codes of the countries
(locales) to which the chart data applies. The values are refs to
hashes with the following keys -- the values of the hashes being the
files holding the specified data:

=over

=item code

'alpha-2' code of the country/locale

=item name

Full name or description of the country/locale

=item chart

List of available files defining a chart of accounts

=item gifi

List of available files defining an alternative (legally required) set
of accounts such as required per Canadian GIFI regulations

=item sic

List of available files defining a Standard of Industry Codes

=back

=cut

sub charts_of_accounts {
    ###TODO: Define a parameter to the SQL directory!!
    my $basedir = File::Spec->catfile('.', 'locale', 'coa');
    my $countries = _list_directory($basedir);
    my %regions = Locales
                    ->new(LedgerSMB::Sysconfig::language() || 'en')
                    ->get_territory_lookup();

    return {
        map {
            my $dir = File::Spec->catfile($basedir, $_);
            $_ => {
                code => $_,
                name => $regions{lc($_)},
                chart => _list_directory($dir),
                sic => _list_directory(File::Spec->catfile('.', 'sql', 'coa',
                                                           $_, 'sic')),
              }
        } @$countries
    };
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2018 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
