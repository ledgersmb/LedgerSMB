=head1 NAME

LedgerSMB::Template - Template support module for LedgerSMB

=head1 DESCRIPTION

This module renders templates to an in-memory property.

This module does not handle the
output/delivery of the rendered template to browser, file,
e-mail etc.  For that, see modules such as LedgerSMB::PSGI::Util
and LedgerSMB::Legacy_Util.

=head1 METHODS

=over

=item new(user => \%myconfig, template => $string, format => $string, [format_options => $hashref], [locale => $locale], [language => $string], [path => $path], [no_escape => $bool], [debug => $bool] );

Instantiates a new template. Accepts the following arguments:

=over

=item user (optional)

A LedgerSMB::User object defining user preferences.

=item template

The template to be processed.  This is the file that is the template to be
processed. When 'path' equals 'DB', the file is retrieved from
the database instead of from disk.
Based on the specified format, an appropriate extension is appended
to resolve to the correct template file.

=item format

The format to be used.  Currently HTML, PS, PDF, TXT, CSV, ODS, XLS, XLSX
are supported, subject to their dependencies being available.

=item format_options (optional)

A hash of format-specific options.  See the appropriate LSMB::T::foo for
details.

=item output_options (optional)

A hash of output-specific options, not used internally by LedgerSMB::Template.
These options may be used by output/delivery code.

For example, if the output is sent as an HTTP response using
LedgerSMB::PSGI::Util::template_to_psgi(),  the output option C<filename>
causes C<Content-Disposition> headers to be generated of the type
C<attachment> (forcing file download).

=item locale (optional)

The locale object to use for regular gettext lookups.  Having this option adds
the text function to the usable list for the templates.  Has no effect on the
gettext function.

=item language (optional)

The language for template selection.

=item path (optional)

Overrides the template directory.

The special value 'DB' enforces reading of the template from the
current database.  Resolving the template takes the 'language' and
'format' values into account.

=item no_escape (optional)

Disables escaping on the template variables when true.

=item debug (optional)

Enables template debugging.

With the TT-based renderers, HTML, PS, PDF, TXT, and CSV, the portion of the
template to get debugging messages is to be surrounded by
<?lsmb DEBUG format 'foo' ?> statements.  Example:

    <tr><td colspan="<?lsmb columns.size ?>"></td></tr>
    <tr class="listheading">
  <?lsmb FOREACH column IN columns ?>
  <?lsmb DEBUG format '$file line $line : [% $text %]' ?>
      <th class="listtop"><?lsmb heading.$column ?></th>
  <?lsmb DEBUG format '' ?>
  <?lsmb END ?>
    </tr>

=back


=item available_formats()

Returns a list of format names, any of the following (in order) as applicable:

=over

=item HTML (always available)

=item TXT (includes CSV, always available))

=item PDF

=item PS

=item XLS

=item XLSX

=item ODS

=back


=item new_UI($request, template => $file, ...)

Wrapper around the constructor that sets the following properties:

    path   => 'UI'
    format => 'HTML',
    user   => $request->{_user}
    locale => $request->{_locale}

Additionally, variables are added to the template processor as required
by the HTML UI.


=item render($variables, $raw_variables)

Returns the LedgerSMB::Template object itself. Dies on error.

The rendered template result is available from the LedgerSMB::Template
object's C<output> property, based on C<variables> and C<raw_variables>.

C<variables> are escaped using the specific mechanism to the output
format. C<raw_variables> are passed without escaping or processing
to the template processor.


=item get_template_source($extension)

Returns the name of the Template source, incorporating the specified
extension as appropriate.


=item get_template_args($extension)

Returns a hash with the default arguments for the Template and the
desired file extention

=back


=head1 FUNCTIONS

=over

=item preprocess ($rawvars, $escape)

Preprocess for rendering. This is not an object method, it is a standalone
subroutine.

=back


=head1 PROPERTIES

=over 

=item output

The result of rendering the template.

=item mimetype

The mimetype of the rendered template.

=item output_options

Not used internally by LedgerSMB::Template, but used as a way of passing
options to output/delivery code, such as
LedgerSMB::PSGI::Util::template_to_psgi().

=back


=head1 TEMPLATE FUNCTIONS

