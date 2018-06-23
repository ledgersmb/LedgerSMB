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
use LedgerSMB::Template;

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
        push @rows, {
            map { $_ => $request->{"${prefix}_${_}_$rowno"} }
               (@$columns, '--pk')
        };
    }
    # Rename '--pk' to '__pk', the value expected by the upgrade framework
    # but renamed due to TT not allowing access to underscore-prefixed vars
    $_->{__pk} = $_->{'--pk'} for @rows;

    return \@rows;
}

sub _wrap_html {
    my ($request) = shift;

    my $template = LedgerSMB::Template->new_UI(
        $request,
        template => 'setup/upgrade/preamble',
        );
    $template->render(
        {
            check_id => _check_hashid( $failing_check ),
            database => $request->{database},
            action_url => $request->get_relative_url,
        });
    unshift @HTML, $template->{output};

    $template = LedgerSMB::Template->new_UI(
        $request,
        template => 'setup/upgrade/epilogue',
        );
    $template->render();
    push @HTML, $template->{output};

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
        my $template = LedgerSMB::Template->new_UI($request,
                template => 'setup/upgrade/confirm',
            );
        $template->render(
            {
                value => shift @confirmations,
                description => shift @confirmations,
                id => "confirm-$seq",
            });
        push @HTML, $template->{output};

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
    my $template = LedgerSMB::Template->new_UI(
        $request,
        template => 'setup/upgrade/describe',
        );
    $template->render(
        {
            title => $check->{title},
        },
        {
            description => markdown($msg),
        });
    push @HTML, $template->{output};
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
    $cols = [ map { $cols->{$_} } ('__pk', @{$args{columns}}) ];
    my $atts = {
        input_prefix => $args{name},
        id => $args{name},
    };

    my $template = LedgerSMB::Template->new_UI(
        $request,
        template => 'setup/upgrade/grid',
        );
    $template->render(
        {
            attributes => $atts,
            columns => $cols,
            rows => $rows,
        });
    push @HTML, $template->{output};
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
            return _unpack_grid_data($request, $name, $check->{columns});
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

Copyright(C) 2018 The LedgerSMB Core Team.

This file may be reused under the terms of the GNU General Public License
version 2 or at your option any later version.  Please see the included
LICENSE.TXT for more information.

=cut


1;
