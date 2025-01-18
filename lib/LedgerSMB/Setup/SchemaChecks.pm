package LedgerSMB::Setup::SchemaChecks;


=head1 NAME

LedgerSMB::Setup::SchemaChecks - UI for schema checks run from setup.pl

=head1 DESCRIPTION

Provides the UI for schema upgrade precondition checks when run from
setup.pl.

=head1 METHODS

This module doesn't specify any methods.

=head1 FUNCTIONS

=cut

use strict;
use warnings;

use Exporter 'import';
use Digest::MD5 qw(md5_hex);
use Text::Markdown qw(markdown);

use LedgerSMB::Database::ChangeChecks qw/ run_with_formatters /;

our @EXPORT = ## no critic
    qw| html_formatter_context |;


our @HTML;
our $failing_check;

sub _check_hashid {
    my $check = shift;

    return md5_hex($check->{path} // '', $check->{title});
}


sub _unpack_grid_data {
    my ($request, $prefix, $columns) = @_;
    my $rowcount = $request->{"rowcount_$prefix"};

    my @rows = ();
    for my $rowno (1 .. $rowcount) {
        my $rowid = $request->{"${prefix}_row_$rowno"};
        push @rows, {
            (map { $_ => $request->{"${prefix}_${_}_$rowid"} } @$columns),
            __pk => $request->{"${prefix}_--pk_$rowid"}
        };
    }

    return \@rows;
}

sub _wrap_html {
    my ($request) = shift;

    my $template = $request->{_wire}->get('ui');
    unshift @HTML, $template->render_string(
        $request,
        'setup/upgrade/preamble',
        {
            check_id => _check_hashid( $failing_check ),
            database => $request->{database},
            resubmit_action => $request->{resubmit_action},
            action_url => $request->{_uri}->as_string,
            # note: the line below works because the upgrade
            # has completed when this wrapper is being run
            run_id => $request->{run_id},
        });

    $template = $request->{_wire}->get('ui');
    push @HTML, $template->render_string($request,
                                         'setup/upgrade/epilogue');

    return \@HTML;
}

sub _format_confirm {
    my ($request, $check, @confirmations) = @_;

    # We need to have the failing check available, because we need
    # to calculate a hashed ID from it to check later for which
    # check we're being submitted data.
    $failing_check = $check;

    my $seq = 0;
    while (@confirmations) {
        my $template = $request->{_wire}->get('ui');
        push @HTML, $template->render_string(
            $request,
            'setup/upgrade/confirm',
            {
                value => shift @confirmations,
                description => shift @confirmations,
                id => "confirm-$seq",
            });

        $seq++;
    }
}

sub _format_describe {
    my ($request, $check, $msg) = @_;

    # We need to have the failing check available, because we need
    # to calculate a hashed ID from it to check later for which
    # check we're being submitted data.
    $failing_check = $check;

    $msg //= $check->{description};
    my $template = $request->{_wire}->get('ui');
    push @HTML, $template->render_string(
        $request,
        'setup/upgrade/describe',
        {
            title => $check->{title},
        },
        {
            description => markdown($msg),
        });
}

sub _format_grid {
    my ($request, $check, $rows, %args) = @_;

    # We need to have the failing check available, because we need
    # to calculate a hashed ID from it to check later for which
    # check we're being submitted data.
    $failing_check = $check;

    my $c = 0;
    $_->{row_id} = $c++ for @$rows;
    # underscore-prefixed variables are treated as private by
    # TT, so, not available for interpolation --> rename.
    $_->{'--pk'} = $_->{__pk} for @$rows;
    my $cols = {
        map { $_ => { type => 'text',
                      col_id => $_,
                      name => $_,
              }
        } @{$args{columns}}
    };
    $cols->{__pk} = {
        type => 'hidden',
        col_id => '--pk',
        name => '__pk',
    };

    $cols->{$_}->{type} = 'input_text'
        for @{$args{edit_columns}};
    my $dropdowns = $args{dropdowns};
    for my $dropdown (keys %$dropdowns) {
        my $map = $dropdowns->{$dropdown};
        if ($cols->{$dropdown}->{type} eq 'text') {
            # not an input field; resolve key to description
            for my $row (@$rows) {
                $row->{$dropdown} = $map->{$row->{$dropdown}};
            }
        }
        elsif ($cols->{$dropdown}->{type} eq 'input_text') {
            $cols->{$dropdown}->{type} = 'select';
            $cols->{$dropdown}->{default_blank} = 1;
            if (ref $map eq 'CODE') {
                $cols->{$dropdown}->{options} = $map;
            }
            else {
                $cols->{$dropdown}->{options} =
                    [ map { { value => $_, text => $map->{$_} } } keys %$map ];
            }
        }
        else {
            # FAIL!
        }
    }
    my $atts = {
        input_prefix => $args{name} . '_',
        id => $args{name},
    };

    my $template = $request->{_wire}->get('ui');
    push @HTML, $template->render_string(
        $request,
        'setup/upgrade/grid',
        {
            attributes => $atts,
            columns => [ map { $cols->{$_} } ('__pk', @{$args{columns}}) ],
            rows => $rows,
        });
}

sub _provided {
    my $request = shift;
    my $check = shift;

    # We are likely to *have* content, but not for the
    # current processing phase/check...
    # (due to a failed prior check's resubmission)

    # so, it's best to check whether we actually have a matching
    # check/data combo and return early (and return undef) if not.

    return undef
        unless (defined $request->{check_id}
                && $request->{check_id} eq _check_hashid($check));


    if (@_) {
        my $name = shift;
        # we're being asked for a specific element
        # and since we currently only support confirm and grids...
        if ($name eq 'confirm') {
            return $request->{confirm};
        }
        else {
            # it'll be a grid.
            return _unpack_grid_data($request, $name,
                                     $check->{grids}->{$name}->{edit_columns});
        }
    }
    else {
        # we're being asked if we have content to be processed

        return defined $request->{confirm};
    }
}


=head2 html_formatter_context $coderef $request

Calls C<$coderef> with a hash-argument containing the ChangeCheck formatters
required to be passed to C<run_with_formatters> in that module; also sets
up a context for the (HTML) formatters to be called within.

Returns C<undef> when the C<$coderef> returns false.

Returns a reference to an array of HTML snippets when C<$coderef> returns true.

=cut

sub html_formatter_context(&$) { ## no critic
    my ($closure, $request) = @_;

    local @HTML = ();
    local $failing_check = undef;
    return (run_with_formatters { return $closure->(@_); }
            {
                confirm => sub { return _format_confirm( $request, @_ ); },
                grid => sub { return _format_grid( $request, @_ ); },
                describe => sub { return _format_describe( $request, @_ ); },
                provided => sub { return _provided( $request, @_ ); },
            }) ? _wrap_html($request) : undef;
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2018 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
