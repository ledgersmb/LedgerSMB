#!/usr/bin/perl

=pod

=head1 NAME

LedgerSMB::Scripts::customer - LedgerSMB class defining the Controller
functions, template instantiation and rendering for customer editing and display.

=head1 SYOPSIS

This module is the UI controller for the customer DB access; it provides the 
View interface, as well as defines the Save customer. 
Save customer will update or create as needed.


=head1 METHODS

=cut

package LedgerSMB::Scripts::customer;

use LedgerSMB::DBObject::Customer;
use base qw(LedgerSMB::ScriptLib::Company);

sub set_entity_class {
    my ($null, $request) = @_;
    $request->{entity_class} = 2;
    $request->{account_class} = $request->{entity_class};
    return 1;
}

sub new_company {
    my ($null, $request) = @_;
    
    return LedgerSMB::DBObject::Customer->new(base=> $request, copy => 'all');
}

1;
