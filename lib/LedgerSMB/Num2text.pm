#=====================================================================
# LedgerSMB
# Small Medium Business Accounting software
# http://www.ledgersmb.org/
#
# Copyright (C) 2006
# This work contains copyrighted information from a number of sources all used
# with permission.
#
# This file contains source code included with or based on SQL-Ledger which
# is Copyright Dieter Simader and DWS Systems Inc. 2000-2005 and licensed
# under the GNU General Public License version 2 or, at your option, any later
# version.  For a full list including contact information of contributors,
# maintainers, and copyright holders, see the CONTRIBUTORS file.
#
# Original Copyright Notice from SQL-Ledger 2.6.17 (before the fork):
# Copyright (C) 2002
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
#
#  Contributors:
#
#======================================================================
#
# This file has undergone whitespace cleanup.
#
#======================================================================
#
# this is the default code for the Check package
#
#=====================================================================

package LedgerSMB::Num2text;

# The conversion routines can be tested with for example:
# perl <<EOF
#   use LedgerSMB::CP;
#   my $c = CP->new('da');
#   $c->init;
#   for(0 .. 202, 999 .. 1002, 1999 .. 2002, 999999 .. 1000002, 999999999 .. 1000000002)
#     {print $_.":".$c->num2text($_)."\n";};'
# EOF

use utf8;
use strict;
use warnings;
use LedgerSMB::Locale;

sub new {
    my ( $type, $countrycode ) = @_;

    my $self = {};
    $self->{'locale'} = LedgerSMB::Locale->get_handle($countrycode);
    bless $self, $type;

    return $self;
}


sub init {
    my $self    = shift;
    my $locale  = $self->{'locale'} || $self->{'_locale'};
    my $langtag = substr( $locale->language_tag, 0, 2 );
    $self->{'numrules'} = 'en';
    $self->{'numrules'} = $langtag
      if grep { /$langtag/ } (qw/ca de es et fr hu it nl ru da/);
    $self->{'numrules'} = 'es' if $self->{'numrules'} eq 'ca';
    $self->{'numrules'} = 'de' if $self->{'numrules'} eq 'ru';

    %{ $self->{numbername} } = (
        0      => $locale->text('Zero'),
        1      => $locale->text('One'),
        '1o'   => $locale->text('One-o'),
        2      => $locale->text('Two'),
        3      => $locale->text('Three'),
        4      => $locale->text('Four'),
        5      => $locale->text('Five'),
        6      => $locale->text('Six'),
        7      => $locale->text('Seven'),
        8      => $locale->text('Eight'),
        9      => $locale->text('Nine'),
        10     => $locale->text('Ten'),
        11     => $locale->text('Eleven'),
        '11o'  => $locale->text('Eleven-o'),
        12     => $locale->text('Twelve'),
        13     => $locale->text('Thirteen'),
        14     => $locale->text('Fourteen'),
        15     => $locale->text('Fifteen'),
        16     => $locale->text('Sixteen'),
        17     => $locale->text('Seventeen'),
        18     => $locale->text('Eighteen'),
        19     => $locale->text('Nineteen'),
        20     => $locale->text('Twenty'),
        21     => $locale->text('Twenty One'),
        '21o'  => $locale->text('Twenty One-o'),
        22     => $locale->text('Twenty Two'),
        23     => $locale->text('Twenty Three'),
        24     => $locale->text('Twenty Four'),
        25     => $locale->text('Twenty Five'),
        26     => $locale->text('Twenty Six'),
        27     => $locale->text('Twenty Seven'),
        28     => $locale->text('Twenty Eight'),
        29     => $locale->text('Twenty Nine'),
        30     => $locale->text('Thirty'),
        40     => $locale->text('Forty'),
        50     => $locale->text('Fifty'),
        60     => $locale->text('Sixty'),
        70     => $locale->text('Seventy'),
        80     => $locale->text('Eighty'),
        90     => $locale->text('Ninety'),
        10**2  => $locale->text('Hundred'),
        500    => $locale->text('Five Hundred'),
        700    => $locale->text('Seven Hundred'),
        900    => $locale->text('Nine Hundred'),
        10**3  => $locale->text('Thousand'),
        10**6  => $locale->text('Million'),
        10**9  => $locale->text('Billion'),
        10**12 => $locale->text('Trillion'),
    );

}

