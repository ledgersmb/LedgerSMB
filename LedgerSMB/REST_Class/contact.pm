=head1 NAME

LedgerSMB::REST_Class::Contact - Customer/vendor web servicesA

=cut

package LedgerSMB::REST_Class::contact;
use LedgerSMB::Entity;
use LedgerSMB::Entity::Credit_Account;
use LedgerSMB::Entity::Location;
use LedgerSMB::Entity::Contact;
use LedgerSMB::Entity::Company;
use LedgerSMB::Entity::Person;
use LedgerSMB::Entity::Bank;
use LedgerSMB::Report::Contact::Search;
use strict;
use warnings;

=head1 SYNOPSIS

 my $obj = LedgerSMB::REST_Class::Contact->new(%$payload);
 $obj->GET; # or PUT or POST.  DELETE not implemented for this class

=head1 DESCRIPTION

This module contains the basic  handlers

=head1 PROPERTIES

=head1 METHODS

=over

=item get

Searches or retrieves one or more records.

=cut

my $cname = 'LedgerSMB::REST_Class::contact';

sub get {
    my ($request) = @_;
    my $id = $request->{classes}->{$cname};
    my $data;
    if ($id or ($id eq '0')){
       return _get_entity($request, $id);
    } else {
       if ($request->{args}->{entity_class}) {
          @{$data->{contacts}} =  _search_entity_class(
              $request, $request->{args}->{entity_class}
          );
          return $data;
       } else {
            my @results = ();
            for my $ref (LedgerSMB::Entity->call_procedure(
                          funcname => 'entity__list_classes'
                      )
            ){
                push @results,  _search_entity_class($request, $ref->{id});
            }
            return {contacts => \@results};
       }
    }
}

sub _search_entity_class {
    my ($request, $entity_class) = @_;
    my $args = $request->{args};
    $args->{entity_class} = $entity_class;
    my $report = LedgerSMB::Report::Contact::Search->new(%$args);
    $report->run_report;
    my @results;
    for my $r (@{$report->rows}){
        my @new_results = _get_entity($request, $r->{entity_id});
        push @results, @new_results;
    }
    return @results;
}


sub _get_entity {
    my ($request, $id) = @_;
    my $company = LedgerSMB::Entity::Company->get($id);
    my $data;

    if ($company){
       $data= $company;
       $data->{entity_type} = 'Company';
    } else {
       my $person = LedgerSMB::Entity::Person->get($id);
       if ($person){
          $data= $person;
          $data->{entity_type} = 'Person';
       } else {
          die '404 Not Found';
       }
    }
    @{$data->{credit_accounts}} =
       LedgerSMB::Entity::Credit_Account->list_for_entity($id);
    @{$data->{locations}} =
      LedgerSMB::Entity::Location->get_active({entity_id => $id});
    @{$data->{contact}} =
      LedgerSMB::Entity::Contact->list({{entity_id => $id}});
    @{$data->{bank_accounts}} =
      LedgerSMB::Entity::Bank-> list($id);
    return $data;
}

=item post

Determines of record exists and if not creates it.  If so, throws a 400 error

=cut

sub post {
    my ($request, $id) = @_;
    if ($id or $request->{payload}->{entity_id}){
        $request->{payload}->{entity_id} = $id if $id;
        if (LedgerSMB::Entity->get($id)){
            die '409 Conflict';
        }
    }
    put($request, $id);
}

=item put

Saves record, overwriting any record that was there before.

=cut

sub put {
    my ($request, $id) = @_;
    my $payload = $request->{payload};
    $payload->{entity_id} = $id;
    if (lc($payload->{entity_type}) eq 'person') {
        LedgerSMB::Entity::Company->new(%$payload)->save();
    } elsif (lc($payload->{entity_type}) eq 'company'){
        LedgerSMB::Entity::Person->new(%$payload)->save();
    } else {
        die '400 Bad Request:  Must Specify entity_type';
    }
    for my $act (@{$payload->{credit_accounts}}){
        LedgerSMB::Entity::Credit_Account->new(%$payload)->save();
    }
    if ($id){
        die "303 Contact/$id.$request->{format}";
    } else {
        die "303 $id.$request->{format}";
    }
}

=item delete not implemented.

=back

=head1 COPYRIGHT

Copyright (C) 2012, the LedgerSMB Core Team.  This file may be re-used under
the GNU GPL version 2 or at your option any future version.  Please see the
accompanying LICENSE file for details.

=cut

1;
