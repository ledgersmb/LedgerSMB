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

has date_from => (is => 'ro', lazy => '1', builder => 'from_date');

has date_to => (is => 'ro', lazy => '1', builder => 'to_date');

sub _get_from_date {
    my ($self) = @_;
    if ($self->from_month and $self->from_year){
        my $date_string = $self->from_year . "-" .  $self->from_month . '-01';
        return LedgerSMB::PGDate->from_db($date_string, 'date');
    } else {
        my ($ref) = $self->call_dbmethod(funcname => 'lsmb__min_date');
        if ($ref->{lsmb__min_date}){
            my $dt = LedgerSMB::PGDate->from_db($ref->{lsmb__min_date});
            $dt->is_time(0);
            return $dt;
        } else {
            return LedgerSMB::PGDate->from_db();
        }

    }
}

sub _get_to_date {
    my ($self) = @_;
    if (!$self->from_month or !$self->from_year or $self->interval eq 'none'){
        my ($ref) = $self->call_dbmethod(funcname => 'lsmb__max_date');
        if ($ref->{lsmb__max_date}){
             my $dt = LedgerSMB::PGDate->from_db($ref->{lsmb__max_date});
             $dt->is_time(0);
             return $dt;
        } else {
            return LedgerSMB::PGDate->from_db();
        }

    }
    my $dateobj = $self->from_date;
    my $date = $dateobj->from_db($dateobj->to_db); # copy, round trip
    if ($self->interval eq 'month'){
       $date->add(months => 1);
    } elsif ($self->interval eq 'quarter'){
       $date->add(months => 3);
    } elsif ($self->interval eq 'year'){
       $date->add(years => 1);
    }
    $date->subtract(days => 1); # dates are inclusive
    return $date;
}

sub _set_lazy_dates {
              my ($self) = @_;
              # Set lazy attributes
              $self->from_date;
              $self->to_date;
              $self->date_from;
              $self->date_to;
}

before 'render' => sub {
              my ($self) = @_;
              # Set lazy attributes
              $self->_set_lazy_dates;
};
before 'run_report' => sub {
              my ($self) = @_;
              # Set lazy attributes
              $self->_set_lazy_dates;
};


=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

1;
