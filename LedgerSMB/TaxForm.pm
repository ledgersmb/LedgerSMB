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



    
1;
