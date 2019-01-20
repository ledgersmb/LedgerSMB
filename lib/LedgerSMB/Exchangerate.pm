=head1 NAME

LedgerSMB::Exchangerate - Accounting Reporting Dimensions for LedgerSMB

=head1 DESCRIPTION

This holds the information as to the handling of classes of buisness units.
Business units are reporting units which can be used to classify various line
items of transactions in different ways and include handling for departments,
funds, and projects.

=cut

package LedgerSMB::Exchangerate;

use Moose;
use namespace::autoclean;

use LedgerSMB::MooseTypes;
use LedgerSMB::PGObject;
with 'LedgerSMB::PGObject';



=head1 PROPERTIES

=over

=item curr

Required. This is the 3-letter (ISO) currency identifier.
  (cur, type_id, valid_from) together make the primary key for the rate.

Note: the currency needs to be configured before it can be used.

=cut

has 'curr' => (is => 'ro', isa => 'Str', required => 1);

=item rate_type

Required. Internal id of rate type.

=cut

has 'rate_type' => (is => 'ro', isa => 'Int', required => '1');

=item valid_from

Required. This is the first date that the rate is applicable (inclusive).

=cut

has 'valid_from' => (is => 'ro', isa => 'LedgerSMB::Moose::Date',
   required => '1', coerce => 1);


=item valid_until

TODO.

Optional. 'infinity' by default. If a record exists with a later 'valid_from'
than the current record, 'valid_until' is "cut-off" by the existence of
such a record.

=cut

#
#has 'valid_until' => (is => 'rw', isa => 'LedgerSMB::Timestamp')
#
#

=item rate

Rate as foreign currency units per base currency unit.

=cut

has 'rate' => (is => 'rw', isa => 'LedgerSMB::Moose::Number',
                 coerce => 1);

=back

=head1 METHODS

=over

=item get($curr, $type, $date)

Returns the exchange rate applicable on $date for $curr and $type.

Note: the returned value's 'valid_from' value may not be equal to the
  input date, because of validity intervals: this function returs
  *the record valid on the specified date*.

=cut

sub get {
    my ($self, $curr, $type, $date) = @_;
    my ($unit) = $self->call_procedure(funcname => 'exchangerate__get',
                                       args => [$curr, $type, $date]
    );
    return $self->new(%$unit);
}

=item save

Saves the exchange rate.

=cut

sub save {
    my ($self) = @_;
    my ($ref) = $self->call_dbmethod(funcname => 'exchangerate__save');
    $self = $self->new($ref);
}

=item list (curr => $curr, start => $date, end => $date, type => $rate_type_id)

Lists all exchange rates of currency $curr and class $class_id, which have a
valid_from date between $start and $end (inclusive).  undef for $curr or
$class_id select all currencies or classes respectively.
undef on $start and $end means no lower or upper bound on the valid_from date,
respectively.

=cut

sub list {
    my ($self, %args) = @_;
    my @rows =  $self->call_procedure(funcname => 'exchangerate__list',
                                      args => [$args{curr}, $args{type},
                                               $args{start}, $args{end},
                                               $args{offset}, $args{limit}]);
    for my $row(@rows){
        $row = $self->new($row);
    }
    return @rows;
}

=item delete

Deletes the exchange rate.

Note: deleting exchange rates generally doesn't make much sense as rate information
         is copied into transactions using the rates. Thus deleting rates only impacts future
         database actions.

=cut

sub delete {
    my ($self) = @_;
    my ($ref) = $self->call_dbmethod(funcname => 'exchangerate__delete');
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;
1;
