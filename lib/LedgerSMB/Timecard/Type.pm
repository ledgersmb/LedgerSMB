=head1 NAME

LedgerSMB::Timecard::Type - Timecard Types for LedgerSMB

=head1 SYNOPSIS

To retrieve a specific timecard type:

 my $type = LedgerSMB::Timecard::Type->get($id);

To list all types, orderd by label:

 my @types = LedgerSMB::Timecard::Type->list();

=cut

package LedgerSMB::Timecard::Type;
use Moose;
with 'LedgerSMB::PGObject';

=head1 DESCRIPTION

The timecard type system is used to categorize time, material, and overhead
cards for projects, payroll, manufacturing, and the like.  These are not
created through the front-end but rather integral to modules which may be
developed in the future.  The three preloaded types are:

=over

=item time

Tracks time used for professional services for projects.

=item materials

Tracks materials used for projects

=item overhead

Tracks time used for payroll and the like.

=back

Other types may be created over time.

=head1 PROPERTIES

=over

=item id int

This is the internal id of the timecard type.

=cut

has id => (is => 'ro', isa => 'Str', required => 1);

=item label string

This is the human readable ID of the timecard type

=cut

has label => (is => 'ro', isa => 'Str', required => 1);

=item description string

General description for the timecard type

=cut

has description => (is => 'ro', isa => 'Str', required => 1);

=item is_service bool

If this is set to true, then the timecards associated will only pull services.

=cut

has is_service => (is => 'ro', isa => 'Bool', required => 1);

=item is_timecard bool

If true, then the timecard will pull only labor and overhead

=cut

has is_timecard => (is => 'ro', isa => 'Bool', required => 1);


=back

=head1 METHODS

=over

=item get($id int)

Retrieves information for a specific timecard type

=cut

sub get {
    my ($self, $id) = @_;
    my ($ref) = __PACKAGE__->call_procedure(
         funcname => 'timecard_type__get', args => [$id]
    );
    return __PACKAGE__->new($ref);
}

=item list()

Retrieves a list of all timecard types.

=cut

sub list {
    my @results = __PACKAGE__->call_procedure(
            funcname => 'timecard_type__list'
    );
    my @types;
    for my $r (@results){
        push @types, __PACKAGE__->new(%$r);
    }
    return @types;
}

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

__PACKAGE__->meta->make_immutable;
1;

