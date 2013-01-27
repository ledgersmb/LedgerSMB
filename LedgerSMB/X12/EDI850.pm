=head1 NAME 

LedgerSMB::X12::EDI850 - Conversion class for X12 850 files to LedgerSMB 
structures

=head1 SYNOPSIS

 my $edi = LedgerSMB::X12::EDI850->new(message => 'message.edi');
 my $ISA = $edi->ISA;
 my @orders = $edi->orders;

=cut

package LedgerSMB::X12::EDI850;
use Moose;
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

has order => (is => 'ro', isa => 'HashRef[Any]', lazy => 1, 
          builder => '_order');

sub _order {
    my ($self) = $_;
    $self->parse;
    eval {$self->ISA}; # if throws error, ignore
    $self->parse;

    
}


