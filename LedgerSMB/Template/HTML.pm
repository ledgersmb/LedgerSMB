
=head1 NAME

LedgerSMB::Template::HTML  Template support module for LedgerSMB

=head1 METHODS

=over

=item get_template ($name)

Returns the appropriate template filename for this format.

=item preprocess ($vars)

This method returns a reference to a hash that contains a copy of the passed
hashref's data with HTML entities converted to escapes. 

=item process ($parent, $cleanvars)

Processes the template for HTML.

=item postprocess ($parent)

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
use Template;
use LedgerSMB::Template::TTI18N;

sub get_template {
    my $name = shift;
    return "${name}.html";
}

sub preprocess {
    my $rawvars = shift;
    my $vars;
    my $type = ref $rawvars;

    #XXX fix escaping function
    return $rawvars if $type =~ /^LedgerSMB::Locale/;
    if ( $type eq 'ARRAY' ) {
        for (@{$rawvars}) {
            push @{$vars}, preprocess( $_ );
        }
    }
    elsif ( $type eq 'HASH' ) {
        for ( keys %{$rawvars} ) {
            $vars->{preprocess($_)} = preprocess( $rawvars->{$_} );
        }
    }
    else {
        return CGI::escapeHTML($rawvars);
    }
    return $vars;
}

sub process {
	my $parent = shift;
	my $cleanvars = shift;
	my $template;

	$template = Template->new({
		INCLUDE_PATH => $parent->{include_path},
		START_TAG => quotemeta('<?lsmb'),
		END_TAG => quotemeta('?>'),
		DELIMITER => ';',
		}) || throw Error::Simple Template->error(); 
	if (not $template->process(
		get_template($parent->{template}), 
		{%$cleanvars, %$LedgerSMB::Template::TTI18N::ttfuncs,
			'escape' => \&preprocess},
		"$parent->{outputfile}.html", binmode => ':utf8')) {
		throw Error::Simple $template->error();
	}
	$parent->{mimetype} = 'text/html';
}

sub postprocess {
    my $parent = shift;
    $parent->{rendered} = "$parent->{outputfile}.html";
    return "$parent->{outputfile}.html";
}

1;
