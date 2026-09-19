
use v5.38;
use Sublike::Extended 0.29 qw(method sub);
use Syntax::Operator::Equ;
use experimental qw(signatures class);

package LedgerSMB::PGMonetary;

=head1 NAME

LedgerSMB::PGMonetary - Monetary amounts with their currenncies

=head1 DESCRIPTION

Tracks money (amounts and currencies). Overloads basic calculation and
comparison operators.

=head1 CONSTRUCTORS

=head2 new

  $m = LedgerSMB::PGMonetary->new( amount => '201.95', curr => 'CZK' );


=head1 METHODS

=cut

class LedgerSMB::PGMonetary;

use Carp qw(croak);
use Math::BigInt;
use Math::BigFloat;
use LedgerSMB::Magic qw( DEFAULT_NUM_PREC );
use LedgerSMB::PGNumber;

use overload
    '+' => \&_add,
    '-' => \&_sub,
    '*' => \&_mul,
    '/' => \&_div,
    '+=' => \&_ladd,
    '-=' => \&_lsub,
    '*=' => \&_lmul,
    '/=' => \&_ldiv,
    '<' => \&_lt,
    '>' => \&_gt,
    '<=' => \&_le,
    '>=' => \&_ge,
    '==' => \&_eq,
    '!=' => \&_ne,
    'neg' => \&_neg,
    '""'  => \&_stringify;

field $_amount :param(amount) :reader;
field $_curr :param(curr) :reader = undef;

ADJUST {
    if (defined $_amount
        and not ($_amount isa Math::BigFloat
                 or $_amount isa Math::BigInt)) {
        $_amount = Math::BigFloat->new( $_amount );
    }
}

method _add($other, $swap) {
    unless ($other isa __PACKAGE__) {
        croak "Incompatible types in monetary addition\n";
    }
    unless ($other->_curr equ $_curr) {
        croak "Monetary addition requires same currencies (found different ones)\n";
    }
    return $self->new( amount => $_amount + $other->_amount, curr => $_curr );
}

method _sub($other, $swap) {
    unless ($other isa __PACKAGE__) {
        croak "Incompatible types in monetary subtraction\n";
    }
    unless ($other->_curr equ $_curr) {
        croak "Monetary subtraction requires same currencies (found different ones)\n";
    }
    return $self->new( amount => $_amount - $other->_amount, curr => $_curr );
}


method _mul($other, $swap) {
    if ($other isa __PACKAGE__) {
        croak "Multiplication of money requires scalar (found money)\n";
    }
    return $self->new( amount => $_amount * $other, curr => $_curr );
}


method _div($other, $swap) {
    if ($other isa __PACKAGE__) {
        croak "Division of money requires scalar (found money)\n";
    }
    return $self->new( amount => $_amount / $other, curr => $_curr );
}


method _ladd($other, $swap) {
    unless ($other isa __PACKAGE__) {
        croak "Incompatible types in monetary addition\n";
    }
    unless ($other->_curr equ $_curr) {
        croak "Monetary addition requires same currencies (found different ones)\n";
    }
    $_amount += $other->_amount;
    return $self;
}

method _lsub($other, $swap) {
    unless ($other isa __PACKAGE__) {
        croak "Incompatible types in monetary addition\n";
    }
    unless ($other->_curr equ $_curr) {
        croak "Monetary subtraction requires same currencies (found different ones)\n";
    }
    $_amount -= $other->_amount;
    return $self;
}


method _lmul($other, $swap) {
    if ($other isa __PACKAGE__) {
        croak "Multiplication of money requires scalar (found money)\n";
    }
    $_amount *= $other;
    return $self;
}


method _ldiv($other, $swap) {
    if ($other isa __PACKAGE__) {
        # actually, if they have the same currency,
        # the division should return a ratio (a dimension-less amount)
        croak "Division of money requires scalar (found money)\n";
    }
    $_amount /= $other->_amount;
    return $self;
}


method _lt($other, $swap) {
    unless ($other isa __PACKAGE__) {
        croak "Incompatible types in monetary comparison\n";
    }
    unless ($other->_curr equ $_curr) {
        croak "Different currencies in monetary comparison\n";
    }
    if ($swap) {
        return ($_amount >= $other->_amount);
    }
    else {
        return ($_amount < $other->_amount);
    }
}

method _gt($other, $swap) {
    unless ($other isa __PACKAGE__) {
        croak "Incompatible types in monetary comparison\n";;
    }
    unless ($other->_curr equ $_curr) {
        croak "Different currencies in monetary comparison\n";
    }
    if ($swap) {
        return ($_amount <= $other->_amount);
    }
    else {
        return ($_amount > $other->_amount);
    }
}

