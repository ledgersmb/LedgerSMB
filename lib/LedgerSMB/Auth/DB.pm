
package LedgerSMB::Auth::DB;

=head1 NAME

LedgerSMB::Auth::DB - Standard Authentication DB module.

=head1 DESCRIPTION

This is the standard DB-based module for authentication.  Uses HTTP basic
authentication.

=head1 METHODS

=over

=cut

use strict;
use warnings;
use Carp;

use MIME::Base64;
use Log::Log4perl;
use LedgerSMB::Sysconfig;
use Moose;
use namespace::autoclean;

my $logger = Log::Log4perl->get_logger('LedgerSMB::Auth');


has 'env' => (is => 'ro', required => 1, isa => 'HashRef');

has 'credentials' => (is => 'ro', required => 0, lazy => 1,
                      builder => '_build_credentials', isa => 'HashRef');

sub _build_credentials {
    my ($self) = @_;
    my $auth = $self->env->{HTTP_AUTHORIZATION};

    return {} unless defined $auth;

    # use a builder, because the response will be the same, no matter how
    # often we call upon the creds

    die "Authorization header for basic auth expected, but not found ($auth)"
        unless $auth =~ s/^Basic\s+//i;

    $auth = MIME::Base64::decode($auth);
    my %rv;
    @rv{('login', 'password')} = split(/:/, $auth, 2);

    my $username_case = LedgerSMB::Sysconfig::force_username_case;
    if ($username_case) {
        if (lc($username_case) eq 'lower') {
            $rv{login} = lc($rv{login});
        }
        elsif (lc($username_case) eq 'upper') {
            $rv{login} = uc($rv{login});
        }
        else {
            die "Unknown username casing algorithm $username_case; expected 'lower' or 'upper'"
        }
    }

    return \%rv;
}

=item get_credentials

Gets credentials from the 'HTTP_AUTHORIZATION' environment variable which must
be passed in as per the standards of HTTP basic authentication.

Returns a hashref with the keys of login and password.

=cut

sub get_credentials {
    my ($self, $domain) = @_;
    # We ignore domain, but other auth providers may choose to use it

    return $self->credentials;
}

=back

=head1 LICENSE AND COPYRIGHT

# Small Medium Business Accounting software
# http://www.ledgersmb.org/
#
#
# Copyright (C) 2006-2017
# This work contains copyrighted information from a number of sources all used
# with permission.  It is released under the GNU General Public License
# Version 2 or, at your option, any later version.  See COPYRIGHT file for
# details.

=cut

__PACKAGE__->meta->make_immutable;

1;