sub num2text {
    my ( $self, $amount ) = @_;

    return $self->num2text_de($amount) if $self->{'numrules'} eq 'de';
    return $self->num2text_es($amount) if $self->{'numrules'} eq 'es';
    return $self->num2text_nl($amount) if $self->{'numrules'} eq 'nl';
    return $self->num2text_hu($amount) if $self->{'numrules'} eq 'hu';
    return $self->num2text_et($amount) if $self->{'numrules'} eq 'et';
    return $self->num2text_fr($amount) if $self->{'numrules'} eq 'fr';
    return $self->num2text_it($amount) if $self->{'numrules'} eq 'it';
    return $self->num2text_da($amount) if $self->{'numrules'} eq 'da';
    return $self->num2text_en($amount);
}

sub num2text_en {
    my ( $self, $amount ) = @_;

    return $self->{numbername}{0} unless $amount;

    my @textnumber = ();

    # split amount into chunks of 3
    my @num = reverse split //, abs($amount);
    my @numblock = ();
    my @a;
    my $i;

    while (@num) {
        @a = ();
        for ( 1 .. 3 ) {
            push @a, shift @num;
        }
        push @numblock, join ' ', reverse @a;
    }

    while (@numblock) {

        $i = $#numblock;
        @num = split //, $numblock[$i];

        if ( $numblock[$i] == 0 ) {
            pop @numblock;
            next;
        }

        if ( $numblock[$i] > 99 ) {

            # the one from hundreds
            push @textnumber, $self->{numbername}{ $num[0] };

            # add hundred designation
            push @textnumber, $self->{numbername}{ 10**2 };

            # reduce numblock
            $numblock[$i] -= $num[0] * 100;

        }

        $numblock[$i] *= 1;

        if ( $numblock[$i] > 9 ) {

            # tens
            push @textnumber, $self->format_ten_en( $numblock[$i] );
        }
        elsif ( $numblock[$i] > 0 ) {

            # ones
            push @textnumber, $self->{numbername}{ $numblock[$i] };
        }

        # add thousand, million
        if ($i) {
            my $num = 10**( $i * 3 );
            push @textnumber, $self->{numbername}{$num};
        }

        pop @numblock;

    }

    join ' ', @textnumber;

}

sub format_ten_en {
    my ( $self, $amount ) = @_;

    my $textnumber = "";
    my @num = split //, $amount;

    if ( $amount > 20 ) {
        $textnumber = $self->{numbername}{ $num[0] * 10 };
        $amount     = $num[1];
    }
    else {
        $textnumber = $self->{numbername}{$amount};
        $amount     = 0;
    }

    $textnumber .= " " . $self->{numbername}{$amount} if $amount;

    $textnumber;

}

sub num2text_de {
    my ( $self, $amount ) = @_;

    return $self->{numbername}{0} unless $amount;

    my @textnumber = ();

    # split amount into chunks of 3
    my @num = reverse split //, abs($amount);
    my @numblock = ();
    my ( $i, $appendn );
    my @a = ();

    while (@num) {
        @a = ();
        for ( 1 .. 3 ) {
            push @a, shift @num;
        }
        push @numblock, join ' ', reverse @a;
    }

    my $belowhundred = !$#numblock;

    while (@numblock) {

        $i       = $#numblock;
        @num     = split //, $numblock[$i];
        $appendn = "";

        $numblock[$i] *= 1;

        if ( $numblock[$i] == 0 ) {
            pop @numblock;
            next;
        }

        if ( $numblock[$i] > 99 ) {

            # the one from hundreds
            push @textnumber, $self->{numbername}{ $num[0] };

            # add hundred designation
            push @textnumber, $self->{numbername}{ 10**2 };

            # reduce numblock
            $numblock[$i] -= $num[0] * 100;
        }

        $appendn = 'en' if ( $i == 2 );
        $appendn = 'n'  if ( $i > 2 );

        if ( $numblock[$i] > 9 ) {

            # tens
            push @textnumber,
              $self->format_ten_de( $numblock[$i], $belowhundred );
        }
        elsif ( $numblock[$i] > 1 ) {

            # ones
            push @textnumber, $self->{numbername}{ $numblock[$i] };
        }
        elsif ( $numblock[$i] == 1 ) {
            if ( $i == 0 ) {
                push @textnumber, $self->{numbername}{ $numblock[$i] } . 's';
            }
            else {
                if ( $i >= 2 ) {
                    push @textnumber,
                      $self->{numbername}{ $numblock[$i] } . 'e';
                }
                else {
                    push @textnumber, $self->{numbername}{ $numblock[$i] };
                }
            }
            $appendn = "";
        }

        # add thousand, million
        if ($i) {
            $amount = 10**( $i * 3 );
            push @textnumber, $self->{numbername}{$amount} . $appendn;
        }

        pop @numblock;

    }

    join '', @textnumber;

}

