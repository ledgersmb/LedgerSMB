
use v5.38;

package LedgerSMB::Company::Preference;

use Carp qw(croak);
use Log::Any qw($log);

use Moo;
use namespace::autoclean;

=head1 NAME

LedgerSMB::Company::Preference - Preference management

=head1 SYNOPSIS



=head1 DESCRIPTION



=head1 ATTRIBUTES

=head2 app

  my $app = $pref->app

The C<LedgerSMB::Company> instance this preference is associated with.

=cut

has _app => (
    is       => 'ro',
    init_arg => 'app',
    reader   => 'app',
    weak_ref => 1,
    required => 1);

=head2 for_user

  my $user = $pref->for_user;

Returns the user for which this instance tracks a preference. If
this isn't set, this instance does not track specific user preference
and represents the global preference value instead.

=cut

has for_user => (
    is    => 'ro',
    );

=head2 name

  my $name = $pref->name;

Returns the (technical) name of the preference.

=cut

has name => (
    is    => 'ro',
    init_arg => 'name',
    required => 1);


=head2 value

  my $value = $pref->value;

Returns the value of the preference.

=cut

has value => (
    is => 'rw',
    init_arg => 'value',
    reader => 'value',
    writer => 'set_value',
    required => 1);

=head2 default

  my $default = $pref->default;

Returns true if this is a default preference, which happens for
any user preference which does not have a specific value set as
well as for all global preference values.

=cut

has default => (
    is => 'rw',
    init_arg => 'default',
    reader => 'default',
    writer => 'set_default',
    required => 1);

=head1 METHODS

=head2 set

  $pref->set( $value );

Sets the value of the preference.

=cut

sub set($self, $value, $user = $self->for_user) {
    my $dbh = $self->app->dbh;

     my $query = <<~'SQL';
       INSERT INTO user_preference (user_id, "name", "value")
            VALUES (?, ?, ?)
            ON CONFLICT (coalesce(user_id, 0), "name") DO UPDATE SET "value" = ?
       SQL
    $dbh->do($query, {}, ($user ? $user->id : undef), $self->name, $value, $value)
        or croak $log->error( 'Failed to set preference: ' . $dbh->errstr );
}

=head2 reset

  $pref->reset;

Restores a user's preference to its default value, or, if this is a global
user preference, removes the preference from the system entirely.

=cut

sub reset($self, $user = $self->for_user) {
    my $dbh = $self->app->dbh;

    $dbh->do('DELETE FROM user_preference WHERE "name" = ? AND user_id IS NOT DISTINCT FROM ?',
             {},
             $user ? $user->id : undef,
             $self->name)
        or croak $log->error( 'Failed to reset preference: ' . $dbh->errstr );
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.
