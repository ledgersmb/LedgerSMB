
package LedgerSMB::X12::EDI894;

=head1 NAME

LedgerSMB::X12::EDI894 - X12 894 support for LedgerSMB

=head1 SYNPOSIS

 my $edi = LedgerSMB::X12::EDI894->new(message => 'message.edi');
 my $form = $edi->order;

=head1 DESCRIPTION

The X12 894 provides for delivery notifications of orders or product returns.
While it is not yet clear what we want to do with this, this does return the
data in a $form object.

=head1 METHODS

This module doesn't specify any methods.

=cut

use strict;
use warnings;

use Path::Class qw(dir file);
use Module::Runtime qw(module_notional_filename);
use LedgerSMB::Form;
use feature 'switch';

use Moose;
use namespace::autoclean;
extends 'LedgerSMB::X12';

sub _config {
    my $pkg_dir = file($INC{module_notional_filename(__PACKAGE__)})->dir;
    return $pkg_dir->file('cf', '894.cf')->stringify;
}

=head1 PROPERTIES

=over

=item order

This is an order hashref using the same data structures that a form screen
would submit (flat format).

=cut

has order => (is => 'ro', isa => 'HashRef[Any]', lazy => 1,
          builder => '_order');

sub _order {
    my ($self) = @_;
    my $sep = $self->parser->get_element_separator;
    my $form = Form->new;
    my $sender_idx;
    my $sender_id;

    my $i = 0;

    while (my $loop = $self->parser->get_next_loop){
          if ('ISA' eq $loop) {
                my ($segment) = $self->parser->get_loop_segments;
                my @elements = split(/\Q$sep\E/, $segment);
                $sender_idx = $elements[5];  ## no critic (ProhibitMagicNumbers) sniff
                $sender_id = $elements[6];  ## no critic (ProhibitMagicNumbers) sniff
          } elsif ('G82' eq $loop) {
                my ($segment) = $self->parser->get_loop_segments;
                my @elements = split(/\Q$sep\E/, $segment);
                $form->{transdate} = $elements[10];  ## no critic (ProhibitMagicNumbers) sniff
                $form->{ordnumber} = $elements[9];  ## no critic (ProhibitMagicNumbers) sniff
          } elsif ('G83' eq $loop) {
                ++$i;
                my ($segment) = $self->parser->get_loop_segments;
                my @elements = split(/\Q$sep\E/, $segment);
                $form->{"qty_$i"} = $elements[2];
                $form->{"unit_$i"} = $elements[3];  ## no critic (ProhibitMagicNumbers) sniff
                $form->{"partnumber_$i"} = $elements[5];  ## no critic (ProhibitMagicNumbers) sniff
                $form->{"sellprice_$i"} = $elements[9];  ## no critic (ProhibitMagicNumbers) sniff
         }
    }
    return $form;
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2013-2018 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


__PACKAGE__->meta->make_immutable;

1;
