
=head1 NAME

LedgerSMB::Template::ODS - Template support module for LedgerSMB

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

use strict;
use warnings;

use Data::Dumper;  ## no critic
use CGI::Simple::Standard qw(:html);
use Template;
use XML::Twig;
use OpenOffice::OODoc;
use OpenOffice::OODoc::Styles;
use LedgerSMB::Template::TTI18N;
use LedgerSMB::Sysconfig;
use LedgerSMB::Template::DB;

$OpenOffice::OODoc::File::WORKING_DIRECTORY = $LedgerSMB::Sysconfig::tempdir;

my $binmode = undef;
binmode STDOUT, ':bytes';
binmode STDERR, ':bytes';

# SC: The ODS handlers need these vars in common
my $ods;
my $rowcount;
my $currcol;
my $maxrows;
my $maxcols;
my %celltype;
my $sheetnum = -1;
my $sheetname;

# SC: The elements of the style table for regular styles and stack are
#     arrays where the stack name is the first element and the style
#     properties are the second.  The name is used for setting styles,
#     while the properties are used in handling nested styles.
my @style_stack;    # stack of styles, 0 is active style
my %style_table;    # hash table for created styles

# SC: Subtract 8 from the attribute to get the index
#     http://search.cpan.org/src/JMCNAMARA/Spreadsheet-WriteExcel-2.11/doc/palette.html
my @colour = (odfColor(0, 0, 0), odfColor(255, 255, 255),
    odfColor(255, 0, 0), odfColor(0, 255, 0),
    odfColor(0, 0, 255), odfColor(255, 255, 0),
    odfColor(255, 0, 255), odfColor(0, 255, 255),
    odfColor(128, 0, 0), odfColor(0, 128, 0),
    odfColor(0, 0, 128), odfColor(128, 128, 0),
    odfColor(128, 0, 128), odfColor(0, 128, 128),
    odfColor(192, 192, 192), odfColor(128, 128, 128),
    odfColor(153, 153, 255), odfColor(153, 51, 102),
    odfColor(255, 255, 204), odfColor(204, 255, 255),
    odfColor(102, 0, 102), odfColor(255, 128, 128),
    odfColor(0, 102, 204), odfColor(204, 204, 255),
    odfColor(0, 0, 128), odfColor(255, 0, 255),
    odfColor(255, 255, 0), odfColor(0, 255, 255),
    odfColor(128, 0, 128), odfColor(120, 0, 0),
    odfColor(0, 128, 128), odfColor(0, 0, 255),
    odfColor(0, 204, 255), odfColor(204, 255, 255),
    odfColor(204, 255, 204), odfColor(255, 255, 153),
    odfColor(153, 204, 255), odfColor(255, 153, 204),
    odfColor(204, 153, 255), odfColor(192, 192, 192),
    odfColor(51, 102, 255), odfColor(51, 204, 204),
    odfColor(153, 204, 0), odfColor(255, 204, 0),
    odfColor(255, 153, 0), odfColor(255, 102, 0),
    odfColor(102, 102, 153), odfColor(150, 150, 150),
    odfColor(0, 51, 102), odfColor(51, 153, 102),
    odfColor(0, 51, 0), odfColor(51, 51, 0),
    odfColor(153, 51, 0), odfColor(153, 51, 102),
    odfColor(51, 51, 153), odfColor(51, 51, 51),
    );
my %colour_name = ('black' => $colour[0], 'white' => $colour[1],
    'red' => $colour[2], 'lime' => $colour[3],
    'blue' => $colour[4], 'yellow' => $colour[5],
    'magenta' => $colour[6], 'cyan' => $colour[7],
    'brown' => $colour[8], 'green' => $colour[9],
    'navy' => $colour[10], 'purple' => $colour[12],
    'silver' => $colour[14], 'gray' => $colour[15],
    'grey' => $colour[15], 'orange' => $colour[45],
    );

my @line_width = ('none', '0.018cm solid', '0.035cm solid',
    '0.018cm dashed', '0.018cm dotted', '0.141cm solid',
    '0.039cm double', '0.002cm solid'
    );

