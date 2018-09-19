package LedgerSMB::Database::SchemaChecks::JSON;


=head1 NAME

LedgerSMB::Database::SchemaChecks::JSON - Input for schema upgrades

=head1 DESCRIPTION

Provides non-interactive input for schema upgrade precondition checks.

=head1 METHODS

This module doesn't specify any methods.

=head1 FUNCTIONS

=cut

use strict;
use warnings;

use Exporter 'import';
use Digest::MD5 qw(md5_hex);

use LedgerSMB::Database::ChangeChecks qw/ run_with_formatters /;
use JSON::MaybeXS;


our @EXPORT = ## no critic
    qw| json_formatter_context |;


our $failing_check;
our $cached_response;

my $json = JSON::MaybeXS->new(utf8 => 1, pretty => 1);
$json->canonical; # set sorted output of object keys; helps testing

sub _check_hashid {
    my $check = shift;

    return md5_hex($check->{path} // '', $check->{title});
}

sub _response_filename {
    my ($dir, $check) = @_;

    my $hashid = _check_hashid($check);
    return $dir . '/' . $hashid . '.json';
}

sub _generate_json {
    my ($dir, $check) = @_;

    my $response_file = _response_filename($dir, $check);
    open my $fh, '>:encoding(UTF-8)', $response_file
        or die "Unable to open response file '$response_file': $!";
    print $fh $json->encode($cached_response->{response})
        or die "Unable to write failure response to '$response_file': $!";
    close $fh
        or warn "Unable to close response file '$response_file': $!";

    return $response_file;
}

sub _response {
    my ($check, $dir, $create) = @_;

    my $hashid = _check_hashid($check);
    if (defined $cached_response
        && $cached_response->{md5} eq $hashid) {
        return $cached_response->{response};
    }

    my $response_file = _response_filename($dir, $check);
    if (-f $response_file) {
        open my $fh, '<:encoding(UTF-8)', $response_file
            or die "Unable to open pre-defined response '$response_file': $!";
        local $/ = undef;
        my $content = <$fh>;
        close $fh
            or warn "Unable to close response file '$response_file': $!";

        $cached_response = {
            md5 => $hashid,
            response => $json->decode($content),
        };
        # make sure we're not adding to last-time's failure content
        $cached_response->{response}->{failure} = {};
    }
    else {
        $cached_response = {
            md5 => $hashid,
            response => { failure => {}, response => {} },
        };
    }

    return $cached_response->{response};
}

sub _format_confirm {
    my ($dir, $check, @confirmations) = @_;

    $failing_check = $check;
    my $response = _response($check, $dir, 'create');
    if (! defined $response->{failure}->{confirmations}) {
        $response->{failure}->{confirmations} = [];
    }
    while (@confirmations) {
        my %c = ( (shift @confirmations) => (shift @confirmations) );
        push @{$response->{failure}->{confirmations}},
            \%c;
    }
}

sub _format_describe {
    my ($dir, $check, $msg) = @_;

    $failing_check = $check;
    my $response = _response($check, $dir, 'create');
    $response->{failure}->{title} = $check->{title};
    $response->{failure}->{description} = $check->{description};
}

sub _format_grid {
    my ($dir, $check, $rows, %args) = @_;

    $failing_check = $check;
    my $response = _response($check, $dir, 'create');
    my @columns = (@{$args{columns}}, '__pk');
    $response->{failure}->{grids}->{$args{name}} = {
        adjustment_fields => $args{edit_columns},
        rows =>
            [ map { my %cols;
                    @cols{@columns} = @{$_}{@columns};
                    \%cols } @$rows ],
    };
    if ($args{dropdowns}) {
        $response->{failure}->{grids}->{$args{name}}->{options} =
            $args{dropdowns};
    }
}

sub _provided {
    my $dir = shift;
    my $check = shift;

    my $response = _response($check, $dir);
    return undef
        unless defined $response;

    if (@_) {
        my $name = shift;
        return $response->{response}->{$name};
    }
    else {
        # we're being asked if we have content to be processed
        return (defined $response->{response}
                && scalar(keys %{$response->{response}}));
    }
}


=head2 json_formatter_context $coderef $dir

Calls C<$coderef> with a hash-argument containing the ChangeCheck formatters
required to be passed to C<run_with_formatters> in that module; also sets
up a context for the formatters based on C<$dir>, allowing non-interactive
responses to be read from files in it.

Returns C<undef> when the C<$coderef> returns false.

Returns a name of a file in directory C<$dir> when C<$coderef> returns true.
This file contains a JSON object describing a (failed) change check. The
contents of the file is meant to be edited. The edited file provides the
corrected data to be uploaded to the database.

=cut

sub json_formatter_context(&$) { ## no critic
    my ($closure, $dir) = @_;

    local $cached_response = undef;
    # structure of the JSON object (keys):
    # - failure
    #   - title
    #   - description
    #   - confirmations
    #   - grids
    #     - <grid1>
    #       - rows
    #       - options
    #         - field1
    #         - fieldN
    #       - adjustment_fields
    # - response
    #   - confirm
    #   - <grid1>
    local $failing_check = undef;
    return (run_with_formatters { return $closure->(@_); }
            {
                confirm => sub { return _format_confirm( $dir, @_ ); },
                grid => sub { return _format_grid( $dir, @_ ); },
                describe => sub { return _format_describe( $dir, @_ ); },
                provided => sub { return _provided( $dir, @_ ); },
            }) ? _generate_json($dir, $failing_check) : undef;
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2018 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
