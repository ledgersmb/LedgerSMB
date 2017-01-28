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
    return if $File::Find::name !~ m/\.html$/
           || $File::Find::name =~ m/\/pod\//
           || $File::Find::name =~ m(/js(-src)?/(dijit|dojo|util)/);

    my $module = $File::Find::name;
    push @on_disk, $module
}
find(\&collect, 'UI/');

sub content_test {
    my ($filename) = @_;
    my $ui_header_used = 0;
    $ui_header_used = 1 if $filename =~ m/UI\/lib\//;

    my ($fh, @tab_lines, @trailing_space_lines, $text);
    $text = '';
    open $fh, "<$filename";
    while (<$fh>) {
        push @tab_lines, ($.) if /\t/;
        push @trailing_space_lines, ($.) if / $/;
        $ui_header_used = 1 if /ui-header\.html/;
        $text .= $_;
    }
    close $fh;

    my $lint = HTML::Lint->new;
    $lint->only_types(); # Get all

    # Add dojo attributes

    for my $dojo ( 'data-dojo-attach-event',
                   'data-dojo-attach-point',
                   'data-dojo-id',
                   'data-dojo-mixins',
                   'data-dojo-obj',
                   'data-dojo-properties',
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

    $text =~ s#<\?lsmb\s*(.*?)\s*\?>##gs;
    $text =~ s#\$\{[^\}]+\}##gs;
TODO: {
    local $TODO = "$filename: HTML check is still under development";
    $is_todo = Test::More->builder->todo;

    $lint->parse($text);
    $lint->eof;

    my $error_count = $lint->errors;

    foreach my $error ( $lint->errors ) {
        if ( $error->as_string !~ m/(<\/?title>|<\?lsmb.+\?>)/ # m/(Unknown attribute|<\/?title>|<\?lsmb.+\?>)/
           && ! ((  $error->as_string =~ m/<(head|html|body)> tag is required/
                 || $error->as_string =~ m/<\/(html|body)> with no opening/ )
                && $ui_header_used )
            ) {
            fail $error->as_string;
        } else {
            $error_count--;
        }
    }
    ok((! @tab_lines) && (! @trailing_space_lines) && $error_count == 0 || $is_todo,
        "Source critique for '$filename'");
  }
}

content_test($_) for @on_disk;
done_testing;
