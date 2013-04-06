=head1 NAME

LedgerSMB::X12 - Base Class for LedgerSMB X12 handling 

=head1 SYNOPSIS

Not used directly, only by subclasses

However the API expected to be used by a subclass is:

  my $edi945 = LedgerSMB::X12::EDI945->new({message => $string});
  my @shipments = $edi945->shipments
  for my $ship(@shipments){
     ...
  }

=head1 DESCRIPTION

This module is the basis for EDI file parsing in LedgerSMB.  Although X12 is
a very large spec, this only implements the portions of
character-separated-value formatted EDI files that are needed at present.  XML
files would need to go through another interface.

This application relies on X12::Parser and includes some extra configuration
files, namely 850.cf and 895.cf.  Separators for segments and elements is 
supported by X12::Parser.

=cut

package LedgerSMB::X12;
use Moose;
use X12::Parser;
use LedgerSMB::Sysconfig;

=head1 REQUIRED PROPERTIES FOR PARSING

=head2 message

This is the textual message of the EDI file to be processed.  This is only
required if parsing, as running the builders with no message will generate
errors.  Note that interfaces other than parsing do not require instantiation 
of the object externally....

Note that if message is shorter than 180 chars long, if it does not start with 
"ISA" and if it contains slashes or ends in /\.\w{3}/, it will be seen as a 
path to a file, but if it is 180 chars or longer, if it does not start with 
'ISA' or if it does not end in a . followed by a three letter/number extension,
it will be seen as the message text itself.  This can be overridden by setting
the read_file property explicitly below.

=cut

has message => (is => 'ro', isa => 'Str', required => 1);

=head2 config_file

This is the path to the cf file for setting up loop hierarchies.

=cut

has config_file  => (is => 'ro', isa => 'Str', lazy => 1, builder => '_config');

sub _config {
    die 'cannot call builder here!';
}

=head2 read_file bool

If this is set, override the auto detection of the message file.  If true, this
is a file to be read, if false, it is a message, and if not provided, we
autodetect.

=cut

has read_file => (is => 'ro', isa => 'Bool', predicate => 'has_read_file',
            required => 0);

=head2 parser X12::Parser

This is the parser, automatically generated via builder.

=cut

has parser => (is => 'ro', isa => 'X12::Parser', lazy => 1, builder => '_parser');

=item ISA

This is the exchange security and routing information header.

=cut

has ISA => (is => 'ro', isa => 'HashRef[Any]', lazy => 1, builder => '_ISA');

sub _ISA {
    my ($self) = @_;
    my @segments = $self->parser->get_loop_segments;
    @segments = $self->parser->get_loop_segments unless @segments;
    if ($segments[0] != 'ISA'){
        $self->parse;  # re-initialize parser, we don't have an ISA!
        die 'No ISA'; # Trappable error.
    }

    my $isa = {};

    my @keys;
    
    push @keys, sprintf('ISA%02d', $_) for (1 .. 16);

    for my $key (@keys){
       $isa->{$key} = shift @segments;
    }
    return $isa;
}


=head1 METHODS

=over

=item is_message_file

Returns 1 if message is a file, 0 or undef if message is not a file, and dies 
on error.

=cut

sub is_message_file {
    my ($self) = @_;
    return $self->read_file if $self->has_read_file;

    if (length($self->message) > 180 
        or ($self->message !~ /\.\w{3}$/ and $self->message !~ /\//)
    ){
       return 0;
    };
    return 1;
}

=item parse()

This function sets up the basic parser and runs it.  It is the builder for
$self->parser.

=cut

sub _parser {
    my ($self) = @_;
    my $parser = new X12::Parser;
    my $file = $self->message;
    return $parser;
}

sub parse {
    my ($self) = @_;
    my $file;
    my $parser = $self->parser;
    if (!$self->is_message_file){
        $file = $LedgerSMB::Sysconfig::tempdir . '/' . $$ . '-' . $self->message;
        open TMPFILE, '>', $file;
        print TMPFILE $self->message;
        close TMPFILE;
    } else {
        $file = $self->message;
    }
    $parser->parsefile( file => $file,
                        conf => $self->config_file);
    return $parser;
}

=item set_segment_sep(char $sep)

In certain cases, people have been known to generate EDI files using illegal 
characters as separators, or otherwise have EDI files where the parser cannot 
properly define the segment separator (the element separator poses no such 
problems).

In these cases one needs to set it manually.  Use this function to do this.

=cut

sub set_segement_sep {
    my ($self, $sep) = @_;
    # ick, ai don't like how this involves messing around with internals.
    $self->parser->{_SEGMENT_SEPARATOR} = $sep;
}

=back

=head1 COPYRIGHT

Copyright (C) 2013 The LedgerSMB Core Team.  This file may be re-used under the
terms of the GNU General Public License version 2 or at your option any later
version.  Please see included LICENSE.txt file for details.

=cut

__PACKAGE__->meta->make_immutable;
