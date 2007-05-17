
=head1 NAME

LedgerSMB::Menufile  Routines to handle LedgerSMB menu files and format entries
for display.

=head1 SYNOPSIS

Routines to handle LedgerSMB menu files and conversion of menu entries into a
form usable by a web browser.  LedgerSMB menu files are a specific form of ini 
file.

Files use both ';' and '#' to denote line comments.  Any text after a line that
starts with '.' (i.e. ".foo") is ignored.  Menu items are denoted as [section],
with the sections containing key=value pairs.  The keys 'module', 'action', 
'target', 'href', and 'submenu' are specially treated, while other keys are
output as arguments to the destination link.  Blank lines are ignored.

=head2 Special key treatment

=over

=item action

This key is deleted on menuitem calls if there is no href value.

=item module

This is the Perl script that the menu item will call if the href attribute is
not set.  This key is always deleted on a menuitem call.

=item target

The value given for target will be passed as the target attribute for the tag.
This key is always deleted on a menuitem call.

=item href

When set, this key's value becomes the base URL for the menu item.  This key is
always deleted on a menuitem call.

=item submenu

This key is not displayed in output, but is deleted from the Menufile object
when menuitem is called on the item.

=back

=head2 Value Interpolation

If a value for a regular key includes an equals sign (=), values from the user's
configuration are substituted into the place of the string preceding and the 
first encountered equals sign in the value.  So a menu entry of 'apples=login='
would have the substition of 'apples=$myconfig->{login}' on generation of the
menu link.

=head1 METHODS

=over

=item new ([$filename])

Create a new Menufile object.  If a filename is specified, load the file with
add_file.

=item add_file ($filename)

Load the contents of the specified file into the Menufile object.  If the file
cannot be read, Form->error will be called with the failure message.  Attempts
to load already loaded items will result in the newer item merging with and 
overwriting stored data from the previous load.

Menu item titles are stored as keys in the Menufile object, and a special key, 
ORDER maintains a list of the order in which menu items were first seen.

=item menuitem ($myconfig, $form, $item)

Formats the menu item for the given key $item as an HTML <a href=""> open tag.
Returns the tag and deletes the module, target, href, action, and submenu
attributes for the item from the Menufile object.

If the menubar attribute of the passed in Form attribute is set, no style will
be set for the tag, otherwise the style is set to "display:block".

=item access_control ($myconfig, [$menulevel])

Returns the list of menu items that can be displayed with $myconfig->{acs} at
the selected menu level.  $menulevel is the string corresponding to a displayed
menu, such as 'AR' or 'AR--Reports'.  A blank level corresponds to the top 
level.  Merely excluding a top-level element does not exclude corresponding
lower level elements, i.e. excluding 'AR' will not block 'AR--Reports'.

$myconfig->{acs} is a semicolon seperated list of menu items to exclude.

This is only a cosmetic form of access_control.  Users can still access
"disallowed" sections of the application by manually entering in the URL.

=back

=head1 Copyright (C) 2006, The LedgerSMB core team.

 #====================================================================
 # LedgerSMB
 # Small Medium Business Accounting software
 # http://www.ledgersmb.org/
 #
 # Copyright (C) 2006
 # This work contains copyrighted information from a number of sources 
 # all used with permission.
 #
 # This file contains source code included with or based on SQL-Ledger
 # which is Copyright Dieter Simader and DWS Systems Inc. 2000-2005
 # and licensed under the GNU General Public License version 2 or, at
 # your option, any later version.  For a full list including contact
 # information of contributors, maintainers, and copyright holders,
 # see the CONTRIBUTORS file.
 #
 # Original Copyright Notice from SQL-Ledger 2.6.17 (before the fork):
 # Copyright (C) 2002
 #
 #  Author: DWS Systems Inc.
 #     Web: http://www.sql-ledger.org
 #
 #  Contributors:
 #   Tony Fraser <tony@sybaspace.com>
 #
 #=====================================================================
=cut

package LedgerSMB::Menufile;

use LedgerSMB::Form;

sub new {
    my ( $type, $file ) = @_;

    warn "$type has no copy constructor! creating a new object."
      if ref($type);
    $type = ref($type) || $type;
    my $self = bless {}, $type;
    $self->add_file($file) if defined $file;

    return $self;
}

sub add_file {
    my ( $self, $file ) = @_;

    my $id        = "";
    my %menuorder = ();

    for ( @{ $self->{ORDER} } ) { $menuorder{$_} = 1 }

    open FH, '<', "$file" or Form->error("$file : $!");

    while (<FH>) {
        next if /^(#|;|\s)/;
        last if /^\./;

        chop;

        # strip comments
        s/\s*(#|;).*//g;

        # remove any trailing whitespace
        s/^\s*(.*?)\s*$/$1/;

        if (/^\[/) {
            s/(\[|\])//g;
            $id = $_;
            push @{ $self->{ORDER} }, $_ if !$menuorder{$_};
            $menuorder{$_} = 1;
            next;
        }

        # add key=value to $id
        my ( $key, $value ) = split /=/, $_, 2;

        $self->{$id}{$key} = $value;

    }
    close FH;

}

sub menuitem {
    my ( $self, $myconfig, $form, $item ) = @_;

    my $module =
      ( $self->{$item}{module} ) ? $self->{$item}{module} : $form->{script};
    my $action =
      ( $self->{$item}{action} ) ? $self->{$item}{action} : "section_menu";
    my $target = ( $self->{$item}{target} ) ? $self->{$item}{target} : "";

    my $level = $form->escape($item);
    my $style;
    if ( $form->{menubar} ) {
        $style = "";
    }
    else {
        $style = "display:block;";
    }
    my $str =
        qq|<a style="$style"|
      . qq|href="$module?path=$form->{path}&amp;action=$action&amp;|
      . qq|level=$level&amp;login=$form->{login}&amp;|
      . qq|timeout=$form->{timeout}&amp;sessionid=$form->{sessionid}|
      . qq|&amp;js=$form->{js}|;

    my @vars = qw(module action target href);

    if ( $self->{$item}{href} ) {
        $str  = qq|<a href="$self->{$item}{href}|;
        @vars = qw(module target href);
    }

    for (@vars) { delete $self->{$item}{$_} }

    delete $self->{$item}{submenu};

    # add other params
    foreach my $key ( keys %{ $self->{$item} } ) {
        $str .= "&amp;" . $form->escape($key) . "=";
        ( $value, $conf ) = split /=/, $self->{$item}{$key}, 2;
        $value = "$myconfig->{$value}$conf"
          if $self->{$item}{$key} =~ /=/;

        $str .= $form->escape($value);
    }

    $str .= qq|#id$form->{tag}| if $target eq 'acc_menu';

    if ($target) {
        $str .= qq|" target="$target"|;
    }
    else {
        $str .= '"';
    }

    $str .= qq|>|;

}

sub access_control {
    my ( $self, $myconfig, $menulevel ) = @_;

    my @menu = ();

    if ( $menulevel eq "" ) {
        @menu = grep { !/--/ } @{ $self->{ORDER} };
    }
    else {
        @menu = grep { /^${menulevel}--/; } @{ $self->{ORDER} };
    }

    my @a = split /;/, $myconfig->{acs};
    my %excl = ();

    # remove --AR, --AP from array
    grep { ( $a, $b ) = split /--/; s/--$a$//; } @a;

    for (@a) { $excl{$_} = 1 }

    @a = ();
    for (@menu) { push @a, $_ unless $excl{$_} }

    @a;

}

1;
