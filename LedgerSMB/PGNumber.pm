=head1 NAME

LedgerSMB::PGNumeric

=cut


package LedgerSMB::PGNumber;
# try using the GMP library for Math::BigFloat for speed
use Math::BigFloat try => 'GMP';
use base qw(PGObject::Type::BigFloat);
use strict;
use warnings;
use Number::Format;
use LedgerSMB::Setting;

PGObject->register_type(pg_type => $_,
                                  perl_class => __PACKAGE__)
   for ('float4', 'float8', 'double precision', 'float', 'numeric');


=head1 SYNPOSIS

This is a wrapper class for handling a database interface for numeric (int,
float, numeric) data types to/from the database and to/from user input.

This extends PBObject::Type::BigFloat which further extends LedgerSMB::PGNumber and
can be used in this way.

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

use overload "bool" => "_bool";

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
      "1000.00" => { thousands_sep => '',  decimal_sep => '.' },

      "1000,00" => { thousands_sep => '',  decimal_sep => ',' },
     "1 000.00" => { thousands_sep => ' ', decimal_sep => '.' },
     "1 000,00" => { thousands_sep => ' ', decimal_sep => ',' },
     "1,000.00" => { thousands_sep => ',', decimal_sep => '.' },
     "1.000,00" => { thousands_sep => '.', decimal_sep => ',' },
     "1'000,00" => { thousands_sep => "'", decimal_sep => ',' },
     "1'000.00" => { thousands_sep => "'", decimal_sep => '.' },

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

=head1 IO METHODS

=over

=item from_input(string $input, hashref %args);

The input is formatted.

=cut

sub from_input {
    my $self   = shift @_;
    my $string = shift @_;
    { # pre-5.14 compatibility block
        local ($@); # pre-5.14, do not die() in this block
        return $string if eval { $string->isa(__PACKAGE__) };
    }
    #tshvr4 avoid 'Use of uninitialized value $string in string eq'
    if(!defined $string || $string eq ''){
     return undef;
    }
    #$string = undef if $string eq '';
    my %args   = (ref($_[0]) eq 'HASH')? %{$_[0]}: @_;
    my $format = ($args{format}) ? $args{format}
                              : $LedgerSMB::App_State::User->{numberformat};
    die 'LedgerSMB::PGNumber No Format Set' if !$format;
    #return undef if !defined $string;
    my $negate;
    my $pgnum;
    my $newval;
    $negate = 1 if $string =~ /(^\(|DR$)/;
    if ( UNIVERSAL::isa( $string, 'LedgerSMB::PGNumber' ) )
    {
        return $string;
    }
    if (UNIVERSAL::isa( $string, 'LedgerSMB::PGNumber' ) ) {
        $pgnum = $string;
    } else {
        my $formatter = new Number::Format(
                    -thousands_sep => $lsmb_formats->{$format}->{thousands_sep},
                    -decimal_point => $lsmb_formats->{$format}->{decimal_sep},
        );
        $newval = $formatter->unformat_number($string);
        $pgnum = LedgerSMB::PGNumber->new($newval);
        $self->round_mode('+inf');
    }
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

=item money

Specifies to round to configured number format for money

=item neg_format

Specifies the negative format

=item locale

=back

=cut

sub to_output {
    my $self = shift @_;
    my %args  = (ref($_[0]) eq 'HASH')? %{$_[0]}: @_;
    $args{money} = 1 if $ENV{LSMB_ALWAYS_MONEY};
    my $is_neg = $self->is_neg;

    my $format = ($args{format}) ? $args{format}
                              : $LedgerSMB::App_State::User->{numberformat};
    die 'LedgerSMB::PGNumber No Format Set, check numberformat in user_preference' if !$format;

    my $places = undef;
    $places = LedgerSMB::Setting->get('decimal_places') if $args{money};
    $places = ($args{places}) ? $args{places} : $places;
    my $str = $self->bstr;
    my $dplaces = $places;
    $places = 0 unless defined $places and ($places > 0);
    my $zfill = ($places > 0) ? 1 : 0;
    $dplaces = 5 unless defined $dplaces;
    my $formatter;
    if ($format eq '1000.00'){ # Default decimal sep, no thousands sep
        $formatter =  new Number::Format(
                  -decimal_fill => $zfill,
                  -neg_format => 'x'
        );
        $str = $formatter->format_number($str, $dplaces);
        $str =~ s/,//g;
    } else {
        $formatter = new Number::Format(
                    -thousands_sep => $lsmb_formats->{$format}->{thousands_sep},
                    -decimal_point => $lsmb_formats->{$format}->{decimal_sep},
                     -decimal_fill => $zfill,
                       -neg_format => 'x'
        );
        $str = $formatter->format_number($str, $dplaces);
    }

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

1;

=back

=head1 Copyright (C) 2011, The LedgerSMB core team.

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

