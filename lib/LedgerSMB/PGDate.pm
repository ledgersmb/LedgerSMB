=head1 NAME

LedgerSMB::PgDate - Date handling and serialization to database

=cut

package LedgerSMB::PGDate;
use DateTime::Format::Strptime;
use LedgerSMB::App_State;
use Carp;
use PGObject;
use base qw(PGObject::Type::DateTime);
use strict;
use warnings;

PGObject->register_type(pg_type => $_,
                                  perl_class => __PACKAGE__)
   for ('date');


=head1 SYNPOSIS
This class handles formatting and mapping between the DateTime module and
PostgreSQL. It provides a handler for date and timestamp datatypes.

The type behaves internally as a Datetime module.

=head1 SUPPORTED FORMATS

Formats are written with hyphens as separators.  You can actually use any other
character other than D, M, or Y as the separator, so instead of YYYY-MM-DD, you
could have YYYY/MM/DD, YYYY!MM!DD, etc.

On the database side, these are all converted to YYYY-MM-DD format.

=over

=item 'YYYY-MM-DD'

=item DD-MM-YYYY


=item DD/MM/YYYY

=item MM-DD-YYYY

=item MM/DD/YYYY

=item YYYYMMDD

=item YYMMDD

=item DDMMYYYY

=item DDMMYY

=item MMDDYYYY

=item MMDDYY

=item DDmonYYYY

=cut

our $formats = {
    'YYYY-MM-DD' => ['%F'],
    'DD-MM-YYYY' => ['%d-%m-%Y', '%d-%m-%y'],
    'DD.MM.YYYY' => ['%d.%m.%Y', '%d.%m.%y'],
    'DD/MM/YYYY' => ['%d/%m/%Y', '%D'],
    'MM-DD-YYYY' => ['%m-%d-%Y', '%m-%d-%y'],
    'MM/DD/YYYY' => ['%d/%m/%Y', '%d/%m/%y'],
    'MM.DD.YYYY' => ['%d.%m.%Y', '%d.%m.%y'],
      'YYYYMMDD' => ['%Y%m%d'],
        'YYMMDD' => ['%y%m%d'],
      'DDMMYYYY' => ['%d%m%Y'],
        'DDMMYY' => ['%d%m%y'],
      'MMDDYYYY' => ['%m%d%Y'],
        'MMDDYY' => ['%m%d%y'],
     'DDmonYYYY' => ['%d%b%Y', '%d%b%y']
};

=back

=head1 CONSTRUCTOR SYNTAX

LedgerSMB::PgDate->new({ date => DateTime->new(year => 2012, day => 31, month =>
12)});

Note the constructor here is private, and not intended to be called directly.

Use from_db and from_input methods instead since these handle appropriately
different formats and handle construction differently.

=cut


=head1 METHODS

=over

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
    $n *= 3 if $interval eq 'quarter'; # A quarter is 3 months

    my $has_time = $self->is_time();
    $self->add($delta_name => $n, end_of_month => 'preserve');
    $self->is_time($has_time);  # Make sure that is_time sticks

    return $self;
}

=item from_input($string date, optional $has_time)

Parses this from an input string according to the user's dateformat

Input parsing iterates through formats specified for the format string.  If
$has_time is set and true, or if it is not defined then ' %T' is added to the
end of the format string.  Similarly, if $has_time is undef or set and false,
the format is used as is.  This allows the calling scripts to specify either
that the string includes a time portion or that it does not, and allows this
module to handle the parsing.

=cut

sub from_input{
    my ($self, $input) = @_;
    {
        local $@;
        return $input if eval {$input->isa(__PACKAGE__)} && $input->is_date;
    }
    my $dt = $self->from_db($input);
    die "Bad date" if $input && not $dt->is_date;
    die "Bad time" if $input && $input =~ /\:/ and not $dt->is_time();
    bless $dt, __PACKAGE__;
    $dt->is_time(($input && $input =~ /\:/) ? 1 : 0); # Redefine time. Why?
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
    if (defined $LedgerSMB::App_State::User->{dateformat}){
        $fmt = $LedgerSMB::App_State::User->{dateformat};
    } else {
        $fmt = '%F';
    }
    $fmt = $formats->{uc($fmt)}->[0] if defined $formats->{uc($fmt)};

    $fmt .= ' %T' if $self->is_time();
    $fmt =~ s/^\s+//;

    my $formatter = new DateTime::Format::Strptime(
             pattern => $fmt,
              locale => 'en_US',
            on_error => 'croak',
    );
    my $date = $formatter->format_datetime($self);
    if ($date =~ /\:/ and not $self->is_time()) { die "to_output"; }
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

1;

=back

=head1 Copyright (C) 2011, The LedgerSMB core team.

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.