sub format_ten_de {
    my ( $self, $amount, $belowhundred ) = @_;

    my $textnumber = "";
    my @num = split //, $amount;

    if ( $amount > 20 ) {
        if ( $num[1] == 0 ) {
            $textnumber = $self->{numbername}{$amount};
        }
        else {
            if ($belowhundred) {
                $amount = $num[0] * 10;
                $textnumber =
                    $self->{numbername}{ $num[1] } . 'und'
                  . $self->{numbername}{$amount};
            }
            else {
                $amount = $num[0] * 10;
                $textnumber =
                  $self->{numbername}{$amount} . $self->{numbername}{ $num[1] };
                $textnumber .= 's' if ( $num[1] == 1 );
            }
        }
    }
    else {
        $textnumber = $self->{numbername}{$amount};
    }

    $textnumber;

}

sub num2text_et {
    my ( $self, $amount ) = @_;

    return $self->{numbername}{0} unless $amount;

    my @textnumber = ();

    # split amount into chunks of 3
    my @num = reverse split //, abs($amount);
    my @numblock = ();
    my ( $i, $appendit );
    my @a = ();

    while (@num) {
        @a = ();
        for ( 1 .. 3 ) {
            push @a, shift @num;
        }
        push @numblock, join ' ', reverse @a;
    }

    while (@numblock) {

        $i = $#numblock;
        $numblock[$i] *= 1;
        @num = split //, $numblock[$i];

        $appendit = "it";
        my $hundred  = 0;

        if ( $numblock[$i] == 0 ) {
            pop @numblock;
            next;
        }

        if ( $numblock[$i] > 99 ) {

            # the one from hundreds
            push @textnumber,
              "$self->{numbername}{$num[0]}$self->{numbername}{10**2}";

            # reduce numblock
            $numblock[$i] -= $num[0] * 100;
            @num = split //, $numblock[$i];
            $hundred = 1;
        }

        if ( $numblock[$i] > 19 ) {

            # 20 - 99
            push @textnumber, "$self->{numbername}{$num[0]}kümmend";
            @num = split //, $numblock[$i];
            push @textnumber, $self->{numbername}{ $num[1] } if $num[1] > 0;

        }
        elsif ( $numblock[$i] > 10 ) {

            # 11 - 19
            if ($hundred) {
                @num = split //, $numblock[$i];
            }
            my $num = $num[1];

            push @textnumber, "$self->{numbername}{$num}teist";

        }
        elsif ( $numblock[$i] > 1 ) {

            # ones
            push @textnumber, $self->{numbername}{ $numblock[$i] };

        }
        elsif ( $numblock[$i] == 1 ) {
            push @textnumber, $self->{numbername}{ $num[0] };
            $appendit = "";

        }

        # add thousand, million
        if ($i) {
            $amount = 10**( $i * 3 );
            $appendit = ( $i == 1 ) ? "" : $appendit;
            push @textnumber, "$self->{numbername}{$amount}$appendit";
        }

        pop @numblock;

    }

    join ' ', @textnumber;

}

