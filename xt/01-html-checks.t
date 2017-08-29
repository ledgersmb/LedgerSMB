#!perl

use strict;
use warnings;

use File::Find;
use Test::More;
eval "use  HTML::Lint::Pluggable";
plan skip_all => "HTML::Lint::Pluggable not available" if $@;

my @on_disk = ();

sub collect {
    my $module = $File::Find::name;
    return if $module !~ m/\.html$/
           || $module =~ m/\/pod\//
           || $module =~ m(/js/)
           || $module =~ m(/js-src/(dijit|dojo|util)/);

    push @on_disk, $module
}
find(\&collect, $ARGV[0] // 'UI/');

sub strip_pattern {
    my ($text,$pattern) = @_;
    while ( $text =~ /$pattern/ ) {
        my ($v1,$v2,$v3) = ($1,$2,$3);
        $v2 =~ s#[^\n]+##gs;
        $text = ($v1 // '') . ($v2 // '') . ($v3 // '');
    }
    return $text;
}

sub content_test {
    my ($filename) = @_;
    my $ui_header_used = 0;
    $ui_header_used = 1 if $filename =~ m/UI\/lib\//;
    my $is_snippet = 0;

    my ($fh, @tab_lines, @trailing_space_lines, $text);
    $text = '';
    open $fh, "<$filename";
    $is_snippet = 1
        if ($filename !~ m#(log(in|out))|main|setup/#
            || $filename =~ m#setup/ui-db-credentials#);
    while (<$fh>) {
        push @tab_lines, ($.) if /\t/;
        push @trailing_space_lines, ($.) if / $/;
        $ui_header_used = 1 if /ui-header\.html/;
        $text .= $_;
    }
    close $fh;

    #Fix source text. Template statements have to be removed for now.
    #IF/ELSE/END branches will clash though. - YL
    #Strip <?lsmb ... ?>, keep lines for error reporting
    $text = strip_pattern($text,qr/(.*)(<\?lsmb\s*.*?\s*\?>)(.*)/s);
    #Strip ${...}, keep lines for error reporting
    $text = strip_pattern($text,qr/(.*)(\$\{[^\}]+\})(.*)/s);
    #Strip comments, keep lines for error reporting
    $text = strip_pattern($text,qr/(.*)(\<!--.+-->)(.*)/s);

    my $lint = HTML::Lint::Pluggable->new;
    $lint->only_types(); # Get all
    $lint->load_plugins(qw/HTML5/);
    $lint->load_plugin(WhiteList => +{
        rule => +{
            'attr-unknown' => sub {
                my $param = shift;
                return 1 if $param->{tag} =~ /input|div/ && $param->{attr} =~ /type|pwtype/;
                return 1 if $param->{tag} eq "textarea" && $param->{attr} eq "autocomplete";
                return 1 if $param->{tag} eq "div" && $param->{attr} eq "overflow";
                # The following should be removed and files fixed instead
                return 1 if $param->{tag} =~ /div|tr/ && $param->{attr} =~ /height|width|name|cols/;
                return 0;
            },
            'elem-img-sizes-missing' => sub {
                my $param = shift;
                if ($param->{src} eq "images/ledgersmb.png"
                 || $param->{src} =~ /payments\/img\/(up|down)\.gif/ )  {
                    return 1;
                }
                else {
                    return 0;
                }
            },
        },
    });
    $lint->parse($text);
    $lint->eof;

    my @reportable_errors;

    push @reportable_errors,
           "Line(s) with tabs: " . (join ', ', @tab_lines)
        if @tab_lines;
    push @reportable_errors,
           "Line with trailing space(s): " . (join ', ', @trailing_space_lines)
        if @trailing_space_lines;

    foreach my $error ( $lint->errors ) {
        next if $error->as_string =~ m/(<\/?title>|<\?lsmb.+\?>)/;
        next if (($ui_header_used || $is_snippet)
                 && $error->as_string =~ m/<(head|html)> tag is required/);
        next if ($ui_header_used
                 && $error->as_string =~ m/<\/html> with no opening/ );
        next if ($is_snippet
                 && $error->as_string =~ m/<body> tag is required/ );

        push @reportable_errors, $error->as_string;
    }
    ok(scalar @reportable_errors == 0, "Source critique for '$filename'")
       or diag(join("\n", @reportable_errors));
}

content_test($_) for @on_disk;
done_testing;
