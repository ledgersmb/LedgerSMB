
=head1 NAME

LedgerSMB::Template::XLS  Template support module for LedgerSMB

=head1 SYNOPSIS

Excel spreadsheet output.  For details about the XML template document
elements, see Excel::Template.  For details about various parameters used, see
Spreadsheet::WriteExcel.  As this module uses Excel::Template::Plus, flow
control and variable substitution are handled with TT with the usual for LSMB
tag formatting of <?lsmb foo ?> instead of the more HTML::Template-like forms
of Excel::Template.

=head1 METHODS

=over

=item get_template ($name)

Returns the appropriate template filename for this format.  '.xlst' is the
extension that was chosen for the templates.

=item preprocess ($vars)

Returns $vars.

=item process ($parent, $cleanvars)

Processes the template for text.

=item postprocess ($parent)

Returns the output filename.

=back

=head1 Copyright (C) 2007, The LedgerSMB core team.

This work contains copyrighted information from a number of sources all used
with permission.  

It is released under the GNU General Public License Version 2 or, at your 
option, any later version.  See COPYRIGHT file for details.  For a full list 
including contact information of contributors, maintainers, and copyright 
holders, see the CONTRIBUTORS file.
=cut

package LedgerSMB::Template::XLS;

use Error qw(:try);
use CGI::Simple::Standard qw(:html);
use Excel::Template::Plus;
use LedgerSMB::Template::TTI18N;

sub get_template {
	my $name = shift;
	return "${name}.xlst";
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
    } elsif (!$type) {
        return escapeHTML($rawvars);
    } else { # Hashes and objects
        for ( keys %{$rawvars} ) {
            $vars->{preprocess($_)} = preprocess( $rawvars->{$_} );
        }
    }
    
    return $vars;
}

sub process {
	my $parent = shift;
	my $cleanvars = shift;
	my $template;
	my $source;
	my $tempdir = ${LedgerSMB::Sysconfig::tempdir};
	$parent->{outputfile} ||= "$tempdir/$parent->{template}-output-$$";

	if (ref $parent->{template} eq 'SCALAR') {
		$source = $parent->{template};
	} elsif (ref $parent->{template} eq 'ARRAY') {
		$source = join "\n", @{$parent->{template}};
	} else {
		$source = get_template($parent->{template});
	}
	$template = Excel::Template::Plus->new(
		engine => 'TT',
		template => $source,
		params => {%$cleanvars, %$LedgerSMB::Template::TTI18N::ttfuncs,
			'escape' => \&preprocess},
		config => {
			INCLUDE_PATH => $parent->{include_path},
			START_TAG => quotemeta('<?lsmb'),
			END_TAG => quotemeta('?>'),
			DELIMITER => ';',
			DEBUG => ($parent->{debug})? 'dirs': undef,
			DEBUG_FORMAT => '',},
	);
	$template->write_file("$parent->{outputfile}.xls");

	parent->{mimetype} = 'application/vnd.ms-excel';
}

sub postprocess {
	my $parent = shift;
	$parent->{rendered} = "$parent->{outputfile}.xls" if $parent->{outputfile};
	return $parent->{rendered};
}

1;

