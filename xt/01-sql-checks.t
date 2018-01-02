#!perl

use strict;
use warnings;

use File::Find;
use Test::More;

my @on_disk = ();

sub collect {
    return if $File::Find::name !~ m/\.sql$/;

    my $module = $File::Find::name;
    push @on_disk, $module
}
find(\&collect, 'sql/');

sub content_test {
    my ($filename) = @_;

    my ($fh, @tab_lines, @trailing_space_lines);
    open $fh, '<', $filename
        or BAIL_OUT("couldn't open $filename for reading $!");
    while (<$fh>) {
        push @tab_lines, ($.) if /\t/;
        push @trailing_space_lines, ($.) if / $/;
    }
    close $fh or diag("failed to close $filename : $!");
    ok((! @tab_lines) && (! @trailing_space_lines),
       "Source critique for '$filename'");
    diag("Line# with tabs: " . (join ', ', @tab_lines)) if @tab_lines;
    diag("Line# with trailing space(s): " . (join ', ', @trailing_space_lines))
        if @trailing_space_lines;
}

content_test($_) for @on_disk;
done_testing;
