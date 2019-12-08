
package LedgerSMB::Scripts::template;

=head1 NAME

LedgerSMB::Scripts::template - Template editing workflows for LedgerSMB

=head1 DESCRIPTION

Entry points for uploading, listing, saving and editing document templates.

=head1 SYNPOSIS

To display the edit screen1

   LedgerSMB::Scripts::template::display($request)

To edit:

   LedgerSMB::Scripts::template::edit($request)

=cut

use strict;
use warnings;

use LedgerSMB;
use LedgerSMB::Report::Listings::Templates;
use LedgerSMB::Template;
use LedgerSMB::Template::DB;
use LedgerSMB::Template::UI;

=head1 METHODS

This module doesn't specify any methods.

=head1 FUNCTIONS

=head2 list($request)

Lists the templates.

=cut

sub list {
    my ($request) = @_;
    return LedgerSMB::Report::Listings::Templates->new(%$request)
        ->render($request);
}

=head2 display($request)

Displays a template for review

=cut

sub display {
    my ($request) = @_;
    my $dbtemp;
    local $@ = undef;
    eval {$dbtemp = LedgerSMB::Template::DB->get(%$request)};

    $dbtemp->{content} = $dbtemp->template if defined $dbtemp;
    $dbtemp = $request unless $dbtemp->{format};
    $dbtemp->{languages} =
        [ $request->call_procedure(funcname => 'person__list_languages') ];
    return LedgerSMB::Template::UI->new_UI
        ->render($request, 'templates/preview', { request => $request,
                                                  template => $dbtemp,
                                                  %$dbtemp });
}

=head2 edit($request)

Displays a screen for editing the template

=cut

sub edit {
    my ($request) = @_;
    my $dbtemp;

    local $@ = undef;
    $dbtemp = eval { LedgerSMB::Template::DB->get(%$request) } ;
    delete $request->{language_code}
        unless $dbtemp;
    $dbtemp = eval { LedgerSMB::Template::DB->get(%$request) }
        unless $dbtemp;

    die $request->{_locale}->text('Template Not Found')
       unless $dbtemp;
    $dbtemp->{content} = $dbtemp->template;
    $dbtemp = $request unless $dbtemp->{format};
    $dbtemp->{languages} =
        [ $request->call_procedure(funcname => 'person__list_languages') ];

    return LedgerSMB::Template::UI->new_UI
        ->render($request, 'templates/edit', { request => $request,
                                               to_edit => $dbtemp });
}

=head2 save($request)

Saves the template.

=cut

sub save {
    my ($request) = @_;
    my $dbtemp = LedgerSMB::Template::DB->new(%$request);
    $dbtemp->save();
    return display($request);
}

=head2 upload($request)

Sends the file as an upload.  The template_name and format must match before it
will be accepted.

=cut

sub upload {
    my ($request) = @_;

    my $upload = $request->{_uploads}->{template_file}
        or die 'No template file uploaded';

    # Slurp uploaded file
    open my $fh, '<', $upload->path or die "Error opening uploaded file $!";
    local $/ = undef;
    my $fdata = <$fh>;

    # Sanity check that browser-provided local name of uploaded file matches
    # the template name and extension. Is this appropriate/necessary?
    die 'No content' unless $fdata;
    my $testname = $request->{template_name} . '.' . $request->{format};
    die $request->{_locale}->text(
                'Unexpected file name, expected [_1], got [_2]',
                 $testname, $upload->basename)
          unless $upload->basename eq $testname;
    $request->{template} = $fdata;
    my $dbtemp = LedgerSMB::Template::DB->new(%$request);
    $dbtemp->save();

    return display($request);
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014-2018 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