sub _worksheet_handler {
        $sheetnum += 1;
    $rowcount = -1;
    $currcol = 0;
    my $rows = $_->{att}->{rows};
    my $columns = $_->{att}->{columns};
    $rows ||= 1000;
    $columns ||= 52;
        $maxrows = $rows;
        $maxcols = $columns;
    my $sheet;
    if ($_->is_first_child) {
        $sheet = $ods->getTable(0, $rows, $columns);
        $ods->renameTable($sheet, $_->{att}->{name});
                $sheetname = $_->{att}->{name};
    } else {
        $sheet = $ods->appendTable($_->{att}->{name}, $rows, $columns);
    }
}

sub _row_handler {
    $rowcount++;
    $currcol = 0;
}

sub _cell_handler {
        $ods->expandTable($sheetname, $maxrows, $maxcols);
    my $cell = $ods->getCell($sheetname, $rowcount, $currcol);

    if (@style_stack and $celltype{$style_stack[0][0]}) {
        $ods->cellValueType($cell, $celltype{$style_stack[0][0]}[0]);
    } elsif ($_->{att}->{type}) {
        my $type = $_->{att}->{type};
        if ($type =~ /^(string|blank|url)$/i) {
            $ods->cellValueType($cell, 'string');
        } elsif ($type =~ /^(number|formula)$/i) {
            $ods->cellValueType($cell, 'float');
        }
    }
    $ods->cellValue($sheetname, $rowcount, $currcol, $_->{att}->{text});
    if (@style_stack) {
        $ods->cellStyle($cell, $style_stack[0][0]);
    }
    $currcol++;
}

sub _formula_handler {
    my $cell = $ods->getCell($sheetnum, $rowcount, $currcol);

    if (@style_stack and $celltype{$style_stack[0][0]}) {
        $ods->cellValueType($cell, $celltype{$style_stack[0][0]}[0]);
    } elsif ($_->{att}->{type}) {
        my $type = $_->{att}->{type};
        if ($type =~ /^(string|blank|url)$/i) {
            $ods->cellValueType($cell, 'string');
        } elsif ($type =~ /^(number|formula)$/i) {
            $ods->cellValueType($cell, 'float');
        }
    }
    $ods->cellFormula($cell, "oooc:=$_->{att}->{text}");
    if (@style_stack) {
        $ods->cellStyle($cell, $style_stack[0][0]);
    }
    $currcol++;
}

