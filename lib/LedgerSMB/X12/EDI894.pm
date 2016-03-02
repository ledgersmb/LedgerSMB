=head1 NAME

LedgerSMB::X12::EDI894 - X12 894 support for LedgerSMB

=head1 SYNPOSIS

 my $edi = LedgerSMB::X12::EDI894->new(message => 'message.edi');
 my $form = $edi->order;

=cut

package LedgerSMB::X12::EDI894;
use Moose;
use LedgerSMB::Form;
use feature 'switch';
extends 'LedgerSMB::X12';

sub _config {
    return 'LedgerSMB/X12/cf/894.cf';
}

=head1 DESCRIPTION

The X12 894 provides for delivery notifications of orders or product returns.
While it is not yet clear what we want to do with this, this does return the
data in a $form object.

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
    my $form = new Form;
    my $sender_idx;
    my $sender_id;

    my $i = 0;

    while (my $loop = $self->parser->get_next_loop){
          if ('ISA' eq $loop) {
                my ($segment) = $self->parser->get_loop_segments;
                my @elements = split(/\Q$sep\E/, $segment);
                $sender_idx = $elements[5];
                $sender_id = $elements[6];
          } elsif ('G82' eq $loop) {
                my ($segment) = $self->parser->get_loop_segments;
                my @elements = split(/\Q$sep\E/, $segment);
                $form->{transdate} = $elements[10];
                $form->{ordnumber} = $elements[9];
          } elsif ('G83' eq $loop) {
                ++$i;
                my ($segment) = $self->parser->get_loop_segments;
                my @elements = split(/\Q$sep\E/, $segment);
                $form->{"qty_$i"} = $elements[2];
                $form->{"unit_$i"} = $elements[3];
                $form->{"partnumber_$i"} = $elements[5];
                $form->{"sellprice_$i"} = $elements[9];
         }
    }
    return $form;
}

=back

=cut

__PACKAGE__->meta->make_immutable;

1;
