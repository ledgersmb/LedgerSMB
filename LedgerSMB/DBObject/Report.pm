
=head1:  NAME

LedgerSMB::Report:  Stub function for custom reports.

=head1:  COPYRIGHT

Copyright (c) 2007.  LedgerSMB Core Team 

=cut

package LedgerSMB::DBObject::Report;
use base qw(LedgerSMB::DBObject);
use strict;
our $VERSION = '1.0.0';

1;

=head1 METHODS

=cut



# Place report definitions at the bottom of the file, please.  CT

=head1 DEFINED REPORTS

=cut

sub definition_invoice_aging {
    my ($self) = @_;

    @{$self->{entities}} = 
        $self->exec_method(funcname => 'payment_get_all_accounts');

    my $entity_options = [];
    for my $entity (@{$self->{entities}}){
        my $option = {};
        $option->{value} = $entity->{id};
        $option->{label} = $entity->{name};
        push @$entity_options, $option;
    }

    $self->{criteria} = [
           {name => 'entity', type => 'select', label => 'Account', 
                              options => $entity_options}, 
    ];
    $self->{hidden_elements} = [
            {name => 'account_class', value => $self->{account_class}}
    ];
    $self->{columns} = [
            {id => 'entity_id',      label => 'Entity ID'}, 
            {id => 'account_number', label => 'Account Number'},
            {id => 'name',           label => 'Name'},
            {id => 'country',        label => 'Country'},        
            {id => 'contact_name',   label => 'Contact'},  
            {id => 'email',          label => 'Email'},
            {id => 'phone',          label => 'Telephone'},     
            {id => 'fax',            label => 'Fax'},
            {id => 'invnumber',      label => 'Invoice Number'},
            {id => 'transdate',      label => 'Date'},
	    {id => 'till',           label => 'Till'},
	    {id => 'ordnumber',      label => 'Order Number'},
	    {id => 'ponumber',       label => 'PO Number'},
	    {id => 'c0',             label => 'Current'},
	    {id => 'c30',            label => '30'},
	    {id => 'c60',            label => '60'},
	    {id => 'c90',            label => '90'},  
	    {id => 'duedate',        label => 'Due'},
	    {id => 'curr',           label => 'Currency'},
	    {id => 'exchangerate',   label => 'Exchange Rate'},
    ];
    $self->{report_types} = [
            {label => "Detailed",         value => "detailed"},
            {label => "Summary",          value => "summary"},
            {label => "Overdue",          value => "overdue"},
            {label => "Overdue Summary",  value => "overdue_summary"},
    ];

}

=head1 ADDING DEFINED REPORTS

=cut

1;
