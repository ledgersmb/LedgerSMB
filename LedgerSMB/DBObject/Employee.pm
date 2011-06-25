package LedgerSMB::DBObject::Employee;

use base qw(LedgerSMB::DBObject);
use strict;

my $ENTITY_CLASS = 3;

sub set_entity_class {
    my $self = shift @_;
    $self->{entity_class} = $ENTITY_CLASS;
}

sub save {
   my ($self) = @_;
   $self->set_entity_class();
   my ($ref) = $self->exec_method(funcname => 'person__save');
   $self->{entity_id} = $ref->{'person__save'};
   $self->exec_method(funcname => 'employee__save');
   $self->{dbh}->commit;
}

sub save_location {
    my $self = shift @_;

    $self->{country_id} = $self->{country_code};

    my ($ref) = $self->exec_method(funcname => 'person__save_location');
    my @vals = values %$ref;
    $self->{location_id} = $vals[0];

    $self->{dbh}->commit;
}

sub save_contact {
    my ($self) = @_;
    $self->{contact_new} = $self->{contact};
    $self->exec_method(funcname => 'person__save_contact');
    $self->{dbh}->commit;
}

sub save_bank_account {
    my $self = shift @_;
    $self->exec_method(funcname => 'entity__save_bank_account');
    $self->{dbh}->commit;
}

sub save_note {
    my $self = shift @_;
    if ($self->{credit_id} && $self->{note_class} eq '3'){
        $self->exec_method(funcname => 'eca__save_notes');
    } else {
        $self->exec_method(funcname => 'entity__save_notes');
    }
    $self->{dbh}->commit;
}
    

=over

=item get_metadata()

This retrieves various information vor building the user interface.  Among other
things, it sets the following properties:
$self->{ar_ap_acc_list} = qw(list of ar or ap accounts)
$self->{cash_acc_list} = qw(list of cash accounts)

=back

=cut

sub get_metadata {
    my $self = shift @_;

    @{$self->{entity_classes}} = 
		$self->exec_method(funcname => 'entity__list_classes');

    @{$self->{location_class_list}} = 
         $self->exec_method(funcname => 'location_list_class');

    @{$self->{country_list}} = 
         $self->exec_method(funcname => 'location_list_country');

    @{$self->{contact_class_list}} = 
         $self->exec_method(funcname => 'entity_list_contact_class');
    my $country_setting = LedgerSMB::Setting->new({base => $self, copy => 'base'});
    $country_setting->{key} = 'default_country';
    $country_setting->get;
    $self->{default_country} = $country_setting->{value};
}

sub get {
    my $self = shift @_;
    my ($ref) = $self->exec_method(funcname => 'employee__get');
    $self->merge($ref);
    @{$self->{locations}} = $self->exec_method(
		funcname => 'person__list_locations');
    @{$self->{contacts}} = $self->exec_method(
		funcname => 'person__list_contacts');
    @{$self->{notes}} = $self->exec_method(
		funcname => 'person__list_notes');
    @{$self->{bank_account}} = $self->exec_method(
		funcname => 'person__list_bank_account');

    
     
}    

sub save_notes {
    my $self = shift @_;
    $self->exec_method(funcname => 'entity__save_notes');
    $self->{dbh}->commit;
}

sub search {
    my $self = shift @_;
    my @results = $self->exec_method(funcname => 'employee__search');
    @{$self->{search_results}} = @results;
    return @results;
}

=over 

=item delete_contact

required request variables:

contact_class_id:  int id of contact class
contact: text of contact information
person_id: int of entity_credit_account.id, preferred value


=back

=cut

sub delete_contact {
    my ($self) = @_;
    $self->exec_method(funcname => 'person__delete_contact');
}

=over

=item delete_location

Deletes a record from the location side.

Required request variables:

location_id
location_class_id
person_id

Returns true if a record was deleted.  False otherwise.

=back

=cut

sub delete_location {
    my ($self) = @_;
    my $rv;
    ($rv) = $self->exec_method(funcname => 'person__delete_location');
    return $rv;
}

=over 

=item delete_bank_account

Deletes a bank account

Requires:

entity_id
bank_account_id

Returns true if a record was deleted, false otherwise.

=back

=cut

sub delete_bank_account {
    my ($self) = @_;
    my $rv;
    ($rv) = $self->exec_method(funcname => 'entity__delete_bank_account',
                               args => [$self->{entity_id}, 
                                        $self->{bank_account_id}]);
    return $rv;
}

1;
