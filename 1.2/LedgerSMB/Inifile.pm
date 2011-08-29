
=head1 NAME

Inifile  Routines to load LedgerSMB menu files.

=head1 STATUS

API I<deprecated>, removed in 1.3.

=head1 SYNOPSIS

Routines to load LedgerSMB menu files.  LedgerSMB menu files are a specific 
form of ini file.

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

package Inifile;

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

1;