sub num2text_es {
    my ( $self, $amount ) = @_;

    return $self->{numbername}{0} unless $amount;

    my @textnumber = ();

    # split amount into chunks of 3
    my @num      = reverse split //, abs($amount);
    my @numblock = ();
    my $stripun  = 0;
    my @a        = ();
    my $i;

    while (@num) {
        @a = ();
        for ( 1 .. 3 ) {
            push @a, shift @num;
        }
        push @numblock, join ' ', reverse @a;
    }

    # special case for 1000
    if ( $numblock[1] eq '1' && $numblock[0] gt '000' ) {

        # remove first array element from textnumber
        $stripun = 1;
    }

    while (@numblock) {

        $i = $#numblock;
        @num = split //, $numblock[$i];

        $numblock[$i] *= 1;

        if ( $numblock[$i] == 0 ) {
            pop @numblock;
            next;
        }

        if ( $numblock[$i] > 99 ) {
            if ( $num[0] == 1 ) {
                push @textnumber, $self->{numbername}{ 10**2 };
            }
            else {

                # special case for 500, 700, 900
                if ( grep /$num[0]/, ( 5, 7, 9 ) ) {
                    push @textnumber, $self->{numbername}{"${num[0]}00"};

                }
                else {

                    # the one from hundreds, append cientos
                    push @textnumber,
                      $self->{numbername}{ $num[0] }
                      . $self->{numbername}{ 10**2 } . 's';

                }
            }

            # reduce numblock
            $numblock[$i] -= $num[0] * 100;
        }

        if ( $numblock[$i] > 9 ) {

            # tens
            push @textnumber, $self->format_ten_es( $numblock[$i], $i );
        }
        elsif ( $numblock[$i] > 0 ) {

            # ones
            my $num = $numblock[$i];
            $num .= 'o' if ( $num == 1 && $i == 0 );
            push @textnumber, $self->{numbername}{$num};
        }

        # add thousand, million
        if ($i) {
            my $num = 10**( $i * 3 );
            if ( $numblock[$i] > 1 ) {
                if ( $i == 2 || $i == 4 ) {
                    $a = $self->{numbername}{$num} . "es";
                    $a =~ s/ó/o/;
                    push @textnumber, $a;
                }
                elsif ( $i == 3 ) {
                    $num = 10**( $i * 2 );
                    $a   = "$self->{10**3} $self->{numbername}{$num}" . "es";
                    $a =~ s/ó/o/;
                    push @textnumber, $a;
                }
                else {
                    if ( $i == 1 ) {
                        push @textnumber, $self->{numbername}{$num};
                    }
                    else {
                        push @textnumber, $self->{numbername}{$num} . 's';
                    }
                }
            }
            else {
                push @textnumber, $self->{numbername}{$num};
            }
        }

        pop @numblock;

    }

    shift @textnumber if $stripun;

    join ' ', @textnumber;

}

sub format_ten_es {
    my ( $self, $amount, $i ) = @_;

    my $textnumber = "";
    my @num = split //, $amount;

    if ( $amount > 30 ) {
        $textnumber = $self->{numbername}{ $num[0] * 10 };
        $amount     = $num[1];
    }
    else {
        $amount .= 'o' if ( $num[1] == 1 && $i == 0 );
        $textnumber = $self->{numbername}{$amount};
        $amount     = 0;
    }

    $textnumber .= " y " . $self->{numbername}{$amount} if $amount;

    $textnumber;

}

