
=head1 NAME

LedgerSMB::Template::TXT - Template support module for LedgerSMB

=head1 METHODS

=over

=item get_extension
Private method to get extension.  Do not call directly.

=item get_template ($name)

Returns the appropriate template filename for this format.

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

package LedgerSMB::Template::TXT;

use warnings;
use strict;

use Error qw(:try);
use Template;
use LedgerSMB::Template::TTI18N;

my $binmode = ':utf8';
binmode STDOUT, $binmode;
binmode STDERR, $binmode;

sub get_extension {
    my ($parent) = shift;
    if ($parent->{format_args}->{extension}){
        return $parent->{format_args}->{extension};
    } else {
        return 'txt';
    }
}

sub get_template {
    my ($name, $parent) = @_;
    my $extension;
    return "${name}.". get_extension($parent);
}

sub preprocess { # TODO handling of objects with to_output methods
    my $rawvars = shift;
    return $rawvars;
}

sub process {
	my $parent = shift;
	my $cleanvars = shift;
	my $template;
	my $source;
	my $output;
        $parent->{binmode} = $binmode;
	if ($parent->{outputfile}) {
		$output = "$parent->{outputfile}.". get_extension($parent);
	} else {
		$output = \$parent->{output};
	}
	if (ref $parent->{template} eq 'SCALAR') {
		$source = $parent->{template};
	} elsif (ref $parent->{template} eq 'ARRAY') {
		$source = join "\n", @{$parent->{template}};
	} else {
		$source = get_template($parent->{template}, $parent);
	}
	$template = Template->new({
		INCLUDE_PATH => [$parent->{include_path_lang}, $parent->{include_path}, 'UI/lib'],
		START_TAG => quotemeta('<?lsmb'),
		END_TAG => quotemeta('?>'),
		DELIMITER => ';',
		DEBUG => ($parent->{debug})? 'dirs': undef,
		DEBUG_FORMAT => '',
		}) || throw Error::Simple Template->error(); 

	if (not $template->process(
		$source, 
		{%$cleanvars, %$LedgerSMB::Template::TTI18N::ttfuncs,
			'escape' => \&preprocess},
		$output, binmode => ':utf8')) {
		throw Error::Simple $template->error();
	}
	$parent->{mimetype} = 'text/plain';
}

sub postprocess {
    my ($parent) = shift;
    if (!$parent->{rendered}){
        return $parent->{template} . '.' get_extension($parent); 
    }
    $parent->{rendered} = "$parent->{outputfile}.". get_extension($parent) if $parent->{outputfile};
    return $parent->{rendered};
}

1;
