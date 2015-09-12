
=head1 NAME

LedgerSMB::Contact - LedgerSMB class for managing Contacts

=head1 SYOPSIS

This module creates object instances based on LedgerSMB's in-database ORM.

=head1 METHODS

The following method is static:

=over

=item new ($LedgerSMB object);

The following methods are passed through to stored procedures via Autoload.
=item save

=item get

=item search

The above list may grow over time, and may depend on other installed modules.

=back

=head1 Copyright (C) 2007, The LedgerSMB core team.

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

package LedgerSMB::Contact;

use strict;
use warnings;

use base qw(LedgerSMB::PGOld);


sub save {

    my $self = shift @_;

    # check for the various fields being appropriately set..

    if ($self->{person_id} && $self->{contact} && $self->{contact_class}) {

        my $id = shift @ {$self->call_dbmethod( funcname => "save_contact" ) };
        $self->merge($id);
        return $self->{id};
    }
    else {

        # raise an exception
        my $err = LedgerSMB::Error->new();
        $err->text("Unable to save contact information");
        $err->throw();
    }
}

sub get {

    my $self = shift @_;
    my $id = shift @_;

    my $result = shift @{ $self->call_procedure(
        funcname => 'get',
        args     =>[$id]
    ) };
}

sub search {

    my $self = shift @_;
    my ($pattern, $offset, $limit) = @_;

    my $results = $self->call_procedure(
        funcname => 'search',
        args     =>[$pattern, $offset, $limit]
    );

    return $results;
}

1;
