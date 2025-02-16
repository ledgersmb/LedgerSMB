
package LedgerSMB::Report::Dates;

=head1 NAME

LedgerSMB::Report::Dates - Date properties for reports in LedgerSMB

=head1 SYNOPSIS

 with 'LedgerSMB::Report::Dates'

=cut

use LedgerSMB::MooseTypes;
use LedgerSMB::Magic qw( MONTHS_PER_QUARTER );
use LedgerSMB::PGDate;

use Moose::Role;
use namespace::autoclean;

=head1 DESCRIPTION

This handles standard date controls in reports.  It just adds properties to
relevant Moose objects.

=head1 PROPERTIES

=over

=item from_date

=cut

has from_date => (is => 'ro', isa => 'LedgerSMB::PGDate',
                  lazy => 1, builder => '_get_from_date');

=item to_date

=cut

has to_date => (is => 'ro', isa => 'LedgerSMB::PGDate',
                lazy => 1, builder => '_get_to_date');

=item interval string

Either 'none', 'month', 'quarter', or 'year'

=cut

has interval => (is => 'ro', isa => 'Str', required => 0, default => 'None');

=item from_month int

1 - 12

=cut

has from_month => (is => 'ro', isa => 'Int', required => 0);

=item from_year int

=cut

has from_year => (is => 'ro', isa => 'Int', required => 0);

=item comparison_periods

This is the number of periods to compare to

=cut

has comparison_periods => ( is => 'ro', isa => 'Int',
                            required => 0, default => 0);

=item comparison_type

This is either by number of periods or by dates

=cut

has comparison_type => ( is => 'ro', isa => 'Str',
                         required => 0, default => 'by_dates');

=item comparisons

An array of hashes containing the keys 'from_date' and 'to_date'
applicable to each comparison interval.

=cut

has comparisons => ( is => 'ro', isa => 'ArrayRef',
                     required => 0, builder => '_build_comparisons',
                     lazy => 1);


=back

=head1 PROPERTIES (DEPRECATED)

=over

=item date_from

=cut

has date_from => (is => 'ro', lazy => '1', builder => 'from_date');

=item date_to

=cut

has date_to => (is => 'ro', lazy => '1', builder => 'to_date');


=back

=head1 METHODS

=head2 get_bracket_dates

This returns a hashref of from_date/to_date that can be mixed
into the constructor.

These are the first and last date in acc_trans.

=cut

sub get_bracket_dates {
    my ($self) = @_;
    my $return_hashref = {};
    my ($ref) = $self->call_dbmethod(funcname => 'lsmb__min_date');
    if ($ref->{lsmb__min_date}){
        my $dt = LedgerSMB::PGDate->from_db($ref->{lsmb__min_date});
        $dt->is_time(0);
        $return_hashref->{from_date} = $dt
    }
    ($ref) = $self->call_dbmethod(funcname => 'lsmb__max_date');
    if ($ref->{lsmb__max_date}){
         my $dt = LedgerSMB::PGDate->from_db($ref->{lsmb__max_date});
         $dt->is_time(0);
        $return_hashref->{to_date} = $dt
    }
    return $return_hashref;
}

sub _collect_dates_comparisons {
    my (%args) = @_;
    my @dates;

    foreach my $i (1 .. $args{comparison_periods}) {
        push @dates, {
            from_date => LedgerSMB::PGDate->from_input($args{"from_date_$i"},$args{formatter_options}),
            to_date => LedgerSMB::PGDate->from_input($args{"to_date_$i"},$args{formatter_options}),
            column_path_prefix => [ sprintf('%02u', $i) ]
        };
    }

    return \@dates;
}

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    my %args = @_;

    if ($args{comparison_periods}
        && $args{comparison_periods} >= 1) {
        # due to the fact that we get our date comparisons in a flat hash
        # (the request hash), we need to extract them before the object
        # is constructed and they're no longer available.

        # Note that this is an *extreme* hack!!! (which should be removed
        # by handling the request parameters in the request handler better

        if ($args{comparison_type} eq 'by_dates') {
            $args{comparisons} = _collect_dates_comparisons(%args);
        }
    }

    # There are two *mutually exclusive* ways to specify a time range
    if ($args{from_year} && $args{from_month} && $args{interval}) {
        # Prioritise a date range specified as a starting year, month and
        # time interval. The corresponding from_date and to_date values will
        # be calculated and used to populate object properties.
        delete $args{from_date};
        delete $args{to_date};
    }
    else {
        # Use explicit from_date and to_date parameters
        delete $args{from_year};
        delete $args{from_month};
    }

    return $class->$orig(%args);
};

sub _build_comparisons {
    my ($self) = @_;

    my @comparisons;
    if ( $self->comparison_type eq 'by_periods' ) {
        my $interval = $self->interval;
        for my $c_per (1 .. $self->comparison_periods) {
            my $date = $self->date_from->clone->add_interval($interval,-$c_per);

            push @comparisons, {
                from_date => $date,
                to_date => $date->clone->add_interval($interval)
                    ->add_interval('day', -1),
                column_path_prefix => [ sprintf('%02u', $c_per) ]
            };
        }
    }
    return \@comparisons;
}

sub _get_from_date {
    my ($self) = @_;
    if ($self->from_month and $self->from_year){
        my $date_string = $self->from_year . '-' .  $self->from_month . '-01';
        return LedgerSMB::PGDate->from_db($date_string, 'date');
    } else {
        return LedgerSMB::PGDate->from_db();
    }
}

sub _get_to_date {
    my ($self) = @_;
    if (not defined $self->interval
        or $self->interval eq 'none'
        or not defined $self->from_date){
        return LedgerSMB::PGDate->from_db();
    }
    my $dateobj = $self->from_date;
    my $date = LedgerSMB::PGDate->from_db($dateobj->to_db); # copy, round trip
    if ($self->interval eq 'month'){
       $date->add(months => 1);
    } elsif ($self->interval eq 'quarter'){
       $date->add(months => MONTHS_PER_QUARTER);
    } elsif ($self->interval eq 'year'){
       $date->add(years => 1);
    }
    $date->subtract(days => 1); # dates are inclusive
    $date->is_time(0);
    return $date;
}

sub _set_lazy_dates {
              my ($self) = @_;
              # Set lazy attributes
              $self->from_date;
              $self->to_date;
              $self->date_from;
              $self->date_to;
              return;
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


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012-2025 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
