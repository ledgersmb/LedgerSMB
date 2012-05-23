=head1 NAME

LedgerSMB::PGNumeric

=cut

use strict;
use warnings;
use Number::Format;

package LedgerSMB::PGNumber;

BEGIN {
   use LedgerSMB::SODA;
   LedgerSMB::SODA->register_type({sql_type => 'float', 
                                 perl_class => 'LedgerSMB::PGNumber'});
   LedgerSMB::SODA->register_type({sql_type => 'double', 
                                 perl_class => 'LedgerSMB::PGNumber'});
   LedgerSMB::SODA->register_type({sql_type => 'numeric', 
                                 perl_class => 'LedgerSMB::PGNumber'});
}

=head1 SYNPOSIS

This is a wrapper class for handling a database interface for numeric (int, 
float, numeric) data types to/from the database and to/from user input.

This extends Math::BigFloat and can be used in this way.

=head1 INHERITS

=over

=item Math::BigFloat

=back

=cut

use base qw(Math::BigFloat);

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
    my %args   = (ref($_[0]) eq 'HASH')? %{$_[0]}: @_;  
    my $format = ($args{format}) ? $args{format}
                              : $LedgerSMB::App_State::User->{numberformat};
    die 'LedgerSMB::PGNumber No Format Set' if !$format;
    return undef if !defined $string;
    my $negate;
    my $pgnum;
    my $newval;
    $negate = 1 if $string =~ /(^\(|DR$)/;
    if ( UNIVERSAL::isa( $string, 'LedgerSMB::PGNumber' ) )
    {    
        return $string;
    }
    if (UNIVERSAL::isa( $string, 'Math::BigFloat' ) ) {
        $pgnum = $string; 
    } else {
        my $formatter = new Number::Format(
                    -thousands_sep => $lsmb_formats->{$format}->{thousands_sep},
                    -decimal_point => $lsmb_formats->{$format}->{decimal_sep},
        );
        $newval = $formatter->unformat_number($string);
        $pgnum = Math::BigFloat->new($newval);
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
    my $is_neg = $self->is_neg;

    my $format = ($args{format}) ? $args{format}
                              : $LedgerSMB::App_State::User->{numberformat};

    my $places = undef;
    $places = $LedgerSMB::Sysconfig::decimal_places if $args{money};
    $places = ($args{places}) ? $args{places} : $places;
    my $str = $self->bstr;
    my $dplaces = $places;
    $places = 0 unless defined $places and ($places > 0);
    my $zfill = ($places > 0) ? 1 : 0;
    $dplaces = 10 unless defined $dplaces;
    my $formatter = new Number::Format(
                    -thousands_sep => $lsmb_formats->{$format}->{thousands_sep},
                    -decimal_point => $lsmb_formats->{$format}->{decimal_sep},
                     -decimal_fill => $zfill,
                       -neg_format => 'x');   
    $str = $formatter->format_number($str, $dplaces);

    my $neg_format = ($args{neg_format}) ? $args{neg_format} : 'def';
    my $fmt = ($is_neg) ? $lsmb_neg_formats->{$neg_format}->{neg}
                        : $lsmb_neg_formats->{$neg_format}->{pos};
   
    return sprintf($fmt, $str);
}

=item from_db

=cut

sub from_db {
    my ($self, $string) = @_;
    return undef if !defined $string;
    return $self->new($string);
}

=item to_db

=cut

sub to_db {
    my ($self) = @_; 
    return $self->to_output({format => '1000.00'});
}


1;

=back

=head1 Copyright (C) 2011, The LedgerSMB core team.

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

