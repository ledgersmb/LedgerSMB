
package LedgerSMB::App_State;

=head1 NAME

LedgerSMB::App_State - Non-web application global state

=head1 DESCRIPTION

This is a generic container class for non-web-application related state
information.  It provides a central place to track such things as localization,
user, and other application state objects.

=cut

use strict;
use warnings;
use LedgerSMB::Sysconfig;
use LedgerSMB::User;
use LedgerSMB::Locale;

=head1 OBJECTS FOR STORAGE

The following are objects that are expected to be stored in this namespace:

=over

=cut

our $Locale;

=item Locale

Stores a LedgerSMB::Locale object for the specific user.

=cut

our $User;

=item User

Stores a LedgerSMB::User object for the currently logged in user.

=cut


our $Company_Settings;

=item Company_Settings

Hashref for storing connection-specific settings for the application.

=item DBH

Database handle for current connection

=cut

our $DBH;

=item DBName

name of the database connecting to

=cut

our $DBName;

=back

Each of the above has an accessor function of the same name which reads the
data, and a set_... function which writes it.  The set_ function should be
used sparingly.

The direct access approach is deprecated and is likely to go away in 1.5 with
the variables above given a "my" scope instead of an "our" one.

=over

=item DBName

=cut

sub DBName {
    return $DBName;
}

=item set_DBName

=cut

sub set_DBName {
    return $DBName = shift;
}

=item User

=cut

sub User {
    return $User;
}

=item set_User

=cut

sub set_User {
    return $User = shift;
}

=item Locale

=cut

sub Locale {
    return $Locale;
}

=item set_Locale

=cut

sub set_Locale {
    return $Locale = shift;
}

=item Company_Settings

=cut

sub Company_Settings {
    return $Company_Settings;
}

=item set_Company_Settings

=cut

sub set_Company_Settings {
    return $Company_Settings = shift;
}

=item DBH

=cut

sub DBH {
    return $DBH;
}

=item set_DBH

=cut

sub set_DBH {
    return $DBH = shift;
}

=back

=head1 METHODS

=head2 cleanup

Deletes all objects attached here.

=cut

sub cleanup {
    if ($DBH){
        $DBH->commit;
        $DBH->disconnect;
    }
    $Locale           = LedgerSMB::Locale->get_handle(
                            $LedgerSMB::Sysconfig::language
                        );
    $User             = {};
    $Company_Settings = {};
    $DBH = undef;
    $DBName = undef;
    delete $ENV{LSMB_ALWAYS_MONEY} if $ENV{LSMB_ALWAYS_MONEY};
    return;
}

=head2 run_with_state($state, &block)

Runs the block with the App_State parameters passed in C<$state>,
resetting the state after the block exits.

=cut

sub run_with_state {
    my $block = shift;
    my $state = { @_ };

    local ($DBH, $DBName, $User, $Company_Settings,
           $Locale, $ENV{LSMB_ALWAYS_MONEY})
        = ($state->{DBH} // $DBH,
           $state->{DBName} // $DBName,
           $state->{User} // $User,
           $state->{Company_Settings} // $Company_Settings,
           $state->{Locale} // $Locale,
           $ENV{LSMB_ALWAYS_MONEY});

    return $block->();
}

=head2 all_periods(is_short $bool)

Returns hashref of localized date data with following members:

If $is_short is set and true, returns short names (D, W, M, Q, Y) instead of
long names (Days, Weeks, Months, Quarters, Years).

=over

=item dropdown

Period information in drop down format.

=item hashref

Period info in hashref format in D => Days format

=back

=cut

sub all_periods {
    my ($self, $is_short) = @_;
    my $i18n = $Locale;
    my $periods = {
           # XXX That's asking for trouble below.  Need to update .po files
           # before changing however. --CT
     'day'     => { long => $i18n->text('Days'),
                    short => $i18n->text('D'), order => 1 },
     'week'    => { long => $i18n->text('Weeks'),
                    short => $i18n->text('W'), order => 2 },
     'month'   => { long => $i18n->text('Months'),
                    short => $i18n->text('M'), order => 3 },
     'quarter' => { long => $i18n->text('Quarters'),
                    short => $i18n->text('Q'), order => 4 },
     'year'    => { long => $i18n->text('Years'),
                    short => $i18n->text('Y'), order => 5 },
    };

    my $for_dropdown = [];
    my $as_hashref = {};
    for my $key (sort { $periods->{$a}->{order} <=> $periods->{$b}->{order}} keys %$periods){
        my $mname;
        if ($is_short){
           $mname = $periods->{$key}->{short};
        } else {
           $mname = $periods->{$key}->{long};
        }
        $as_hashref->{$key} = $mname;
        push @$for_dropdown, {text => $mname, value => $key};
    }
    return { as_hashref => $as_hashref, dropdown=> $for_dropdown };
}

=head2 all_months(is_short $bool)

Returns hashref of localized date data with following members:

If $is_short is set and true, returns short names (Jan, Feb, etc) instead of
long names (January, February, etc).

=over

=item dropdown

Month information in drop down format.

=item hashref

Month info in hashref format in 01 => January format

=back

=cut

sub all_months {
    my ($self, $is_short) = @_;
    my $i18n = $Locale;
    my $months = {
     '01' => {long => $i18n->text('January'),   short => $i18n->text('Jan'), },
     '02' => {long => $i18n->text('February'),  short => $i18n->text('Feb'), },
     '03' => {long => $i18n->text('March'),     short => $i18n->text('Mar'), },
     '04' => {long => $i18n->text('April'),     short => $i18n->text('Apr'), },
           # XXX That's asking for trouble below.  Need to update .po files
           # before changing however. --CT
     '05' => {long => $i18n->text('May'),       short => $i18n->text('May'), },
     '06' => {long => $i18n->text('June'),      short => $i18n->text('Jun'), },
     '07' => {long => $i18n->text('July'),      short => $i18n->text('Jul'), },
     '08' => {long => $i18n->text('August'),    short => $i18n->text('Aug'), },
     '09' => {long => $i18n->text('September'), short => $i18n->text('Sep'), },
     '10' => {long => $i18n->text('October'),   short => $i18n->text('Oct'), },
     '11' => {long => $i18n->text('November'),  short => $i18n->text('Nov'), },
     '12' => {long => $i18n->text('December'),  short => $i18n->text('Dec'), },
    };

    my $for_dropdown = [];
    my $as_hashref = {};
    for my $key (sort {$a cmp $b} keys %$months){
        my $mname;
        if ($is_short){
           $mname = $months->{$key}->{short};
        } else {
           $mname = $months->{$key}->{long};
        }
        $as_hashref->{$key} = $mname;
        push @$for_dropdown, {text => $mname, value => $key};
    }
    return { as_hashref => $as_hashref, dropdown=> $for_dropdown };
}

1;

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2009 LedgerSMB Core Team.  This file is licensed under the GNU
General Public License version 2, or at your option any later version.  Please
see the included License.txt for details.

