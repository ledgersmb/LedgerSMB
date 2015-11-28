
=head1 NAME

LedgerSMB::Template::HTML - Template support module for LedgerSMB

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

=item escape($string)

Escapes a scalar string and returns the sanitized version.

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

use CGI::Simple::Standard qw(:html);
use Template;
use LedgerSMB::Template::TTI18N;
use LedgerSMB::Sysconfig;
use LedgerSMB::Company_Config;
use LedgerSMB::App_State;
use LedgerSMB::Template::DB;

my $binmode = ':utf8';
binmode STDOUT, $binmode;
binmode STDERR, $binmode;

sub get_template {
    my $name = shift;
    return "${name}.html";
}

sub preprocess {
    my $rawvars = shift;
    my $vars;
    { # pre-5.14 compatibility block
        local ($@); # pre-5.14, do not die() in this block
        if (eval {$rawvars->can('to_output')}){
            $rawvars = $rawvars->to_output;
        }
    }
    my $type = ref $rawvars;

    return $rawvars if $type =~ /^LedgerSMB::Locale/;
    return unless defined $rawvars;
    if ( $type eq 'ARRAY' ) {
        for (@{$rawvars}) {
            push @{$vars}, preprocess( $_ );
        }
    } elsif (!$type) {
        return escape($rawvars);
    } elsif ($type eq 'SCALAR' or $type eq 'Math::BigInt::GMP') {
        return escape($$rawvars);
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

sub escape {
    my $vars = shift @_;
    if (defined $vars){
        $vars = escapeHTML($vars);
        return $vars;
    }
    return undef;
}

sub process {
    my $parent = shift;
    my $cleanvars = shift;
    my $template;
    my $output;
    my $source;
        $parent->{binmode} = $binmode;

        my $dojo_theme;
        if ($LedgerSMB::App_State::DBH){
           local ($@); # pre-5.14, do not die() in this block
           eval { LedgerSMB::Company_Config->initialize()
                       unless $LedgerSMB::App_State::Company_Config;
             $dojo_theme = $LedgerSMB::App_State::Company_Config->{dojo_theme};
           }; # eval required to make setup.pl work as advertised
        }
        $dojo_theme ||= $LedgerSMB::Sysconfig::dojo_theme;
    $cleanvars->{dojo_theme} ||= $dojo_theme;
        $cleanvars->{UNESCAPE} = sub { return unescapeHTML(shift @_) };

    if ($parent->{outputfile}) {
            if (ref $parent->{outputfile}){
        $output = $parent->{outputfile};
            } else {
        $output = "$parent->{outputfile}.html";
            }
    } else {
        $output = \$parent->{output};
    }
        if ($parent->{include_path} eq 'DB'){
                $source = LedgerSMB::Template::DB->get_template(
                       $parent->{template}, undef, 'html'
                );
    } elsif (ref $parent->{template} eq 'SCALAR') {
        $source = $parent->{template};
    } elsif (ref $parent->{template} eq 'ARRAY') {
        $source = join "\n", @{$parent->{template}};
    } else {
        $source = get_template($parent->{template});
    }
        my $tempdir;
        my $paths = [$parent->{include_path},'templates/demo','UI/lib'];
        unshift @$paths, $parent->{include_path_lang}
            if defined $parent->{include_path_lang};
        my $arghash = {
        INCLUDE_PATH => $paths,
                ENCODING => 'utf8',
        START_TAG => quotemeta('<?lsmb'),
        END_TAG => quotemeta('?>'),
        DELIMITER => ';',
        TRIM => 1,
        DEBUG => ($parent->{debug})? 'dirs': undef,
        DEBUG_FORMAT => '',
        };
        if ($LedgerSMB::Sysconfig::cache_templates){
            $arghash->{COMPILE_EXT} = '.lttc';
            $arghash->{COMPILE_DIR} = $LedgerSMB::Sysconfig::cache_template_dir;
        }

    $template = Template->new(
                    $arghash
        ) || die Template->error();
    unless ($template->process(
        $source,
        {%$cleanvars, %$LedgerSMB::Template::TTI18N::ttfuncs,
            'escape' => \&preprocess},
        $output, {binmode => ':utf8'})){
        my $err = $template->error();
        die "Template error: $err" if $err;
    }
    $parent->{mimetype} = 'text/html';
}

sub postprocess {
    my $parent = shift;
    $parent->{rendered} = "$parent->{outputfile}.html" if $parent->{outputfile};
    return $parent->{rendered};
}

1;