sub _border_set {
    my ($format, $properties, $border) = @_;
    my $edge = $border;
    $edge =~ s/^border-?//;

    my $val;
    if ($edge) {
        $val = $format->{att}{$edge};
    } else {
        $val = $format->{att}{'border'};
    }

    if ($properties->{cell}{"fo:$border"}){
        $properties->{cell}{"fo:$border"} =~ s/^.* (\#......)$/$val $1/;
    } else {
        $properties->{cell}{"fo:$border"} = "$line_width[$val] #000000";
    }
    if ($edge and $format->{att}->{"${edge}_color"}) {
        my $colour = $format->{att}->{"${edge}_color"};
        if ($colour =~ /^\d+$/) {
            $colour = $colour[$colour];
        } elsif ($colour !~ /^\#......$/) {
            $colour = $colour_name{$colour};
        }
        $properties->{cell}{"fo:$border"} =~ s/^(.*) \#......$/$1 $colour/;
    } elsif ($format->{att}->{border_color}) {
        my $colour = $format->{att}->{"${edge}_color"};
        if ($colour =~ /^\d+$/) {
            $colour = $colour[$colour];
        } elsif ($colour !~ /^\#......$/) {
            $colour = $colour_name{$colour};
        }
        $properties->{cell}{"fo:$border"} =~ s/^(.*) \#......$/$1 $colour/;
    }
}

sub _prepare_float {
    my ($style) = shift;
    my %properties;
    my @sides = split /\./, $style;

    if ($#sides == 1) { # decimal places
        $properties{'number:decimal-places'} = length $sides[1];
    } else {
        $properties{'number:decimal-places'} = 0;
    }
    $properties{'number:min-integer-digits'} = length($sides[0] =~ /0+$/);
    $properties{'number:grouping'} = 'true' if $sides[0] =~ /.,...$/;

    \%properties;
}

sub _prepare_fraction {
    my ($style) = shift;
    my %properties;
    my @sides = split /[ \/]/, $style;

    $properties{'number:min-integer-digits'} = length($sides[0] =~ /0+$/);
    $properties{'number:min-numerator-digits'} = length($sides[1]);
    $properties{'number:min-denominator-digits'} = length($sides[2]);

    \%properties;
}

sub _create_positive_style {
    my ($name, $type, $base) = @_;
    my $pstyle = $ods->createStyle(
        $name,
        namespace => 'number',
        type => $type,
        properties => $base,
        references => {
            'style:volatile' => 'true',
            },
        );
    $pstyle->insert_new_elt('last-child',
        'number:text', {}, ' ');
}

sub _format_handler {
    my ($t, $format) = @_;
    my $style = sprintf "ce%d", (scalar (keys %style_table) + 1);
    my @extras;

    # SC: There are multiple types of properties that can be associated
    #     with a style.  However, the OO::OOD style creation code appears
    #     to only allow for a single type to be added to the style at a
    #     time.  As a result, %properties is split into property groupings
    #     to allow for each group to get the correct type.
    my %properties;
    if (@style_stack) {
        %properties = %{$style_stack[0][1]};
        if ($celltype{$style_stack[0][0]}) {
            $celltype{$style} = $celltype{$style_stack[0][0]};
            @extras = ('references', {
                'style:data-style-name' => $celltype{$style}[1]
                });
        }
    }
    &_border_set(\%properties, $format, 'border') if $format->{att}->{border};
    while (my ($attr, $val) = each %{$format->{att}}) {
        if ($attr eq 'bottom') {
            &_border_set($format, \%properties, 'border-bottom');
        } elsif ($attr eq 'top') {
            &_border_set($format, \%properties, 'border-top');
        } elsif ($attr eq 'left') {
            &_border_set($format, \%properties, 'border-left');
        } elsif ($attr eq 'right') {
            &_border_set($format, \%properties, 'border-right');
        } elsif ($attr eq 'bg_color' or $attr eq 'bg_colour') {
            if ($val =~ /^\d+$/) {
                $properties{cell}{'fo:background-color'} =
                    $colour[$val - 8];
            } elsif ($val =~ /^\#[0-9A-Fa-f]{6}$/) {
                $properties{cell}{'fo:background-color'} = $val;
            } else {
                $properties{cell}{'fo:background-color'} =
                    $colour_name{$val};
            }
        } elsif ($attr eq 'color' or $attr eq 'colour') {
            if ($val =~ /^\d+$/) {
                $properties{text}{'fo:color'} =
                    $colour[$val - 8];
            } elsif ($val =~ /^\#[0-9A-Fa-f]{6}$/) {
                $properties{text}{'fo:color'} = $val;
            } else {
                $properties{text}{'fo:color'} =
                    $colour_name{$val};
            }
        } elsif ($attr eq 'align') {
            if (lc $val eq 'right') {
                $properties{paragraph}{'fo:text-align'} = 'end';
            } elsif (lc $val eq 'left') {
                $properties{paragraph}{'fo:text-align'} = 'start';
            } else {
                $properties{paragraph}{'fo:text-align'} = $val;
            }
        } elsif ($attr eq 'valign') {
            # takes top, vcenter, bottom, or vjustify
            # needs top, middle, or bottom
            if ($val =~ /^v/i) {
                $properties{paragraph}{'style:vertical-align'} = 'middle';
            } else {
                $properties{paragraph}{'style:vertical-align'} = $val;
            }
        } elsif ($attr eq 'hidden') {
            if ($properties{cell}{'style:cell-protect'} and !$val) {
                delete $properties{cell}{'style:cell-protect'};
            } elsif ($val) {
                $properties{cell}{'style:cell-protect'} = 'formula-hidden';
            }
        } elsif ($attr eq 'font') {
            $properties{text}{'style:font-name'} = $val;
        } elsif ($attr eq 'size') {
            $properties{text}{'fo:font-size'} = "${val}pt";
        } elsif ($attr eq 'bold') {
            if ($properties{text}{'fo:font-weight'} and !$val) {
                delete $properties{text}{'fo:font-weight'};
            } elsif ($val) {
                $properties{text}{'fo:font-weight'} = 'bold';
            }
        } elsif ($attr eq 'italic') {
            if ($properties{text}{'fo:font-style'} and !$val) {
                delete $properties{text}{'fo:font-style'};
            } elsif ($val) {
                $properties{text}{'fo:font-style'} = 'italic';
            }
        } elsif ($attr eq 'font_strikeout') {
            if (!$val) {
                $properties{text}{'style:text-line-through-type'} = 'none';
            } elsif ($val) {
                $properties{text}{'style:text-line-through-type'} = 'single';
            }
        } elsif ($attr eq 'font_shadow') {
            if ($properties{text}{'fo:text-shadow'} and !$val) {
                delete $properties{text}{'fo:text-shadow'};
            } elsif ($val) {
                $properties{text}{'fo:text-shadow'} = '2pt';
            }
        } elsif ($attr eq 'font_outline') {
            if ($properties{text}{'style:text-outline'} and !$val) {
                delete $properties{text}{'style:text-outline'};
            } elsif ($val) {
                $properties{text}{'style:text-outline'} = 'true';
            }
        } elsif ($attr eq 'shrink') {
            if ($properties{cell}{'style:shrink-to-fit'} and !$val) {
                delete $properties{cell}{'style:shrink-to-fit'};
            } elsif ($val) {
                $properties{cell}{'style:shrink-to-fit'} = 'true';
            }
        } elsif ($attr eq 'text_wrap') {
            if (!$val) {
                $properties{cell}{'style:wrap-option'} = 'no-wrap';
            } else {
                $properties{text}{'style:wrap-option'} = 'wrap';
            }
        } elsif ($attr eq 'text_justlast') {
            if ($properties{paragraph}{'fo:text-align-last'} and !$val) {
                delete $properties{paragraph}{'fo:text-align-last'};
            } elsif ($val) {
                $properties{paragraph}{'fo:text-align-last'} = 'justify';
            }
        } elsif ($attr eq 'num_format') {
            #SC: Number formatting is when I hit the point of,
            #    "Screw the OO::OOD API, XML::Twig is simpler".
            #    @children's elements are passed right into the
            #    style via XML::Twig::Elt's insert_new_elt.  The
            #    OO:OOD API, while decent enough for the text
            #    styles, is not so pleasant with complex number
            #    styles.
            my @children;
            my %nproperties;
            my @nextras;
            my $nstyle;
            my $fval = sprintf 'N%02d', $val;
            @extras = ('references', {'style:data-style-name' => $fval});
            if ($style_table{$fval}) {
                # pass through
            } elsif ($val == 0) {
                $celltype{$style} = 'float';
            } elsif ($val == 1) {
                $celltype{$style} = ['float', 'N01'];
                $nstyle = 'number-style';
                %nproperties = %{&_prepare_float('0')}
            } elsif ($val == 2) {
                $celltype{$style} = ['float', 'N02'];
                $nstyle = 'number-style';
                %nproperties = %{&_prepare_float('0.00')}
            } elsif ($val == 3) {
                $celltype{$style} = ['float', 'N03'];
                $nstyle = 'number-style';
                %nproperties = %{&_prepare_float('#,##0')}
            } elsif ($val == 4) {
                $celltype{$style} = ['float', "N04"];
                $nstyle = 'number-style';
                %nproperties = %{&_prepare_float('#,##0.00')}
            } elsif ($val == 5) { ## ($#,##0_);($#,##0)
            } elsif ($val == 6) {
                $celltype{$style} = 'currency';
            } elsif ($val == 7) {
                $celltype{$style} = 'currency';
            } elsif ($val == 8) {
                $celltype{$style} = 'currency';
            } elsif ($val == 9) { ##      0%
                $celltype{$style} = ['percentage', "N09"];
                $nstyle = 'percentage-style';
                %nproperties = %{&_prepare_float('0')};
                push @children, ['number:text', {}, '%'];
            } elsif ($val == 10) { ##    0.00%
                $celltype{$style} = ['percentage', "N10"];
                $nstyle = 'percentage-style';
                %nproperties = %{&_prepare_float('0.00')};
                push @children, ['number:text', {}, '%'];
            } elsif ($val == 11) { ##  0.00E+00
                $celltype{$style} = ['float', "N11"];
                $nstyle = 'number-style';
                push @children, ['number:scientific-number', {
                        %{&_prepare_float('0.00')},
                        'number:min-exponent-digits' => 2
                        }];
            } elsif ($val == 12) { ## # ?/?
                $celltype{$style} = ['float', "N12"];
                $nstyle = 'number-style';
                push @children, ['number:fraction',
                    %{&_prepare_fraction('# ?/?')}];
            } elsif ($val == 13) { ## # ??/??
                $celltype{$style} = ['float', "N13"];
                $nstyle = 'number-style';
                push @children, ['number:fraction',
                    %{&_prepare_fraction('# ??/??')}];
            } elsif ($val == 14) { ##  m/d/yy
                $celltype{$style} = ['date', "N14"];
                $nstyle = 'date-style';
                @nextras = ('references' => {
                    'number:automatic-order' => 'true'});
                @children = (
                    ['number:month'],
                    ['number:text', {}, '/'],
                    ['number:day'],
                    ['number:text', {}, '/'],
                    ['number:year'],
                    );
            } elsif ($val == 15) { ## d-mmm-yy
                $celltype{$style} = ['date', "N15"];
                $nstyle = 'date-style';
                @nextras = ('references' => {
                    'number:automatic-order' => 'true'});
                @children = (
                    ['number:day'],
                    ['number:text', {}, '-'],
                    ['number:month', {
                        'number:textual' => 'true'}],
                    ['number:text', {}, '-'],
                    ['number:year'],
                    );
            } elsif ($val == 16) { ## d-mmm
                $celltype{$style} = ['date', "N16"];
                $nstyle = 'date-style';
                @nextras = ('references' => {
                    'number:automatic-order' => 'true'});
                @children = (
                    ['number:day'],
                    ['number:text', {}, '-'],
                    ['number:month', {
                        'number:textual' => 'true'}],
                    );
            } elsif ($val == 17) { ## mmm-yy
                $celltype{$style} = ['date', "N17"];
                $nstyle = 'date-style';
                @nextras = ('references' => {
                    'number:automatic-order' => 'true'});
                @children = (
                    ['number:month', {
                        'number:textual' => 'true'}],
                    ['number:text', {}, '-'],
                    ['number:year'],
                    );
            } elsif ($val == 18) { ## h:mm AM/PM
                $celltype{$style} = ['time', "N18"];
                $nstyle = 'time-style';
                @nextras = ('references' => {
                    'number:automatic-order' => 'true'});
                @children = (
                    ['number:hours'],
                    ['number:text', {}, ':'],
                    ['number:minutes',
                        {'number:style' => 'long'}],
                    ['number:text', {}, ' '],
                    ['number:am-pm']
                    );
            } elsif ($val == 19) { ## h:mm:ss AM/PM
                $celltype{$style} = ['time', "N19"];
                $nstyle = 'time-style';
                @nextras = ('references' => {
                    'number:automatic-order' => 'true'});
                @children = (
                    ['number:hours'],
                    ['number:text', {}, ':'],
                    ['number:minutes',
                        {'number:style' => 'long'}],
                    ['number:text', {}, ':'],
                    ['number:seconds',
                        {'number:style' => 'long'}],
                    ['number:text', {}, ' '],
                    ['number:am-pm']
                    );
            } elsif ($val == 20) { ## h:mm
                $celltype{$style} = ['time', "N20"];
                $nstyle = 'time-style';
                @nextras = ('references' => {
                    'number:automatic-order' => 'true'});
                @children = (
                    ['number:hours'],
                    ['number:text', {}, ':'],
                    ['number:minutes',
                        {'number:style' => 'long'}],
                    );
            } elsif ($val == 21) { ## h:mm:ss
                $celltype{$style} = ['time', "N21"];
                $nstyle = 'time-style';
                @nextras = ('references' => {
                    'number:automatic-order' => 'true'});
                @children = (
                    ['number:hours'],
                    ['number:text', {}, ':'],
                    ['number:minutes',
                        {'number:style' => 'long'}],
                    ['number:text', {}, ':'],
                    ['number:seconds',
                        {'number:style' => 'long'}],
                    );
            } elsif ($val == 22) { ## m/d/yy h:mm
                $celltype{$style} = ['date', "N22"];
                $nstyle = 'date-style';
                @nextras = ('references' => {
                    'number:automatic-order' => 'true'});
                @children = (
                    ['number:month'],
                    ['number:text', {}, '/'],
                    ['number:day'],
                    ['number:text', {}, '/'],
                    ['number:year'],
                    ['number:text', {}, ' '],
                    ['number:hours'],
                    ['number:text', {}, ':'],
                    ['number:minutes',
                        {'number:style' => 'long'}],
                    );
            } elsif ($val == 37) { ##  (#,##0_);(#,##0)
                $celltype{$style} = ['float', "N37"];
                $nstyle = 'number-style';
                my %base = (
                    'number:min-integer-digits' => 1,
                    'number:grouping' => 'true',
                    );

                @children = (
                    ['number:text', {}, '('],
                    ['number:number', \%base],
                    ['number:text', {}, ')'],
                    ['style:map', {
                        'style:condition' => 'value()>=0',
                        'style:apply-style-name' => "NP37",
                        }],
                    );

                &_create_positive_style("NP37",
                    $nstyle, \%base);
            } elsif ($val == 38) { ## (#,##0_);[Red](#,##0)
                $celltype{$style} = ['float', "N38"];
                $nstyle = 'number-style';
                my %base = %{&_prepare_float('#,##0')};

                @children = (
                    ['style:text-properties',
                        {'fo:color' => '#ff0000'}],
                    ['number:text', {}, '('],
                    ['number:number', \%base],
                    ['number:text', {}, ')'],
                    ['style:map',{
                        'style:condition' => 'value()>=0',
                        'style:apply-style-name' => "NP38",
                        }]
                    );

                &_create_positive_style("NP38",
                    $nstyle, \%base);
            } elsif ($val == 39) { ## (#,##0.00_);(#,##0.00)
                $celltype{$style} = ['float', "N39"];
                $nstyle = 'number-style';
                my %base = %{&_prepare_float('#,##0.00')};

                @children = (
                    ['number:text', {}, '('],
                    ['number:number', \%base],
                    ['number:text', {}, ')'],
                    ['style:map',{
                        'style:condition' => 'value()>=0',
                        'style:apply-style-name' => "NP39",
                        }]
                    );

                &_create_positive_style("NP39",
                    $nstyle, \%base);
            } elsif ($val == 40) { ## (#,##0.00_);[Red](#,##0.00)
                $celltype{$style} = ['float', "N40"];
                $nstyle = 'number-style';
                my %base = %{&_prepare_float('#,##0.00')};

                @children = (
                    ['style:text-properties',
                        {'fo:color' => '#ff0000'}],
                    ['number:text', {}, '('],
                    ['number:number', \%base],
                    ['number:text', {}, ')'],
                    ['style:map', {
                        'style:condition' => 'value()>=0',
                        'style:apply-style-name' => "NP40",
                        }],
                    );

                &_create_positive_style("NP40",
                    $nstyle, \%base);
            } elsif ($val == 41) {
                $celltype{$style} = 'float';
            } elsif ($val == 42) {
                $celltype{$style} = 'currency';
            } elsif ($val == 43) {
                $celltype{$style} = 'float';
            } elsif ($val == 44) {
                $celltype{$style} = 'currency';
            } elsif ($val == 45) {  ## mm:ss
                $celltype{$style} = ['time', "N45"];
                $nstyle = 'time-style';
                @nextras = ('references' => {
                    'number:automatic-order' => 'true'});
                @children = (
                    ['number:minutes',
                        {'number:style' => 'long'}],
                    ['number:text', {}, ':'],
                    ['number:seconds',
                        {'number:style' => 'long'}],
                    );
            } elsif ($val == 46) { ## [h]:mm:ss
                $celltype{$style} = ['time', "N46"];
                $nstyle = 'time-style';
                @nextras = ('references' => {
                    'number:automatic-order' => 'true',
                    'number:truncate-on-overflow' => 'false'});
                @children = (
                    ['number:hours', {}],
                    ['number:text', {}, ':'],
                    ['number:minutes',
                        {'number:style' => 'long'}],
                    ['number:text', {}, ':'],
                    ['number:seconds',
                        {'number:style' => 'long'}],
                    );
            } elsif ($val == 47) { ## mm:ss.0
                $celltype{$style} = ['time', "N47"];
                $nstyle = 'time-style';
                @nextras = ('references' => {
                    'number:automatic-order' => 'true'});
                @children = (
                    ['number:minutes',
                        {'number:style' => 'long'}],
                    ['number:text', {}, ':'],
                    ['number:seconds',
                        {'number:style' => 'long',
                        'number:decimal-places' => 1}],
                    );
            } elsif ($val == 48) { ##   ##0.0E+0
                $celltype{$style} = ['float', "N48"];
                $nstyle = 'number-style';
                %nproperties = ();
                push @children, ['number:scientific-number',
                    {%{&_prepare_float(0.0)},
                    'number:min-exponent-digits' => 1
                    }];
            } elsif ($val == 49) {
                $celltype{$style} = 'string';
            }
            # $nstyle is set on new styles
            if ($nstyle) {
                my $cstyle = $ods->createStyle(
                    $celltype{$style}[1],
                    namespace => 'number',
                    type => $nstyle,
                    properties => \%nproperties,
                    @nextras,
                    );
                for my $child (@children) {
                    $cstyle->insert_new_elt('last_child',
                        @$child);
                }
                $style_table{$fval} = 1;
            }
        }
    }

    # Maintain a hash table to keep the final style list size down
    $Data::Dumper::Sortkeys = 1;
    my $mystyle = Digest::MD5::md5_hex(Dumper(\%properties, \@extras));
    if (!$style_table{$mystyle}) {
        $ods->createStyle(
            $style,
            family => 'table-cell',
            properties => $properties{cell},
            @extras,
            );
        $ods->updateStyle(
            $style,
            properties => {
                -area => 'text',
                %{$properties{text}}
                }
            ) if $properties{text};
        $ods->updateStyle(
            $style,
            properties => {
                -area => 'paragraph',
                %{$properties{paragraph}}
                }
            ) if $properties{paragraph};
        $style_table{$mystyle} = [$style, \%properties];
    }
    unshift @style_stack, $style_table{$mystyle};
}

sub _named_format {
    my ($name, $t, $format) = @_;
    $format->{att}{$name} = 1;
    &_format_handler($t, $format);
}

sub _format_cleanup_handler {
    my ($t, $format) = @_;
    shift @style_stack;
}

sub _ods_process {
    my ($filename, $template) = @_;
    $ods = ooDocument(file => "$filename", create => 'spreadsheet');

    my $parser = XML::Twig->new(
        start_tag_handlers => {
            worksheet => \&_worksheet_handler,
            row => \&_row_handler,
            cell => \&_cell_handler,
            formula => \&_formula_handler,
            format => \&_format_handler,
            bold => sub { &_named_format('bold', @_) },
            hidden => sub { &_named_format('hidden', @_) },
            italic => sub { &_named_format('italic', @_) },
            shadow => sub { &_named_format('shadow', @_) },
            strikeout => sub { &_named_format('strikeout', @_) },
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
    $parser->purge;
    $ods->save;
}

sub get_template {
    my $name = shift;
    return "${name}.odst";
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
    } elsif (!$type) {
        return escapeHTML($rawvars);
    } elsif ($type eq 'SCALAR' or $type eq 'Math::BigInt::GMP') {
        return escapeHTML($$rawvars);
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
    my $source;
    my $tempdir = ${LedgerSMB::Sysconfig::tempdir};
    my $output = '';
        $parent->{binmode} = $binmode;
    $parent->{outputfile} ||= "$tempdir/$parent->{template}-output-$$";

        if ($parent->{include_path} eq 'DB'){
                $source = LedgerSMB::Template::DB->get_template(
                       $parent->{template}, undef, 'ods'
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
        \$output, binmode => ':utf8')) {
        die $template->error();
    }
    &_ods_process("$parent->{outputfile}.ods", $output);

    $parent->{mimetype} = 'application/vnd.oasis.opendocument.spreadsheet';
}

sub postprocess {
    my $parent = shift;
    $parent->{rendered} = "$parent->{outputfile}.ods";
    return $parent->{rendered};
}

1;

