=head1 NAME

LedgerSMB::DBObject::User - LedgerSMB User DB Objects

=cut

package LedgerSMB::DBObject::User;

use strict;
use warnings;

use base qw(LedgerSMB::PGOld);
use Log::Log4perl;

use Try::Tiny;

=head2 NOTES

This badly needs to be rewritten and moved to later frameworks.  Planned for
1.5.

=head2 METHODS

=over

=item country_codes();

Returns a hash where the keys are registered locales and the values are the
textual representation of the locale name.

=cut

sub country_codes {
    use Locale::Country;
    use Locale::Language;

    my %cc = ();

    # scan the locale directory and read in the LANGUAGE files
    opendir DIR, "${LedgerSMB::Sysconfig::localepath}";

    my @dir = grep !/^\..*$/, readdir DIR;

    foreach my $dir (@dir) {
        $dir = substr( $dir, 0, -3 );  ## no critic (ProhibitMagicNumbers) sniff
        $cc{$dir} = code2language( substr( $dir, 0, 2 ) );
        $cc{$dir} .= ( "/" . code2country( substr( $dir, 3, 2 ) ) )  ## no critic (ProhibitMagicNumbers) sniff
          if length($dir) > 2;
        $cc{$dir} .= ( " " . substr( $dir, 6 ) ) if length($dir) > 5;  ## no critic (ProhibitMagicNumbers) sniff
    }

    closedir(DIR);

    return %cc;
}


=item save_preferences()

Saves preferences to the database and reloads the values in the object
from the db for consistency.

=cut


sub save_preferences {
    my ($self) = @_;
    $self->call_dbmethod(funcname => 'user__save_preferences');
    return $self->get;
}

=item change_my_password()

Uses the object keys:

 * login
 * old_password
 * new_password

to establish a database connection and change the user's password.

=cut

sub change_my_password {
    my ($self) = @_;

    # Before doing any work at all, reject the request when the passwords
    # don't match...
    if ($self->{new_password} ne $self->{confirm_password}){
        $self->error($self->{_locale}->text('Passwords must match.'));
        die;
    }


    $self->get unless $self->{user};

    my $dbname = $self->{company};

    my $verify = DBI->connect(
        qq|dbi:Pg:dbname="$dbname"|, $self->{login}, $self->{old_password}
    );
    if (!$verify){
        $self->error($self->{_locale}->text('Incorrect Password'));
    }
    else {
        $verify->disconnect;
    }

    $self->{password} = $self->{new_password};
    return $self->call_dbmethod(funcname => 'user__change_password');
}

=item get_option_data()

Sets the options for the user preference screen.

=cut

sub get_option_data {
    my $self = shift @_;
    $self->{dateformats} = [];
    $self->{numberformats} = [];
    for my $opt (qw(mm-dd-yyyy mm/dd/yyyy dd-mm-yyyy dd/mm/yyyy dd.mm.yyyy yyyy-mm-dd)){
        push @{$self->{dateformats}}, {format => $opt};
    }
    no warnings 'qw';
    for my $opt (qw(1,000.00 1000.00 1.000,00 1000,00 1'000.00)){
        push @{$self->{numberformats}}, {format => $opt};
    }
    use warnings;

    my %country_codes = country_codes();

    foreach my $key ( sort { $country_codes{$a} cmp $country_codes{$b} }
        keys %country_codes )
    {
        push @{$self->{country_codes}}, {
            label => $country_codes{$key},
            id => $key,
        };
    }

    $self->{cssfiles} = [];
    opendir CSS, "UI/css/.";
    for my $opt (grep /.*\.css$/, readdir CSS){
         push @{$self->{cssfiles}}, {file => $opt};
    }
    closedir CSS;

    $self->{printers} = [];

    if ( %{LedgerSMB::Sysconfig::printer} && ${LedgerSMB::Sysconfig::latex} ) {
        foreach my $item ( sort keys %{LedgerSMB::Sysconfig::printer} ) {
            push @{$self->{printers}}, {printer => $item};
        }
    }
    my ($pw_expiration) = $self->call_dbmethod(
            funcname => 'user__check_my_expiration');
    return $self->{password_expires} = $pw_expiration->{user__check_my_expiration};
}

=item save()

Saves (creates) the user in the database

Return codes:
 - 0 as success,
 - 8 as duplicate user, and
 - 1 as general failure

=cut

sub save {

    my $self = shift @_;
    my $user = $self->get();

    my $errcode;
    my ($ref) = try { $self->call_dbmethod(funcname=>'admin__save_user') }
                catch {
                   if ($_ =~ /No password/){
                      die LedgerSMB::App_State::Locale->text(
                             'Password required'
                      );
                   } elsif ($_ =~/Duplicate user/){
                      $self->{dbh}->rollback;
                      $errcode = 8;  ## no critic (ProhibitMagicNumbers) sniff
                   }
                };
    return $errcode if $errcode;

    ($self->{id}) = values %$ref;
    if (!$self->{id}) {

        return 0;
    }
    return 1;
}

=item get($id)

Initializes the $self instance with data from the database, identified
with user id $id.

=cut

sub get {

    my $self = shift @_;
    my $id = shift;
    if ($id){
        $self->{user_id} = $id;
    }
    if (!defined $self->{user_id}){
       return;
    }
    my ($user) = $self->call_dbmethod(funcname=>'admin__get_user');
    $self->{user} = $user;
    my ($prefs) = $self->call_dbmethod(funcname=>'user__get_preferences');
    $self->{prefs} = $prefs;
    my ($emp) = $self->call_procedure(
        funcname=>'employee__get',
        args=>[$self->{user}->{entity_id}]
        );
    $self->{employee} = $emp;
    my ($ent) = $self->call_procedure(
        funcname=>'entity__get',
        args=>[ $self->{user}->{entity_id} ]
        );
    $self->{entity} = $ent;
    my @roles = $self->call_dbmethod(
        funcname=>'admin__get_roles_for_user',
    );
    # Now, location and stuff.
    my @loc = $self->call_procedure(
        funcname=>'person__list_locations',
        args=>[ $self->{user}->{entity_id} ]
    );
    $self->{locations} = \@loc;
    my @contacts = $self->call_procedure(
        funcname=>"person__list_contacts",
        args=>[$self->{user}->{entity_id} ]
    );
    $self->{contacts} = \@contacts;
    my @rolstore;

    for my $role (@roles) {
        my $rolname = $role->{'admin__get_roles_for_user'};
        my $company = $self->{company};
        push @rolstore, $rolname; # Only one key=>value pair
    }
    $self->{roles} = \@rolstore;

    $self->{entity_id} = $self->{entity}->{id};

    return $user;
}

=item remove()

Removes the user identified by $self->{id} and $self->{username}.

=cut

sub remove {

    my $self = shift;

    my $code = $self->call_procedure(funcname=>"admin__delete_user", args=>[$self->{id}, $self->{username}]);
    $self->{id} = undef;

    return $code->[0];
}

# sub save_prefs {

#     my $self = shift @_;

#     my $pref_id = $self->call_procedure(funcname=>"admin__save_preferences",
#         args=>[
#             'language',
#             'stylesheet',
#             'printer',
#             'dateformat',
#             'numberformat'
#         ]
#     );
# }

=item get_all_users()

Retrieves a list of users for the company (database).
Sets $self->{users} and returns an arrayref.

=cut

sub get_all_users {

    my $self = shift @_;

    my @ret = $self->call_dbmethod( funcname=>"user__get_all_users" );
    return $self->{users} = \@ret;
}


=back

=cut

1;

