
=head1 NAME

LedgerSMB::Setting - LedgerSMB class for managing Business Locations

=head1 SYOPSIS

This module creates object instances based on LedgerSMB's in-database ORM.

=head1 METHODS

The following method is static:

=over

=item new ($LedgerSMB object);

=back

The following methods are passed through to stored procedures:

=over

=item get ($self->{key})

=item set ($self->{key}, $self->{value})

=item all_accounts()

Returns a list of all accounts on the system.

=item parse_increment ($self->{key})

This function updates a default entry in the database, incrimenting the last
set of digits not including <?lsmb ?> tags or non-digits, and then parses the
returned value, doing tag substitution.  The final value is then returned by
the function.

=back

The above list may grow over time, and may depend on other installed modules.

=head1 Copyright (C) 2007, The LedgerSMB core team.

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

package LedgerSMB::Setting;
use LedgerSMB::App_State;
use base qw(LedgerSMB::PGOld);
use strict;
use warnings;

our $VERSION = '1.0.0';


sub get {
    my $self = shift;
    my ($key) = @_;
    $key = $self->{key} unless $key;
    my ($hashref) = __PACKAGE__->call_procedure(
                                             dbh => LedgerSMB::App_State::DBH(),
                                        funcname => 'setting_get',
                                            args => [$key]) ;
    $self->{value} = $hashref->{value} if ref $self !~ /hash/i;
    return $hashref->{value};
}

sub increment {

    my $self     = shift;
    my $myconfig = shift;
    my $key = shift;
    $key ||= $self->{key};

    my ($retval) = $self->call_procedure(funcname => 'setting_increment',
                                             args => [$key]) ;
    my $value = $retval->{setting_increment};

    my $var = _increment_process($value, $self, $myconfig);

    $self->{value} = $var if $self->{key};
    return $var;
}

# Increment processing routine, used by only related classes.
#
sub _increment_process{
    my ($value, $self ) = @_;
# check for and replace
# <?lsmb DATE ?>, <?lsmb YYMMDD ?>, <?lsmb YEAR ?>, <?lsmb MONTH ?>, <?lsmb DAY ?> or variations of
# <?lsmb NAME 1 1 3 ?>, <?lsmb BUSINESS ?>, <?lsmb BUSINESS 10 ?>, <?lsmb CURR... ?>
# <?lsmb DESCRIPTION 1 1 3 ?>, <?lsmb ITEM 1 1 3 ?>, <?lsmb PARTSGROUP 1 1 3 ?> only for parts
# <?lsmb PHONE ?> for customer and vendors

    my $myconfig = $LedgerSMB::App_State::User;
    my $dbvar = $value;
    my $var   = $value;
    my $str;
    my $param;

    if ($value =~ /<\?lsmb /) {

        while ($value =~ /<\?lsmb /) {

            $value =~ s/(<\?lsmb .*? \?>)//;
            last unless $&;
            $param = $1;
            $str   = "";

            if ( $param =~ /<\?lsmb date \?>/i ) {
                $str = (
                    $self->split_date(
                        $myconfig->{dateformat},
                        $self->{transdate}
                    )
                )[0];
                $var =~ s/$param/$str/;
            }

            if ( $param =~
/<\?lsmb (name|business|description|item|partsgroup|phone|custom)/i
               )
            {

                my $fld = lc $&;
                $fld =~ s/<\?lsmb //;

                if ( $fld =~ /name/ ) {
                    if ( $self->{type} ) {
                        $fld = $self->{vc};
                    }
                }

                my $p = $param;
                $p =~ s/(<|>|%)//g;
                my @p = split / /, $p;
                my @n = split / /, uc $self->{$fld};

                if ( $#p > 0 ) {

                    for ( my $i = 1 ; $i <= $#p ; $i++ ) {
                        $str .= substr( $n[ $i - 1 ], 0, $p[$i] );
                    }

                }
                else {
                    ($str) = split /--/, $self->{$fld};
                }

                $var =~ s/$param/$str/;
                $var =~ s/\W//g if $fld eq 'phone';
            }

            if ( $param =~ /<\?lsmb (yy|mm|dd)/i ) {
        # SC: XXX Does this even work anymore?
                my $p = $param;
                $p =~ s/lsmb//;
                $p =~ s/[^YyMmDd]//g;
                my %d = ( yy => 1, mm => 2, dd => 3 );
                my $str = $p;

                my @a = $self->split_date( $myconfig->{dateformat},
                    $self->{transdate} );
                for my $k( keys %d ) { $str =~ s/$k/$a[ $d{$k} ]/i}
                $var =~ s/\Q$param\E/$str/i;
            }

            if ( $param =~ /<\?lsmb curr/i ) {
                $var =~ s/$param/$self->{currency}/;
            }
        }
    }
    return $var;
}

sub get_currencies {
    my $self = shift;
    my @data = $self->call_dbmethod(funcname => 'setting__get_currencies');
    @{$self->{currencies}} = $self->_parse_array($data[0]->{setting__get_currencies});
    return @{$self->{currencies}};
}

sub set {
    my ($self, $key, $value) = @_;
    $key ||= $self->{key};
    $value ||= $self->{value};
    $self->call_procedure(funcname => 'setting__set',
                              args => [$key, $value]);
}

sub accounts_by_link {
    my ($self, $link) = @_;
    my @results = $self->call_procedure(funcname => 'account__get_by_link_desc',
                              args => [$link]);
    for my $ref (@results){
        $ref->{text} = "$ref->{accno} -- $ref->{description}";
    }
    return \@results;
}

sub all_accounts {
    my ($self) = @_;

    my @results = $self->call_procedure(funcname => 'chart_list_all',
                              args => []);

    for my $ref (@results){
        $ref->{text} = "$ref->{accno} -- $ref->{description}";
    }
    return \@results;
}

1;
