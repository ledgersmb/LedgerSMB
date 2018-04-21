package LedgerSMB::Setup::SchemaChecks;


=head1 NAME

LedgerSMB::Setup::SchemaChecks - UI for schema checks run from setup.pl

=head1 SYNOPSIS

Provides the UI for schema upgrade precondition checks when run from
setup.pl.

=head1


=cut

use strict;
use warnings;

use Digest::MD5 qw(md5_hex);

use LedgerSMB::Database::ChangeChecks qw/ run_with_formatter_scope /;

our @HTML;
our $failing_check;

sub _check_hashid {
    my $check = shift;

    return md5_hex($check->{title});
}

sub _unpack_grid_data {

}

sub _wrap_html {
    my ($request) = shift;

    my $vars = {
        check_id => _check_hashid( $failing_check );
    };
    my $template = LedgerSMB::Template->new_UI(
        $request,
        template => 'setup/upgrade/preamble',
        );
    $template->render(
        {
            check_id => _check_hashid( $failing_check ),
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
    my $template = LedgerSMB::Template->new_UI($request,
        template => 'setup/upgrade/confirm',
        );
    while (@confirmations) {
        $template->render(
            {
                value => pop @confirmations,
                description => pop @confirmations,
                id => "confirm-$seq",
            });
        push @HTML, $template->{output};

        $seq++;
    }
}

sub _format_describe {
    my ($request, $check, $msg) = @_;

    my $template = LedgerSMB::Template->new_UI(
        $request,
        template => 'setup/upgrade/description',
        );
    my $description
    $template->render(
        {
            title => $check->{title},
            description => $msg
        });
}

sub _format_grid {
    my ($request, $check, $rows, %args) = @_;

    my $c = 0;
    $_->{row_id} = $c++ for @$rows;
    my $cols = {
        {
            type => 'hidden',
            col_id => '__pk',
        },
        map { $_ => { type => 'text',
                      col_id => $_,
                      name => $_,
              }
        }
    };
    $cols->{$_}->{type} = 'input_text'
        for @{$check->{edit_columns}};
    my $atts = {
        input_prefix => $args{name},
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
                && $request->{check_id} eq _check_hashid($request));


    if (@_) {
        # we're being asked for a specific element
        # and since we currently only support grids... it'll be a grid.

    }
    else {
        # we're being asked if we have content to be processed

        return defined $request->{confirm};
    }
}


sub run_with_formatter_scope(&) {
    my ($closure, $request) = @_;

    local @HTML = ();
    local $failing_check = undef;
    return $closure->(
        {
            confirm => sub { return _format_confirm( $request, @_ ); },
            grid => sub { return _format_grid( $request, @_ ); },
            describe => sub { return _format_describe( $request, @_ ); },
            provided => sub { return _provided( $request, @_ ); },
        }) ? _wrap_html($request) : undef;
}


1;
