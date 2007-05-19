
=head1 NAME

LedgerSMB::Template::HTML  Template support module for LedgerSMB

=head1 METHODS

=over

=item get_template ()

Returns the appropriate template filename for this format.

=item preprocess ($vars)

This method returns a reference to a hash that contains a copy of the passed
hashref's data with HTML entities converted to escapes. 

=item postprocess ()

Currently does nothing.

=back

=head1 Copyright (C) 2007, The LedgerSMB core team.

This work contains copyrighted information from a number of sources all used
with permission.  

It is released under the GNU General Public License Version 2 or, at your 
option, any later version.  See COPYRIGHT file for details.  For a full list 
including contact information of contributors, maintainers, and copyright 
holders, see the CONTRIBUTORS file.
=cut

package LedgerSMB::Template::HTML;

use Error qw(:try);
use CGI;

sub get_template {
    my $name = shift;
    return "${name}.html";
}

sub preprocess {
    my $rawvars = shift;
    my $vars;
    my $type = ref $rawvars;

    #XXX fix escaping function
    if ( $type eq 'ARRAY' ) {
        for (@{$rawvars}) {
            push @{$vars}, preprocess( $_ );
        }
    }
    elsif ( $type eq 'HASH' ) {
        for ( keys %{$rawvars} ) {
            $vars->{$_} = preprocess( $rawvars->{$_} );
        }
    }
    else {
        return CGI::escapeHTML($rawvars);
    }
    return $vars;
}

sub postprocess {
    my $parent = shift;
    return;
}

1;
