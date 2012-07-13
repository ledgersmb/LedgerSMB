=head1 NAME

LedgerSMB::REST_Class::Contact - Customer/vendor web servicesA

=cut

package LedgerSMB::REST_Class::Contact;
use LedgerSMB::DBObject::Entity;
use LedgerSMB::DBObject::Entity::Credit_Acount;
use LedgerSMB::DBObject::Entity::Location;
use LedgerSMB::DBObject::Entity::Contact;
use LedgerSMB::DBObject::Entity::Company;
use LedgerSMB::DBObject::Entity::Person;
use LedgerSMB::DBObject::Entity::Bank;

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
    my $id = $request->{$cname};
    my $data;
    if ($id){
       my $company = LedgerSMB::DBObject::Entity::Company->get($id);
       if ($company){
          $data= $company;
          $data->{entity_type} = 'Company';
       } else {
          my $person = LedgerSMB::DBObject::Entity::Person->get($id);
          if ($person){
             $data= $person;
             $data->{entity_type} = 'Person';
          } else {
             die '404  Not Found';
          }
       }
       @{$data->{credit_accounts}} = 
          LedgerSMB::DBObject::Entity::Credit_Account->list_for_entity($id);
       @{$data->{locations}} = 
         LedgerSMB::DBObject::Entity::Location->get_active({entity_id => $id});
       @{$data->{contact}} =
         LedgerSMB::DBObject::Entity::Contact->list({{entity_id => $id}});
       @{$data->{bank_accounts}} = 
         LedgerSMB::DBObject::Entity::Bank-> list($id);
       return $data;
    } else {
       ...
    }
}

=item post

Determines of record exists and if not creates it.  If so, throws a 400 error

=item put

Saves record, overwriting any record that was there before.

=item delete not implemented.

=back

=head1 COPYRIGHT

Copyright (C) 2012, the LedgerSMB Core Team.  This file may be re-used under 
the GNU GPL version 2 or at your option any future version.  Please see the 
accompanying LICENSE file for details.

=cut

