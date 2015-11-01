=head1 NAME

LedgerSMB::App_State

=cut
package LedgerSMB::App_State;
use strict;
use warnings;
use LedgerSMB::Sysconfig;
use LedgerSMB::User;
use LedgerSMB::Locale;

=head1 SYNPOSIS

This is a generic container class for non-web-application related state
information.  It provides a central place to track such things as localization,
user, and other application state objects.

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

=item Roles

This is a list (array) of role names for the current user.

=cut

our @Roles;

=item Role_Prefix

String of the beginning of the role.

=cut

our $Role_Prefix;

=item DBName

name of the database connecting to

=cut

our $DBName;

=back

Each of the above has an accessor function fo the same name which reads the
data, and a set_... function which writes it.  The set_ function should be
used sparingly.

The direct access approach is deprecated and is likely to go away in 1.5 with
the variables above given a "my" scope instead of an "our" one.

=cut

sub _set_n {
    no strict 'refs';
    my ($att) = shift @_;
    for (@_){
        if ($_ ne __PACKAGE__){
            $$att = $_;
            return $_;
        }
    }
}

sub DBName {
    return $DBName;
}

sub set_DBName {
    return _set_n('DBName', @_);
}

sub User {
    return $User;
}

sub set_User {
    return _set_n('User', @_);
}

sub Locale {
    return $Locale;
}

sub set_Locale {
    return _set_n('Locale', @_);
}

sub Roles {
    return @Roles;
}

sub set_Roles {
    shift @_ if $_[0] eq __PACKAGE__;
    @Roles = @_;
    return @Roles;
}

sub Company_Settings {
    return $Company_Settings;
}

sub set_Company_Settings {
    return _set_n('Company_Settings', @_);
}

sub DBH {
    return $DBH;
}

sub set_DBH {
    return _set_n('DBH', @_);
}

sub Role_Prefix {
    return $Role_Prefix;
}

sub set_Role_Prefix {
    return _set_n('Role_Prefix', @_);
}

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
    @Roles = ();
    $Role_Prefix = undef;
    delete $ENV{LSMB_ALWAYS_MONEY} if $ENV{LSMB_ALWAYS_MONEY};
}

1;

=head2 get_url

Returns URL of get request or undef

=cut

sub get_url {
    if ($ENV{REQUEST_METHOD} ne 'GET') {
       return undef;
    }
    return "$ENV{SCRIPT_NAME}?$ENV{QUERY_STRING}";
}

sub get_relative_url {
    if ($ENV{REQUEST_METHOD} ne 'GET') {
       return undef;
    }
    my $script = $ENV{SCRIPT_NAME};
    $script =~ s#.*/([^/]+)$#$1#;
    return "$script?$ENV{QUERY_STRING}";
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

=head1 COPYRIGHT

Copyright (C) 2009 LedgerSMB Core Team.  This file is licensed under the GNU
General Public License version 2, or at your option any later version.  Please
see the included License.txt for details.

