=head1 NAME

LedgerSMB::Template::DB - Template administration functions for LedgerSMB

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

=head1 METHODS

=head1 COPYRIGHT

Copyright (C) 2014 The LedgerSMB Core Team

This file may be re-used under the terms of the GNU General Public License 
version 2 or at your option any later version.  Please see the included 
LICENSE.txt for details.

=cut

__PACKAGE__->meta->make_immutable;
