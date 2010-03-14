
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

use warnings;
use strict;

use Error qw(:try);
use CGI::Simple::Standard qw(:html);
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
    return unless defined $rawvars;
    if ( $type eq 'ARRAY' ) {
        for (@{$rawvars}) {
            push @{$vars}, preprocess( $_ );
        }
    } elsif (!$type) {
        return escapeHTML($rawvars);
    } elsif ($type eq 'SCALAR' or $type eq 'Math::BigInt::GMP') {
        return escapeHTML($$rawvars);
    } elsif ($type eq 'CODE'){
        return $rawvars;
    } elsif ($type eq 'IO::File'){
        return undef;
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
	my $output;
	my $source;
	
	if ($parent->{outputfile}) {
		$output = "$parent->{outputfile}.html";
	} else {
		$output = \$parent->{output};
	}
	if (ref $parent->{template} eq 'SCALAR') {
		$source = $parent->{template};
	} elsif (ref $parent->{template} eq 'ARRAY') {
		$source = join "\n", @{$parent->{template}};
	} else {
		$source = get_template($parent->{template});
	}
        my $tempdir;
        if ($LedgerSMB::Sysconfig::cache_templates){
            $tempdir = $LedgerSMB::Sysconfig::cache_template_dir;
        } else {
            $tempdir = undef;
        }
	$template = Template->new({
		INCLUDE_PATH => [$parent->{include_path}, 'UI/lib'],
		START_TAG => quotemeta('<?lsmb'),
		END_TAG => quotemeta('?>'),
		DELIMITER => ';',
		TRIM => 1,
                COMPILE_DIR=> $tempdir,
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
	$parent->{mimetype} = 'text/html';
}

sub postprocess {
    my $parent = shift;
    $parent->{rendered} = "$parent->{outputfile}.html" if $parent->{outputfile};
    return $parent->{rendered};
}

1;
