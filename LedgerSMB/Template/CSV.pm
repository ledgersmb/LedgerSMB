
=head1 NAME

LedgerSMB::Template::CSV - Template support module for LedgerSMB

=head1 METHODS

=over

=item get_template ($name)

Returns the appropriate template filename for this format.

=item preprocess ($vars)

Returns $vars.

=item process ($parent, $cleanvars)

Processes the template for text.

=item escape ($var)

Escapes the variable for CSV inclusion

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

package LedgerSMB::Template::CSV;

use warnings;
use strict;

use Template;
use LedgerSMB::Template::TTI18N;
use LedgerSMB::Template::DB;

my $binmode = ':utf8';
binmode STDOUT, $binmode;
binmode STDERR, $binmode;

sub get_template {
    my $name = shift;
    return "${name}.csv";
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

    #XXX fix escaping function
    return $rawvars if $type =~ /^LedgerSMB::Locale/;
    return unless defined $rawvars;
    if ( $type eq 'ARRAY' ) {
        for (@{$rawvars}) {
            push @{$vars}, preprocess( $_ );
        }
    } elsif ( !$type or $type eq 'SCALAR' or $type eq 'Math::BigInt::GMP') {
            # Scalars or GMP objects (which are SCALAR refs) --CT
        if ($type eq 'SCALAR' or $type eq 'Math::BigInt::GMP') {
            $vars = $$rawvars;
            return unless defined $vars;
        } else {
            $vars = $rawvars;
        }
        $vars =~ s/(^ +| +$)//g;
    } elsif ( $type eq 'CODE' ) { # a code reference makes no sense
        return undef;
    } else { # hashes and objects
        for ( keys %{$rawvars} ) {
            $vars->{$_} = preprocess( $rawvars->{$_} );
        }
    }
    return $vars;
}

sub process {
    my $parent = shift;
    my $cleanvars = shift;
    my $template;
    my $source;
    my $output;
        $parent->{binmode} = $binmode;

    if ($parent->{outputfile}) {
            if (ref $parent->{outputfile}){
                $output = $parent->{outputfile};
            } else {
        $output = "$parent->{outputfile}.csv";
            }
    } else {
        $output = \$parent->{output};
    }
        if ($parent->{include_path} eq 'DB'){
                $source = LedgerSMB::Template::DB->get_template(
                       $parent->{template}, undef, 'csv'
                );
    } elsif (ref $parent->{template} eq 'SCALAR') {
        $source = $parent->{template};
    } elsif (ref $parent->{template} eq 'ARRAY') {
        $source = join "\n", @{$parent->{template}};
    } else {
        $source = get_template($parent->{template});
    }
    $template = Template->new({
        INCLUDE_PATH => [$parent->{include_path_lang}, $parent->{include_path}, 'UI/lib'],
        START_TAG => quotemeta('<?lsmb'),
        END_TAG => quotemeta('?>'),
        DELIMITER => ';',
        DEBUG => ($parent->{debug})? 'dirs': undef,
        DEBUG_FORMAT => '',
        }) || die Template->error();

    if (not $template->process(
        $source,
        {%$cleanvars, %$LedgerSMB::Template::TTI18N::ttfuncs,
            'escape' => \&preprocess},
        $output, binmode => ':utf8')) {
        die $template->error();
    }
    $parent->{mimetype} = 'text/csv';
}

sub postprocess {
    my $parent = shift;
    $parent->{rendered} = "$parent->{outputfile}.csv" if $parent->{outputfile};
        if (!$parent->{rendered}){
            return "$parent->{template}.csv";
        }
    return $parent->{rendered};
}

sub escape {
}

1;
