=head1 NAME

LedgerSMB::Menu:  Menu Handling Back-end Routines for LedgerSMB

=head1 SYNOPSIS

Provides the functions for generating the data structures for the LedgerSMB
menu.

=head1 COPYRIGHT

Copyright (c) 2007 The LedgerSMB Core Team.  Licensed under the GNU General 
Public License version 2 or at your option any later version.  Please see the
included COPYRIGHT and LICENSE files for more information.

=cut

package LedgerSMB::DBObject::Menu;

use Config::Std;
use base(qw(LedgerSMB::DBObject));
1;

=head1 METHODS

=over

=item LedgerSMB::Menu->new()

Inherited from LedgerSMB::DBObject.  Please see that documnetation for details.

=item $menu->generate()

This function returns a list of menu items.  Each list item is a hashref:
keys %menu_item would return the equivalent of qw(position id level label path 
args).  Returns the complete list and sets $menu->{menu_items} to a referene to 
th result set, This function does not return an entry for the top-level menu.

=cut

sub generate {
    my ($self) = shift @_;

    @{$self->{menu_items}} = $self->exec_method(funcname => 'menu_generate');
    $self->__generate;

    return @{$self->{menu_items}};
}

=over

=item Menu::generate_secton($object)

This class acts like Menu::Generate except it returns only a cross-section of 
the menu.  Basically it returns all nodes which are direct children below
$object->{parent_id}.

=cut

sub generate_section {
    my ($self) = shift @_;

    @{$self->{menu_items}} = $self->exec_method(funcname => 'menu_children');
    $self->__generate;

    return @{$self->{menu_items}};
}

=over

=item Menu::will_expire_soon($object)

This method returns true if the user's password will expire soon 
(within the next week).

=back

=cut

sub will_expire_soon {
    my ($self) = @_;
    my ($pw_expires) = $self->exec_method(
          funcname => 'user__expires_soon');
    $self->{expires_soon} = $pw_expires->{'user__expires_soon'};
    return $self->{expires_soon};
}

# Private method which contains logic common to the full menu and section logic

sub __generate {
    my ($self) = @_;
    my @args;

    shift @{$self->{menu_items}};

    for my $attribute (@{$self->{menu_items}}){
        
        @args = $self->_parse_array($attribute->{args});
        delete $attribute->{args};
        @{$attribute->{args}} = @args;
	for (@{$attribute->{args}}){
            if ($_ =~ /(module|menu|action)=/){
               @elems = split(/=/, $_);
               $attribute->{$elems[0]} = $elems[1];
            }
        }
    }
}

