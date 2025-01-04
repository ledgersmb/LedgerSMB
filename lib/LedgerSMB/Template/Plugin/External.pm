
use v5.36;
use warnings;
use experimental 'try';

package LedgerSMB::Template::Plugin::External;

=head1 NAME

LedgerSMB::Template::Plugin::External - Template support module for LedgerSMB

=head1 DESCRIPTION

Runs an external command over an evaluated template to transform the textual
input into the rendered output (eg., PDF, SVG, PNG, etc.)

=head1 DETAILS


=cut

use File::Spec;
use File::Temp ();
use IPC::Open3;
use Log::Any;
use POSIX;

use Moo;

my $logger = Log::Any->get_logger(category => __PACKAGE__);

=head1 ATTRIBUTES

=head2 formats

Holds an array of strings naming the formats supported by this plugin.

=cut

has formats => (is => 'ro', required => 1);

=head2 format

Holds a string naming the actual format for which this plugin
is configured. The plugin can be used multiple times with different
formats, as long as they are in the list of formats.

=cut

has format => (is => 'ro', required => 1);

=head2 binmode

=cut

has binmode => (is => 'ro', default => ':UTF-8');

=head2 command

The command to run. The command can have 3 placeholders:

=over 8

=item C<%d>

The (temporary) directory to do all processing

=item C<%f>

The input file containing the evaluated template

=item C<%o>

The file from which output will be read

=item C<%%>

A literal percent-sign

=back

=cut

has command => (is => 'ro', required => 1);

=head2 cleanup

Defaults to C<1>.

Set to C<0> or C<''> to prevent removal of the temporary working directory

=cut

has cleanup => (is => 'ro', default => 1);

=head2 input_extension

Extension of the file holding the template input.

Serves to identify which input template to select.

=cut

has input_extension => (is => 'ro', required => 1);

=head2 mime_type

The mime type to use to serve the resulting file.

=cut

has mime_type => (is => 'ro', required => 1);

=head2 rendered_template_name (Optional)

Name of the file to store the evaluated template in.

=cut

has rendered_template_name => (is => 'ro', default => 'template-output.txt');

=head2 rendered_output_name (Optional)

Name of the file used by the external process to store its result in.

The plugin will read the content to return it as its result.

=cut

has rendered_output_name => (is => 'ro', default => 'output.bin');

=head1 METHODS

=head2 setup($parent, $cleanvars, $output)

Implements the template's initialization protocol.

=cut

sub setup {
    my ($self, $parent, $cleanvars, $output) = @_;

    my (undef, undef, $base) =
        File::Spec->splitpath( $self->rendered_template_name );
    my $dir = File::Temp->newdir( UNLINK => $self->cleanup );
    my $render_input = File::Spec->catfile( $dir->dirname, $base );
    open( my $fh, '>', $render_input )
        or die "Can't open template output file: $!";
    return ($fh, {
        binmode         => $self->binmode,
        input_extension => $self->input_extension,
        _dir            => $dir,
        _format         => lc $self->format,
        _output         => $output,
        _render_input   => $render_input,
   });
}

=head2 postprocess($parent, $output, $config)

Implements the template's post-processing protocol.

=cut

sub postprocess {
    my ($self, $parent, $output, $config) = @_;

    my $dir = $config->{_dir}->dirname;
    my $cmd = $self->command;

    my (undef, undef, $base) =
        File::Spec->splitpath( $self->rendered_output_name );
    my $render_output = File::Spec->catfile( $dir, $base );
    my %replacements = (
        '%%' => '%',
        '%d' => $dir,
        '%f' => $config->{_render_input},
        '%o' => $render_output
        );
    $cmd =~ s/(%[%dfo])/$replacements{$1}/g;

    open my $out, '>', File::Spec->catfile( $dir, 'output.log' )
        or die "Unable to open output log for template plugin: $!";
    open my $err, '>', File::Spec->catfile( $dir, 'error.log' )
        or die "Unable to open error log for template plugin: $!";
    my $script = File::Temp->new( DIR => $dir );
    my $script_name = $script->filename;
    print $script $cmd;
    close $script
        or warn "Unable to close generated rendering script: $!";

    my $pid = open3( my $chld_in, $out, $err, '/bin/sh ' . $script_name )
        or die "Error rendering: $!";
    close $chld_in
        or warn "Unable to close template renderer stdin: $!";

    waitpid $pid, 0;
    my $exitcode = ($? >> 8);
    die "External template renderer ($cmd) failed; exit code: $exitcode"
        unless $exitcode == 0;

    open my $res, '<', File::Spec->catfile( $dir, $self->rendered_output_name )
        or die "Unable to read template processor output: $!";
    $config->{_output}->$* = do { local $/ = undef; binmode $res, ':raw'; <$res> };

    return undef;
}

=head2 mimetype()

Returns the rendered template's mimetype.

=cut

sub mimetype {
    my $self = shift;
    return $self->mime_type;
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007-2024 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
