
=head1 NAME

LedgerSMB::Template::PS  Template support module for LedgerSMB

=head1 METHODS

=over

=item get_template ($name)

Returns the appropriate template filename for this format.

=item preprocess ($vars)

Currently does nothing.

=item process ($parent, $cleanvars)

Processes the template for Postscript.

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

package LedgerSMB::Template::PS;

use Error qw(:try);
use Template::Latex;
use LedgerSMB::Template::TTI18N;

sub get_template {
	my $name = shift;
	return "${name}.tex";
}

sub preprocess {
	my $rawvars = shift;
	my $vars;
	my $type = ref $rawvars;

	return $rawvars if $type =~ /^LedgerSMB::Locale/;
	if ($type eq 'ARRAY') {
		for (@{$rawvars}) {
			push @{$vars}, preprocess($_);
		}
	} elsif (!$type) {
		#XXX Fix escaping
		$rawvars =~ s/([&\$\\_<>~^#\%\{\}])/\\$1/g;
		$rawvars =~ s/"(.*)"/``$1''/gs;
		return $rawvars;
	} else {
		for ( keys %{$rawvars} ) {
			$vars->{$_} = preprocess($rawvars->{$_});
		}
	}
	return $vars;
}

sub process {
	my $parent = shift;
	my $cleanvars = shift;
	my $template;
	$parent->{outputfile} ||=
		"${LedgerSMB::Sysconfig::tempdir}/$parent->{template}-output-$$";

	$template = Template::Latex->new({
		LATEX_FORMAT => 'ps',
		INCLUDE_PATH => $parent->{include_path},
		START_TAG => quotemeta('<?lsmb'),
		END_TAG => quotemeta('?>'),
		DELIMITER => ';',
		DEBUG => ($parent->{debug})? 'dirs': undef,
		DEBUG_FORMAT => '',
		}) || throw Error::Simple Template::Latex->error(); 

	if (not $template->process(
		get_template($parent->{template}), 
		{%$cleanvars, %$LedgerSMB::Template::TTI18N::ttfuncs,
			'escape' => \&preprocess},
		"$parent->{outputfile}.ps", binmode => 1)) {
		throw Error::Simple $template->error();
	}
	$parent->{mimetype} = 'application/postscript';
}

sub postprocess {
	my $parent = shift;
	$parent->{rendered} = "$parent->{outputfile}.ps";
	return "$parent->{outputfile}.ps";
}

1;
