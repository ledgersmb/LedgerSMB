
=head1 NAME

LedgerSMB::Template::ODS  Template support module for LedgerSMB

=head1 SYNOPSIS

OpenDocument Spreadsheet output.

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

package LedgerSMB::Template::ODS;

use Error qw(:try);
use CGI::Simple::Standard qw(:html);
use Template;
use XML::Twig;
use OpenOffice::OODoc;
use LedgerSMB::Template::TTI18N;

sub get_template {
	my $name = shift;
	return "${name}.odst";
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

sub _worksheet_handler {
	if ($sheet) {
		$rowcount = -1;
		$currcol = 0;
	}
	$sheet = $ods->getTable(0, $_->{att}->{rows}, $_->{att}->{columns});
	$ods->renameTable($sheet, $_->{att}->{name});
}

sub _row_handler {
	$rowcount++;
	$currcol = 0;
}

sub _cell_handler {
	my $cell = $ods->getCell(-1, $rowcount, $currcol);
	$ods->cellValue($cell, $_->{att}->{text});
	$currcol++;
}

sub _ods_process {
	my ($filename, $template, $user) = @_;

	# the handlers need these vars in common
	local $ods = ooDocument(file => $filename, create => 'spreadsheet');
	local $sheet;
	local $rowcount;
	local $currcol;
	my $parser = XML::Twig->new(
		start_tag_handlers => {
			worksheet => \&_worksheet_handler,
			row => \&_row_handler,
			},
		twig_handlers => {
			cell => \&_cell_handler,
			}
		);
	$parser->parse($template);
	$parser->flush;
	#$ods->normalizeSheet($sheet, $rowcount, $colcount);
	$ods->save;
}

sub process {
	my $parent = shift;
	my $cleanvars = shift;
	my $template;
	my $source;
	my $tempdir = ${LedgerSMB::Sysconfig::tempdir};
	my $output = '';
	$parent->{outputfile} ||= "$tempdir/$parent->{template}-output-$$";

	if (ref $parent->{template} eq 'SCALAR') {
		$source = $parent->{template};
	} elsif (ref $parent->{template} eq 'ARRAY') {
		$source = join "\n", @{$parent->{template}};
	} else {
		$source = get_template($parent->{template});
	}
	$template = Template->new({
		INCLUDE_PATH => $parent->{include_path},
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
		\$output, binmode => ':utf8')) {
		throw Error::Simple $template->error();
	}
	&_ods_process("$parent->{outputfile}.ods", $output, $parent->{myconfig});

	parent->{mimetype} = 'application/vnd.oasis.opendocument.spreadsheet';
}

sub postprocess {
	my $parent = shift;
	$parent->{rendered} = "$parent->{outputfile}.ods";
	return $parent->{rendered};
}

1;

