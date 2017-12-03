=head1 NAME

LedgerSMB::Template - Template support module for LedgerSMB

=head1 SYNOPSIS

This module renders templates.

=head1 METHODS

=over

=item new(user => \%myconfig, template => $string, format => $string, [locale => $locale] [language => $string], [include_path => $path], [no_auto_output => $bool], [method => $string], [no_escape => $bool], [debug => $bool], [output_file => $string] );

This command instantiates a new template:

=over

=item template

The template to be processed.  This is the file that is the template to be
processed. When C<include_path> equals 'DB', the file is retrieved from
the database instead of from disk.
Based on the specified format, an appropriate extension is appended
to resolve to the correct template file.

=item format

The format to be used.  Currently HTML, PS, PDF, TXT and CSV are supported.

=item format_options (optional)

A hash of format-specific options.  See the appropriate LSMB::T::foo for
details.

=item output_options (optional)

A hash of output-specific options.  If the output is sent as an HTTP
response, the output option C<filename> causes C<Content-Disposition>
headers to be generated of the type C<attachment> (forcing file download).

=item locale (optional)

The locale object to use for regular gettext lookups.  Having this option adds
the text function to the usable list for the templates.  Has no effect on the
gettext function.

=item language (optional)

The language for template selection.

=item include_path (optional)

Overrides the template directory.

The special value 'DB' enforces reading of the template from the
current database.  Resolving the template takes the 'language' and
'format' values into account.

=item no_auto_output (optional)

Disables the automatic output of rendered templates.

=item no_escape (optional)

Disables escaping on the template variables.

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

=item method/media (optional)

The output method to use, defaults to HTTP.  Media is a synonym for method

=item output_file (optional)

The base name of the file for output.

=back

=item available_formats()

Returns a list of format names, any of the following (in order) as applicable:

=over

=item HTML (always available)

=item TXT (includes CSV, always available))

=item PDF

=item PS

=item XLS

=item ODS

=back

=item new_UI($request, template => $file, ...)

Wrapper around the constructor that sets the path to 'UI', format to 'HTML',
the user to C<$request->{_user}>, the locale to C<$request->{_locale}
and leaves auto-output enabled.

Additionally, variables are added to the template processor as required
by the HTML UI.

=item preprocess ($rawvars, $escape)

Preprocess for rendering.


=item render($hashref)

This command renders the template.  If no_auto_output was not specified during
instantiation, this also writes the result to standard output and exits.
Otherwise it returns the name of the output file if a file was created.  When
no output file is created, the output is held in $self->{output}.

Currently email and server-side printing are not supported.

=item render_to_psgi( $variables, extra_headers => \@headers)

Like C<render>, but instead of printing to STDOUT, returns
a PSGI return value triplet (status, headers and body).

Note that the only guarantee here is that the triplet can
be used as a PSGI return value which means that the body
is *not* restricted to being an array of strings.

When C<extra_headers> is specified, these are included in
the headers part of returned triplet.


=item output

This function outputs the rendered file in an appropriate manner.

=item my $bool = _valid_language()

This command checks for valid langages.  Returns 1 if the language is valid,
0 if it is not.

=item column_heading()

Apply locale settings to column headings and add sort urls if necessary.

=item my $source = get_template_source($get_template)

Returns the Template source when common or call a specialized getter if not

=item my $arghash = get_template_args($extension)

Returns a hash with the default arguments for the Template and the
desired file extention

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

=back

=head1 Copyright 2007-2017, The LedgerSMB Core Team

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
use LedgerSMB::Mailer;
use LedgerSMB::Setting;
use LedgerSMB::Sysconfig;
use LedgerSMB::Template::DBProvider;

use Template::Parser;
use Log::Log4perl;
use File::Copy 'cp';
use File::Spec;
use HTTP::Status qw( HTTP_OK);
use Module::Runtime qw(use_module);
use Scalar::Util qw(reftype);
use Try::Tiny;

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
        for (qw( template format language no_escape debug locale method
                 format_options output_options no_auto_output
                 additional_vars ));
    $self->{myconfig} = $args{user};
    $self->{outputfile} =
        "${LedgerSMB::Sysconfig::tempdir}/$args{output_file}" if
        $args{output_file};
    $self->{include_path} = $args{path};
    $self->{method} ||= $args{media};
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

    my $dojo_theme = $LedgerSMB::App_State::Company_Config->{dojo_theme}
            if $LedgerSMB::App_State::Company_Config;
    my $UI_vars = {
        dojo_theme => $dojo_theme // $LedgerSMB::Sysconfig::dojo_theme,
        dojo_built => $LedgerSMB::Sysconfig::dojo_built,
        dojo_location => $LedgerSMB::Sysconfig::dojo_location,
    };

    return $class->new(
        @_,
        no_auto_ouput => 0,
        format => 'HTML' ,
        path => 'UI',
        user => $request->{_user},
        locale => $request->{_locale},
        additional_vars => $UI_vars
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
            $vars->{preprocess($_, $escape)} = preprocess( $rawvars->{$_}, $escape );
        }
    }
    # return undef for GLOB references (includes IO::File objects)
    return $vars;
}

