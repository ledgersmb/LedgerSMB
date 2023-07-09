
package LedgerSMB::Report::Listings::User;

=head1 NAME

LedgerSMB::Report::Listings::User - List users in LedgerSMB

=head1 DESCRIPTION

Implements an unfiltered listing of users.

=head1 SYNOPSIS

Since no parameters are required:

  LedgerSMB::Report::Listings::User->new()->render;

=cut

use Moose;
use namespace::autoclean;
extends 'LedgerSMB::Report';

=head1 ATTRIBUTES

=head2 login

The login (username) of the current user

=cut

has login => (is => 'ro', default => '');

=head1 REPORT CRITERIA

None

=head1 REPORT CONSTANTS

=head2 columns

=over

=item Description

=back

=cut

sub columns {
    my ($self) = @_;
    return [
        {
            col_id => 'username',
            type  => 'href',
            href_base  => 'admin.pl?__action=edit_user&id=',
            name  => $self->Text('Username'),
        },
        {
            col_id => 'name',
            type => 'text',
            name => $self->Text('Name'),
        },
        {
            col_id => 'delete',
            type => 'href',
            href_base => 'admin.pl?__action=delete_user&id=',
            name => ''
        },
        ];
}

=head2 name

Users

=cut

sub name {
    my ($self) = @_;
    return $self->Text('Users');
}

=head1 METHODS

=head2 run_report

=cut

sub run_report {
    my ($self) = @_;
    my @rows = $self->call_dbmethod(funcname => 'user__get_all_users');
    for my $row (@rows) {
        $row->{row_id} = $row->{id};
        if ($row->{username} eq $self->login) {
            $row->{delete_NOHREF} = 1;
        }
        else {
            $row->{delete} = $self->Text('Delete');
        }
    }
    return $self->rows(\@rows);
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2023 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
