package LedgerSMB::Setting;

use LedgerSMB::App_State;
use base qw(LedgerSMB::PGOld Exporter);
use strict;
use warnings;

=head1 NAME

LedgerSMB::Setting - Interact with LedgerSMB company settings.

=head1 SYNOPSIS

    use LedgerSMB::Setting;

    $setting = LedgerSMB::Setting->new();
    $setting->set_dbh($dbh);

    # Write to the defaults table
    $setting->set('company_name' => 'Bar Foo')

    # Get from the defaults table
    $name = $setting->get('company_name');

    # Display all accounts
    $accounts = $setting->all_accounts;
    foreach my $account (@{$accounts}) {
        print $account->{description} . "\n";
    }

    # Display all AR tax accounts
    $accounts = $setting->accounts_by_link('AR_tax');
    foreach my $account (@{$accounts}) {
        print $account->{description} . "\n";
    }

    # Get defined currencies
    @currencies = $setting->get_currencies;

=head1 EXPORTS

C<increment_process>

=cut

our @EXPORT_OK = qw( increment_process );

=head1 METHODS

Inherits from L<LedgerSMB::PGOld>

=head2 get($key)

Retrieve the value of the specified C<key> from the database C<defaults>
table.

=cut

sub get {
    my $self = shift;
    my ($key) = @_;
    $key = $self->{key} unless $key;
    my ($hashref) = __PACKAGE__->call_procedure(
                                             dbh => LedgerSMB::App_State::DBH(),
                                        funcname => 'setting_get',
                                            args => [$key]) ;
    if (defined($hashref)) {
        $self->{value} = $hashref->{value} if ref $self !~ /hash/i;
        return $hashref->{value};
    }
    return undef;
}

=head2 increment($myconfig, $key)

TODO

=cut

sub increment {

    my $self     = shift;
    my $myconfig = shift;
    my $key = shift;
    $key ||= $self->{key};

    my ($retval) = $self->call_procedure(funcname => 'setting_increment',
                                             args => [$key]) ;
    my $value = $retval->{setting_increment};

    my $var = increment_process($value, $self, $myconfig);

    $self->{value} = $var if $self->{key};
    return $var;
}

=head2 increment_process

Increment processing subroutine (NOT an object method), used by only related classes.

This function updates a default entry in the database, incrementing the last
set of digits not including <?lsmb ?> tags or non-digits, and then parses the
returned value, doing tag substitution.  The final value is then returned by
the function.

=cut

sub increment_process{
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
            last unless $1;
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

                my $fld = lc $1;

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

=head2 get_currencies()

Returns an array of currencies defined for the current company.

=cut

sub get_currencies {
    my $self = shift;
    my @data = $self->call_dbmethod(funcname => 'setting__get_currencies');
    $self->{currencies} = $data[0]->{setting__get_currencies};
    return @{$self->{currencies}};
}

=head2 set($key, $value)

Update the C<defaults> database table with the specified key/value pair.

=cut

sub set {
    my ($self, $key, $value) = @_;
    $key ||= $self->{key};
    $value ||= $self->{value};
    return $self->call_procedure(funcname => 'setting__set',
                              args => [$key, $value]);
}

=head2 accounts_by_link($link_description)

Returns an arrayref containing all accounts having the specified
C<link_description> (AP, AR, AR_tax, IC_cogs etc).

Useful for populating drop-down lists.

=cut

sub accounts_by_link {
    my ($self, $link) = @_;
    my @results = $self->call_procedure(funcname => 'account__get_by_link_desc',
                              args => [$link]);
    for my $ref (@results){
        $ref->{text} = "$ref->{accno} -- $ref->{description}";
    }
    return \@results;
}

=head2 all_accounts()

Returns an arrayref containing all accounts.

=cut

sub all_accounts {
    my ($self) = @_;

    my @results = $self->call_procedure(funcname => 'chart_list_all',
                              args => []);

    for my $ref (@results){
        $ref->{text} = "$ref->{accno} -- $ref->{description}";
    }
    return \@results;
}

=head1 Copyright (C) 2007-2018, The LedgerSMB core team.

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
