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

=item new(user => \%myconfig, template => $string, format => $string, [format_options => $hashref], [locale => $locale], [language => $string], [path => $path], [debug => $bool] );

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

=item format_plugin

The formatter to be used.  Currently HTML, PS, PDF, TXT, CSV, ODS, XLS, XLSX
are supported, through the plugins in LedgerSMB::Template::Plugin modules,
subject to their dependencies being available.

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

=item formatter_options (optional)

C<numberformat> and C<dateformat>.

=item path (optional)

Overrides the template directory.

The special value 'DB' enforces reading of the template from the
current database.  Resolving the template takes the 'language' and
'format' values into account.

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

=item preprocess ($rawvars, $escape, $formatter_options)

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

=item text($string, @args)

This function looks up the translation of C<$string> in the language lexicon,
interpolating the string's variable placeholders with the arguments provided
in C<@args>. The resulting string will be escaped using the C<escape> function.

Note: This string looks up the exact string C<$string>, which makes it
unsuited for translation of string values passed to the template through
(escaped) string variable values.

=item dbfile_path($name)
=item dbfile_string($name)
=item dbfile_base64($name)

These functions retrieve a file uploaded through System > Files. C<dbfile_path>
returns a file name on the file system holding the content of the file in the
database. C<dbfile_string> returns the content of the uploaded file in a
string, whereas C<dbfile_base64> returns the content in a string, encoded
using base64 encoding.

The file returned by C<dbfile_path> is guaranteed as long as a reference to
the template is kept. There are no guarantees beyond the life of the template
itself.

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

=cut

package LedgerSMB::Template;

use strict;
use warnings;
use Carp;

use LedgerSMB::File;
use LedgerSMB::Locale;
use LedgerSMB::Magic qw( FC_INTERNAL );
use LedgerSMB::Template::DBProvider;

use File::Spec;
use File::Temp;
use Log::Any;
use MIME::Base64;
use Module::Runtime qw(use_module);
use Template;
use Template::Parser;
use Template::Provider;
use Scalar::Util qw(blessed reftype);

my $logger = Log::Any->get_logger(category => 'LedgerSMB::Template');

sub new {
    my $class = shift;
    my %args = @_;
    my $self = {
        binmode => undef,
        dbh => $args{dbh},
    };
    bless $self, $class;

    $logger->trace('new(<args>), keys: ' . join '|', keys %args);
    $logger->trace('output_options, keys: ' . join '|', keys %{$args{output_options}});

    $self->{$_} = $args{$_}
        for (qw( template format_plugin language debug locale
                 format_options output_options formatter_options ));
    $self->{user} = $args{user};
    $self->{include_path} = $args{path};
    if ($self->{language}){ # Language takes precedence over locale
        $self->{locale} = LedgerSMB::Locale->get_handle($self->{language});
    }

    return $self;
}

