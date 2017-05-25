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

The template to be processed.  This can either be a reference to the template
in string form or the name of the file that is the template to be processed.

=item format

The format to be used.  Currently HTML, PS, PDF, TXT and CSV are supported.

=item format_options (optional)

A hash of format-specific options.  See the appropriate LSMB::T::foo for
details.

=item output_options (optional)

A hash of output-specific options.  See the appropriate output method for
details.

=item locale (optional)

The locale object to use for regular gettext lookups.  Having this option adds
the text function to the usable list for the templates.  Has no effect on the
gettext function.

=item language (optional)

The language for template selection.

=item include_path (optional)

Overrides the template directory.  Used with user interface templates.

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

=item new_UI(user => \%myconfig, locale => $locale, template => $file, ...)

Wrapper around the constructor that sets the path to 'UI', format to 'HTML',
and leaves auto-output enabled.

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

=item escape($string)

Escapes a scalar string if the format supports such escaping and returns the
sanitized version.

=item my $source = get_template_source($get_template)

Returns the Template source when common or call a specialized getter if not

=item my $arghash = get_template_args($extension)

Returns a hash with the default arguments for the Template and the
desired file extention

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
use Log::Log4perl;
use File::Copy "cp";
use File::Spec;
use Module::Runtime qw(use_module);

my $logger = Log::Log4perl->get_logger('LedgerSMB::Template');

sub available_formats {
    my @retval = ('HTML', 'TXT');
    local ($@);
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
    my $self = {};
    my %args = @_;

    $self->{myconfig} = $args{user};
    $self->{template} = $args{template};
    $self->{format} = $args{format};
    $self->{language} = $args{language};
    $self->{no_escape} = $args{no_escape};
    $self->{debug} = $args{debug};
    $self->{binmode} = undef;
    $self->{outputfile} =
        "${LedgerSMB::Sysconfig::tempdir}/$args{output_file}" if
        $args{output_file};
    $self->{include_path} = $args{path};
    $self->{locale} = $args{locale};
    $self->{noauto} = $args{no_auto_output};
    $self->{method} = $args{method};
    $self->{method} ||= $args{media};
    $self->{format_args} = $args{format_options};
    $self->{output_args} = $args{output_options};
    if ($self->{language}){ # Language takes precedence over locale
        $self->{locale} = LedgerSMB::Locale->get_handle($self->{language});
    }

    if (lc $self->{format} eq 'pdf') {
        $self->{format} = 'LaTeX';
        $self->{format_args}{filetype} = 'pdf';
    } elsif (lc $self->{format} eq 'ps' or lc $self->{format} eq 'postscript') {
        $self->{format} = 'LaTeX';
        $self->{format_args}{filetype} = 'ps';
    } elsif (lc $self->{format} eq 'xlsx'){
        $self->{format} = 'XLSX';
        $self->{format_args}{filetype} = 'xlsx';
    } elsif (lc $self->{format} eq 'XML'){
        $self->{format} = 'XML';
        $self->{format_args}{filetype} = 'xml';
    } elsif ($self->{format} =~ /edi$/i){
        $self->{format_args}{extension} = lc $self->{format};
        $self->{format} = 'TXT';
    }
    bless $self, $class;

    if ($self->{format} !~ /^\p{IsAlnum}+$/) {
        die "Invalid format";
    }
    if (!$self->{include_path}){
        $self->{include_path} = $self->{'myconfig'}->{'templates'};
        $self->{include_path} ||= 'templates/demo';
        if (defined $self->{language}){
            if (!$self->_valid_language){
                die 'Invalid language';
            }
            $self->{include_path_lang} = "$self->{'include_path'}"
                    ."/$self->{language}";
            $self->{locale} = LedgerSMB::Locale->get_handle(
                $self->{language}
            );
        }
    }

    return $self;
}

sub new_UI {
    my $class = shift;
    return $class->new(@_, no_auto_ouput => 0, format => 'HTML', path => 'UI');
}

sub _valid_language {
    my $self = shift;
    if ($self->{language} =~ m#(/|\\|:|\.\.|^\.)#){
        return 0;
    }
    return 1;
}

sub _preprocess {
    my ($rawvars, $escape) = @_;
    return undef unless defined $rawvars;

    local ($@);
    if (eval {$rawvars->can('to_output')}){
        $rawvars = $rawvars->to_output;
    }
    my $type = ref $rawvars;
    return $rawvars if $type =~ /^LedgerSMB::Locale/;

    my $vars;
    if ( $type eq 'ARRAY' ) {
        $vars = [];
        for (@{$rawvars}) {
            push @{$vars}, _preprocess( $_, $escape );
        }
    } elsif (!$type) {
        return defined($escape) ? &$escape($rawvars) : $rawvars;
    } elsif ($type eq 'SCALAR' or $type eq 'Math::BigInt::GMP') {
        return defined($escape) ? &$escape($$rawvars) : $$rawvars;
    } elsif ($type eq 'CODE'){ # a code reference makes no sense
        return $rawvars;
    } elsif ($type eq 'IO::File'){
        return undef;
    } else { # Hashes and objects
        $vars = {};
        for ( keys %{$rawvars} ) {
            # don't encode the object's internals; TT won't forward anyway...
            # btw, some (internal) objects are XS objects, on which this trick
            # treating it as a hashref really doesn't work...
            next if /^_/;
            $vars->{_preprocess($_, $escape)} = _preprocess( $rawvars->{$_}, $escape );
        }
    }
    return $vars;
}

