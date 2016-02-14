=head1 NAME

LedgerSMB::X12::EDI850 - Conversion class for X12 850 files to LedgerSMB
structures

=head1 SYNOPSIS

 my $edi = LedgerSMB::X12::EDI850->new(message => 'message.edi');
 my $form = $edi->order;

=cut

package LedgerSMB::X12::EDI850;
use Moose;
use LedgerSMB::Form;
use feature 'switch';
extends 'LedgerSMB::X12';

sub _config {
    return 'LedgerSMB/X12/cf/850.cf';
}

=head1 DESCRIPTION

This module processes X12 EDI 850 purchase orders and can present them in
structures compatible with LedgerSMB's order entry system.  The API is simple.

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
    my $form = new Form;
    my $sender_idx;
    my $sender_id;

    my $i = 0;

    while (my $loop = $self->parser->get_next_loop){
        if ('ISA' eq $loop){
                my ($segment) = $self->parser->get_loop_segments;
                my @elements = split(/\Q$sep\E/, $segment);
                $sender_idx = $elements[5];
                $sender_id = $elements[6];
                $form->{edi_isa} = \@elements;
                my @new_elements = (
                   $elements[0],
                   $elements[1],
                   $elements[2],
                   $elements[3],
                   $elements[4],
                   $elements[7],
                   $elements[8],
                   $elements[5],
                   $elements[6],
                   $elements[9],
                   $elements[10],
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

=cut

__PACKAGE__->meta->make_immutable;

1;
