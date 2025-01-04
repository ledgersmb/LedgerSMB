
package LedgerSMB::PGNumber;

=head1 NAME

LedgerSMB::PGNumber - Number handling and serialization to database

=head1 DESCRIPTION

This is a wrapper class for handling a database interface for numeric (int,
float, numeric) data types to/from the database and to/from user input.

This extends PGObject::Type::BigFloat which further extends
Math::BigFloat and can be used in this way.

=cut

use v5.36.1;
use warnings;
use parent qw(PGObject::Type::BigFloat);

# try using the GMP library for Math::BigFloat for speed
use Carp;
use Math::BigFloat try => 'GMP';
use Memoize;
use Number::Format;
use PGObject::Type::BigFloat;

use LedgerSMB::Magic qw( DEFAULT_NUM_PREC );

__PACKAGE__->register(registry => 'default',
    types => [qw(float4 float8 float numeric), 'double precision']);

our ($accuracy, $precision, $round_mode, $div_scale);

# Same initialization as PGObject::Type::BigFloat
# which works around Math::BigFloat's weird idea of OO
$accuracy = $precision = undef;
$round_mode = 'even';
$div_scale = 40;

# Prevent downgrading to Math::BigInt
$Math::BigFloat::downgrade = undef;

=head1 INHERITS

=over

=item LedgerSMB::PGNumber

=back

=cut

=head1 OVERLOADS

=over

=item "bool"

=back

=cut

use overload 'bool' => '_bool';

# function to return boolean value based on the numerical value
# of the BigFloat (zero being false)
sub _bool {
    my ($self) = @_;

    return !($self == 0);
}


=head1 SUPPORTED I/O FORMATS

=over

=item 1000.00 (default)

=item 1000,00

=item 1 000.00

=item 1 000,00

=item 1,000.00

=item 1.000,00

=item 1'000,00

=item 1'000.00

=cut

our $lsmb_formats = {
       '1000.00' => { thousands_sep => '',   decimal_sep => '.' },
       '1000,00' => { thousands_sep => '',   decimal_sep => ',' },
      '1 000.00' => { thousands_sep => ' ',  decimal_sep => '.' },
      '1 000,00' => { thousands_sep => ' ',  decimal_sep => ',' },
      '1,000.00' => { thousands_sep => ',',  decimal_sep => '.' },
      '1.000,00' => { thousands_sep => '.',  decimal_sep => ',' },
     q{1'000,00} => { thousands_sep => q{'}, decimal_sep => ',' },
     q{1'000.00} => { thousands_sep => q{'}, decimal_sep => '.' },

};

=back

=head1 SUPPORTED NEGATIVE FORMATS

All use 123.45 as an example.

=over

=item def (DEFAULT)

positive:  123.45
negative: -123.45

=item DRCR

positive:  123.45 CR
negative:  123.45 DR

=item paren

positive:  123.45
negative: (123.45)

=cut

my $lsmb_neg_formats = {
  'def' => { pos => '%s',   neg => '-%s'   },
 'DRCR' => { pos => '%s CR', neg => '%s DR' },
'paren' => { pos => '%s',   neg => '(%s)'  },
};

=back

=head1 METHODS

=over

=item new;

Constructor to prevent BigFloat downgrades to BigInt

=cut

sub _formatter {
    return Number::Format->new(@_);
}

# Together with the memoization in PGNumber,
# this workaround shaved off 25% rendering time off a 10k acc_trans
# table (being GL>Search-ed without restrictions)
memoize('_formatter');


sub new {
    my $class = shift;
    local $Math::BigFloat::downgrade = undef;
    return $class->SUPER::new(@_);
}

=item from_input(string $input, hashref %args);

The input is formatted.

=cut

sub from_input {
    my $self = shift;
    my $string = shift;

    return $string if $string isa __PACKAGE__;
    if (!defined $string || $string eq '') {
        return undef;
    }
    my %args   = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;
    my $format = $args{format} // $args{numberformat};
    croak 'LedgerSMB::PGNumber No Format Set' if !$format;

    my $negate;
    my $pgnum;
    my $newval;
    $negate = 1 if $string =~ /(^\(|DR$)/;

    my $formatter = _formatter(
        -thousands_sep => $lsmb_formats->{$format}->{thousands_sep},
        -decimal_point => $lsmb_formats->{$format}->{decimal_sep},
        );
    $newval = $formatter->unformat_number($string);
    $pgnum = LedgerSMB::PGNumber->new($newval);
    $self->round_mode('+inf');

    bless $pgnum, $self;
    $pgnum->bmul(-1) if $negate;
    die 'LedgerSMB::PGNumber Invalid Number' if $pgnum->is_nan();
    return $pgnum;
}

=item to_output($hashref or %hash);

All arguments are optional.  Hash or hashref arguments include

=over

=item format

Override user's default output format with specified format for this number.

=item places

Specifies the number of places to round

=item money_places

Specifies the number of decimal places for for money

=item money

Specifies to round to configured number format for money

=item neg_format

Specifies the negative format

=back

=cut


sub to_output {
    my $self = shift @_;
    my %args  = (ref($_[0]) eq 'HASH')? %{$_[0]}: @_;
    my $is_neg = $self->is_neg;

    my $format = $args{format} // $args{numberformat};
    croak 'LedgerSMB::PGNumber No Format Set, check numberformat in user_preference' if !$format;

    my $places = undef;
    $places = $args{money_places} if $args{money};
    $places = ($args{places}) ? $args{places} : $places;
    my $str = $self->bstr;
    my $dplaces = $places;
    $places = 0 unless defined $places and ($places > 0);
    my $zfill = ($places > 0) ? 1 : 0;
    $dplaces = DEFAULT_NUM_PREC  unless defined $dplaces;
    my $formatter = _formatter(
        -thousands_sep => $lsmb_formats->{$format}->{thousands_sep},
        -decimal_point => $lsmb_formats->{$format}->{decimal_sep},
        -decimal_fill => $zfill,
        -neg_format => 'x'
    );
    $str = $formatter->format_number($str, $dplaces);

    my $neg_format = ($args{neg_format}) ? $args{neg_format} : 'def';
    $neg_format = 'def' unless $lsmb_neg_formats->{$neg_format};
    my $fmt = ($is_neg) ? $lsmb_neg_formats->{$neg_format}->{neg}
                        : $lsmb_neg_formats->{$neg_format}->{pos};

    return sprintf($fmt, $str);
}

=item to_sort

Returns the value for sorting purposes

=cut

sub to_sort {
    return $_[0]->bstr;
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011-2018 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
