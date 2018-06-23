
package LedgerSMB::X12::EDI850;

=head1 NAME

LedgerSMB::X12::EDI850 - Conversion class for X12 850 files to LedgerSMB
structures

=head1 DESCRIPTION

This module processes X12 EDI 850 purchase orders and can present them in
structures compatible with LedgerSMB's order entry system.  The API is simple.

=head1 SYNOPSIS

 my $edi = LedgerSMB::X12::EDI850->new(message => 'message.edi');
 my $form = $edi->order;

=head1 METHODS

This module doesn't specify any methods.

=cut

use strict;
use warnings;

use Path::Class qw(dir file);
use Module::Runtime qw(module_notional_filename);
use LedgerSMB::Form;


use Moose;
use namespace::autoclean;
use feature 'switch';
extends 'LedgerSMB::X12';

sub _config {
    my $pkg_dir = file($INC{module_notional_filename(__PACKAGE__)})->dir;
    return $pkg_dir->file('cf', '850.cf')->stringify;
}

=head1 PROPERTIES

=over

=item order

This is an order hashref using the same data structures that a form screen
would submit (flat format).

=cut

has order => (is => 'ro', isa => 'Form', lazy => 1,
          builder => '_order');

sub _order {
    my ($self) = @_;
    $self->parse;
    my $sep = $self->parser->get_element_separator;
    my $form = Form->new;
    my $sender_idx;
    my $sender_id;

    my $i = 0;

    while (my $loop = $self->parser->get_next_loop){
        if ('ISA' eq $loop){
                my ($segment) = $self->parser->get_loop_segments;
                my @elements = split(/\Q$sep\E/, $segment);
                $sender_idx = $elements[5];  ## no critic (ProhibitMagicNumbers) sniff
                $sender_id = $elements[6];  ## no critic (ProhibitMagicNumbers) sniff
                $form->{edi_isa} = \@elements;
                my @new_elements = (
                   $elements[0],
                   $elements[1],
                   $elements[2],
                   $elements[3],  ## no critic (ProhibitMagicNumbers) sniff
                   $elements[4],  ## no critic (ProhibitMagicNumbers) sniff
                   $elements[7],  ## no critic (ProhibitMagicNumbers) sniff
                   $elements[8],  ## no critic (ProhibitMagicNumbers) sniff
                   $elements[5],  ## no critic (ProhibitMagicNumbers) sniff
                   $elements[6],  ## no critic (ProhibitMagicNumbers) sniff
                   $elements[9],  ## no critic (ProhibitMagicNumbers) sniff
                   $elements[10],  ## no critic (ProhibitMagicNumbers) sniff
                   $elements[11],
                   $elements[12],
                   $elements[13],
                   $elements[14],
                   $elements[15],
                   $elements[16],
                );
                $form->{edi_isa_return} = join $sep, @new_elements;
        } elsif ('ST' eq $loop){
                my ($segment) = $self->parser->get_loop_segments;
                my @elements = split(/\Q$sep\E/, $segment);
                $form->{edi_st_id} = $elements[2];
                $form->{edi_spec} = '850';
        } elsif ('GS' eq $loop) {
                my ($segment) = $self->parser->get_loop_segments;
                my @elements = split(/\Q$sep\E/, $segment);
                $form->{edi_gs} = \@elements;
                $form->{edi_f_id} = $elements[1];
                $form->{edi_g_cc} = $elements[6];
        } elsif ('GE' eq $loop) {
                my ($segment) = $self->parser->get_loop_segments;
                my @elements = split(/\Q$sep\E/, $segment);
                $form->{edi_ge} = \@elements;
        } elsif ('BEG' eq $loop) {
                my ($segment) = $self->parser->get_loop_segments;
                my @elements = split(/\Q$sep\E/, $segment);
                $form->{ordnumber} = $elements[3];
                $form->{transdate} = $elements[5];
                $form->{transdate} =~ s/(\d{4})(\d{2})(\d{2})/$1-$2-$3/;
        } elsif ('PO1' eq $loop) {
                ++$i;
                my ($segment) = $self->parser->get_loop_segments;
                my @elements = split(/\Q$sep\E/, $segment);
                $form->{"qty_$i"} = $elements[2];
                $form->{"sellprice_$i"} = $elements[4];
                $form->{"partnumber_$i"} = $elements[7];
        } elsif ('PID' eq $loop) {
                my ($segment) = $self->parser->get_loop_segments;
                my @elements = split(/\Q$sep\E/, $segment);
                $form->{"description_$i"}  = $elements[5];
        } elsif ('CTT' eq $loop) {
                # Perform checks and error if does not work.
                my ($segment) = $self->parser->get_loop_segments;
                my @elements = split(/\Q$sep\E/, $segment);
                my $invtotal;
                $invtotal += ($form->{"qty_$_"} * $form->{"sellprice_$_"})
                     for (1 .. $i);
                #die 'Incorrect total: got ' . $elements[2] . " expected $invtotal" if $elements[2] and $elements[2] != $invtotal;
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
