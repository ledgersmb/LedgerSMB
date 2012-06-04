=head1 NAME

LedgerSMB::DBObject::Report::Contact::Search - Search for Customers, Vendors,
and more.

=head1 SYNPOSIS

  my $report = LedgerSMB::DBObject::Report::GL->new(%$request);
  $report->run;
  $report->render($request, $format);

=head1 DESCRIPTION

This report provides contact search facilities.  It can be used to search for
any sort of company or person, whether sales lead, vendor, customer, or
referral.

=head1 INHERITS

=over

=item LedgerSMB::DBObject::Report;

=back

=cut

package LedgerSMB::DBObject::Report::Contact::Search;
use Moose;
extends 'LedgerSMB::DBObject::Report';
use LedgerSMB::App_State;
use LedgerSMB::PGDate;

my $locale = $LedgerSMB::App_State::Locale;

=head1 PROPERTIES

=over

=item columns

Read-only accessor, returns a list of columns.

=over

=back

=cut

sub columns {
    my ($self) = @_;
    my $script = 'contacts.pl';

    return [
       {col_id => 'name',
            type => 'text',
            name => $locale->text('Name') },

       {col_id => 'entity_control_code',
            type => 'href',
       href_base =>"contact.pl?action=get&entity_class=".$self->entity_class,
            name => $locale->text('Control Code') },

       {col_id => 'meta_number',
            type => 'href',
       href_base =>"contact.pl?action=get&entity_class=".$self->entity_class,
            name => $locale->text('Credit Account Number') },

       {col_id => 'credit_description',
            type => 'text',
            name => $locale->text('Description') },

       {col_id => 'business_type',
            type => 'text',
            name => $locale->text('Business Type') },

       {col_id => 'curr',
            type => 'text',
            name => $locale->text('Currency') },
    ];
}

=item name

=cut

sub name { return $locale->text('Contact Search') }

=item header_lines

=cut

sub header_lines {
     return []; # TODO
}

=back

=head1 CRITERIA PROPERTIES

=over

=item entity_class

The account/entity class of the contact.  Required and an exact match.

=cut

has entity_class => (is => 'ro', isa => 'Int');

=item name_part

Full text search on contact name.

=cut

has name_part => (is => 'ro', isa => 'Maybe[Str]');

=item control_code

Matches the beginning of the control code string

=cut

has control_code => (is => 'ro', isa => 'Maybe[Str]');

=item contact_info 

Aggregated from email, phone, fax, etc.  Aggregated by this report (internal).

=cut

has contact_info => (is => 'ro', isa => 'Maybe[ArrayRef[Str]]');

=item email

Email address, exact match on any email address.

=cut

has email => (is => 'ro', isa => 'Maybe[Str]');

=item phone

Exact match on phone any phone number, fax, etc.

=cut

has phone => (is => 'ro', isa => 'Maybe[Str]');

=item meta_number

Matches beginning of customer/vendor/etc. number.

=cut

has meta_number => (is => 'ro', isa => 'Maybe[Str]');

=item address

Full text search (fully matching) on any address line.

=cut

has address => (is => 'ro', isa => 'Maybe[Str]');

=item city

Exact match on city

=cut

has city => (is => 'ro', isa => 'Maybe[Str]');

=item state

Exact match on state/province

=cut

has state => (is => 'ro', isa => 'Maybe[Str]');

=item mail_code

Match on beginning of mail or post code

=cut

has mail_code => (is => 'ro', isa => 'Maybe[Str]');

=item country

Full or short name of country (i.e. US or United States, or CA or Canada).

=cut

has country => (is => 'ro', isa => 'Maybe[Str]'); 

=item active_date_from

Active items only from this date.

=item active_date_to

Active items only to this date.

=cut

has active_date_from => (is => 'ro', isa => 'Maybe[LedgerSMB::PgDate]');   
has active_date_to => (is => 'ro', isa => 'Maybe[LedgerSMB::PGDate]');

=back

=head1 METHODS

=over 

=item prepare_criteria

Converts inputs to PgDate where needed

=cut

sub prepare_criteria {
    my ($self, $request) = @_;
    $request->{active_date_from} = LedgerSMB::PGDate->from_input(
               $request->{active_date_from}
    );
    $request->{active_date_to} = LedgerSMB::PGDate->from_input(
               $request->{active_date_to}
    );
}

=item run_report

Runs the report, populates rows.

=cut

sub run_report {
    my ($self) = @_;
    my @rows = $self->exec_method({funcname => 'contact__search'});
    for my $r(@rows){
        $r->{meta_number_href_suffix} = 
               "&entity_id=$r->{entity_id}&meta_number=$r->{meta_number}";
        $r->{entity_control_code_href_suffix} = $r->{meta_number_href_suffix};
    }
    $self->rows(\@rows);
}

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used following
the terms of the GNU General Public License version 2 or at your option any
later version.  Please see included LICENSE.TXT for details.

=cut

__PACKAGE__->meta->make_immutable;
return 1;