sub num2text_fr {
    my ( $self, $amount ) = @_;

    return $self->{numbername}{0} unless $amount;

    my @textnumber = ();

    # split amount into chunks of 3
    my @num = reverse split //, abs($amount);
    my @numblock = ();
    my @a;
    my $i;

    while (@num) {
        @a = ();
        for ( 1 .. 3 ) {
            push @a, shift @num;
        }
        push @numblock, join ' ', reverse @a;
    }

    my $cent = 0;

    while (@numblock) {

        $i = $#numblock;
        @num = split //, $numblock[$i];

        if ( $numblock[$i] == 0 ) {
            pop @numblock;
            next;
        }

        if ( $numblock[$i] > 99 ) {
            $cent = 1;

            # the one from hundreds

            if ( $num[0] > 1 ) {
                push @textnumber, $self->{numbername}{ $num[0] };
            }

            # reduce numblock
            $numblock[$i] -= $num[0] * 100;

            # add hundred designation
            if ( $num[0] > 1 ) {
                if ( $numblock[$i] > 0 ) {
                    push @textnumber, $self->{numbername}{ 10**2 };
                }
                else {
                    push @textnumber, "$self->{numbername}{10**2}s";
                }
            }
            else {
                push @textnumber, $self->{numbername}{ 10**2 };
            }

        }

        $numblock[$i] *= 1;

        if ( $numblock[$i] > 9 ) {

            # tens
            push @textnumber, $self->format_ten_fr( $numblock[$i] );
        }
        elsif ( $numblock[$i] > 0 ) {

            # ones
            if ( $i == 1 ) {
                if ( $cent == 1 ) {
                    push @textnumber, $self->{numbername}{ $numblock[$i] };
                }
                $cent = 0;
            }
            else {
                push @textnumber, $self->{numbername}{ $numblock[$i] };
            }
        }

        # add thousand, million
        if ($i) {
            my $num = 10**( $i * 3 );
            if ( $i == 1 ) {
                push @textnumber, $self->{numbername}{$num};
            }
            elsif ( $numblock[$i] > 1 ) {
                push @textnumber, "$self->{numbername}{$num}s";
            }
            else {
                push @textnumber, "$self->{numbername}{$num}";
            }
        }

        pop @numblock;

    }

    join ' ', @textnumber;

}

sub format_ten_fr {
    my ( $self, $amount ) = @_;

    my $textnumber = "";
    my @num = split //, $amount;

    if ( $amount > 20 ) {
        if ( $num[0] == 8 ) {
            if ( $num[1] > 0 ) {
                $textnumber = $self->{numbername}{ $num[0] * 10 };
            }
            else {
                $textnumber = "$self->{numbername}{$num[0]*10}s";
            }
            $amount = $num[1];
        }
        elsif ( $num[0] == 7 || $num[0] == 9 ) {
            if ( $num[1] > 0 ) {
                $textnumber = $self->{numbername}{ ( $num[0] - 1 ) * 10 };

                $textnumber .= " et" if ( $num[1] == 1 && $num[0] == 7 );

                $amount -= ( $num[0] - 1 ) * 10;
            }
            else {
                $textnumber = $self->{numbername}{ $num[0] * 10 };
                $amount     = $num[1];
            }
        }
        else {
            $textnumber = $self->{numbername}{ $num[0] * 10 };
            $textnumber .= " et" if ( $num[1] == 1 );
            $amount = $num[1];
        }
    }
    else {
        $textnumber = "$self->{numbername}{$amount}";
        $amount     = 0;
    }

    $textnumber .= " " . $self->{numbername}{$amount} if $amount;

    $textnumber;

}

sub num2text_hu {
    my ( $self, $amount ) = @_;

    return $self->{numbername}{0} unless $amount;

    my @textnumber = ();

    # split amount into chunks of 3
    my @num = reverse split //, abs($amount);
    my @numblock = ();
    my @a;
    my $i;
    my $res;
    while (@num) {
        @a = ();
        for ( 1 .. 3 ) {
            push @a, shift @num;
        }
        push @numblock, join ' ', reverse @a;
    }
    while (@numblock) {
        $i = $#numblock;
        @num = split //, $numblock[$i];

        if ( $numblock[$i] == 0 ) {
            pop @numblock;
            next;
        }
        if ( $numblock[$i] > 99 ) {
            push @textnumber, $self->{numbername}{ $num[0] };

            # add hundred designation
            push @textnumber, $self->{numbername}{ 10**2 };

            # reduce numblock
            $numblock[$i] -= $num[0] * 100;

        }

        $numblock[$i] *= 1;
        if ( $numblock[$i] > 9 ) {

            # tens
            push @textnumber, $self->format_ten_hu( $numblock[$i] );
        }
        elsif ( $numblock[$i] > 0 ) {

            # ones
            push @textnumber, $self->{numbername}{ $numblock[$i] };
        }

        # add thousand, million
        if ($i) {
            if ( $i == 1 && $amount < 2000 ) {

                my $num = 10**( $i * 3 );
                push @textnumber, $self->{numbername}{$num};
            }
            else {

                my $num = 10**( $i * 3 );
                push @textnumber, $self->{numbername}{$num} . "-";
            }
        }

        pop @numblock;

    }
    $res = ucfirst join '', @textnumber;
    $res =~ s/(\-)$//;
    return $res;
}

