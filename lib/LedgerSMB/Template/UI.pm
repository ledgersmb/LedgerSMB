
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

use LedgerSMB::Locale;
use LedgerSMB::Sysconfig;
use LedgerSMB::Template;

use Carp;
use File::Spec;
use HTML::Escape;
use HTML::Entities;
use Template;

our $engine;
our $singleton;
our @pre_render_cbs = (
    sub {
        my ($request, $template, $vars, $cvars) = @_;
        $vars->{USER} = $request->{_user};
        $vars->{DBNAME} = $request->{company};
        $vars->{locale} = $vars->{language} // $vars->{locale};
        $cvars->{locale} = $cvars->{language} // $cvars->{locale};
        if ($request->{company} && $request->{_company_config}) {
            $vars->{SETTINGS} = {
                (%{$request->{_company_config}},)
            };
        }
    },
    );


sub _available_formats {
    my @retval = ('HTML', 'TXT');

    if ($LedgerSMB::Sysconfig::template_latex){
        push @retval, 'PDF', 'PS';
    }
    if ($LedgerSMB::Sysconfig::template_xls){
        push @retval, 'XLS';
    }
    if ($LedgerSMB::Sysconfig::template_xlsx){
        push @retval, 'XLSX';
    }
    if ($LedgerSMB::Sysconfig::template_ods){
        push @retval, 'ODS';
    }
    return \@retval;
}

=head2 new_UI()

Constructor. Returns (singleton) template UI renderer.

=cut

sub new_UI {
    my $class = shift;
    croak 'called LedgerSMB::Template::UI::new_UI with args while it takes none'
        if @_;

    if (! defined $singleton) {
        if (!defined $engine) {
            $engine = Template->new(
                ### TODO: These should be configurable absolute paths
                INCLUDE_PATH => [ 'UI/', 'UI/lib/' ],
                ENCODING => 'utf8',
                TRIM => 1,
                START_TAG => quotemeta('[%'),
                END_TAG => quotemeta('%]'),
                DELIMITER => ';',
                COMPILE_EXT => '.lttc',
                COMPILE_DIR =>
                   File::Spec->rel2abs( $LedgerSMB::Sysconfig::templates_cache,
                                        File::Spec->tmpdir ),
                VARIABLES => {
                    LIST_FORMATS => sub {
                        return _available_formats();
                    },
                    UNESCAPE => sub {
                        return decode_entities(shift @_);
                    },
                }
                )
                or die Template->error;
        }

        $singleton = bless {
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
The file is looked up in C<UI/> or C<UI/lib/> and should be a relative
path to either of those.

The values of the variables specified in C<$vars> will be HTML-encoded
and passed to the template.

C<$cvars> is optional. It's an additional set of variables assumed to
be HTML encoded and ready for inclusion in the generated HTML output.

=cut

sub render_string {
    my ($self, $request, $template, $vars, $cvars) = @_;
    my $locale;
    $vars //= {};

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
        ( %{LedgerSMB::Template::preprocess(
                $vars,
                sub { return escape_html($_[0]); }) },
          %{$self->{standard_vars}},
          dojo_theme => (
              $request->{_company_config}->{dojo_theme}
              || LedgerSMB::Sysconfig::dojo_theme()),
          PRINTERS => [
              ( ( map { { text => $_, value => $_ } }
                  keys %LedgerSMB::Sysconfig::printers ),
                {
                    text  => $request->{_locale}->text('Screen'),
                    value => 'screen'
                } )
          ],
          text => sub {
              if ($locale) {
                  return $locale->maketext(@_);
              }
              else {
                  return shift;
              }
          },
          %{$cvars // {}}
        )
    };

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
