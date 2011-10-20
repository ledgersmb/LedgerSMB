=head1 NAME

LedgerSMB::PGNumeric

=cut

use strict;
use warnings;
use Number::Format;

package LedgerSMB::PGNumeric;

BEGIN {
   use LedgerSMB::SODA;
   LedgerSMB::SODA->register_type({sql_type => 'float', 
                                 perl_class => 'LedgerSMB::PGNumeric');
   LedgerSMB::SODA->register_type({sql_type => 'double', 
                                 perl_class => 'LedgerSMB::PGNumeric');
   LedgerSMB::SODA->register_type({sql_type => 'numeric', 
                                 perl_class => 'LedgerSMB::PGNumeric');
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

=cut

our $lsmb_formats = {
      "1000.00" => { thousands_sep => '',  decimal_sep => '.' },
=item 1000.00 (default)

=cut
      "1000,00" => { thousands_sep => '',  decimal_sep => ',' },
=item 1000,00

=cut
     "1 000.00" => { thousands_sep => ' ', decimal_sep => '.' },
=item 1 000.00

=cut
     "1 000,00" => { thousands_sep => ' ', decimal_sep => ',' },
=item 1 000,00

=cut
     "1,000.00" => { thousands_sep => ',', decimal_sep => '.' },
=item 1,000.00

=cut
     "1.000,00" => { thousands_sep => '.', decimal_sep => ',' },
=item 1.000,00

=cut
     "1'000,00" => { thousands_sep => "'", decimal_sep => ',' },
=item 1'000,00

=cut

};

=back

=head1 SUPPORTED NEGATIVE FORMATS

All use 123.45 as an example.

=over

=cut

my $lsmb_neg_formats = {
  'def' => { pos => '%s',   neg => '-%s'   },

=item def (DEFAULT)

positive:  123.45
negative: -123.45

=cut
 'DRCR' => { pos => '%s CR' neg => '%s DR' },
=item DRCR

positive:  123.45 CR
negative:  123.45 DR

=cut
    'paren' => { pos => '%s',   neg => '(%s)'  },
=item paren

positive:  123.45
negative: (123.45)

=cut
}

=back

=head1 I/O METHODS

=over

=item from_input

=cut

sub from_input {
    use Number::Format qw(:subs :vars);
    my ($self, $string) = @_; 
    $format = ($args{format}) ? $args{format}
                              : $LedgerSMB::App_State::User->{numberformat};

    $THOUSANDS_SEP   = $lsmb_formats->{format}->{thousands_sep};
    $DECIMAL_POINT   = $lsmb_formats->{format}->{decimal_sep};
    my $pgnum = $self->new(unformat_number($string));
    die 'LedgerSMB::PGNumber Invalid Number' if $pgnum->isnan();
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
    use Number::Format qw(:subs :vars);
    my ($self) = shift;
    my %args  = (ref($_[0]) eq 'HASH')? %{$_[0]}: @_;  
    my $is_neg = $self->is_neg;
    $self->babs;

    my $str = $self->bstr;
    $format = ($args{format}) ? $args{format}
                              : $LedgerSMB::App_State::User->{numberformat};

    my $places = $LedgerSMB::Sysconfig::decimal_places if $args{money};
    $places = ($args{places}) ? $args{places} : $places;

    $DECIMAL_FILL    = 0;
    $DECIMAL_DIGITS  = $places if defined $places;
    $THOUSANDS_SEP   = $lsmb_formats->{format}->{thousands_sep};
    $DECIMAL_POINT   = $lsmb_formats->{format}->{decimal_sep};
    $str = format_number($str);

    my $neg_format = ($args{neg_format}) ? $args{neg_format} : 'def';
    my $fmt = ($is_neg) ? $lsmb_neg_formats->{$neg_format}->{neg}
                        : $lsmb_neg_formats->{$neg_format}->{pos};
   
    return sprintf($fmt, $str);
}

=item from_db

=cut

sub from_db {
    my ($self, $string) = @_;
    return $self->new($string);
}

=item to_db

=cut

sub to_db {
    my ($self) = @_; 
    return $self->to_output({format => '1000.00'});
}

1;

=head1 Copyright (C) 2011, The LedgerSMB core team.

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