sub format_ten_hu {
    my ( $self, $amount ) = @_;

    my $textnumber = "";
    my @num = split //, $amount;
    if ( $amount > 30 ) {
        $textnumber = $self->{numbername}{ $num[0] * 10 };
        $amount     = $num[1];
    }
    else {
        $textnumber = $self->{numbername}{$amount};
        $amount     = 0;
    }

    $textnumber .= "" . $self->{numbername}{$amount} if $amount;

    $textnumber;

}

sub num2text_nl {
    my ( $self, $amount ) = @_;

    return $self->{numbername}{0} unless $amount;

    my @textnumber = ('**');

    # split amount into chunks of 3
    my @num = reverse split //, abs($amount);
    my @numblock = ();
    my ( $i, $appendn );
    my @a = ();

    while (@num) {
        @a = ();
        for ( 1 .. 3 ) {
            push @a, shift @num;
        }
        push @numblock, join ' ', reverse @a;
    }

    while (@numblock) {

        $i = $#numblock;
        @num = split //, $numblock[$i];

        $numblock[$i] *= 1;

        if ( $numblock[$i] == 0 ) {
            pop @numblock;
            next;
        }

        if ( $numblock[$i] > 99 ) {

            # the one from hundreds
            push @textnumber, $self->{numbername}{ $num[0] };

            # add hundred designation
            push @textnumber, $self->{numbername}{ 10**2 };

            # reduce numblock
            $numblock[$i] -= $num[0] * 100;
        }

        if ( $numblock[$i] > 9 ) {

            # tens
            push @textnumber, $self->format_ten_nl( $numblock[$i] );
        }
        else {

            # ones
            push @textnumber, $self->{numbername}{ $numblock[$i] };
        }

        # add thousand, million
        if ($i) {
            $amount = 10**( $i * 3 );
            push @textnumber, $self->{numbername}{$amount};
        }

        pop @numblock;

    }

    push @textnumber, '**';
    join '', @textnumber;

}

sub format_ten_nl {
    my ( $self, $amount ) = @_;

    my $textnumber = "";
    my @num = split //, $amount;

    if ( $amount > 20 ) {

        # reverse one and ten and glue together with 'en'
        $amount = $num[0] * 10;
        $textnumber =
          $self->{numbername}{ $num[1] } . 'en' . $self->{numbername}{$amount};
    }
    else {
        $textnumber = $self->{numbername}{$amount};
    }

    $textnumber;

}

sub num2text_it {
    my ( $self, $amount ) = @_;

    return $self->{numbername}{0} unless $amount;

    my @textnumber = ();

    # split amount into chunks of 3
    my @num = reverse split //, abs($amount);
    my @numblock = ();
    my ( $i, $appendn );
    my @a = ();

    while (@num) {
        @a = ();
        for ( 1 .. 3 ) {
            push @a, shift @num;
        }
        push @numblock, join ' ', reverse @a;
    }

    while (@numblock) {

        $i = $#numblock;
        @num = split //, $numblock[$i];

        $numblock[$i] *= 1;

        if ( $numblock[$i] == 0 ) {
            pop @numblock;
            next;
        }

        if ( $numblock[$i] > 99 ) {

            # the one from hundreds
            push @textnumber, $self->{numbername}{ $num[0] };

            # add hundred designation
            push @textnumber, $self->{numbername}{ 10**2 };

            # reduce numblock
            $numblock[$i] -= $num[0] * 100;
        }

        if ( $numblock[$i] > 9 ) {

            # tens
            push @textnumber, $self->format_ten_it( $numblock[$i] );
        }
        elsif ( $numblock[$i] > 1 ) {

            # ones
            push @textnumber, $self->{numbername}{ $numblock[$i] };
        }

        # add thousand, million
        if ($i) {
            $amount = 10**( $i * 3 );
            push @textnumber, $self->{numbername}{$amount};
        }

        pop @numblock;

    }

    join '', @textnumber;

}

