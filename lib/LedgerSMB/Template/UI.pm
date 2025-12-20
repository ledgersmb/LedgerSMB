
package LedgerSMB::Template::UI;

=head1 NAME

LedgerSMB::Template::UI - Renderer for UI templates

=head1 DESCRIPTION

This module instantiates a singleton UI template rendering engine
(backed by Template Toolkit).

=head1 METHODS

=cut

use strict;
use warnings;
use experimental 'signatures';

use LedgerSMB::Locale;
use LedgerSMB::Template;

use Carp;
use File::Spec;
use HTML::Escape;
use HTML::Entities;
use Scalar::Util qw(blessed reftype);
use Template;

our $engine;
our $singleton;
our @pre_render_cbs = (
    sub {
        my ($request, $template, $vars, $cvars) = @_;
        $vars->{USER} = $request->{_user};
        $vars->{locale} = $vars->{language} // $vars->{locale};
        $cvars->{locale} = $cvars->{language} // $cvars->{locale};
    },
    );


=head2 new_UI( cache => $path, root => $path )

Constructor. Returns (singleton) template UI renderer.

=cut

sub new_UI {
    my $class = shift;
    my %args = @_;
    my $cache = $args{cache} // 'lsmb_templates';
    my $root = $args{root} // './UI';

    if (! defined $singleton) {
        if (!defined $engine) {
            $engine = Template->new(
                INCLUDE_PATH => [
                    map { File::Spec->catdir($root, $_) } ('js', '', 'lib') ],
                ENCODING => 'utf8',
                TRIM => 1,
                START_TAG => quotemeta('[%'),
                END_TAG => quotemeta('%]'),
                DELIMITER => ';',
                COMPILE_EXT => '.lttc',
                COMPILE_DIR =>
                   File::Spec->rel2abs( $cache, File::Spec->tmpdir ),
                VARIABLES => {
                    UNESCAPE => sub {
                        return decode_entities(shift @_);
                    },
                })
                or die Template->error;
        }

        $singleton = bless {
            root => $root,
            stylesheet => $args{stylesheet} // 'ledgersmb.css',
            standard_vars => {
            },
        }, __PACKAGE__;
    }
    return $singleton;
}

=head2 render_string($self, $request, $template, $vars, $cvars)

Returns the processed template as a string (of bytes, UTF-8 encoded).

Adds template variables C<USER>, C<DBNAME>, C<locale> and C<SETTINGS>
from C<$request>.

Renders the template stored in the file indicated by C<$template>.
The file is looked up in the root templates directory as configured
or in the C<lib/> subdirectory of it and should be a relative
path to either of those.

The values of the variables specified in C<$vars> will be HTML-encoded
and passed to the template.

C<$cvars> is optional. It's an additional set of variables assumed to
be HTML encoded and ready for inclusion in the generated HTML output.

=cut

sub _preprocess($rawvars, $formatter_options) {
    #
    # Note: before changing *anything* in the function below,
    #  please note that it's extremely performance sensitive
    #  and that the current code is the result of extensive
    #  profiling work.
    #
    return undef unless defined $rawvars;

    if (not ref $rawvars) {
        return escape_html( $rawvars );
    }

    if (blessed $rawvars and $rawvars->can('to_output') ){
        return escape_html( $rawvars->to_output( %{ $formatter_options // {} } ) );
    }

    my $reftype = (reftype $rawvars) // ''; # '' is falsy, but works with EQ
    if ($reftype eq 'HASH') { # Hashes and objects
        return {
            map { $_ => (ref $rawvars->{$_})
                      ? _preprocess( $rawvars->{$_}, $formatter_options )
                      : escape_html( $rawvars->{$_} ) }
            grep { not /^(?:_|dbh$)/ }
            keys %{$rawvars}
        };
    }

    if ( $reftype eq 'ARRAY' ) {
        return [ map { (ref $_)
                           ? _preprocess( $_, $formatter_options )
                           : escape_html( $_ )
                 } @{$rawvars} ];
    }

    if ($reftype eq 'CODE'){ # a code reference makes no sense
        return $rawvars;
    }

    if ($reftype eq 'SCALAR' or (ref $rawvars) eq 'Math::BigInt::GMP') {
        return escape_html( $$rawvars );
    }

    # return undef for GLOB references (includes IO::File objects)
    return undef;
}


sub render_string {
    my ($self, $request, $template, $vars, $cvars) = @_;
    my $locale;
    $vars //= {};
    delete $vars->{HIDDENS}->{form_id} if $vars->{HIDDENS};

    for my $cb (@pre_render_cbs) {
        $cb->($request, $template, $vars, $cvars);
    }

    if ($vars->{locale}) {
        $locale = LedgerSMB::Locale->get_handle($vars->{locale});
    }
    elsif ($request->{_locale}) {
        $locale = $request->{_locale};
    }
    my $cleanvars = {
        ( %{_preprocess(
                {
                    $vars->%*,
                    PRINTERS => [
                        ( $request->{_wire}->get( 'printers' )->as_options,
                          {
                              text  => $request->{_locale}->text('Screen'),
                              value => 'screen'
                          } )
                    ],
                    SETTINGS => {
                        ($request->{_company_config} // {})->%*,
                        # Reports rendered as UI elements have SETTINGS in $vars
                        ($vars->{SETTINGS} // {})->%*
                    },
                    dojo_theme => (
                        $request->{_company_config}->{dojo_theme} || 'claro'
                        ),
                    csrf_token => $request->{_req}->env->{'lsmb.session'}->{csrf_token},
                },
                $request->formatter_options,
                )},
          %{$self->{standard_vars}},
          LIST_FORMATS => sub {
              return [
                  map { escape_html($_) }
                  $request->{_wire}->get( 'output_formatter' )->get_formats->@*
                  ];
          },
          # translation of constant-string arguments
          text => sub {
              if ($locale) {
                  return escape_html($locale->maketext(@_));
              }
              else {
                  return shift;
              }
          },
          # translation of dynamic string content
          maketext => sub {
              if ($locale) {
                  return escape_html($locale->maketext(@_));
              }
              else {
                  return escape_html(shift);
              }
          },
          %{$cvars // {}}
        )
    };
    if (defined $cleanvars->{form}->{stylesheet}
        and not defined $cleanvars->{stylesheet}) {
        $cleanvars->{stylesheet} = $cleanvars->{form}->{stylesheet};
    }
    if (not defined $cleanvars->{stylesheet}
        or (defined $cleanvars->{stylesheet}
            and not -e ($self->{root} . 'css/' . $cleanvars->{stylesheet}))) {
        $cleanvars->{stylesheet} = $self->{stylesheet};
    }

    my $output;
    if (! $engine->process(
            $template . '.html',
            $cleanvars,
            \$output,
            { binmode => 'utf8' })) {
        my $error = $engine->error() // '<undef>';
        croak 'Template error: ' . $error;
    }
    utf8::encode($output) if utf8::is_utf8($output); ## no critic
    return $output;
}

=head2 render($self, $request, $template, $vars, $cvars)

Calls C<render_string> with its arguments and converts the response
to a PSGI response triplet.

=cut

sub render {
    return [ 200, [ 'Content-Type' => 'text/html; charset=UTF-8' ],
             [ render_string(@_) ] ];
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2018 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