Templates can make use of the following functions, installed by the
template processor, when available for the current format.

=over

=item escape($string)

This function encodes the string argument to be safe for inclusion in
the target document, showing the exact content of the string.

E.g. for HTML encoding, this means that ampersand is encoded into C<&amp;>
and that newline characters in LaTeX are encoded into double backslashes.

=item UNESCAPE($string) [optional]

This function reverses the string-escaping as might have been applied by
the C<escape> function. This function is not guaranteed to be available
(currently only supported for HTML templates).

=item text($string, @args)

This function looks up the translation of C<$string> in the language lexicon,
interpolating the string's variable placeholders with the arguments provided
in C<@args>. The resulting string will be escaped using the C<escape> function.

Note: This string looks up the exact string C<$string>, which makes it
unsuited for translation of string values passed to the template through
(escaped) string variable values.

=item tt_url($string)

This function applies basic URL encoding to C<$string>.

=back

=head1 FORMATS

The template employs formats for a number of format-specific tasks:

=over

=item Escaping/encoding of values

=item Discovery of format specific templates

=item Evaluation of the template

=back

In order to perform these actions, formats need to implement the following
entry-points:

=over

=item escape($value)

The template calls this function with one scalar value as its argument,
repeatedly until all values to be passed to the template have been escaped.

The return value is the escaped value to substitute for C<$value>. The
escaping mechanism is format specific.

=item unescape($value) [optional]

The template calls this function with one scalar value as its argument,
in order to reverse the transformation as applied by C<escape>.

=item setup($parent, $variables, $output)

The template driver calls this function just before the evaluation of
the template. The C<$parent> is an instance of this class. The C<$variables>
is a hashref containing the escaped variable values which will be passed to
the template. C<$output> holds the output destination; either
a string (containing a filename) or a scalar reference (for in-memory
capturing of template output).

This function returns a tuple with the first value being the (temporary)
output destination and the second a configuration hash with at least the
following keys:

=over

=item format_extension

This extension, together with the base name specified by the caller of
the renderer, is used to look up the format specific template.

=item binmode

This value indicates which binmode to use for the output being generated.
Valid values are C<':utf8'>, C<1> or C<0>.

=back

The configuration hash can be used as a communication channel between
C<setup> and C<postprocess> by adding keys starting with an underscore (C<_>).

=item initialize_template($parent, $config, $template)

After the Template Toolkit engine has been initialized based on the
values returned by C<setup>, the driver calls this function, if a format
provides it.

C<$config> corresponds with the second argument returned by C<setup>.

C<$template> is an instance of a Template Toolkit template
processor - its value can be used to register plugins if such is required
for the specific format.

=item postprocess($parent, $output, $config)

After having evaluated the template, the driver calls this function. Its
arguments are the instance of the driver C<$parent> (same as for C<setup>),
C<$output> (the first item of the tuple returned by C<setup>) and the
configuration hash C<$config>.

This function does not have a defined return value, but should return
C<undef> for forward compatibility.

=item mimetype()

Returns the MIME content-type for the rendered template.

=back

=head1 Copyright 2007-2018, The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

package LedgerSMB::Template;

use strict;
use warnings;
use Carp;
use LedgerSMB::App_State;
use LedgerSMB::Company_Config;
use LedgerSMB::Locale;
use LedgerSMB::Setting;
use LedgerSMB::Sysconfig;
use LedgerSMB::Template::DBProvider;

use Template::Parser;
use Log::Log4perl;
use File::Spec;
use Module::Runtime qw(use_module);
use Scalar::Util qw(reftype);

use parent qw( Exporter );
our @EXPORT_OK = qw( preprocess );

my $logger = Log::Log4perl->get_logger('LedgerSMB::Template');

