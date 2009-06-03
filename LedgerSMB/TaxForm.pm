#! /usr/bin/perl

package LedgerSMB::TaxForm;

use base qw(LedgerSMB::DBObject);

use strict;

sub save 
{
  
    my ($self) = shift @_;

    my $dbh=$self->{dbh};
    
    my $query="insert into country_tax_form(country_id,form_name) values(?,?);";

    my $sth=$dbh->prepare($query) or die "prepare problem";
    
    $sth->execute($self->{country_code},$self->{taxform_name}) or die "execute problem";
  
    $dbh->commit();

    
}

sub get_metadata
{
    my ($self) = @_;

    @{$self->{countries}} = $self->exec_method(
                funcname => 'location_list_country'
    );

    my ($ref) = $self->call_procedure(procname => 'setting_get', args => ['default_country']);
    $self->{default_country} = $ref->{setting_get};
}

1;
   

    
1;
