
package LedgerSMB::PGTimestamp;

=head1 NAME

LedgerSMB::PGTimestamp - Timestamp handling and serialization to database

=head1 DESCRIPTION

This class handles formatting and mapping between the DateTime module and
PostgreSQL. It provides a handler for the timestamp datatype.

The type behaves internally as a Datetime module.

=cut

use strict;
use warnings;
use base qw(PGObject::Type::DateTime);

use Carp;
use DateTime::Format::Strptime qw(strptime);

use LedgerSMB::App_State;
use LedgerSMB::Magic
    qw( MONTHS_PER_QUARTER YEARS_PER_CENTURY FUTURE_YEARS_LIMIT );

use overload (
    fallback => 1,
    q{""}    => '_stringify',
    );

__PACKAGE__->register(registry => 'default',
                      types => ['timestamp', 'timestamptz']);

sub _stringify {
    my $self = shift;

    # Stringify without the 'T' in the middle
    #   which is the same way Pg stringifies
    return $self->strftime('%F %T');
}

=head1 SUPPORTED FORMATS

### TO DOCUMENT

=cut


=head1 CONSTRUCTOR SYNTAX

Note the constructor is private, and not intended to be called directly.

Use from_db and from_input methods instead since these handle different
formats appropriately and handle construction

=cut


=head1 METHODS

=over

=item new

Returns an empty timestamp object when the input is an empty string; otherwise
defers object creation to the superclass.

=cut

sub new {
    my $class = shift;
    my @args = @_;

    if (! @args) {
        my $self = {};
        bless $self, $class;

        $self->is_date(0);
        $self->is_time(0);

        return $self;
    }
    return $class->SUPER::new(@args);
}


=item add_interval(string $interval, optional integer $n)

This adds $n * $interval to the date, defaulting to 1 if $n is not supplied.

=cut

sub add_interval {
    my ($self,$interval,$n) = @_;

    my %delta_names = (
        day => 'days',
        week => 'weeks',
        month => 'months',
        quarter => 'months',
        year => 'years',
    );
    my $delta_name = $delta_names{$interval};
    #Validate asked interval
    die "Bad interval: $interval" if not defined $delta_name;

    $n //= 1;    # Default to 1
    $n *= MONTHS_PER_QUARTER if $interval eq 'quarter'; # A quarter is 3 months

    my $has_time = $self->is_time();
    $self->add($delta_name => $n, end_of_month => 'preserve');
    $self->is_time($has_time);  # Make sure that is_time sticks

    return $self;
}

=item from_input($timestamp_string)

Parses the input string as 'YYYY-MM-DD HH:mm:ss' or without the
time part, setting it to 00:00:00.

=cut

our $formats = {
    'YYYY-MM-DD' => '%F',
    'DD-MM-YYYY' => '%d-%m-%Y',
    'DD.MM.YYYY' => '%d.%m.%Y',
    'DD/MM/YYYY' => '%d/%m/%Y',
    'MM-DD-YYYY' => '%m-%d-%Y',
    'MM/DD/YYYY' => '%m/%d/%Y',
    'MM.DD.YYYY' => '%m.%d.%Y',
      'YYYYMMDD' => '%Y%m%d',
      'DDMMYYYY' => '%d%m%Y',
      'MMDDYYYY' => '%m%d%Y',
};

my $pref_parser =  DateTime::Format::Strptime->new(
    pattern   => '%F %T',
    locale    => 'en_US',
    strict    => 1,
    time_zone => 'UTC',
    on_error  => 'undef' );

my $fb_parser =  DateTime::Format::Strptime->new(
    pattern   => '%F',
    locale    => 'en_US',
    strict    => 1,
    time_zone => 'UTC',
    on_error  => 'undef' );


sub from_input{
    my ($self, $input) = @_;

    local $@ = undef;
    return $input if eval {$input->isa(__PACKAGE__)} && $input->is_date;

    return __PACKAGE__->new()
        if ! $input; # matches undefined as well as ''

    my $dt = $pref_parser->parse_datetime($input)
        // $fb_parser->parse_datetime($input);

    die "Bad timestamp ($input)" if $input && ! $dt;
    bless $dt, __PACKAGE__;
    $dt->is_date(1);
    $dt->is_time(($input && $input =~ /\:/) ? 1 : 0); # Define time
    return $dt;
}


=item to_output(optional string $format)

This returns the human readable formatted date.  If $format is supplied, it is
used.  If $format is not supplied, the dateformat of the user is used.

=cut

sub to_output {
    my ($self) = @_;
    return '' if not $self->is_date();
    my $fmt;
    if (defined LedgerSMB::App_State::User()->{dateformat}){
        $fmt = LedgerSMB::App_State::User()->{dateformat};
    } else {
        $fmt = '%F';
    }
    $fmt = $formats->{uc($fmt)} if defined $formats->{uc($fmt)};

    $fmt .= ' %T' if $self->is_time();
    $fmt =~ s/^\s+//;

    # the hard-coded 'en_US' locale here is no problem: it's used
    # for the %b format ('mon') to look up the names of the months;
    # however, we only support numeric formats
    my $formatter = DateTime::Format::Strptime->new(
             pattern => $fmt,
              locale => 'en_US',
            on_error => 'croak',
    );
    my $date = $formatter->format_datetime($self);
    if ($date =~ /\:/ and not $self->is_time()) { die 'to_output'; }
    return $date;
}

=item $self->to_sort()

Returns sortable key for the Date/Time value (epoch)

=cut

sub to_sort {
    my $self = shift;
    return $self->epoch;
}

#__PACKAGE__->meta->make_immutable;

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011-2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
