#!/usr/bin/perl

package LedgerSMB::Scripts::taxform;
use LedgerSMB::DBObject::TaxForm;
use LedgerSMB::Template;
use LedgerSMB::Form;

sub add_taxform 
{
    my ($request) = @_;
    my $taxform = LedgerSMB::DBObject::TaxForm->new({base => $request});
    
    $taxform->get_metadata();
    my $template = LedgerSMB::Template->new(
        user =>$request->{_user}, 
        locale => $request->{_locale},
        path => 'UI',
        template => 'taxform/add_taxform',
        format => 'HTML'
    );
    $template->render($taxform);
}

sub save
{
    my ($request) = @_;
    my $taxform = LedgerSMB::DBObject::TaxForm->new({base => $request}); 
    
    $taxform->save();
    $taxform->get_metadata();
    my $template = LedgerSMB::Template->new(
        user =>$request->{_user}, 
        locale => $request->{_locale},
        path => 'UI',
        template => 'taxform/add_taxform',
        format => 'HTML'
    );
    $template->render($taxform);
}



1;
