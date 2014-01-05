=head1 NAME

LedgerSMB::Scripts::template - Template editing workflows for LedgerSMB

=cut

package LedgerSMB::Scripts::template;
use LedgerSMB::Template::DB;
use LedgerSMB::Report::Listings::Templates;
use LedgerSMB::Template;

=head1 SYNPOSIS

To display the edit screen

   LedgerSMB::Scripts::template::display($request)

To edit:

   LedgerSMB::Scripts::template::edit($request)

=head1 FUNCTIONS

=head2 list($request)

Lists the templates.

=cut

sub list {
    my ($request) = @_;
    LedgerSMB::Report::Listing::Templates->new(%$request)->render($request);
}

=head2 display($request)

Displays a template for review

=cut

sub display {
    my ($request) = @_;
    my $dbtemp = LedgerSMB::Template::DB->get(%$request);
    $dbtemp->{content} = $dbtemp->template;
    LedgerSMB::Template->new(
        user     => $request->{_user},
        locale   => $request->{_locale},
        path     => 'UI/templates',
        template => 'preview',
        format   => 'HTML'
    )->render($dbtemp);
}

=head2 edit($request)

Displays a screen for editing the template

=cut

sub edit {
    my ($request) = @_;
    my $dbtemp = LedgerSMB::Template::DB->get(%$request);
    $dbtemp->{content} = $dbtemp->template;
    LedgerSMB::Template->new(
        user     => $request->{_user},
        locale   => $request->{_locale},
        path     => 'UI/templates',
        template => 'edit',
        format   => 'HTML'
    )->render($dbtemp);
}

=head2 save($request)

Saves the template.

=cut

sub save {
    my ($request) = @_;
    my $dbtemp = LedgerSMB::Template::DB->get(%$request);
    $dbtemp->save();
    display($request);
}

=head1 COPYRIGHT

Copyright (C) 2014 The LedgerSMB Core Team.

This file may be re-used under the terms of the GNU General Public License 
version 2 or at your option any later version.  Please see the included 
LICENSE.txt for details.

=cut

1;