sub available_formats {
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

sub new {
    my $class = shift;
    my %args = @_;
    my $self = {
        binmode => undef,
    };
    bless $self, $class;

    $logger->trace('new(<args>), keys: ' . join '|', keys %args);
    $logger->trace('output_options, keys: ' . join '|', keys %{$args{output_options}});

    $self->{$_} = $args{$_}
        for (qw( template format language no_escape debug locale
                 format_options output_options additional_vars ));
    $self->{user} = $args{user};
    $self->{include_path} = $args{path};
    if ($self->{language}){ # Language takes precedence over locale
        $self->{locale} = LedgerSMB::Locale->get_handle($self->{language});
    }

    if (lc $self->{format} eq 'pdf') {
        $self->{format} = 'LaTeX';
        $self->{format_options}{filetype} = 'pdf';
    } elsif (lc $self->{format} eq 'ps' or lc $self->{format} eq 'postscript') {
        $self->{format} = 'LaTeX';
        $self->{format_options}{filetype} = 'ps';
    } elsif (lc $self->{format} eq 'xlsx'){
        $self->{format} = 'XLSX';
        $self->{format_options}{filetype} = 'xlsx';
    } elsif (lc $self->{format} eq 'xls'){
        $self->{format} = 'XLSX';
        $self->{format_options}{filetype} = 'xls';
    } elsif ($self->{format} =~ /edi$/i){
        $self->{format_options}{extension} = lc $self->{format};
        $self->{format_options}{filetype} = lc $self->{format};
        $self->{format} = 'TXT';
    }

    if ($self->{format} !~ /^\p{IsAlnum}+$/) {
        die 'Invalid format';
    }
    use_module("LedgerSMB::Template::$self->{format}")
       or die "Failed to load module $self->{format}";

    carp 'no_escape mode enabled in rendering'
        if $self->{no_escape};

    return $self;
}

sub new_UI {
    my $class = shift;
    my $request = shift;

    return $class->new(
        @_,
        format => 'HTML' ,
        path => 'UI',
        user => $request->{_user},
        locale => $request->{_locale},
        additional_vars => {
            dojo_theme =>
                ($LedgerSMB::App_State::Company_Config->{dojo_theme}
                 // $LedgerSMB::Sysconfig::dojo_theme),
        },
    );
}

sub preprocess {
    my ($rawvars, $escape) = @_;
    return undef unless defined $rawvars;

    local $@ = undef;
    if (eval {$rawvars->can('to_output')}){
        $rawvars = $rawvars->to_output;
    }
    my $type = ref $rawvars;
    my $reftype = (reftype $rawvars) // ''; # '' is falsy, but works with EQ
    return $rawvars if $type =~ /^LedgerSMB::Locale/;

    my $vars;
    if ( $reftype and $reftype eq 'ARRAY' ) {
        $vars = [];
        for (@{$rawvars}) {
            push @{$vars}, preprocess( $_, $escape );
        }
    } elsif (!$type) {
        return $escape->($rawvars);
    } elsif ($reftype eq 'SCALAR' or $type eq 'Math::BigInt::GMP') {
        return $escape->($$rawvars);
    } elsif ($reftype eq 'CODE'){ # a code reference makes no sense
        return $rawvars;
    } elsif ($reftype eq 'HASH') { # Hashes and objects
        $vars = {};
        for ( keys %{$rawvars} ) {
            # don't encode the object's internals; TT won't forward anyway...
            # btw, some (internal) objects are XS objects, on which this trick
            # treating it as a hashref really doesn't work...
            next if /^_/;
            $vars->{$_} = preprocess( $rawvars->{$_}, $escape );
        }
    }
    # return undef for GLOB references (includes IO::File objects)
    return $vars;
}

sub get_template_source {
    my ($self, $format_extension) = @_;

    my $source;
    if ($self->{include_path} && $self->{include_path} eq 'DB'){
        $source = $self->{template};
    } else {
        $source = $self->{template} . '.' . $format_extension;
    }
    return $source;
}

sub get_template_args {
    my $self = shift;
    my $extension = shift;
    my $binmode = shift;

    my %additional_options = ();
    if ($self->{include_path} && $self->{include_path} eq 'DB'){
        $additional_options{INCLUDE_PATH} = [];
        $additional_options{LOAD_TEMPLATES} =
            [ LedgerSMB::Template::DBProvider->new(
                  {
                      format => $extension,
                      language_code => $self->{language},
                      PARSER => Template::Parser->new({
                         START_TAG => quotemeta('<?lsmb'),
                         END_TAG => quotemeta('?>'),
                      }),
                  }) ];
    }
    my $paths = ['UI/lib'];
    unshift @$paths, $self->{include_path}
        if defined $self->{include_path};
    unshift @$paths, $self->{include_path_lang}
        if defined $self->{include_path_lang};
    my $arghash = {
        INCLUDE_PATH => $paths,
        ENCODING => 'utf8',
        TRIM => (!$binmode || $binmode eq ':utf8'),
        START_TAG => quotemeta('<?lsmb'),
        END_TAG => quotemeta('?>'),
        DELIMITER => ';',
        DEBUG => ($self->{debug})? 'dirs': undef,
        DEBUG_FORMAT => '',
        (%additional_options)
    };

    if ($LedgerSMB::Sysconfig::cache_templates
        && (!$self->{include_path} || $self->{include_path} ne 'DB')) {
       # don't cache compiled database-retrieved templates
       # they will vary between databases
        $arghash->{COMPILE_EXT} = '.lttc';
        $arghash->{COMPILE_DIR} =
           File::Spec->rel2abs( $LedgerSMB::Sysconfig::templates_cache,
                                File::Spec->tmpdir );
    }
    $self->{binmode} = $binmode;
    return $arghash;
}

sub _tt_url {
    my $str = shift;

    $str =~ s/([^a-zA-Z0-9_.-])/sprintf("%%%02x", ord($1))/ge;
    return $str;
}

sub _maketext {
    my $self = shift;
    my $escape = shift;

    return $escape->(defined $self->{locale}
                    ? $self->{locale}->maketext(@_)
                    : shift);
}

sub _render {
    my $self = shift;
    my $vars = shift;
    my $cvars = shift;
    $vars->{ENVARS} = \%ENV;
    $vars->{USER} = $self->{user};
    $vars->{DBNAME} = $LedgerSMB::App_State::DBName;
    $vars->{SETTINGS} = {
        default_currency =>
            (LedgerSMB::Setting->new(%$self)->get_currencies)[0],
        decimal_places => $LedgerSMB::Company_Config::decimal_places,
    } if $vars->{DBNAME} && LedgerSMB::App_State::DBH;

    @{$vars->{PRINTERS}} =
        map { { text => $_, value => $_ } }
        keys %LedgerSMB::Sysconfig::printers;
    unshift @{$vars->{PRINTERS}}, {
        text => $LedgerSMB::App_State::Locale->text('Screen'),
        value => 'screen'
    } if $LedgerSMB::App_State::Locale;

    my $format = "LedgerSMB::Template::$self->{format}";
    my $escape = $format->can('escape');
    my $unescape = $format->can('unescape');
    my $cleanvars = $self->{no_escape} ? $vars : preprocess($vars, $escape);
    $cleanvars->{LIST_FORMATS} = sub { return $self->available_formats; };
    $cleanvars->{escape} = sub { return $escape->(@_); };
    $cleanvars->{UNESCAPE} = sub { return $unescape->(@_); }
        if ($unescape && !$self->{no_escape});
    $cleanvars->{text} = sub { return $self->_maketext($escape, @_); };
    $cleanvars->{tt_url} = \&_tt_url;
    $cleanvars->{$_} = $self->{additional_vars}->{$_}
        for (keys %{$self->{additional_vars}});
    $cleanvars->{$_} = $cvars->{$_}
        for (keys %$cvars);

    my $output;
    my $config;
    ($output, $config) = $format->can('setup')->($self, $cleanvars,
                                                 \$self->{output});

    my $arghash = $self->get_template_args(
        $config->{input_extension},
        $config->{binmode});
    my $template = Template->new($arghash)
        || die Template->error();

    my $initialize_template = $format->can('initialize_template');
    $initialize_template->($self, $config, $template)
        if defined $initialize_template;

    if (! $template->process(
              $self->get_template_source($config->{input_extension}),
              $cleanvars,
              $output,
              { binmode => $config->{binmode} })) {
        my $err = $template->error();
        die "Template error: $err" if $err;
    }

    $format->can('postprocess')->($self, $output, $config);
    $self->{mimetype} = $format->can('mimetype')->($config);
    return;
}

sub render {
    my $self = shift @_;
    my $vars = shift @_;
    my $cvars = shift @_;

    $self->_render($vars, $cvars);
    return $self;
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007-2018 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
