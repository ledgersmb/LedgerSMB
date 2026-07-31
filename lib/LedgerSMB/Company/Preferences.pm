
use v5.38;

package LedgerSMB::Company::Preferences;

use Moo;
use namespace::autoclean;

use Carp qw(croak);
use Log::Any qw($log);

use LedgerSMB::Company::Preference;

use Moo;
use namespace::autoclean;

=head1 NAME

LedgerSMB::Company::Preferences - Management of preferences

=head1 SYNOPSIS

  use LedgerSMB::Company;

  my $c = LedgerSMB::Company->new( dbh => $dbh, wire => $wire );
  my $p = $c->users->preferences;
  for my $i ($r->list->@*) {
    say $i->name;
  }

=head1 DESCRIPTION

Management of preferences.

=head1 VARIABLES

=head2 @PREFERENCES

=cut

our @PREFERENCES = qw( dateformat numberformat language stylesheet printer );

=head1 ATTRIBUTES

=head2 app

  my $app = $prefs->app;

Contains a reference to a C<LedgerSMB::Company> instance.

=cut

has _app => (
    is       => 'ro',
    init_arg => 'app',
    reader   => 'app',
    weak_ref => 1,
    required => 1);

=head2 for_user

  my $user = $prefs->for_user;

If this instance represents a collection of preferences assigned to
a specific user, this contains the C<LedgerSMB::Company::User>
instance for that user.

=cut

has for_user => (
    is   => 'ro'
    );

#
#  Cached preferences
#
#  Contains a hash with LedgerSMB::Company::Preference instances
#  as the values and the names of the preferences as keys.
#

has _preferences => (
    is   => 'rw',
    init_arg => undef,
    lazy => 1,
    builder => '_build_preferences',
    clearer => '_clear_preferences');

sub _build_preferences($self) {
    my $dbh = $self->app->dbh;

    # by sorting the NULLs (global defaults) first,
    # rows with the same setting *with* a user_id, get preference
    # over those *without* one
    my $query = <<~'SQL';
       SELECT user_id is null as default, id, name, value
         FROM user_preference
        WHERE user_id is null
               OR user_id = ?
        ORDER BY user_id NULLS FIRST
       SQL
    my $prefs = $dbh->selectall_arrayref( $query,
                                          { Slice => {} },
                                          $self->for_user ? $self->for_user->id : undef )
        or croak $log->error( 'Internal failure; unable to retrieve roles: ' . $dbh->errstr );

    return {
        map {
            $_->{name} => LedgerSMB::Company::Preference->new(
                app => $self->app,
                for_user => $self->for_user,
                $_->%{ qw( id name value default ) }
                );
        } $prefs->@*
    };
}

=head1 METHODS


=head2 fetch

=cut

sub fetch( $self ) {
    my %prefs;
    for my $p ($self->list->@*) {
        $prefs{ $p->name } = $p->value;
    }
    return \%prefs;
}

=head2 set

  $prefs->set( $name, $value, [$user] );

Adds a preference with C<$name> and C<$value> to the set of preferences
for C<$user>, or if no user is specified, to the user indicated by
the C<for_user> attribute. When the C<for_user> attribute isn't set,
the set of defaults is added to.

=cut

sub set( $self, $name, $value, $user = $self->for_user ) {
    if (not defined $name) {
        my $username = $user ? $user->name : '';
        my $usermsg = $user ?
            qq{preferences for user '$username'} :
            'default preferences';
        $log->warn( qq{Skipping addition of preference to $usermsg: value is <undef>} );
        return;
    }
    my $dbh = $self->app->dbh;
    my $query = <<~'SQL';
       INSERT INTO user_preference (user_id, "name", "value")
            VALUES (?, ?, ?)
            ON CONFLICT (coalesce(user_id, 0), "name") DO UPDATE SET "value" = ?
       SQL
    $dbh->do($query, {}, ($user ? $user->id : undef), $name, $value, $value)
        or croak $log->error( 'Failed to set preference: ' . $dbh->errstr );

    if ($user) {
        $user->preferences->_clear_preferences;
    }
    else {
        $self->_clear_preferences;
    }
    return;
}

=head2 get_by_name

  my $p = $prefs->get_by_name( $name );

Retrieves a preference from the collection by name. Returns C<undef>
when there is no preference by the given name in the collection.

=cut

sub get_by_name( $self, $name ) {
    return $self->_preferences->{$name};
}

=head2 list

  my $l = $prefs->list;

Lists all preferences in the collection. Returns all preferences for the
user indicated by C<for_user> or all default preferences if that's undefined.

=cut

sub list( $self ) {
    return [ sort { $a->name cmp $b->name } values $self->_preferences->%* ];
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.