method _le($other, $swap) {
    unless ($other isa __PACKAGE__) {
        croak "Incompatible types in monetary comparison\n";;
    }
    unless ($other->_curr equ $_curr) {
        croak "Different currencies in monetary comparison\n";
    }
    if ($swap) {
        return ($_amount > $other->_amount);
    }
    else {
        return ($_amount <= $other->_amount);
    }
}

method _ge($other, $swap) {
    unless ($other isa __PACKAGE__) {
        croak "Incompatible types in monetary comparison\n";;
    }
    unless ($other->_curr equ $_curr) {
        croak "Different currencies in monetary comparison\n";
    }
    if ($swap) {
        return ($_amount < $other->_amount);
    }
    else {
        return ($_amount >= $other->_amount);
    }
}

method _eq($other, $swap) {
    unless ($other isa __PACKAGE__) {
        croak "Incompatible types in monetary comparison\n";;
    }
    unless ($other->_curr equ $_curr) {
        croak "Different currencies in monetary comparison\n";
    }
    return ($_amount == $other->_amount);
}

method _ne($other, $swap) {
    unless ($other isa __PACKAGE__) {
        croak "Incompatible types in monetary comparison\n";;
    }
    unless ($other->_curr equ $_curr) {
        croak "Different currencies in monetary comparison\n";
    }
    return ($_amount != $other->_amount);
}

method _neg($other, $swap) {
    return $self->new( amount => -$_amount, curr => $_curr );
}

method _stringify($other, $swap) {
    my $curr = $_curr // 'XXX'; # XXX designates 'no currency'
    return "$_amount $curr";
}


=head2 to_output

  $str = $money->to_output( numberformat => $numberformat,
                            neg_format   => $neg_format,
                            money_places => $money_places,
                            places       => $places,
                            [ ... ] );

Converts the monetary amount to a string.

The C<numberformat> and C<neg_format> are a strings naming formats documented
in L<LedgerSMB::PGNumber>.

C<places> determines the number of fractional digits; if C<money_places> is
given, it takes precedence over C<places>.

=cut

method to_output(:$numberformat = undef,
                 :$neg_format //= 'def',
                 :$money_places = undef,
                 :$places //= $money_places,
                 %) {
    croak 'LedgerSMB::PGMonetary No Format Set, check numberformat in user_preference' if !$numberformat;

    my $formatter = LedgerSMB::PGNumber::_formatter(
        -thousands_sep => $LedgerSMB::PGNumber::lsmb_formats->{$numberformat}->{thousands_sep},
        -decimal_point => $LedgerSMB::PGNumber::lsmb_formats->{$numberformat}->{decimal_sep},
        -decimal_fill  => (defined $places and $places > 0),
        -neg_format    => 'x'
    );
    my $str = $formatter->format_number($_amount->bstr, $places);
    $neg_format = 'def' unless exists $LedgerSMB::PGNumber::lsmb_neg_formats->{$neg_format};

    my $fmt = ($_amount->is_neg) ?
        $LedgerSMB::PGNumber::lsmb_neg_formats->{$neg_format}->{neg} :
        $LedgerSMB::PGNumber::lsmb_neg_formats->{$neg_format}->{pos};

    return sprintf($fmt, $str);
}

=head2 from_input

  $money = LedgerSMB::PGMonetary->from_input( '10.02 DR', numberformat => '1,000.00' );

Converts a string having a monetary amount to its numeric representation.

The C<numberformat> is a string naming formats documented
in L<LedgerSMB::PGNumber>.

=cut

sub from_input($class, $value, :$numberformat, %) {
    unless (defined $value) {
        return undef;
    }
    croak 'LedgerSMB::PGMonetary No Format Set' if not $numberformat;

    my $negate    = ($value =~ m/(^\(|DR$)/);
    my $formatter = LedgerSMB::PGNumber::_formatter(
        -thousands_sep => $LedgerSMB::PGNumber::lsmb_formats->{$numberformat}->{thousands_sep},
        -decimal_point => $LedgerSMB::PGNumber::lsmb_formats->{$numberformat}->{decimal_sep},
        );

    my $amt = $formatter->unformat_number($value);
    my $money = $class->new( amount => $amt, curr => undef );
    $money->_lmul( -1, undef ) if $negate;
    return $money;
}

=head2 to_db

  $db_str = $money->to_db;

Converts the monetary amount to its database representation. Currently discards
the currency indicator.

=cut

method to_db() {
    return $_amount->bstr;
}

# sub from_db() {
#
# }

=head2 to_sort

  $sort_value = $money->to_sort;

Returns the value for sorting.

=cut

method to_sort() {
    return $_amount->bstr;
}

1;

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.