sub format_ten_it {
    my ( $self, $amount ) = @_;

    my $textnumber = "";
    my @num = split //, $amount;

    if ( $amount > 20 ) {
        if ( $num[1] == 0 ) {
            $textnumber = $self->{numbername}{$amount};
        }
        else {
            $amount = $num[0] * 10;
            $textnumber =
              $self->{numbername}{$amount} . $self->{numbername}{ $num[1] };
        }
    }
    else {
        $textnumber = $self->{numbername}{$amount};
    }

    $textnumber;

}

# A special (swedish-like) spelling of danish check numbers
sub num2text_da {
    my ( $self, $amount ) = @_;

    # Handle 0
    return $self->{numbername}{0} unless $amount;

    # List of collected digits
    my @textnumber = ();

    # split amount into chunks of 3
    my @num      = reverse split //, abs($amount);
    my @numblock = ();
    my @a        = ();
    while (@num) {
        @a = ();
        for ( 1 .. 3 ) {
            push @a, shift @num;
        }
        push @numblock, join ' ', reverse @a;
    }

    my $i;
    my $bigplural;
    while (@numblock) {
        $i = $#numblock;
        $numblock[$i] *= 1;

        if ( $numblock[$i] == 0 ) {
            pop @numblock;
            next;
        }

        # Plural suffix "er" for million and up, not for tusinde
        my $bigpluralsuffix = "";
        $bigpluralsuffix = "er" if ( $i > 1 && $numblock[$i] > 1 );

        if ( $numblock[$i] > 99 ) {
            @num = split //, $numblock[$i];

            # the one from hundreds
            push @textnumber, $self->{numbername}{ $num[0] };

            # add hundred designation
            push @textnumber, $self->{numbername}{100};

            # reduce numblock
            $numblock[$i] -= $num[0] * 100;
        }

        if ( $numblock[$i] > 9 ) {
            @num = split //, $numblock[$i];

            # the one from tens
            push @textnumber, $self->{numbername}{ $num[0] };

            # add ten designation
            push @textnumber, $self->{numbername}{10};

            # reduce numblock
            $numblock[$i] -= $num[0] * 10;
        }

        if ( $numblock[$i] > 0 ) {

            # the ones left in the block
            if ( $numblock[$i] == 1 && $i != 1 ) {
                push @textnumber,
                  $self->{numbername}{'1o'};    # Special case for "Et" tusinde
            }
            else {
                push @textnumber, $self->{numbername}{ $numblock[$i] };
            }
        }

        # add thousand, million, etc
        if ($i) {
            $amount = 10**( $i * 3 );
            push @textnumber, $self->{numbername}{$amount} . $bigpluralsuffix;
        }

        pop @numblock;
    }

    join '', @textnumber;

}