sub get_template_source {
    my ($self, $format_extension) = @_;

    my $source;
    if ($self->{include_path} eq 'DB'){
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
    if ($self->{include_path} eq 'DB'){
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
    my $paths = [$self->{include_path},'templates/demo','UI/lib'];
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
        && $self->{include_path} ne 'DB') {
       # don't cache compiled database-retrieved templates
       # they will vary between databases
        $arghash->{COMPILE_EXT} = '.lttc';
        $arghash->{COMPILE_DIR} =
           File::Spec->rel2abs( $LedgerSMB::Sysconfig::templates_cache,
                                $LedgerSMB::Sysconfig::tempdir );
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
    $vars->{LIST_FORMATS} = sub { return $self->available_formats; };
    $vars->{ENVARS} = \%ENV;
    $vars->{USER} = $LedgerSMB::App_State::User;
    $vars->{USER} ||= {dateformat => 'yyyy-mm-dd'};
    $vars->{CSSDIR} = $LedgerSMB::Sysconfig::cssdir;
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
    $cleanvars->{escape} = sub { return $escape->(@_); };
    $cleanvars->{UNESCAPE} = sub { return $unescape->(@_); }
        if ($unescape && !$self->{no_escape});
    $cleanvars->{text} = sub { return $self->_maketext($escape, @_); };
    $cleanvars->{tt_url} = \&_tt_url;
    $cleanvars->{$_} = $self->{additional_vars}->{$_}
        for (keys %{$self->{additional_vars}});

    my $output;
    if ($self->{outputfile}) {
        $output = $self->{outputfile};
    } else {
        $output = \$self->{output};
    }

    my $config;
    ($output, $config) = $format->can('setup')->($self, $cleanvars, $output);

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

    if($self->{_no_postprocess}) {
        return undef;
    }
    $format->can('postprocess')->($self, $output, $config);
    return $self->{outputfile};
}

sub render {
    my $self = shift @_;
    my $vars = shift @_;

    my $post = $self->_render($vars);

    if (!$self->{no_auto_output}) {
        # Clean up
        $logger->debug('before self output');
        $self->output;
        $logger->debug('after self output');
        if ($self->{outputfile}) {
            unlink($self->{outputfile});
        }
    }

    return $post;
}

sub render_to_psgi {
    my $self = shift @_;
    my $vars = shift @_;
    my %args = ( @_ );

    $self->{outputfile} = undef;
    $self->_render($vars);

    my $charset = '';
    $charset = '; charset=utf-8'
        if $self->{mimetype} =~ m!^text/!;

    # $self->{mimetype} set by format
    my $headers = [
        'Content-Type' => "$self->{mimetype}$charset",
        (@{$args{extra_headers} // []})
        ];

    my $body;
    if ($self->{output}) {
        $body = $self->{output};
        utf8::encode($body)
            if utf8::is_utf8($body);
        $body = [ $body ];
        my $ext = lc($self->{format_options}{filetype} // $self->{format});
        push @$headers,
            ( 'Content-Disposition' =>
                  'attachment; filename="Report.' . $ext . '"'
            ) if $self->{format} && 'html' ne lc $self->{format};
    }
    elsif ($self->{outputfile}) {
        open $body, '<:raw', $self->{outputfile}
            or die "Failed to open rendered file $self->{outputfile} : $!";
        # as we don't support Windows anyway: unlinking an open file works!
        unlink $self->{outputfile};
    }

    return [ HTTP_OK, $headers, $body ];
}

sub output {
    my $self = shift;
    my %args = @_;

    for ( keys %args ) { $self->{output_options}->{$_} = $args{$_}; };

    my $method = $self->{method} || $args{method} || $args{media};
    $method = '' if !defined $method;

    if ('email' eq lc $method) {
        $self->_email_output;
    } elsif (defined $args{OUT} and $args{printmode} eq '>'){ # To file
        cp($self->{outputfile}, $args{OUT});
        return if 'zip' eq lc($method);
    } elsif ('print' eq lc $method) {
        $self->_lpr_output;
    } elsif (lc $method eq 'screen') {
        $self->_http_output;
    } elsif (defined $method and $method ne '' ) {
        $self->_lpr_output;
    } else {
        $self->_http_output;
    }
    return;
}

sub _http_output {
    my ($self) = @_;
    my $data = $self->{output};
    my $cache = 1; # default

    $logger->trace('Entering _http_output()');
    # the sub below is a performance optimization: we don't want to
    # concatenate the keys for every request when not logging.
    $logger->trace(sub {
        return 'output_options keys: ' . join '|', keys %{$self->{output_options}};
    });
    if ($LedgerSMB::App_State::DBH){
        # we have a db connection, so are logged in.
        # Let's see about caching.
        $cache = 0 if LedgerSMB::Setting->get('disable_back');
    }
    # clean up after getting the (last) setting
    LedgerSMB::App_State::cleanup();

    if (not defined $data and defined $self->{outputfile}) {
        local $/ = undef;
        open(my $fh, '<:bytes', $self->{outputfile}) or
            die 'Unable to open rendered file';
        $data = <$fh>;
        close($fh) or warn 'Unable to close rendered file';

        unlink($self->{outputfile}) or
            die 'Unable to delete output file';
    }

    my $disposition = '';
    my $name = $self->{output_options}{filename};
    if ($name) {
        $name =~ s#^.*/##;
        $disposition .= qq|\nContent-Disposition: attachment; filename="$name"|;
        $logger->debug("Adding disposition header: $disposition");
    }
    if (!$ENV{LSMB_NOHEAD}){
        if (!$cache){
            print "Cache-Control: no-store, no-cache, must-revalidate\n"
                . "Cache-Control: post-check=0, pre-check=0, false\n"
                . "Pragma: no-cache\n"
                or die 'Cannot print to STDOUT';
        }
        if ($self->{mimetype} =~ /^text/) {
            print "Content-Type: $self->{mimetype}; charset=utf-8$disposition\n\n"
                or die 'Cannot print to STDOUT';
        } else {
            print "Content-Type: $self->{mimetype}$disposition\n\n"
                or die 'Cannot print to STDOUT';
        }
    }
    binmode STDOUT, $self->{binmode};
    print $data or die 'Cannot print to STDOUT';
    # change global resource back asap
    binmode STDOUT, 'encoding(:UTF-8)';
    $logger->trace('end print to STDOUT');
    return;
}

sub _email_output {
    my $self = shift;
    my $args = $self->{output_options};
    my @mailmime;

    if (not $self->{outputfile} and not $args->{attach}) {
        $args->{message} .= $self->{output};
        @mailmime = ('contenttype', $self->{mimetype});
    }

    # User default for email from
    $args->{from} ||= $self->{user}->{email};

    # Default addresses
    my $csettings = $LedgerSMB::Company_Config::settings;
    $args->{from} ||= $csettings->{default_email_from};
    $args->{to} ||= $csettings->{default_email_to};
    $args->{cc} ||= $csettings->{default_email_cc};
    $args->{bcc} ||= $csettings->{default_email_bcc};


    # Mailer stuff
    my $mail = LedgerSMB::Mailer->new(
        from => $args->{from},
        to => $args->{to},
        cc => $args->{cc},
        bcc => $args->{bcc},
        subject => $args->{subject},
        notify => $args->{notify},
        message => $args->{message},
        @mailmime,
    );
    if ($args->{attach} or $self->{mimetype} !~ m#^text/# or $self->{outputfile}) {
        my @attachment;
        my $name = $args->{filename};

        if ($self->{outputfile}) {
            @attachment = ('file', $self->{outputfile});
        }
        else {
            @attachment = ('data', $self->{output});
        }

        $mail->attach(
            mimetype => $self->{mimetype},
            filename => $name,
            strip => $$,
            @attachment,
        );
    }
    $mail->send;
    return;
}

sub _lpr_output {
    my ($self, $in_args) = shift;
    my $args = $self->{output_options};
    if ($self->{format} ne 'LaTeX') {
        die 'Invalid Format';
    }
    my $lpr = $LedgerSMB::Sysconfig::printer{$args->{media}};

    open my $pipe, '|-', $lpr
        or die "Failed to open lpr pipe $lpr : $!";

    # Output is not defined here.  In the future we should consider
    # changing this to use the system command and hit the file as an arg.
    #  -- CT
    open my $file, '<', "$self->{outputfile}"
        or die "Failed to open rendered file $self->{outputfile} : $!";

    while (my $line = <$file>) {
        print $pipe $line or die "Cannot print to $lpr";
    }

    close $pipe or die "Cannot close pipe to $lpr";
    close $file or die "Cannot close file $self->{rendered}";
    return;
}

1;
