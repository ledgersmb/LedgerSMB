
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

use strict;
use warnings;

use Template;
use Template::Parser;
use LedgerSMB::Template::TTI18N;
use LedgerSMB::Template::DBProvider;
use DateTime;

# The following are for EDI only
my $dt = DateTime->now;
my $date = sprintf('%04d%02d%02d', $dt->year, $dt->month, $dt->day);
my $time = sprintf('%02d%02d', $dt->hour, $dt->min);

my $binmode = ':utf8';
my $extension = 'txt';

sub get_extension {
    my ($parent) = shift;
    if ($parent->{format_args}->{extension}){
        return $parent->{format_args}->{extension};
    } else {
        return $extension;
    }
}

sub get_template {
    my ($name, $parent) = @_;
    return "${name}.". get_extension($parent);
}

sub preprocess {
    # I wonder how much of this can be concentrated in the main template
    # module? --CT
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
        $vars = [];
        for (@{$rawvars}) {
            push @{$vars}, preprocess( $_ );
        }
    } elsif (!$type) {
        return escape($rawvars);
    } elsif ($type eq 'SCALAR' or $type eq 'Math::BigInt::GMP') {
        return escape($$rawvars);
    } elsif ($type eq 'CODE'){ # a code reference makes no sense
        return $rawvars;
    } elsif ($type eq 'IO::File'){
        return undef;
    } elsif ($type eq 'Apache2::RequestRec'){
        # When running in mod_perl2, we might encounter an Apache2::RequestRec
        # object; escaping its content is nonsense
        return undef;
    } else { # Hashes and objects
        $vars = {};
        for ( keys %{$rawvars} ) {
            $vars->{preprocess($_)} = preprocess( $rawvars->{$_} );
        }
    }

    return $vars;
}

sub escape {
    my $vars = shift @_;
    return undef unless defined $vars;
    $vars = escapeHTML($vars);
    return $vars;
}

sub process {
    my $parent = shift;
    my $cleanvars = shift;
        $cleanvars->{EDI_CURRENT_DATE} = $date;
        $cleanvars->{EDI_CURRENT_TIME} = $time;

    $parent->{binmode} = $binmode;

    my $output = '';
    if ($parent->{outputfile}) {
        if (ref $parent->{outputfile}){
            $output = $parent->{outputfile};
        } else {
            $output = "$parent->{outputfile}.". get_extension($parent);
            $parent->{outputfile} = $output;
        }
    }
    my $arghash = $parent->get_template_args($extension,$binmode);
    my $template = Template->new($arghash) || die Template->error();
    unless ($template->process(
                $parent->get_template_source(\&get_template),
                {
                    %$cleanvars,
                    %$LedgerSMB::Template::TTI18N::ttfuncs,
                    'escape' => \&preprocess
                },
                \$parent->{output},
                {binmode => $binmode})
    ){
        my $err = $template->error();
        die "Template error: $err" if $err;
    }
    if ($output){
        open(OUT, '>', $output);
        print OUT $parent->{output};
        close OUT;
    }
    $parent->{mimetype} = 'text/plain';
}

sub postprocess {
    my ($parent) = shift;
    if (!$parent->{rendered}){
        return $parent->{template} . '.' . get_extension($parent);
    }
    $parent->{rendered} = "$parent->{outputfile}.". get_extension($parent) if $parent->{outputfile};
    return $parent->{rendered};
}

1;
