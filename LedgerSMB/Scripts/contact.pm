
=pod

=head1 NAME

LedgerSMB::Scripts::contact - LedgerSMB class defining the Controller
functions, template instantiation and rendering for customer editing and display.

=head1 SYOPSIS

This module is the UI controller for the customer, vendor, etc functions; it 

=head1 METHODS

=cut

package LedgerSMB::Scripts::contact;

use LedgerSMB::DBObject::Customer;
use base qw(LedgerSMB::ScriptLib::Company);


=head1 INHERITS

LedgerSMB::ScriptLib::Company

=head1 COPYRIGHT

Copyright (c) 2009, the LedgerSMB Core Team.  This is licensed under the GNU 
General Public License, version 2, or at your option any later version.  Please 
see the accompanying License.txt for more information.

=cut

=head1 METHODS

=over

=item get_by_cc 

Populates the company area with info on the company, pulled up through the 
control code

=cut

sub get_by_cc {
    my ($request) = @_;
    $request->{entity_class} ||= $request->{account_class};
    $request->{legal_name} ||= 'test';
    $request->{country_id} = 0;
    my $company = LedgerSMB::DBObject::Entity::Company->new(%$request);
    $company = $company->get_by_cc($request->{control_code});
    $request->{company} = $company;
    LedgerSMB::ScriptLib::Company::_render_main_screen($request, $company);
}


=item get($self, $request, $user)

Requires form var: id

Extracts a single company from the database, using its company ID as the primary
point of uniqueness. Shows (appropriate to user privileges) and allows editing
of the company information.

=cut

sub get {
    my ($request) = @_;
    $request->{entity_class} ||= $request->{account_class};
    $request->{legal_name} ||= 'test';
    my $company = LedgerSMB::DBObject::Entity::Company->new(%$request);
    $company = $company->get($request->{entity_id});
    $request->{company} = $company;
    LedgerSMB::ScriptLib::Company::_render_main_screen($request, $company);
}


1;
