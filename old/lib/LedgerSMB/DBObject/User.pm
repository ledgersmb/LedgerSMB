=head1 NAME

LedgerSMB::DBObject::User - LedgerSMB User DB Objects

=cut

package LedgerSMB::DBObject::User;

use strict;
use warnings;

use base qw(LedgerSMB::PGOld);

use Locales unicode => 1;

use Log::Any;

=head2 NOTES

This badly needs to be rewritten and moved to later frameworks.  Planned for
1.5.

=head2 METHODS

=over

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
    $verify->disconnect;
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

    # Pull supported languages codes
    my @rows = $self->call_dbmethod(funcname => 'person__list_languages');

    # Load localized data from current locale
    my $locale = Locales->new($self->{prefs}{language});
    my %regions = $locale->get_territory_lookup();
    my %languages = $locale->get_language_lookup(); # Localized languages

    # Localize the list, making sure to keep the language key as is
    foreach my $row ( @rows ) {
        # Pull languages codes are of the form
        # 'Language(_country)?' where country is set when there is a variant
        # for a specific country.
        my ($language,$region) = split /_/, $row->{code};
        # Locales defines all language and country codes and some variants
        # have their name defined in specific
        # For example, fr_CA (French Canadian) has a translation available in
        # Spanish and French languages but nowhere else, so we need to compose
        # one for those others.
        # Use the language_country localized version if available
        my $label = $languages{$row->{code}} // $languages{$language};
        # Append the country if required
        $label .= ' - ' . $regions{lc($region)}
            if $region && !$languages{$row->{code}};
        push @{$self->{language_codes}}, {
            label => $label,
            id => $row->{code},
        }
    }
    @{$self->{language_codes}} =
        sort { $a->{label} cmp $b->{label} } @{$self->{language_codes}};

    $self->{cssfiles} = [];
    opendir CSS, "UI/css/.";
    for my $opt (grep /.*\.css$/, readdir CSS){
         push @{$self->{cssfiles}}, {file => $opt};
    }
    closedir CSS;

    $self->{printers} = [];

    if ( LedgerSMB::Sysconfig::printer()->%*
         && LedgerSMB::Sysconfig::latex() ) {
        foreach my $item ( sort keys LedgerSMB::Sysconfig::printer()->%* ) {
            push @{$self->{printers}}, {printer => $item};
        }
    }
    my ($pw_expiration) = $self->call_dbmethod(
            funcname => 'user__check_my_expiration');
    return $self->{password_expires} = $pw_expiration->{user__check_my_expiration};
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
