=head1 NAME

LedgerSMB::ScriptLib::Common_Search::Part - Part Search Routines

=head1 SYNPOSIS

This provides functionality to search for a part, for new 1.3-framework code.

=cut

package LedgerSMB::ScriptLib::Common_Search::Part;
use strict;
use warnings;
use LedgerSMB::DBObject::Part; 

=head1 PROPERTIES/ACCESSORS

=over

=item columns (Global, static, read-only)

Returns a list of columns for the embedded table engine as an arrayref.

=cut

my $COLUMNS = [
      {col_id => 'id',
         name => 'ID',
         type => 'mirrored', }

      {col_id => 'partnumber',
         name => 'Partnumber',
         type => 'mirrored', },

      {col_id => 'description',
         name => 'Description',
         type => 'mirrored', },

      {col_id => 'on_hand',
         name => 'On Hand',
         type => 'text', } ,
      # Can add more later
];

sub columns {
   return $COLUMNS;
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
    my ($request) = @_;
    my $self = {};
    bless $self, __PACKAGE__;
    $self->{_part} = LedgerSMB::DBObject::Part->new({base => $request});
    $self->{_results} = [];
    return $self;
};


=item search({partnumber => $string, description => $string})

Performs a search and caches it.  One object should be used per search unless
results are no longer needed.

=cut

sub search {
    my ($self, $args) = @_;
    @results = $self->{_part}->search($args);
    $self->{_results} = \@results;
    return $self->{_results};
}

=back

=head1 COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team.  This file may be used in 
accordance with the GNU General Public License version 2 or at your option any
later version.  Please see attached LICENSE file for details.

=cut

return 1;