sub num2text_sl {
  my ($self, $amount) = @_;

  return $self->{numbername}{0} unless $amount;

  my @textnumber = ();

  # split amount into chunks of 3
  my @num = reverse split //, abs($amount);
  my @numblock = ();
  my ($i, $appendn);
  my @a = ();

  my $skip1k = 0;
  my $skip1m = 0;
  my $skip1b = 0;

  my $checkvalue = abs($amount) % 10**6;
  $checkvalue /= 1000;
  if (1 <= $checkvalue && $checkvalue <= 2) {
    $skip1k = 1;
  }

  $checkvalue = abs($amount) % 10**9;
  $checkvalue /= 10**6;
  if (1 <= $checkvalue && $checkvalue <= 2) {
    $skip1m = 1;
  }

  $checkvalue = abs($amount) % 10**15;
  $checkvalue /= 10**12;
  if (1 <= $checkvalue && $checkvalue <= 2) {
    $skip1b = 1;
  }

  my $check1m = abs($amount) % 10**8;
  my $check1md = abs($amount) % 10**11;
  my $check1b = abs($amount) % 10**14;

  while (@num) {
    @a = ();
    for (1 .. 3) {
      push @a, shift @num;
    }
    push @numblock, join ' ', reverse @a;
  }

  my $belowhundred = !$#numblock;

  while (@numblock) {

    $i = $#numblock;
    @num = split //, $numblock[$i];
    $appendn = "";

    $numblock[$i] *= 1;

    if ($numblock[$i] == 0) {
      pop @numblock;
      next;
    }

    if ($numblock[$i] > 99) {
      # the one from hundreds
      if ( $num[0] > 2 ) {
    push @textnumber, $self->{numbername}{$num[0]};
      } elsif ( $num[0] > 1 ) {
    push @textnumber, 'dve';
      }

      # add hundred designation
      push @textnumber, $self->{numbername}{10**2};

      # reduce numblock
      $numblock[$i] -= $num[0] * 100;
    }

# Appends, where for 1 they shall be eliminated later below:
    if ($i == 2) {
      if (2*10**6 <= $check1m && $check1m < 3*10**6) {
        $appendn = 'a';
      } elsif (3*10**6 <= $check1m && $check1m < 5*10**6) {
        $appendn = 'e';
      } else {
        $appendn = 'ov';
      }
    }
    if ($i == 4) {
      if (2*10**12 <= $check1b && $check1b < 3*10**12) {
        $appendn = 'a';
      } elsif (3*10**12 <= $check1b && $check1b < 5*10**12) {
        $appendn = 'e';
      } else {
        $appendn = 'ov';
      }
    }

    if ($numblock[$i] > 9) {
      # tens
      push @textnumber, $self->format_ten($numblock[$i], $belowhundred);
    } elsif ($numblock[$i] > 1) {
      # ones
      if (2*10**9 <= $check1md && $check1md < 3*10**9) {
    push @textnumber, 'dve';
      } else {
    push @textnumber, $self->{numbername}{$numblock[$i]};
      }
    } elsif ($numblock[$i] == 1) {
      if ($i == 0) {
    push @textnumber, $self->{numbername}{$numblock[$i]};
      } else {
    if ($i >= 5) {
        push @textnumber, $self->{numbername}{$numblock[$i]}.'-!-too big number-!-?!';
    } elsif ($i == 4) {
      if ($skip1b == 0) {
        push @textnumber, $self->{numbername}{$numblock[$i]};
      }
    } elsif ($i == 3) {
      if (1*10**9 <= $check1md && $check1md < 2*10**9) {
        push @textnumber, 'ena';
      } else {
        push @textnumber, $self->{numbername}{$numblock[$i]};
      }
    } elsif ($i == 2) {
      if ($skip1m == 0) {
        push @textnumber, $self->{numbername}{$numblock[$i]};
      }
    } elsif ($i == 1) {
      if ($skip1k == 0) {
        push @textnumber, $self->{numbername}{$numblock[$i]};
      }
    } else {
      push @textnumber, $self->{numbername}{$numblock[$i]};
    }
      }
      $appendn = "";
    }

# Appends, where also for 1 they shall be considered as below;
# if specified above with the others, they would be eliminated
# by a command just a few lines above...
#
    if ($i == 3) {
      if (1*10**9 <= $check1md && $check1md < 2*10**9) {
        $appendn = 'a';
      } elsif (2*10**9 <= $check1md && $check1md < 3*10**9) {
        $appendn = 'i';
      } elsif (3*10**9 <= $check1md && $check1md < 5*10**9) {
        $appendn = 'e';
      }
    }

    # add thousand, million
    if ($i) {
      $amount = 10**($i * 3);
      push @textnumber, $self->{numbername}{$amount}.$appendn;
    }

    pop @numblock;

    @textnumber = 'NAPAKA! ¿TEVILKA JE PREVELIKA!' if ($i > 4);

  }

  join '', @textnumber;

}


sub format_ten_sl {
  my ($self, $amount, $belowhundred) = @_;

  my $textnumber = "";
  my @num = split //, $amount;

  if ($amount > 20) {
    if ($num[1] == 0) {
      $textnumber = $self->{numbername}{$amount};
    } elsif ($num[1] == 1) {
      $amount = $num[0] * 10;
      $textnumber = $self->{numbername}{$num[1]}.'ain'.$self->{numbername}{$amount};
    } else {
      $amount = $num[0] * 10;
      $textnumber = $self->{numbername}{$num[1]}.'in'.$self->{numbername}{$amount};
    }
  } else {
    $textnumber = $self->{numbername}{$amount};
  }

  $textnumber;

}


1;


