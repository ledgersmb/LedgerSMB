=head1 NAME

LedgerSMB::Template::DB - Template administration functions for LedgerSMB

=cut

package LedgerSMB::Template::DB;
use Moose;
with 'LedgerSMB::DBObject_Moose';

=head1 SYNPOPSIS

To retrieve template data as a scalar ref (for TT):

   LedgerSMB::Template::DB->get_template($template_name, $language_code);

To retrieve for editing:

   LedgerSMB::Template::DB->get_by_id($id);

or

   LedgerSMB::Template::DB->get(
           template_name => $template_name, language_code => $language_code
   );

To save:

   my $template =  LedgerSMB::Template::DB->new(%$request);
   $template->save;

=head1 PROPERTIES

=head2 id int

=head2 template_name text (required)

=head2 language_code text

=head2 template text (required)

=head2 format text (required)

=cut

has id             => (is => 'ro', isa => 'Int', required => 0);
has template_name  => (is => 'ro', isa => 'Str', required => 1);
has language_code  => (is => 'ro', isa => 'Str', required => 0);
has format         => (is => 'ro', isa => 'Str', required => 1);
has template       => (is => 'ro', isa => 'Str', required => 1);

=head1 METHODS

=head2 get_template(template_name, language_code, format)

Returns a scalar ref to the template text so that Template Toolkit can run it.

=cut

sub get_template {
    my ($module, $template_name, $language_code, $format) = @_;
    my ($temp) = __PACKAGE__->call_procedure(
         procname => 'template__get',
         args => [$template_name, $language_code, $format]
    );
    my $text = $temp->{template};
    return \$text;
}

=head2 get_by_id(id)

Gets the template by ID.  Returns a whole template object.

=cut

sub get_by_id {
    my ($module, $id) = @_;
    my ($temp) = __PACKAGE__->call_procedure(
         procname => 'template__get_by_id',
         args => [$id]
    );
    return __PACKAGE__->new(%$temp);
}


=head2 get(hash args)

Gets the template by args (for editing or management).  Args are:

=over

=item template_name

=item language_code

=item format

=back

=cut

sub get {
    my $module = shift @_;
    my %args = @_;
    my ($temp) = __PACKAGE__->call_procedure(
         procname => 'template__get',
         args => [$args{template_name}, $args{language_code}, $args{format}]
    );
    return __PACKAGE__->new(%$temp);
}

=head2 save

Saves the current object

=cut

sub save {
    my ($self) = @_;
    $self->exec_method(funcname => 'template__save');
}

=head1 COPYRIGHT

Copyright (C) 2014 The LedgerSMB Core Team

This file may be re-used under the terms of the GNU General Public License 
version 2 or at your option any later version.  Please see the included 
LICENSE.txt for details.

=cut

__PACKAGE__->meta->make_immutable;
