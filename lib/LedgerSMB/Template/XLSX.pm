
=head1 NAME

LedgerSMB::Template::XLSX - Template support module for LedgerSMB

=head1 SYNOPSIS

Microsoft Spreadsheet XLSX output.

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

package LedgerSMB::Template::XLSX;

use strict;
use warnings;

use Template;
use LedgerSMB::Template::TTI18N;
use LedgerSMB::Sysconfig;
use Excel::Writer::XLSX;

my $binmode = undef;
my $extension = 'xlsx';

my $workbook;
my $worksheet;
my $rowcount;
my $currcol;

sub _worksheet_handler {
    $_->set_att(type => 'worksheet');
    return;
}

sub _row_handler {
    $rowcount++;
    $currcol = 0;
    $_->set_att(type => 'row');
    return;
}

sub _cell_handler {
    $_->set_att( row => $rowcount, col => $currcol);
    $currcol++;
    $_->set_att(type => 'cell');
    return;
}

sub _formula_handler {
    $_->set_att( row => $rowcount, col => $currcol);
    $currcol++;
    $_->set_att(type => 'formula');
    return;
}

sub _format_handler {
    my ($t, $format) = @_;
    my %properties;
    while (my ($attr, $val) = each %{$format->{att}}) {
        if ($attr eq 'border') {
            $properties{'border'} = $val;
        } elsif ($attr =~ 'border_(top|bottom|left|right)') {
            $properties{$attr} = $val;
        } elsif ($attr =~ '(top|bottom|left|right)_color') {
            $properties{$attr} = $val;
        } elsif ($attr =~ '(top|bottom|left|right)') {
            $properties{$attr} = $val;
        } elsif ($attr =~ '(bg_color|bg_colour)') {
            $properties{'bg_color'} = $val;
        } elsif ($attr =~ '(color|colour)') {
            $properties{'fg_color'} = $val;
        } elsif ($attr =~ '(align|valign)') {
            $properties{$attr} = $val;
        } elsif ($attr =~ /(hidden|font|size|bold|italic|font_strikeout|font_shadow)/
              || $attr =~ /(font_outline|shrink|text_wrap|text_justlast)/) {
            $properties{$attr} = $val;
        } elsif ($attr eq 'num_format') {
            $properties{'num_format'} = $val;
        } else {
            warn $attr;
        }
        $format->del_att($attr);
    }
    $_->set_att(type => 'format', format => { %properties });
    return;
}

# Not yet implemented
#sub _named_format {
#    my ($name, $t, $format) = @_;
##warn "_named_format:" . p($format);
#    $format->{att}{$name} = 1;
#    &_format_handler($t, $format);
#    $format->set_att(type => 'named_format');
#    return;
#}

sub _format_cleanup_handler {
    my ($t, $format) = @_;
    return ($t, $format); # dubious; evaluation of my is undoc/undefined
}

sub _xlsx_process {
    my ($filename, $template) = @_;

    $workbook  = Excel::Writer::XLSX->new("$filename");

    my $parser = XML::Twig->new(
        start_tag_handlers => {
            worksheet => \&_worksheet_handler,
            row => \&_row_handler,
            cell => \&_cell_handler,
            formula => \&_formula_handler,
            format => \&_format_handler,
#            bold => sub { &_named_format('bold', @_) },
#            hidden => sub { &_named_format('hidden', @_) },
#            italic => sub { &_named_format('italic', @_) },
#            shadow => sub { &_named_format('shadow', @_) },
#            strikeout => sub { &_named_format('strikeout', @_) },
            },
        twig_handlers => {
            format => \&_format_cleanup_handler,
            bold => \&_format_cleanup_handler,
            hidden => \&_format_cleanup_handler,
            italic => \&_format_cleanup_handler,
            shadow => \&_format_cleanup_handler,
            strikeout => \&_format_cleanup_handler,
            }
        );
    $parser->parse($template);
    _handle_subtree($parser->root);
    #$parser->purge;
    return $workbook->close;
}

sub _handle_subtree {
    my ($tree,$format) = @_;
    my @children = $tree->children;
    foreach my $child (@children) {
        my $att = $child->{att};
        if ($att->{type} eq 'worksheet') {
            $worksheet = $workbook->add_worksheet($att->{name});
            _handle_subtree($child);
        } elsif ($att->{type} eq 'cell') {
            $worksheet->write($att->{row},$att->{col},$att->{text},$format);
        } elsif ($att->{type} eq 'format') {
            my $format = $workbook->add_format(%{$att->{format}});
            _handle_subtree($child,$format);
        } elsif ($att->{type} eq 'row') {
            _handle_subtree($child,$format);
        } else {
            warn p($child);
        }
        $child->purge;
    }
    return;
}

sub get_template {
    my $name = shift;
    return "${name}.xlst";
}

sub preprocess {
    my $rawvars = shift;
    return LedgerSMB::Template::_preprocess($rawvars);
}

sub process {
    my $parent = shift;
    my $cleanvars = shift;

    my $output = '';
    my $tempdir = $LedgerSMB::Sysconfig::tempdir;
    $parent->{outputfile} ||= "$tempdir/$parent->{template}-output-$$";

    my $arghash = $parent->get_template_args($extension,$binmode);
    my $template = Template->new($arghash) || die Template->error();
    unless ($template->process(
                $parent->get_template_source(\&get_template),
                {
                    %$cleanvars,
                    %$LedgerSMB::Template::TTI18N::ttfuncs,
                    'escape' => \&preprocess
                },
                \$output,
                {binmode => ':utf8'})
    ){
        my $err = $template->error();
        die "Template error: $err" if $err;
    }
    &_xlsx_process("$parent->{outputfile}.$extension", $output);

    return $parent->{mimetype} = 'application/vnd.ms-excel';
}

sub postprocess {
    my $parent = shift;
    $parent->{rendered} = "$parent->{outputfile}.$extension";
    return $parent->{rendered};
}

1;
