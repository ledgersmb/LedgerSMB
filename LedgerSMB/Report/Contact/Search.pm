=head1 NAME

LedgerSMB::Report::Contact::Search - Search for Customers, Vendors,
and more.

=head1 SYNPOSIS

  my $report = LedgerSMB::Report::GL->new(%$request);
  $report->run;
  $report->render($request, $format);

=head1 DESCRIPTION

This report provides contact search facilities.  It can be used to search for
any sort of company or person, whether sales lead, vendor, customer, or
referral.

=head1 INHERITS

=over

=item LedgerSMB::Report;

=back

=cut

package LedgerSMB::Report::Contact::Search;
use Moose;
use LedgerSMB::MooseTypes;
extends 'LedgerSMB::Report';

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

    my $entity_class_param = '';
    $entity_class_param = "&entity_class=".$self->entity_class
        if $self->entity_class;

    return [
       {col_id => 'name',
            type => 'href',
       href_base => "contact.pl?action=get$entity_class_param",
            name => LedgerSMB::Report::text('Name') },

       {col_id => 'entity_control_code',
            type => 'href',
       href_base => "contact.pl?action=get$entity_class_param",
            name => LedgerSMB::Report::text('Control Code') },

       {col_id => 'meta_number',
            type => 'href',
       href_base => "contact.pl?action=get$entity_class_param",
            name => LedgerSMB::Report::text('Credit Account Number') },

       {col_id => 'credit_description',
            type => 'text',
            name => LedgerSMB::Report::text('Description') },

       {col_id => 'business_type',
            type => 'text',
            name => LedgerSMB::Report::text('Business Type') },

       {col_id => 'curr',
            type => 'text',
            name => LedgerSMB::Report::text('Currency') },
    ];
}

=item name

=cut

sub name { return LedgerSMB::Report::text('Contact Search') }

=item header_lines

=cut

sub header_lines {
     return [
            {name => 'name_part',
             text => LedgerSMB::Report::text('Name')},
            {name => 'meta_number',
             text => LedgerSMB::Report::text('Account Number')}
       ];
}

=back

=head1 CRITERIA PROPERTIES

=over

=item entity_class

The account/entity class of the contact.  Required and an exact match.

=cut

has entity_class => (is => 'ro', isa => 'Int');

=item name_part

Full text search on contact name.  This also matches the beginning of a
company's name.  So Acme Software Testing Inc would come up under searches of
'Ac', 'Software', 'Software Tester', and so forth but not 'Sting' or 'are.'

=cut

has name_part => (is => 'ro', isa => 'Str', required => 0);

=item control_code

Matches the beginning of the control code string

=cut

has control_code => (is => 'ro', isa => 'Str', required => 0);

=item contact_info

Aggregated from email, phone, fax, etc.  Aggregated by this report (internal).

=cut

has contact_info => (is => 'ro', isa => 'ArrayRef[Str]]', required => 0);

=item email

Email address, exact match on any email address.

=cut

has email => (is => 'ro', isa => 'Str', required => 0);

=item phone

Exact match on phone any phone number, fax, etc.

=cut

has phone => (is => 'ro', isa => 'Str', required => 0);

=item contact

Full text search on contact string

=cut

has contact => (is => 'ro', isa => 'Str', required => 0);


=item meta_number

Matches beginning of customer/vendor/etc. number.

=cut

has meta_number => (is => 'ro', isa => 'Str', required => 0);

=item notes

Full text search of all entity/eca notes

=cut

has notes => (is => 'ro', isa => 'Str', required => 0);

=item address

Full text search (fully matching) on any address line.

=cut

has address => (is => 'ro', isa => 'Str', required => 0);

=item city

City contains this string.

=cut

has city => (is => 'ro', isa => 'Str', required => 0);

=item state

State or province contains this string

=cut

has state => (is => 'ro', isa => 'Str', required => 0);

=item mail_code

Match on beginning of mail or post code

=cut

has mail_code => (is => 'ro', isa => 'Str', required => 0);

=item country

Full or short name of country (i.e. US or United States, or CA or Canada).

=cut

has country => (is => 'ro', isa => 'Str', required => 0);

=item active_date_from

Active items only from this date.

=item active_date_to

Active items only to this date.

=cut

has active_date_from => (is => 'ro',
                        isa => 'LedgerSMB::Moose::Date',
                     coerce => 1,
                   required => 0);
has active_date_to => (is => 'ro',
                      isa => 'LedgerSMB::Moose::Date',
                   coerce => 1,
                 required => 0);

=item users

If the entity_class is 3 then this restricts the report to only users.

=cut

has users => (is => 'ro', isa => 'Bool', required => 0);

=back

=head1 METHODS

=over

=item run_report

Runs the report, populates rows.

=cut

sub run_report {
    my ($self) = @_;
    my @rows = $self->call_dbmethod(funcname => 'contact__search');
    for my $r(@rows){
        $r->{meta_number} ||= "";
        $r->{name_href_suffix} =
               "&entity_id=$r->{entity_id}&meta_number=$r->{meta_number}";
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

1;
