=head1 NAME

LedgerSMB::ScriptLib::Common_Search::Customer - Customer Search Routines

=head1 SYNPOSIS

This provides functionality to search for a customer,
for new 1.3-framework code.

=cut

package LedgerSMB::ScriptLib::Common_Search::Customer;
use base qw(LedgerSMB::ScriptLib::Common_Search);
use strict;
use warnings;
use LedgerSMB::DBObject::Customer;

=head1 PROPERTIES/ACCESSORS

=over

=item columns (Global, static, read-only)

Returns a list of columns for the embedded table engine as an arrayref.

=cut

my $COLUMNS = [
      {col_id => 'entity_control_code',
         name => 'Control code',
         type => 'mirrored', },

      {col_id => 'meta_number',
         name => 'Account number',
         type => 'mirrored', },

      {col_id => 'legal_name',
         name => 'Company name',
         type => 'mirrored', },

      {col_id => 'credit_description',
         name => 'Description',
         type => 'mirrored', },

      # Can add more later
];

sub columns {
   return $COLUMNS;
}


=item row_id

Returns the name of the column which contains the row unique id.  

=cut

sub row_id {
    return 'entity_id';
}

=item results

Returns a list of results as an array of hashrefs.

=cut

sub results {
    my ($self) = @_;
    return $self->{_results};
}

=back

=head1 METHODS

=over 

=item new ($request)

Instantiates a new search object.

=cut

sub new {
    my ($pkg, $request) = @_;
    my $self = {};
    bless $self, __PACKAGE__;
    $self->{_customer} =
	LedgerSMB::DBObject::Customer->new({base => $request});
    $self->{_results} = [];
    return $self;
};


=item search({contact => $string, contact_info => $string,
  meta_number => $string, address => $string, city => $string,
  state => $string, mail_code => $string, country => $string,
  date_from => $string, date_to => $string, business_id => $int,
  legal_name => $string, control_code => $string})

Performs a search and caches it.  One object should be used per search unless
results are no longer needed.

=cut

sub search {
    my ($self, $args) = @_;
    $args->{account_class} = 2; # search requires account_class (1=customer)
    $self->{_customer}->merge($args);
    my @results = $self->{_customer}->search;
    $self->{_results} = \@results;
    return @{$self->{_results}};
}

=back

=head1 COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team.  This file may be used in 
accordance with the GNU General Public License version 2 or at your option any
later version.  Please see attached LICENSE file for details.

=cut

return 1;