sub preprocess {
    #
    # Note: before changing *anything* in the function below,
    #  please note that it's extremely performance sensitive
    #  and that the current code is the result of extensive
    #  profiling work.
    #
    my ($rawvars, $escape, $formatter_options) = @_;
    return undef unless defined $rawvars;

    if (not ref $rawvars) {
        return $escape->($rawvars);
    }

    if (blessed $rawvars and $rawvars->can('to_output') ){
        return $escape->( $rawvars->to_output( %{ $formatter_options // {} } ) );
    }

    my $reftype = (reftype $rawvars) // ''; # '' is falsy, but works with EQ
    if ($reftype eq 'HASH') { # Hashes and objects
        return {
            map { $_ => (ref $rawvars->{$_})
                      ? preprocess( $rawvars->{$_}, $escape, $formatter_options )
                      : $escape->($rawvars->{$_}) }
            grep { not /^(?:_|dbh$)/ }
            keys %{$rawvars}
        };
    }

    if ( $reftype eq 'ARRAY' ) {
        return [ map { (ref $_)
                           ? preprocess( $_, $escape, $formatter_options )
                           : $escape->($_)
                 } @{$rawvars} ];
    }

    if ($reftype eq 'CODE'){ # a code reference makes no sense
        return $rawvars;
    }

    if ($reftype eq 'SCALAR' or (ref $rawvars) eq 'Math::BigInt::GMP') {
        return $escape->($$rawvars);
    }

    # return undef for GLOB references (includes IO::File objects)
    return undef;
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
        my $parser =  Template::Parser->new(
            {
                START_TAG => quotemeta('<?lsmb'),
                END_TAG => quotemeta('?>'),
            });
        $additional_options{LOAD_TEMPLATES} =
            [ LedgerSMB::Template::DBProvider->new(
                  {
                      format => $extension,
                      language_code => $self->{language},
                      PARSER => $parser,
                      _dbh => $self->{dbh}
                  }),
              # We need this provider in order to allow the templates to
              # depend on 'dynatable.*'
              Template::Provider->new(
                  {
                      INCLUDE_PATH => [ 'templates/lib/' ],
                      PARSER => $parser,
                  }),
            ];
    }
    my $paths = ['templates/lib'];
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

    $self->{binmode} = $binmode;
    return $arghash;
}

sub _dbfile_path {
    my $self = shift;
    my ($name) = @_;
    my $content = $self->_dbfile_string(@_);

    $self->{_tmpdir} = File::Temp->newdir() unless defined $self->{_tmpdir};
    $self->{_files} = [] unless defined $self->{_files};

    # PDFLaTeX wants the extension of the original file...
    $name =~ m/([.][a-zA-Z0-9]*)$/;
    my $ext = $1 // '';
    my $file = File::Temp->new( SUFFIX => $ext,
                                DIR => $self->{_tmpdir} );

    syswrite($file, $content)
        or die "Unable to write content for database-file $_[0]: $!";
    close($file)
        or warn "Unable to close file for database-file content $_[0]: $!";
    # Keep the file reference from going out of scope until the
    # template itself finishes processing
    push @{$self->{_files}}, $file;
    return $file->filename;
}

sub _dbfile_base64 {
    return encode_base64(_dbfile_string(@_), '');
}

sub _dbfile_string {
    my ($self, $name) = @_;

    my $file = LedgerSMB::File->new(
        file_class => FC_INTERNAL,
        file_name  => $name,
        ref_key    => 0,
        );
    $file->get_by_name;
    return ${$file->content};
}

sub _maketext {
    my $self = shift;

    return defined $self->{locale} ? $self->{locale}->maketext(@_) : shift;
}

sub _render {
    my $self = shift;
    my $vars = shift;
    my $cvars = shift // {};
    $vars->{USER} = $self->{user};

    my $escape = $self->{format_plugin}->can('escape');
    my $cleanvars;

    if ($escape) {
        $cleanvars = {
            %{ preprocess($vars,
                          sub { $self->{format_plugin}->escape(@_) },
                          $self->{formatter_options},
                   ) },
            %{$self->{additional_vars} // {}},
            %$cvars,
            escape => sub { $self->{format_plugin}->escape(@_) },
            text => sub {
                return $self->{format_plugin}->escape($self->_maketext(@_));
            },
        };
    }
    else {
        $cleanvars = {
            ( %$vars,
              %{$self->{additional_vars} // {}},
              %$cvars,
              escape => sub { $_[0] },
              text => sub { return $self->_maketext(@_); },
            )
        };
    }

    if ($self->{dbh}) {
        $cleanvars->{dbfile_path} = sub { $self->_dbfile_path($_[0]) };
        $cleanvars->{dbfile_string} = sub { $self->_dbfile_string($_[0]) };
        $cleanvars->{dbfile_base64} = sub { $self->_dbfile_base64($_[0]) };
    }
    my $output;
    my $config;
    ($output, $config) = $self->{format_plugin}->setup(
        $self, $cleanvars, \$self->{output}
        );

    my $arghash = $self->get_template_args(
        $config->{input_extension},
        $config->{binmode});
    my $template = Template->new($arghash)
        || die Template->error();

    $self->{format_plugin}->initialize_template($self, $config, $template)
        if $self->{format_plugin}->can('initialize_template');

    if (! $template->process(
              $self->get_template_source($config->{input_extension}),
              $cleanvars,
              $output,
              { binmode => $config->{binmode} })) {
        my $err = $template->error();
        die "Template error: $err" if $err;
    }

    $self->{format_plugin}->postprocess($self, $output, $config);
    $self->{mimetype} = $self->{format_plugin}->mimetype($config);
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

Copyright (C) 2007-2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
