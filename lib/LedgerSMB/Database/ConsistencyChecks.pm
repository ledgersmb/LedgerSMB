package LedgerSMB::Database::ConsistencyChecks;

use v5.28.0;
use warnings;

use Exporter 'import';
use File::Find::Rule;
use File::Spec;
use YAML::PP;

my $yaml = YAML::PP->new();

our @EXPORT = ## no critic
    qw( find_checks load_checks run_checks );

=head1 NAME

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 METHODS

=head1 FUNCTIONS

=head2 find_checks

=cut

sub find_checks {
    my ($path) = @_;
    my @checks = sort File::Find::Rule->new()
        ->name( '*.sql' )
        ->in( File::Spec->catdir( $path, 'consistency' ) );

    return \@checks;
}

=head2 load_checks

=cut

sub load_checks {
    my ($paths) = @_;

    return [
        map {
            my $path = $_;
            my $content = do {
                open my $fh, '<', $path
                    or die "Unable to open file $path: $!";
                local $/ = undef;
                <$fh>;
            };
            $content =~ m/^---.*?\n(?<frontmatter>.*?)\n---.*?\n(?<query>.*)$/s;
            {
                path => $path,
                query => $+{query},
                frontmatter => $yaml->load_string( $+{frontmatter} )
            };
        } $paths->@* ];
}

=head2 run_checks

=cut

sub run_checks {
    my ($dbh, $checks) = @_;

    for my $check ($checks->@*) {
        my $query = qq|select count(*) from ($check->{query}) x|;
        my ($count) = $dbh->selectrow_array($query);
        die $dbh->errstr if $dbh->err != 0;

        $check->{result} = $count ? 'failed' : 'consistent';
        $check->{count} = $count;
    }

    return $checks;
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2023 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;

