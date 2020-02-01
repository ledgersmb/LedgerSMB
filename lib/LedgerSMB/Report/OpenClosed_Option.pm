
package LedgerSMB::Report::OpenClosed_Option;

=head1 NAME

LedgerSMB::Report::OpenClosed_Option - Report UI to open/closed attrib mapper

=head1 DESCRIPTION

This moose role maps the Open/Closed/All radio buttons to their respective
combinations of 'open' and 'closed' attribute values.

=cut


use strict;
use warnings;

use Moose::Role;
use namespace::autoclean;

=head1 CRITERIA PROPERTIES

This role adds the 'open' and 'closed' criteria properties to the classes
in which it's included.

=head2 open bool

If true, show open invoices

=head2 closed bool

If true, show closed invoices.  Naturally if neither open or closed is set, no
invoices will be shown.

=cut

has open => (is => 'ro', isa => 'Bool', required => 0);
has closed => (is => 'ro', isa => 'Bool', required => 0);


=head1 METHODS

This module doesn't declare any (public) methods

=cut

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    my %args = @_;

    if ($args{oc_state} eq 'open') {
        $args{open}   = 1;
        $args{closed} = 0;
    }
    elsif ($args{oc_state} eq 'closed') {
        $args{open}   = 0;
        $args{closed} = 1;
    }
    elsif ($args{oc_state} eq 'all') {
        $args{open}   = 1;
        $args{closed} = 1;
    }
    return $class->$orig(%args);
};

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
