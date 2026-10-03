
use v5.38;
use Sublike::Extended 0.29 qw(sub);
use Syntax::Operator::Equ;
use experimental qw(signatures);

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

use Moo;

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


has amount => (is => 'rw', required => 1,
               coerce => sub {
                   if ($_[0] isa 'Math::BigFloat'
                       or $_[0] isa 'Math::BigInt') {
                       return $_[0];
                   }
                   return Math::BigFloat->new( $_[0] );
               });

has curr => (is => 'ro', required => 0);


sub _add($self, $other, $swap) {
    unless ($other isa __PACKAGE__) {
        croak "Incompatible types in monetary addition\n";
    }
    unless ($other->curr equ $self->curr) {
        croak "Monetary addition requires same currencies (found different ones)\n";
    }
    return $self->new( amount => $self->amount + $other->amount, curr => $self->curr );
}

sub _sub($self, $other, $swap) {
    unless ($other isa __PACKAGE__) {
        croak "Incompatible types in monetary subtraction\n";
    }
    unless ($other->curr equ $self->curr) {
        croak "Monetary subtraction requires same currencies (found different ones)\n";
    }
    return $self->new( amount => $self->amount - $other->amount, curr => $self->curr );
}


sub _mul($self, $other, $swap) {
    if ($other isa __PACKAGE__) {
        croak "Multiplication of money requires scalar (found money)\n";
    }
    return $self->new( amount => $self->amount * $other, curr => $self->curr );
}


sub _div($self, $other, $swap) {
    if ($other isa __PACKAGE__) {
        croak "Division of money requires scalar (found money)\n";
    }
    return $self->new( amount => $self->amount / $other, curr => $self->curr );
}


sub _ladd($self, $other, $swap) {
    unless ($other isa __PACKAGE__) {
        croak "Incompatible types in monetary addition\n";
    }
    unless ($other->curr equ $self->curr) {
        croak "Monetary addition requires same currencies (found different ones)\n";
    }
    $self->amount += $other->amount;
    return $self;
}

sub _lsub($self, $other, $swap) {
    unless ($other isa __PACKAGE__) {
        croak "Incompatible types in monetary addition\n";
    }
    unless ($other->curr equ $self->curr) {
        croak "Monetary subtraction requires same currencies (found different ones)\n";
    }
    $self->amount -= $other->amount;
    return $self;
}


sub _lmul($self, $other, $swap) {
    if ($other isa __PACKAGE__) {
        croak "Multiplication of money requires scalar (found money)\n";
    }
    $self->amount *= $other;
    return $self;
}


sub _ldiv($self, $other, $swap) {
    if ($other isa __PACKAGE__) {
        # actually, if they have the same currency,
        # the division should return a ratio (a dimension-less amount)
        croak "Division of money requires scalar (found money)\n";
    }
    $self->amount /= $other->amount;
    return $self;
}


sub _lt($self, $other, $swap) {
    unless ($other isa __PACKAGE__) {
        croak "Incompatible types in monetary comparison\n";
    }
    unless ($other->curr equ $self->curr) {
        croak "Different currencies in monetary comparison\n";
    }
    if ($swap) {
        return ($self->amount >= $other->amount);
    }
    else {
        return ($self->amount < $other->amount);
    }
}

sub _gt($self, $other, $swap) {
    unless ($other isa __PACKAGE__) {
        croak "Incompatible types in monetary comparison\n";;
    }
    unless ($other->curr equ $self->curr) {
        croak "Different currencies in monetary comparison\n";
    }
    if ($swap) {
        return ($self->amount <= $other->amount);
    }
    else {
        return ($self->amount > $other->amount);
    }
}

sub _le($self, $other, $swap) {
    unless ($other isa __PACKAGE__) {
        croak "Incompatible types in monetary comparison\n";;
    }
    unless ($other->curr equ $self->curr) {
        croak "Different currencies in monetary comparison\n";
    }
    if ($swap) {
        return ($self->amount > $other->amount);
    }
    else {
        return ($self->amount <= $other->amount);
    }
}

sub _ge($self, $other, $swap) {
    unless ($other isa __PACKAGE__) {
        croak "Incompatible types in monetary comparison\n";;
    }
    unless ($other->curr equ $self->curr) {
        croak "Different currencies in monetary comparison\n";
    }
    if ($swap) {
        return ($self->amount < $other->amount);
    }
    else {
        return ($self->amount >= $other->amount);
    }
}

sub _eq($self, $other, $swap) {
    unless ($other isa __PACKAGE__) {
        croak "Incompatible types in monetary comparison\n";;
    }
    unless ($other->curr equ $self->curr) {
        croak "Different currencies in monetary comparison\n";
    }
    return ($self->amount == $other->amount);
}

sub _ne($self, $other, $swap) {
    unless ($other isa __PACKAGE__) {
        croak "Incompatible types in monetary comparison\n";;
    }
    unless ($other->curr equ $self->curr) {
        croak "Different currencies in monetary comparison\n";
    }
    return ($self->amount != $other->amount);
}

sub _neg($self, $other, $swap) {
    return $self->new( amount => -$self->amount, curr => $self->curr );
}

sub _stringify($self, $other, $swap) {
    my $curr = $self->curr // 'XXX'; # XXX designates 'no currency'
    return "$self->amount $curr";
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

sub to_output($self, :$numberformat = undef,
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
    my $str = $formatter->format_number($self->amount->bstr, $places);
    $neg_format = 'def' unless exists $LedgerSMB::PGNumber::lsmb_neg_formats->{$neg_format};

    my $fmt = ($self->amount->is_neg) ?
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

sub to_db($self) {
    return $self->amount->bstr;
}

# sub from_db() {
#
# }

=head2 to_sort

  $sort_value = $money->to_sort;

Returns the value for sorting.

=cut

sub to_sort($self) {
    return $self->amount->bstr;
}

1;

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.
