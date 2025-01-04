
use v5.36;
use warnings;

package LedgerSMB::Template::Plugin::XLSX;

=head1 NAME

LedgerSMB::Template::Plugin::XLSX - Template support module for LedgerSMB

=head1 DESCRIPTION

Implements C<LedgerSMB::Template>'s FORMATTER protocol for XLSX output.

=cut

use Excel::Writer::XLSX;
use Spreadsheet::WriteExcel;
use XML::Twig;


use Moo;

=head1 ATTRIBUTES

=head2 formats

Holds an array of strings naming the formats supported by this plugin.

=cut

has formats => (is => 'ro', default => sub { [ 'XLS', 'XLSX' ] });

=head2 format

Holds a string naming the actual format for which this plugin
is configured. The plugin can be used multiple times with different
formats, as long as they are in the list of formats.

=cut

has format => (is => 'ro', required => 1);

my $binmode = undef;
my $extension = 'xlsx';

sub _get_extension {
    my ($parent) = shift;
    if ($parent->{format_options}->{filetype}){
        return $parent->{format_options}->{filetype};
    } else {
        return $extension;
    }
}

my $workbook;
my $worksheet;
my $rowcount;
my $currcol;
my $format;

sub _worksheet_handler {
    my ($twig, $elt) = @_;
    $rowcount = 0;
    $currcol = 0;

    $worksheet = $workbook->add_worksheet($elt->att('name'));
    return undef;
}

sub _row_handler {
    $rowcount++;
    $currcol = 0;
    return undef;
}

sub _cell_handler {
    my ($twig, $elt) = @_;
    $worksheet->write($rowcount,$currcol,$elt->att('text'),$format);
    $currcol++;
    return undef;
}

sub _formula_handler {
    $currcol++;
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

    $format = $workbook->add_format(%properties);
    return undef;
}

# Not yet implemented
#sub _named_format {
#    my ($name, $t, $format) = @_;
##warn "_named_format:" . p($format);
#    $format->{att}{$name} = 1;
#    &_format_handler($t, $format);
#    $format->set_att(type => 'named_format');
#    return undef;
#}

sub _format_cleanup_handler {
    my ($t, $format) = @_;
    return ($t, $format); # dubious; evaluation of my is undoc/undefined
}

sub _xlsx_process {
    my ($wbk, $template) = @_;
    $workbook = $wbk;

    my $parser = XML::Twig->new(
        start_tag_handlers => {
            worksheet => \&_worksheet_handler,
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
            row => \&_row_handler,
            format => \&_format_cleanup_handler,
            bold => \&_format_cleanup_handler,
            hidden => \&_format_cleanup_handler,
            italic => \&_format_cleanup_handler,
            shadow => \&_format_cleanup_handler,
            strikeout => \&_format_cleanup_handler,
            }
        );
    $parser->parse($template);
    return $workbook->close;
}

=head1 METHODS

=head2 setup($parent, $cleanvars, $output)

Implements the template's initialization protocol.

=cut

sub setup {
    my ($self, $parent, $cleanvars, $output) = @_;

    my $temp_output;
    return (\$temp_output, {
        input_extension => 'xlst',
        _output_extension => _get_extension($parent),
        binmode => $binmode,
        _output => $output,
    });
}

=head2 postprocess($parent, $output, $config)

Implements the template's post-processing protocol.

=cut

sub postprocess {
    my ($self, $parent, $temp_output, $config) = @_;

    # Implement Template Toolkit's protocol: if the variable
    # '$output' contains a string, it's a filename. If it's a
    # reference, the variable referred to is the output memory area
    #
    # Excel::Writer::XLSX wants a filehandle or filename, so
    # convert the variable reference into a filehandle
    my $output = $config->{_output};

    if (ref $output) {
        open(my $fh, '>', $output)
            or die "Unable to create a filehandle to \$output: $!";
        $output = $fh;
    }

    if (lc $self->format eq 'xlsx') {
        $workbook  = Excel::Writer::XLSX->new($output);
        $workbook->set_optimization(); # reduce memory consumption
    }
    else {
        $workbook = Spreadsheet::WriteExcel->new($output);
    }
    &_xlsx_process($workbook, $$temp_output);

    return undef;
}

=head2 mimetype()

Returns the rendered template's mimetype.

=cut

sub mimetype {
    my $self = shift;
    my $config = shift;
    my $mimetype;

    if (lc $self->format eq 'xlsx') {
        $mimetype = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    else {
        $mimetype = 'application/vnd.ms-excel';
    }

    return $mimetype;
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016-2022 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
