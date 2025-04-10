
package LedgerSMB::PGDate;

=head1 NAME

LedgerSMB::PgDate - Date handling and serialization to database

=head1 DESCRIPTION

This class handles formatting and mapping between the DateTime module and
PostgreSQL. It provides a handler for date datatype.

The type behaves internally as a Datetime module.

=cut

use strict;
use warnings;
use base qw(PGObject::Type::DateTime);

use Carp;
use DateTime;
use DateTime::Format::Strptime;
use Memoize;
use PGObject;

use LedgerSMB::App_State;
use LedgerSMB::Magic
    qw( MONTHS_PER_QUARTER YEARS_PER_CENTURY FUTURE_YEARS_LIMIT );


__PACKAGE__->register(registry => 'default', types => ['date']);

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


# Originally, we used DateTime::Format::Strptime for the tasks of
# formatting as well as parsing.  However, the parser turns out
# (as of version 1.67 of DateTime::Format::Strptime), to match
# 2016-11-30 when requested to match 'dd-mm-yy'; worse, it matches
# it into 2030-11-16.
# Since we only match a limited set of patterns, below is what I
# had expected DateTime::Format::Strptime would have done.
my $regexes = {
    'YYYY-MM-DD' => [ { regex => qr/^(\d{4,4})\-(\d\d)\-(\d\d)$/,
                        fields => [ 'year', 'month', 'day' ] },
                    ],
    'DD-MM-YYYY' => [ { regex => qr/^(\d\d)\-(\d\d)\-(\d{4,4})$/,
                        fields => [ 'day', 'month', 'year' ] },
                    ],
    'DD.MM.YYYY' => [ { regex => qr/^(\d\d)\.(\d\d)\.(\d{4,4})$/,
                        fields => [ 'day', 'month', 'year' ] },
                    ],
    'DD/MM/YYYY' => [ { regex => qr/^(\d\d)\/(\d\d)\/(\d{4,4})$/,
                        fields => [ 'day', 'month', 'year' ] },
                    ],
    'MM-DD-YYYY' => [ { regex => qr/^(\d\d)\-(\d\d)\-(\d{4,4})$/,
                        fields => [ 'month', 'day', 'year' ] },
                    ],
    'MM.DD.YYYY' => [ { regex => qr/^(\d\d)\.(\d\d)\.(\d{4,4})$/,
                        fields => [ 'month', 'day', 'year' ] },
                    ],
    'MM/DD/YYYY' => [ { regex => qr/^(\d\d)\/(\d\d)\/(\d{4,4})$/,
                        fields => [ 'month', 'day', 'year' ] },
                    ],
      'YYYYMMDD' => [ { regex => qr/^(\d{4,4})(\d\d)(\d\d)$/,
                        fields => [ 'year', 'month', 'day' ] },
                    ],
      'DDMMYYYY' => [ { regex => qr/^(\d\d)(\d\d)(\d{4,4})$/,
                        fields => [ 'day', 'month', 'year' ] },
                    ],
      'MMDDYYYY' => [ { regex => qr/^(\d\d)(\d\d)(\d{4,4})$/,
                        fields => [ 'month', 'day', 'year' ] },
                    ],
};

=back

=head1 CONSTRUCTOR SYNTAX

Note the constructor here is private, and not intended to be called directly.

Use from_db and from_input methods instead since these handle appropriately
different formats and handle construction differently.

=cut


=head1 METHODS

=over

=item new

Returns an empty date object when the input is an empty string; otherwise
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

=item from_input($date_string, [$format])

Parses this from an input string according to the user's dateformat,
unless C<$format> has been specified to override it.

=cut

sub from_input{
    my ($self, $input, $format) = @_;

    local $@ = undef;
    return $input if eval {$input->isa(__PACKAGE__)} && $input->is_date;

    return __PACKAGE__->new()
        if ! $input; # matches undefined as well as ''

    my $dt;
    my @fmts;
    if ($format) {
        @fmts = @{$regexes->{uc($format)}};
    }
    elsif (defined LedgerSMB::App_State::User()->{dateformat}) {
        @fmts = @{$regexes->{uc(LedgerSMB::App_State::User()->{dateformat})}};
    }

    for my $fmt (@fmts, @{$regexes->{'YYYY-MM-DD'}} ) {
        my ($success, %args);
        if ($input =~ $fmt->{regex}) {
            @args{@{$fmt->{fields}}} = ($1, $2, $3);
            $success = 1;
        }

        if ($success) {
            $dt = __PACKAGE__->new(%args);
            last;
        }
    }

    die "Bad date ($input)" if $input && ! $dt;
    bless $dt, __PACKAGE__;
    $dt->is_date(1);
    $dt->is_time(($input && $input =~ /\:/) ? 1 : 0); # Define time
    return $dt;
}


=item to_output(optional string $format)

This returns the human readable formatted date.  If $format is supplied, it is
used.  If $format is not supplied, the dateformat of the user is used.

=cut

sub _formatter {
    return DateTime::Format::Strptime->new(@_);
}

# Together with the memoization in PGNumber,
# this workaround shaved off 25% rendering time off a 10k acc_trans
# table (being GL>Search-ed without restrictions)
memoize('_formatter');

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
    my $formatter = _formatter(
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

Copyright (C) 2011-2018 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

# Strings for localization
# Long months are in LedgerSMB.pm
# this is for our short month
# $locale->text('Jan')
# $locale->text('Feb')
# $locale->text('Mar')
# $locale->text('Apr')
# $locale->text('May')
# $locale->text('Jun')
# $locale->text('Jul')
# $locale->text('Aug')
# $locale->text('Sep')
# $locale->text('Oct')
# $locale->text('Nov')
# $locale->text('Dec')

1;
