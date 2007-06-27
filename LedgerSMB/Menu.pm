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

package LedgerSMB::Menu;

use Config::Std;
use base(qw(LedgerSMB));

1;

=head1 METHODS

=over

=item new({files => ['path/to/file/glob' ... ], user = $user_ref})

Creates a new Menu data structure with the files listed and the files in the 
paths.

=cut


sub new {
    my ($class, $args) = @_;
    my $self = {};
    bless ($self, $class);
    my $index = 1;
    for $file_glob (@{$args->{files}}){
        for $file (glob($file_glob)){
            my %config;
            read_config($file => %config );
            for $key (keys %config){
                next if $args->{user}->{acs} =~ /$key/;
                my $orig_key = $key;
                my $ref = $self;
                while ($key =~ s/^([^-]*)--//){
                    $ref->{subs} ||= {};
                    $ref->{subs}->{$1} ||= {};
                    $ref = $ref->{subs}->{$1};
                }
                $ref->{subs} ||= {};
		$ref->{subs}->{key} ||= {};
                $ref = $ref->{subs}->{$key};
                for (keys %{$config{$orig_key}}){
                     $ref->{$_} = ${$config{$orig_key}}{$_};
                }
                $ref->{id} = $index;
                $ref->{label} = $key;
                ++$index;
            }
        }
    }
    return $self;
}
1;
=back
