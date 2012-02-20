=head1 NAME 

LedgerSMB::Scripts::business_unit

=cut

package LedgerSMB::Scripts::business_unit;
use LedgerSMB::DBObject::Business_Unit_Class;
use LedgerSMB::DBObject::Business_Unit;
use LedgerSMB::Template;

=head1 SYNOPSIS

Workflow routines for LedgerSMB business reporting units

=head1 FUNCTIONS

All functions take a single $request object as their sole argument

=over

=item list_classes

=cut

sub list_classes {
    my ($request) = @_;
    my $bu_class = LedgerSMB::DBObject::Business_Unit_Class->new(%$request);
    @{$request->{classes}} = $bu_class->list;
    my $template = LedgerSMB::Template->new(
        user =>$request->{_user},
        locale => $request->{_locale},
        path => 'UI/business_units',
        template => 'list_classes',
        format => 'HTML'
    );
    $template->render($request);
}

=item add

Adds a new business unit.  $request->{class_id} must be set.

=cut

sub add {
    my ($request) = @_;
    
}

=item edit

Edits an existing business unit.  $request->{id} must be set.

=cut

sub edit {
    my ($request) = @_;
}

=item list

Lists business units.  The following properties of $request may be set:

=over

=item class_id (required)

Lists units for appropriate class.

=item active_on

If set filters for units active on the date in question, inclusive of start/end
dates

=item credit_id

If set, filters excludes those which are for customers/vendors other than than 
identified by this value.

=item strict_credit_id 

If set, excludes those which are not associated with customers/vendors.

=back

=cut

sub list {
    my ($request) = @_;
}

=item delete

Deletes an existing business unit.  Only vaid for ones with no transactions or 
sub-units.

$request->{id} must be set.

=cut

sub delete {
    my ($request) = @_;
    my $unit = LedgerSMB::DBObject::Business_Unit->new($request);
    $unit->delete;
    list($request);
}

=item delete_class

Deletes an existing business unit class.  Only valid of no units are of class.

$request->{id} must be set.

=cut

sub delete_class {
    my ($request) = @_;
    my $bu_class = LedgerSMB::DBObject::Business_Unit_Class->new($request);
    $bu_class->delete;
    list_classes($request);
}

=item save

Saves the existing unit.  Standard properties of 
LedgerSMB::DBObject::Business_Unit must be set for $request.

=cut

sub save {
    my ($request) = @_;
    my $unit = LedgerSMB::DBObject::Business_Unit->new($request);
    $unit->save;
    edit($request);
}

=item save_class

Saves the existing unit class.  Standard properties for 
LedgerSMB::DBObject::Business_Unit_Class must be set for $request.

=cut

sub save_class {
    my ($request) = @_;
    my $bu_class = LedgerSMB::DBObject::Business_Unit_Class->new($request);
    $bu_class->save;
    list_classes($request);
}

=back

=head COPYRIGHT

Copyright (C) 2012 LedgerSMB core team.  Redistribution and use of work is 
governed under the GNU General Public License, version 2 or at your option any
later version.

=cut

1;
