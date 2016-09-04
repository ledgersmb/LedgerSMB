#!perl

use strict;
use warnings;

use File::Find;
use Test::More;
eval "use HTML::Lint";
plan skip_all => "HTML::Lint not available" if $@;

my @on_disk = ();
my $is_todo = '';

sub collect {
    return if $File::Find::name !~ m/\.html$/ || $File::Find::name =~ m/\/pod\//;

    my $module = $File::Find::name;
    push @on_disk, $module
}
find(\&collect, 'UI/');

sub content_test {
    my ($filename) = @_;
    my $ui_header_used = 0;
    $ui_header_used = 1 if $filename =~ m/UI\/lib\//;

    my ($fh, @tab_lines, @trailing_space_lines);
    open $fh, "<$filename";
    while (<$fh>) {
        push @tab_lines, ($.) if /\t/;
        push @trailing_space_lines, ($.) if / $/;
        $ui_header_used = 1 if /ui-header\.html/;
    }
    close $fh;

TODO: {
    local $TODO = 'LedgerSMB HTML files is still under development';
    $is_todo = Test::More->builder->todo;
    ok((! @tab_lines) && (! @trailing_space_lines),
        "Source critique for '$filename'");
    diag("Line# with tabs: " . (join ', ', @tab_lines))
        if @tab_lines;
    diag("Line# with trailing space(s): " . (join ', ', @trailing_space_lines))
        if @trailing_space_lines;

    my $lint = HTML::Lint->new;
    $lint->only_types(); # Get all

    # Add dojo attributes

    for my $dojo ( 'data-dojo-attach-event',
                   'data-dojo-attach-point',
                   'data-dojo-id',
                   'data-dojo-mixins',
                   'data-dojo-obj',
                   'data-dojo-props',
                   'data-dojo-textdir',
                   'data-dojo-type',
                   'data-myscope-id',
                   'data-myscope-props',
                   'data-myscope-type') {
        for my $tag ( 'body', 'button', 'center', 'div', 'fieldset', 'form', 'h1', 'h2', 'h3', 'h4',
                      'html', 'img', 'input', 'legend', 'li', 'ol', 'option', 'p', 'select', 'span',
                      'table', 'tbody', 'td', 'textarea', 'th', 'tr', 'ul' ) {
            HTML::Lint::HTML4::add_attribute( $tag, $dojo );
        }
    }
    HTML::Lint::HTML4::add_attribute( 'input', 'constraints' );
    HTML::Lint::HTML4::add_attribute( 'textarea', 'placeholder' );
    HTML::Lint::HTML4::add_attribute( 'textarea', 'value' );
    HTML::Lint::HTML4::add_attribute( 'textarea', 'width' );

    # Add moose attributes
    HTML::Lint::HTML4::add_attribute( 'body', 'role' );
    HTML::Lint::HTML4::add_attribute( 'center', 'role' );
    HTML::Lint::HTML4::add_attribute( 'div', 'role' );
    HTML::Lint::HTML4::add_attribute( 'span', 'role' );
    HTML::Lint::HTML4::add_attribute( 'table', 'role' );
    HTML::Lint::HTML4::add_attribute( 'tr', 'role' );
    HTML::Lint::HTML4::add_attribute( 'td', 'role' );

    # Add our attributes
    HTML::Lint::HTML4::add_attribute( 'form', 'lsmb/form' );

#    # Add the HTML 5 <lsmb> tag.
#    HTML::Lint::HTML4::add_tag( '\?lsmb' );
#    HTML::Lint::HTML4::add_attribute( 'canvas', $_ ) for qw( height width );


    $lint->parse_file($filename);

    my $error_count = $lint->errors;

    foreach my $error ( $lint->errors ) {
        fail $error->as_string
            if ( $error->as_string !~ m/(<\/?title>|<\?lsmb.+\?>)/ # m/(Unknown attribute|<\/?title>|<\?lsmb.+\?>)/
               && ! ((  $error->as_string =~ m/<(head|html|body)> tag is required/ 
                     || $error->as_string =~ m/<\/html> with no opening/ )
                    && $ui_header_used )
                );
    }
  }
  ok( $is_todo, '01-html-checks' );
}

content_test($_) for @on_disk;
done_testing;
