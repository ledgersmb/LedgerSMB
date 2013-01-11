=head1 NAME

LedgerSMB::Report::Dates - Date properties for reports in LedgerSMB

=head1 SYNOPSIS

 with 'LedgerSMB::Report::Dates'

=cut

package LedgerSMB::Report::Dates;
use Moose::Role;
use LedgerSMB::MooseTypes;

=head1 DESCRIPTION

This handles standard date controls in reports.  It just adds properties to 
relevant Moose objects.

=head1 PROPERTIES ADDED

=over

=item from_date

=cut 

has from_date => (is => 'ro', isa => 'LedgerSMB::Moose::Date', coerce => 1, 
                lazy => 1, builder => '_get_from_date');

=item to_date

=cut 

has to_date => (is => 'ro', isa => 'LedgerSMB::Moose::Date', coerce => 1,
              lazy => 1, builder => '_get_to_date');

=item interval string

Either 'none', 'month', 'quarter', or 'year'

=cut

has interval => (is => 'ro', isa => 'Str', required => 0);

=item from_month int

1 - 12

=cut

has from_month => (is => 'ro', isa => 'Int', required => 0);

=item from_year int

=cut

has from_year => (is => 'ro', isa => 'Int', required => 0);

=back

=cut

sub _get_from_date {
    my ($self) = @_;
    if ($self->from_month and $self->from_year){
        my $date_string = $self->from_year . "-" .  $self->from_month . '-01';
        return LedgerSMB::PGDate->from_db($date_string, 'date');
    } else {
        my ($ref) = $self->exec_method({funcname => 'lsmb__min_date'});
        return $ref->{lsmb__min_date};
    }
}

sub _get_to_date {
    my ($self) = @_;
    if (!$self->from_month or !$self->from_year or $self->interval eq 'none'){
        my ($ref) = $self->exec_method({funcname => 'lsmb__max_date'});
        return $ref->{lsmb__max_date};
    }
    my $dateobj = $self->from_date;
    my $date = $dateobj->from_db($dateobj->to_db, 'date'); # copy, round trip
    if ($self->interval eq 'month'){
       $date->date->add(months => 1);
    } elsif ($self->interval eq 'quarter'){
       $date->date->add(months => 3);
    } elsif ($self->interval eq 'year'){
       $date->date->add(years => 1);
    }
    $date->date->subtract(days => 1); # dates are inclusive
    return $date;
}

before 'render' => sub { 
              my ($self) = @_;
              $self->from_date;
              $self->to_date;
};


=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

1;