sub get_template_source {
    my $self = shift;
    my $get_template = shift;

    my $source;
    if ($self->{include_path} eq 'DB'){
        $source = $self->{template};
    } elsif (ref $self->{template} eq 'SCALAR') {
        $source = $self->{template};
    } elsif (ref $self->{template} eq 'ARRAY') {
        $source = join "\n", @{$self->{template}};
    } elsif (defined $get_template) {
        $source = $get_template->($self->{template});
    } else {
        $source = undef;
    }
    return $source;
}

sub get_template_args {
    my $self = shift;
    my $extension = shift;
    my $binmode = shift;
    my $trim = shift // 0;

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
        START_TAG => quotemeta('<?lsmb'),
        END_TAG => quotemeta('?>'),
        DELIMITER => ';',
        TRIM => $trim,
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

sub _render {
    my $self = shift;
    my $vars = shift;
    $vars->{LIST_FORMATS} = sub { return $self->available_formats} ;
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
    $vars->{LETTERHEAD} = sub { $self->_include('letterhead', $vars) };
    my @stdformats = ();
    for (qw(HTML PDF PS)){
       if (scalar(grep {/^$_$/} $self->available_formats)){
           push @stdformats, $_;
       }
    }
    $vars->{STDFORMATS} = \@stdformats;
    { # pre-5.14 compatibility block
        local ($@); # pre-5.14, do not die() in this block
        eval {
            $vars->{PRINTERS} = [
                {text => $LedgerSMB::App_State::Locale->text('Screen'),
                 value => 'screen'},
                ];
        };
    }
    for (keys %LedgerSMB::Sysconfig::printers){
        push @{$vars->{PRINTERS}}, { text => $_, value => $_ };
    }

    if ($self->{format} !~ /^\p{IsAlnum}+$/) {
        die "Invalid format";
    }

    my $format = "LedgerSMB::Template::$self->{format}";
    use_module($format) or die "Failed to load module $format";

    my $cleanvars;
    if ($self->{no_escape}) {
        carp 'no_escape mode enabled in rendering';
        $cleanvars = $vars;
    } else {
        $cleanvars = $format->can('preprocess')->($vars);
    }
    $cleanvars->{escape} = sub { return $format->escape(@_)};
    if (UNIVERSAL::isa($self->{locale}, 'LedgerSMB::Locale')){
        $cleanvars->{text} = sub {
                    return $self->escape($self->{locale}->maketext(@_))
                        if defined $_[0]};
    }
    else {
        $cleanvars->{text} = sub { return $self->escape(shift @_) };
    }
    $cleanvars->{tt_url} = sub {
           my $str  = shift @_;

           my $regex = qr/([^a-zA-Z0-9_.-])/;
           $str =~ s/$regex/sprintf("%%%02x", ord($1))/ge;
           return $str;
    };

    $format->can('process')->($self, $cleanvars);

    # Will return undef if postprocessing if disabled -YL
    if($self->{_no_postprocess}) {
        return undef;
    }

    return $format->can('postprocess')->($self);
}

sub render {
    my $self = shift @_;
    my $vars = shift @_;

    my $post = $self->_render($vars);

    if (!$self->{'noauto'}) {
        # Clean up
        $logger->debug("before self output");
        $self->output(%$vars);
        $logger->debug("after self output");
        if ($self->{rendered}) {
            unlink($self->{rendered});
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

    push @$headers, (
        'Cache-Control' =>
          'no-store, no-cache, must-revalidate, post-check=0, pre-check=0, false',
        'Pragma' => 'no-cache'
    ) if ($LedgerSMB::App_State::DBH && LedgerSMB::Setting->get('disable_back'));

    my $body;
    if ($self->{output}) {
        $body = $self->{output};
        utf8::encode($body)
            if utf8::is_utf8($body);
        $body = [ $body ];
        push @$headers,
            ( 'Content-Disposition' =>
                  'attachment; filename="Report.' .
                                lc($self->{format}) . '"'
            ) if $self->{format} && 'html' ne lc $self->{format};
    }
    elsif ($self->{rendered}) {
        open $body, '<:raw', $self->{rendered}
            or die "Failed to open rendered file $self->{rendered} : $!";
        # as we don't support Windows anyway: unlinking an open file works!
        unlink $self->{rendered};
    }

    return [ 200, $headers, $body ];
}

sub escape {
    my ($self, $vars) = @_;
    my $format = "LedgerSMB::Template::$self->{format}";
    if ($format->can('escape')){
         return $format->can('escape')->($vars);
    } else {
         return $vars;
    }
}

sub output {
    my $self = shift;
    my %args = @_;

    for ( keys %args ) { $self->{output_args}->{$_} = $args{$_}; };

    my $method = $self->{method} || $args{method} || $args{media};
    $method = '' if !defined $method;

    if ('email' eq lc $method) {
        $self->_email_output;
    } elsif (defined $args{OUT} and $args{printmode} eq '>'){ # To file
        cp($self->{rendered}, $args{OUT});
        return if "zip" eq lc($method);
    } elsif ('print' eq lc $method) {
        $self->_lpr_output;
    } elsif (defined $self->{output} or lc $method eq 'screen') {
        $self->_http_output;
    } elsif (defined $method and $method ne '' ) {
        $self->_lpr_output;
    } else {
        $self->_http_output_file;
    }
    return;
}

sub _http_output {
    my ($self, $data) = @_;
    LedgerSMB::App_State::cleanup();
    $data ||= $self->{output};
    my $cache = 1; # default
    if ($LedgerSMB::App_State::DBH){
        # we have a db connection, so are logged in.
        # Let's see about caching.
        $cache = 0 if LedgerSMB::Setting->get('disable_back');
    }

    if ($self->{format} !~ /^\p{IsAlnum}+$/) {
        die "Invalid format";
    }
    if (!defined $data and defined $self->{rendered}){
        $data = "";
        $logger->trace("begin DATA < self->{rendered}=$self->{rendered} \$self->{format}=$self->{format}");
        open my $fh, '<', $self->{rendered}
            or die "failed to open rendered file $self->{rendered} : $!";
        binmode $fh, $self->{binmode};
        while (my $line = <$fh>){
            $data .= $line;
        }
        close $fh;
        $logger->trace("end DATA < self->{rendered}");
        unlink($self->{rendered}) or die 'Unable to delete output file';
    }

    my $format = "LedgerSMB::Template::$self->{format}";
    my $disposition = "";
    my $name;
    $name = $format->can('postprocess')->($self) if $format->can('postprocess');
    $name ||= $self->{rendered};
    if ($name) {
        $name =~ s#^.*/##;
        $disposition .= qq|\nContent-Disposition: attachment; filename="$name"|;
    }
    if (!$ENV{LSMB_NOHEAD}){
        if (!$cache){
            print "Cache-Control: no-store, no-cache, must-revalidate\n";
            print "Cache-Control: post-check=0, pre-check=0, false\n";
            print "Pragma: no-cache\n";
        }
        if ($self->{mimetype} =~ /^text/) {
            print "Content-Type: $self->{mimetype}; charset=utf-8$disposition\n\n";
        } else {
            print "Content-Type: $self->{mimetype}$disposition\n\n";
        }
    }
    binmode STDOUT, $self->{binmode};
    print $data;
    # change global resource back asap
    binmode (STDOUT, ':utf8');
    $logger->trace("end print to STDOUT");
    return;
}

sub _http_output_file {
    my $self = shift;
        LedgerSMB::App_State::cleanup();
    my $FH;

    open($FH, '<:bytes', $self->{rendered}) or
        die 'Unable to open rendered file';
    my $data;
    {
        local $/;
        $data = <$FH>;
    }
    close($FH);

    $self->_http_output($data);

    unlink($self->{rendered}) or
        die 'Unable to delete output file';

    return;
}

sub _email_output {
    my $self = shift;
    my $args = $self->{output_args};

    my @mailmime;
    if (!$self->{rendered} and !$args->{attach}) {
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
    if ($args->{attach} or $self->{mimetype} !~ m#^text/# or $self->{rendered}) {
        my @attachment;
        my $name = $args->{filename};

        if ($self->{rendered}) {
            @attachment = ('file', $self->{rendered});
            $name ||= $self->{rendered};
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
    my $args = $self->{output_args};
    if ($self->{format} ne 'LaTeX') {
        die "Invalid Format";
    }
    my $lpr = $LedgerSMB::Sysconfig::printer{$args->{media}};

    open my $pipe, '|-', $lpr
        or die "Failed to open lpr pipe $lpr : $!";

    # Output is not defined here.  In the future we should consider
    # changing this to use the system command and hit the file as an arg.
    #  -- CT
    open my $file, '<', "$self->{rendered}"
        or die "Failed to open rendered file $self->{rendered} : $!";

    while (my $line = <$file>) {
        print $pipe $line;
    }

    close $pipe;
    close $file;
    return;
}

# apply locale settings to column headings and add sort urls if necessary.
sub column_heading {

    my $self = shift;
    my ($names, $sortby) = @_;
    my %sorturls;

    if ($sortby) {
        %sorturls = map
        { $_ => $sortby->{href}."=$_"} @{$sortby->{columns}};
    }

    foreach my $attname (keys %$names) {

        # process 2 cases - simple name => value, and complex name => hash
        # pairs. The latter is used to include urls in column headers.

        if (ref $names->{$attname} eq 'HASH') {
            my $t = $self->{locale}->maketext($names->{$attname}{text});
            $names->{$attname}{text} = $t;
        } else {
            my $t = $self->{locale}->maketext($names->{$attname});
            if (defined $sorturls{$attname}) {
                $names->{$attname} =
                {
                    text => $t,
                     href => $sorturls{$attname}
                };
            } else {
                $names->{$attname} = $t;
            }
        }
    }

    return $names;
}

1;
