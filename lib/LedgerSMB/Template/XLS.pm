
=head1 NAME

LedgerSMB::Template::XLS - Template support module for LedgerSMB

=head1 SYNOPSIS

Microsoft Spreadsheet output.

=head1 METHODS

=over

=cut

package LedgerSMB::Template::XLS;

use strict;
use warnings;

use IO::Scalar;
use Template;
use Spreadsheet::WriteExcel;

my $binmode = undef;
my $extension = 'xls';

my $workbook;
my $worksheet;
my $rowcount;
my $currcol;

sub _worksheet_handler {
    $rowcount = -1;
    $currcol = 0;
    $_->set_att(type => 'worksheet');
    return undef;
}

sub _row_handler {
    $rowcount++;
    $currcol = 0;
    $_->set_att(type => 'row');
    return undef;
}

sub _cell_handler {
    $_->set_att( row => $rowcount, col => $currcol);
    $currcol++;
    $_->set_att(type => 'cell');
    return undef;
}

sub _formula_handler {
    $_->set_att( row => $rowcount, col => $currcol);
    $currcol++;
    $_->set_att(type => 'formula');
    return undef;
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
    return undef;
}

# Not yet implemented
#sub _named_format {
#    my ($name, $t, $format) = @_;
##warn "_named_format:" . p($format);
#    $format->{att}{$name} = 1;
#    &_format_handler($t, $format);
#    $format->set_att(type => 'named_format');
#}

sub _format_cleanup_handler {
    my ($t, $format) = @_;
    return undef;
}

sub _xls_process {
    my ($output, $template) = @_;

    # Implement Template Toolkit's protocol: if the variable
    # '$output' contains a string, it's a filename. If it's a
    # reference, the variable referred to is the output memory area
    #
    # Spreadsheet::WriteExcel wants a filehandle or filename, so
    # convert the variable reference into a filehandle
    $output = IO::Scalar->new($output) if ref $output;
    $workbook  = Spreadsheet::WriteExcel->new($output);

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
    return undef;
}

=item escape($string)

Escapes a scalar string and returns the sanitized version.

=cut

sub escape {
    return shift;
}

=item setup($parent, $cleanvars, $output)

Implements the template's initialization protocol.

=cut

sub setup {
    my ($parent, $cleanvars, $output) = @_;

    my $temp_output;
    return (\$temp_output, {
        input_extension => 'xlst',
        binmode => $binmode,
        _output => $output,
    });
}

=item postprocess($parent, $output, $config)

Implements the template's post-processing protocol.

=cut

sub postprocess {
    my ($parent, $output, $config) = @_;

    $parent->{mimetype} = 'application/vnd.ms-excel';
    &_xls_process($config->{_output}, $output);

    return undef;
}

=back

=head1 Copyright (C) 2007-2017, The LedgerSMB core team.

It is released under the GNU General Public License Version 2 or, at your
option, any later version.  See COPYRIGHT file for details.  For a full list
including contact information of contributors, maintainers, and copyright
holders, see the CONTRIBUTORS file.

=cut

1;
