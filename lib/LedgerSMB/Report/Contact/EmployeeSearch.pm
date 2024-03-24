package LedgerSMB::Report::Contact::EmployeeSearch;

=head1 NAME

LedgerSMB::Report::Contact::EmployeeSearch - Search for employees
and more.

=head1 SYNPOSIS

  my $report = LedgerSMB::Report::Contact::EmployeeSearch->new(%$request);
  $report->render();

=head1 DESCRIPTION

This report provides employee search facilities.

=head1 INHERITS

=over

=item LedgerSMB::Report;

=back

=cut

use Moose;
use namespace::autoclean;
use LedgerSMB::MooseTypes;
extends 'LedgerSMB::Report::Contact::Search';

=head1 PROPERTIES

This report doesn't add any properties over its parent
C<LedgerSMB::Report::Contact::Search>.

=over

=item columns

Read-only accessor, returns a list of columns.

=cut

sub columns {
    my ($self) = @_;
    my $script = 'contacts.pl';

    my $entity_class_param = '';
    $entity_class_param = '&entity_class='.$self->entity_class
        if $self->entity_class;

    return [
       {col_id => 'name',
            type => 'href',
       href_base => "contact.pl?__action=get$entity_class_param",
            name => $self->Text('Name') },

       {col_id => 'entity_control_code',
            type => 'href',
       href_base => "contact.pl?__action=get$entity_class_param",
            name => $self->Text('Control Code') },

       {col_id => 'role',
            type => 'text',
            name => $self->Text('Job Title') },

       {col_id => 'dob',
            type => 'text',
            name => $self->Text('Birthdate') },

       {col_id => 'startdate',
            type => 'text',
            name => $self->Text('Start date') },

       {col_id => 'enddate',
            type => 'text',
            name => $self->Text('End date') },
    ];
}

=item name

=cut

sub name {
    my ($self) = @_;
    return $self->Text('Employee Search');
}

=item header_lines

=cut

sub header_lines {
    my ($self) = @_;
     return [
            {value => $self->name_part,
             text  => $self->Text('Name')},
       ];
}

=back

=head1 CRITERIA PROPERTIES

This report adds no criteria over the parent class
C<LedgerSMB::Report::Contact::Search>.

=head1 METHODS

=over

=item run_report

Runs the report, populates rows.

=cut

sub run_report {
    my ($self) = @_;
    my @contact_info;
    push @contact_info, $self->phone if $self->phone;
    push @contact_info, $self->email if $self->email;
    $self->contact_info(\@contact_info) if @contact_info;
    my @rows = $self->call_dbmethod(funcname => 'employee__search');
    for my $r(@rows){
        $r->{name_href_suffix} =
               "&entity_id=$r->{entity_id}";
        $r->{entity_control_code_href_suffix} = $r->{name_href_suffix};
    }
    return $self->rows(\@rows);
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2024 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
